Imports System.IO

Public NotInheritable Class CircularsDocuments
    Public Shared Function Pdf(file As HttpPostedFile) As Byte()
        If _
            file Is Nothing OrElse file.ContentLength = 0 OrElse file.ContentLength > 10485760 OrElse
            Not String.Equals(Path.GetExtension(file.FileName), ".pdf", StringComparison.OrdinalIgnoreCase) Then _
            Throw New ArgumentException("اختر ملف PDF لا يتجاوز 10MB.")
        For Each character As Char In file.FileName
            If Char.IsControl(character) Then Throw New ArgumentException("اسم الملف غير صالح.")
        Next
        Dim bytes(file.ContentLength - 1) As Byte
        Dim offset = 0
        While offset < bytes.Length
            Dim read = file.InputStream.Read(bytes, offset, bytes.Length - offset)
            If read = 0 Then Throw New ArgumentException("لم يكتمل رفع الملف.")
            offset += read
        End While
        If _
            bytes.Length < 8 OrElse Encoding.ASCII.GetString(bytes, 0, 5) <> "%PDF-" OrElse
            Not _
            Encoding.ASCII.GetString(bytes, Math.Max(0, bytes.Length - 2048), Math.Min(2048, bytes.Length)).
                Contains("%%EOF") Then Throw New ArgumentException("محتوى الملف ليس PDF صالحًا.")
        Return bytes
    End Function
End Class


