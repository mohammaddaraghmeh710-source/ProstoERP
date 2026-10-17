
Imports System.IO

Public Class DeptVideoHandler
    Implements IHttpHandler

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim token As String = context.Request.QueryString("t")

        If String.IsNullOrEmpty(token) Then
            context.Response.StatusCode = 404
            Return
        End If

        Dim rawBytes As Byte()

        Try
            rawBytes = MachineKey.Unprotect(HttpServerUtility.UrlTokenDecode(token), "DeptVideoToken")
        Catch ex As Exception
            context.Response.StatusCode = 404
            Return
        End Try

        If rawBytes Is Nothing OrElse rawBytes.Length = 0 Then
            context.Response.StatusCode = 404
            Return
        End If

        Dim payload As String = Encoding.UTF8.GetString(rawBytes)
        Dim parts = payload.Split("|"c)
        If parts.Length <> 2 Then
            context.Response.StatusCode = 404
            Return
        End If

        Dim virtualPath As String = parts(0)
        Dim ticks As Long

        If Not Long.TryParse(parts(1), ticks) Then
            context.Response.StatusCode = 404
            Return
        End If

        If DateTime.UtcNow.Ticks > ticks Then
            context.Response.StatusCode = 410 ' Gone (انتهت الصلاحية)
            Return
        End If

        Dim physicalPath As String = context.Server.MapPath(virtualPath)
        If Not File.Exists(physicalPath) Then
            context.Response.StatusCode = 404
            Return
        End If

        context.Response.Clear()
        context.Response.ContentType = "video/mp4"
        context.Response.AddHeader("Content-Disposition", "inline")
        context.Response.TransmitFile(physicalPath)
        context.Response.End()
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
End Class


