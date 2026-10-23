Imports System.Data.SqlClient
Imports System.Globalization
Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Add_News
    Inherits PageBase

    Private NewsImagePath As String = Nothing

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ClearFileSession()
            NewsData.FillBrands(ddlBrand, "اختر العلامة التجارية")
        End If
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Page.Validate("NewsForm")
        If Not Page.IsValid Then Return
        Dim brand As Integer
        If Not Integer.TryParse(ddlBrand.SelectedValue, brand) OrElse brand <= 0 Then Return
        lblError.Visible = False
        Dim userId = SessionManager.GetInstance.Users.UserID

        Dim orderVal As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
            Dim o As Integer
            If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
        End If

        Dim dateVal As Nullable(Of DateTime) = Nothing
        If Not String.IsNullOrWhiteSpace(txtDate.Text) Then
            Dim d As DateTime
            ' input type datetime-local => "yyyy-MM-ddTHH:mm"
            If _
                DateTime.TryParseExact(txtDate.Text.Trim(), "yyyy-MM-ddTHH:mm", CultureInfo.InvariantCulture,
                                       DateTimeStyles.None, d) Then
                dateVal = d
            End If
        End If

        Try
            Using db As New Prosto_ERP_DataClassesDataContext

                Dim files = SaveFilesFromSession()
                If files IsNot Nothing AndAlso files.Count > 0 Then
                    For Each f In files
                        NewsImagePath = f.Key
                        Exit For
                    Next
                End If

            NewsData.Save(userId, brand, Nothing,
                If(String.IsNullOrWhiteSpace(txtTitleAr.Text), Nothing, txtTitleAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtTitleEn.Text), Nothing, txtTitleEn.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtBriefAr.Text), Nothing, txtBriefAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtBriefEn.Text), Nothing, txtBriefEn.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtDetails.Text), Nothing, txtDetails.Text.Trim()),
                If(String.IsNullOrWhiteSpace(NewsImagePath), Nothing, NewsImagePath),
                If(dateVal.HasValue, dateVal.Value, CType(Nothing, DateTime?)),
                orderVal,
                True, txtDetailsEn.Text
            )
        End Using

        Catch ex As ArgumentException
            lblError.Text = Server.HtmlEncode(ex.Message)
            lblError.Visible = True : Return
        Catch ex As System.Data.SqlClient.SqlException
            lblError.Text = "تعذّر حفظ الخبر. تحقق من العلامة التجارية وصلاحية الحساب ثم حاول مجددًا."
            lblError.Visible = True
            Return
        End Try

        Response.Redirect("/Modules/News/Manage_News.aspx?added=1")
    End Sub

    Protected Sub NewsImageUploader_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub NewsImageUploader_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub
End Class

