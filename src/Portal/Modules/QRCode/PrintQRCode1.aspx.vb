Imports System
Imports System.Drawing
Imports System.Drawing.Imaging
Imports System.IO
Imports QRCoder

Public Class PrintQRCode1
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
            Return
        End If

        ' (اختياري) منع غير الأدمن
        'If SessionManager.GetInstance.Users.UserType <> 1 Then
        '    Response.Redirect("/Default.aspx")
        '    Return
        'End If

        If Not IsPostBack Then
            Dim typeStr As String = (Request.QueryString("Type") & "").Trim()
            Dim idStr As String = (Request.QueryString("ID") & "").Trim()

            Dim entityId As Integer
            If String.IsNullOrWhiteSpace(typeStr) OrElse Not Integer.TryParse(idStr, entityId) OrElse entityId <= 0 Then
                litInfo.Text = "<span class='text-danger'>Invalid parameters.</span>"
                Return
            End If

            ' جلب/إنشاء Token ثابت من DB
            Dim tokenGuid As Guid = GetOrCreateToken(typeStr, entityId)

            ' محتوى الـ QR (ليس URL)
            Dim qrText As String = "CRMQR:" & tokenGuid.ToString()

            imgQR.ImageUrl = GenerateQrDataUrl(qrText)

            litInfo.Text =
                    "النوع: <b>" & Server.HtmlEncode(typeStr) & "</b>" &
                    " | ID: <b>" & entityId.ToString() & "</b><br/>" &
                    "Token: <span style='direction:ltr;display:inline-block;'>" & tokenGuid.ToString() & "</span>"
        End If
    End Sub

    Private Function GetOrCreateToken(ByVal entityType As String, ByVal entityId As Integer) As Guid
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            ' هذا يفترض أنك أضفت SP (QR_GetOrCreate) إلى LINQ DataContext
            Dim res = db.QR_GetOrCreate(entityType, entityId).FirstOrDefault()

            If res Is Nothing OrElse res.Token Is Nothing Then
                Throw New Exception("Failed to get/create QR token.")
            End If

            Return Guid.Parse(res.Token.ToString())
        End Using
    End Function

    Private Function GenerateQrDataUrl(ByVal content As String) As String
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

    Protected Sub btnBack_Click(sender As Object, e As EventArgs)
        ' يرجع للصفحة السابقة إن وجدت
        If Request.UrlReferrer IsNot Nothing Then
            Response.Redirect(Request.UrlReferrer.ToString())
        Else
            Response.Redirect("/Default.aspx")
        End If
    End Sub

End Class