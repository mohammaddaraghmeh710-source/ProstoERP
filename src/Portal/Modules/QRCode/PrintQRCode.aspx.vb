Imports System.Drawing
Imports System.Drawing.Imaging
Imports System.IO
Imports Prosto_ERP_ClassLibrary
Imports QRCoder

Public Class PrintQRCode
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
            Return
        End If

        If Not IsPostBack Then

            Dim typeStr As String = (Request.QueryString("Type") & "").Trim()
            Dim idStr As String = (Request.QueryString("ID") & "").Trim()

            Dim entityId As Integer
            If String.IsNullOrWhiteSpace(typeStr) OrElse Not Integer.TryParse(idStr, entityId) OrElse entityId <= 0 Then
                Response.Write("Invalid parameters")
                Response.End()
                Return
            End If

            ' ✅ جلب/إنشاء Token ثابت من DB (Stored Procedure)
            Dim tokenGuid As Guid

            Using db As New Prosto_ERP_DataClassesDataContext
                Dim res = db.QR_GetOrCreate(typeStr, entityId).FirstOrDefault()
                If res Is Nothing OrElse res.Token Is Nothing Then
                    Throw New Exception("Failed to get/create QR token.")
                End If
                tokenGuid = Guid.Parse(res.Token.ToString())
            End Using

            ' ✅ محتوى QR (ليس رابط)
            Dim qrText As String = "CRMQR:" & tokenGuid.ToString()

            imgQR.ImageUrl = GenerateQrDataUrl(qrText)
        End If
    End Sub

    Private Function GenerateQrDataUrl(content As String) As String
        Using generator As New QRCodeGenerator()
            Using data = generator.CreateQrCode(content, QRCodeGenerator.ECCLevel.Q)
                Using qr As New QRCode(data)
                    Using bmp As Bitmap = qr.GetGraphic(20)
                        Using ms As New MemoryStream()
                            bmp.Save(ms, ImageFormat.Png)
                            Dim base64 As String = Convert.ToBase64String(ms.ToArray())
                            Return "data:image/png;base64," & base64
                        End Using
                    End Using
                End Using
            End Using
        End Using
    End Function
End Class

