using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Prosto_ERP_API.Mobile
{
    internal sealed class CorrespondenceFiles : IDisposable
    {
        internal const int MaxBytes = 10 * 1024 * 1024;
        private const int MaxBody = 51 * 1024 * 1024;
        private readonly List<Part> files = new List<Part>();
        private readonly List<string> paths = new List<string>();
        internal string Data;
        internal bool PreserveFiles;
        internal string Xml { get; private set; }

        internal static string Root
        {
            get
            {
                var root = ConfigurationManager.AppSettings["MobileApi.CorrespondenceStoragePath"];
                if (string.IsNullOrWhiteSpace(root) || !Path.IsPathRooted(root))
                    throw new ConfigurationErrorsException(
                        "Configure the shared Portal/FileManager/Correspondence storage.");
                return Path.GetFullPath(root);
            }
        }

        public void Dispose()
        {
            if (!PreserveFiles)
                foreach (var path in paths)
                    try
                    {
                        File.Delete(path);
                    }
                    catch (IOException)
                    {
                        Trace.TraceWarning("Unable to clean uncommitted correspondence attachment.");
                    }
        }

        internal static async Task<CorrespondenceFiles> Read(HttpRequestMessage request)
        {
            var result = new CorrespondenceFiles();
            if (request.Content == null || !request.Content.IsMimeMultipartContent("form-data"))
                throw new FeedbackException(HttpStatusCode.UnsupportedMediaType, "MULTIPART_REQUIRED",
                    "أرسل data والملفات باستخدام multipart/form-data.");
            if (request.Content.Headers.ContentLength > MaxBody) throw TooLarge();
            try
            {
                await request.Content.LoadIntoBufferAsync(MaxBody);
            }
            catch (HttpRequestException)
            {
                throw TooLarge();
            }

            var provider = new LimitedProvider();
            try
            {
                try
                {
                    await request.Content.ReadAsMultipartAsync(provider);
                }
                catch (Exception ex)
                {
                    for (var inner = ex; inner != null; inner = inner.InnerException)
                    {
                        var known = inner as FeedbackException;
                        if (known != null) throw known;
                    }

                    if (ex is IOException || ex is HttpRequestException) throw FeedbackController.Invalid();
                    throw;
                }

                foreach (var content in provider.Contents)
                {
                    var header = content.Headers.ContentDisposition;
                    if (header == null || header.DispositionType != "form-data") throw FeedbackController.Invalid();
                    var key = (header.Name ?? "").Trim('"');
                    if (key == "data" && header.FileName == null && header.FileNameStar == null)
                    {
                        if (result.Data != null) throw FeedbackController.Invalid();
                        var bytes = await content.ReadAsByteArrayAsync();
                        if (bytes.Length > 65536) throw TooLarge();
                        result.Data = new UTF8Encoding(false, true).GetString(bytes);
                    }
                    else if (key == "files")
                    {
                        if (result.files.Count >= 5) throw TooLarge();
                        var name = (header.FileNameStar ?? header.FileName ?? "").Trim('"');
                        var ext = Path.GetExtension(name).TrimStart('.').ToLowerInvariant();
                        if (!new[] { "pdf", "doc", "docx", "xls", "xlsx", "png", "jpg", "jpeg", "gif" }.Contains(ext))
                            throw new FeedbackException(HttpStatusCode.BadRequest, "FILE_TYPE",
                                "المرفقات المسموحة: PDF وWord وExcel والصور.");
                        var bytes = await content.ReadAsByteArrayAsync();
                        if (bytes.Length == 0 || bytes.Length > MaxBytes) throw TooLarge();
                        result.files.Add(new Part { Bytes = bytes, Extension = ext, Name = Path.GetFileName(name) });
                    }
                    else
                    {
                        throw FeedbackController.Invalid();
                    }
                }

                if (result.Data == null) throw FeedbackController.Invalid();
                return result;
            }
            finally
            {
                foreach (var content in provider.Contents) content.Dispose();
            }
        }

        internal byte[] Hash(string model)
        {
            using (var sha = SHA256.Create())
            {
                var prefix = Encoding.UTF8.GetBytes(model);
                sha.TransformBlock(prefix, 0, prefix.Length, null, 0);
                foreach (var file in files)
                {
                    var name = Encoding.UTF8.GetBytes("\n" + file.Name + "\n" + file.Bytes.Length + "\n");
                    sha.TransformBlock(name, 0, name.Length, null, 0);
                    sha.TransformBlock(file.Bytes, 0, file.Bytes.Length, null, 0);
                }

                sha.TransformFinalBlock(new byte[0], 0, 0);
                return sha.Hash;
            }
        }

        internal void Prepare()
        {
            var xml = new XElement("files");
            // Validate every attachment before persisting any of them.
            foreach (var file in files)
                if (file.Extension == "pdf")
                {
                    if (file.Bytes.Length < 5 || Encoding.ASCII.GetString(file.Bytes, 0, 5) != "%PDF-") throw BadFile();
                }
                else if (file.Extension == "docx" || file.Extension == "xlsx")
                {
                    try
                    {
                        using (var input = new MemoryStream(file.Bytes))
                        using (var archive = new ZipArchive(input, ZipArchiveMode.Read))
                        {
                            var entry = file.Extension == "docx" ? "word/document.xml" : "xl/workbook.xml";
                            if (archive.GetEntry(entry) == null || archive.GetEntry("[Content_Types].xml") == null ||
                                archive.Entries.Any(e =>
                                    e.FullName.EndsWith("vbaProject.bin", StringComparison.OrdinalIgnoreCase)))
                                throw BadFile();
                        }
                    }
                    catch (InvalidDataException)
                    {
                        throw BadFile();
                    }
                }
                else if (file.Extension == "doc" || file.Extension == "xls")
                {
                    byte[] signature = { 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1 };
                    if (file.Bytes.Length < 8 || !file.Bytes.Take(8).SequenceEqual(signature)) throw BadFile();
                }
                else
                {
                    try
                    {
                        using (var input = new MemoryStream(file.Bytes))
                        using (var image = Image.FromStream(input, true, true))
                        {
                            if ((long)image.Width * image.Height > 20000000) throw BadFile();
                            using (var clean = new Bitmap(image.Width, image.Height))
                            using (var graphics = Graphics.FromImage(clean))
                            using (var output = new MemoryStream())
                            {
                                graphics.DrawImage(image, 0, 0, image.Width, image.Height);
                                clean.Save(output, ImageFormat.Png);
                                file.Bytes = output.ToArray();
                                file.Extension = "png";
                            }
                        }
                    }
                    catch (ArgumentException)
                    {
                        throw BadFile();
                    }

                    if (file.Bytes.Length > MaxBytes) throw TooLarge();
                }

            if (files.Count > 0) Directory.CreateDirectory(Root);
            foreach (var file in files)
            {
                var name = Guid.NewGuid().ToString("N") + "." + file.Extension;
                var path = Path.Combine(Root, name);
                paths.Add(path);
                using (var stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    stream.Write(file.Bytes, 0, file.Bytes.Length);
                    stream.Flush(true);
                }

                // Neutral stored labels also avoid exposing a device path or an identity in the filename.
                xml.Add(new XElement("file", new XAttribute("name", name), new XAttribute("type", Mime(file.Extension)),
                    new XAttribute("original", "attachment." + file.Extension),
                    new XAttribute("size", file.Bytes.Length)));
            }

            Xml = xml.ToString(SaveOptions.DisableFormatting);
        }

        private static FeedbackException BadFile()
        {
            return new FeedbackException(HttpStatusCode.BadRequest, "INVALID_FILE",
                "الملف غير صالح أو أبعاد الصورة أكبر من المسموح.");
        }

        private static FeedbackException TooLarge()
        {
            return new FeedbackException((HttpStatusCode)413, "UPLOAD_LIMIT", "الحد الأقصى خمسة ملفات، 10MB لكل ملف.");
        }

        internal static string Mime(string ext)
        {
            switch (ext)
            {
                case "doc": return "application/msword";
                case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
                case "xls": return "application/vnd.ms-excel";
                case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                case "pdf": return "application/pdf";
                case "png": return "image/png";
                case "jpg":
                case "jpeg": return "image/jpeg";
                case "gif": return "image/gif";
                default: return "application/octet-stream";
            }
        }

        private sealed class Part
        {
            internal byte[] Bytes;
            internal string Extension;
            internal string Name;
        }

        private sealed class LimitedProvider : MultipartMemoryStreamProvider
        {
            private int count;

            public override Stream GetStream(HttpContent parent, HttpContentHeaders headers)
            {
                if (++count > 6) throw TooLarge();
                return base.GetStream(parent, headers);
            }
        }
    }
}
