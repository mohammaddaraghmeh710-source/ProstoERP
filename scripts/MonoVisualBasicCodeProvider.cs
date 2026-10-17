// Local macOS hosting bridge: Mono's VB compiler cannot parse modern generated
// Web Forms code, while the NuGet Roslyn provider calls Windows-only kernel APIs.
// Use Mono's code generator and invoke the already restored Roslyn compiler.
using System;
using System.CodeDom;
using System.CodeDom.Compiler;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;

namespace Prosto.Development
{
    public sealed class MonoVisualBasicCodeProvider : Microsoft.VisualBasic.VBCodeProvider
    {
        public override CompilerResults CompileAssemblyFromDom(CompilerParameters options, params CodeCompileUnit[] units)
        {
            var paths = new string[units.Length];
            for (int i = 0; i < units.Length; i++)
            {
                paths[i] = options.TempFiles.AddExtension(i + ".vb");
                using (var writer = new StreamWriter(paths[i]))
                    GenerateCodeFromCompileUnit(units[i], writer, new CodeGeneratorOptions());
            }
            return CompileAssemblyFromFile(options, paths);
        }

        public override CompilerResults CompileAssemblyFromSource(CompilerParameters options, params string[] sources)
        {
            var paths = new string[sources.Length];
            for (int i = 0; i < sources.Length; i++)
            {
                paths[i] = options.TempFiles.AddExtension(i + ".vb");
                File.WriteAllText(paths[i], sources[i]);
            }
            return CompileAssemblyFromFile(options, paths);
        }

        public override CompilerResults CompileAssemblyFromFile(CompilerParameters options, params string[] files)
        {
            var compiler = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "bin/roslyn/vbc.exe");
            if (!File.Exists(compiler)) throw new FileNotFoundException("Build Portal to restore bin/roslyn/vbc.exe.", compiler);
            var response = options.TempFiles.AddExtension("rsp");
            if (string.IsNullOrEmpty(options.OutputAssembly)) options.OutputAssembly = options.TempFiles.AddExtension("dll");
            using (var writer = new StreamWriter(response))
            {
                writer.WriteLine("/nologo /utf8output /target:library /optioninfer+ /define:_MYTYPE=\"Web\"");
                writer.WriteLine("/sdkpath:" + Quote(Path.GetDirectoryName(typeof(object).Assembly.Location)));
                writer.WriteLine("/out:" + Quote(options.OutputAssembly));
                if (options.IncludeDebugInformation) writer.WriteLine("/debug:portable");
                writer.WriteLine(options.CompilerOptions);
                foreach (string reference in options.ReferencedAssemblies) writer.WriteLine("/reference:" + Quote(reference));
                foreach (string resource in options.EmbeddedResources) writer.WriteLine("/resource:" + Quote(resource));
                foreach (string file in files) writer.WriteLine(Quote(file));
            }
            var info = new ProcessStartInfo("mono", Quote(compiler) + " @" + Quote(response)) {
                UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true,
                CreateNoWindow = true
            };
            var result = new CompilerResults(options.TempFiles);
            using (var process = Process.Start(info))
            {
                var output = process.StandardOutput.ReadToEnd();
                var error = process.StandardError.ReadToEnd();
                process.WaitForExit();
                result.NativeCompilerReturnValue = process.ExitCode;
                foreach (var line in (output + "\n" + error).Split('\n'))
                {
                    if (line.Length == 0) continue;
                    result.Output.Add(line);
                    var match = Regex.Match(line, @"^(?:(.+)\((\d+)(?:,(\d+))?\)\s*:\s*)?(?:vbc\s*:\s*)?(error|warning)\s+(BC\d+)\s*:\s*(.*)$");
                    if (match.Success)
                        result.Errors.Add(new CompilerError(match.Groups[1].Value,
                            match.Groups[2].Success ? int.Parse(match.Groups[2].Value) : 0,
                            match.Groups[3].Success ? int.Parse(match.Groups[3].Value) : 0,
                            match.Groups[5].Value, match.Groups[6].Value) { IsWarning = match.Groups[4].Value == "warning" });
                }
                if (process.ExitCode != 0 && !result.Errors.HasErrors)
                    result.Errors.Add(new CompilerError("", 0, 0, "ROSLYN", output + error));
            }
            result.PathToAssembly = options.OutputAssembly;
            if (options.GenerateInMemory && !result.Errors.HasErrors)
                result.CompiledAssembly = Assembly.Load(File.ReadAllBytes(options.OutputAssembly));
            return result;
        }

        private static string Quote(string value) { return "\"" + value.Replace("\"", "\\\"") + "\""; }
    }
}
