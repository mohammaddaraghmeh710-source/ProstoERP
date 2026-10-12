Imports System.Linq
Imports AjaxControlToolkit
Imports System.Globalization

Public Class Edit_News
    Inherits PageBase

    Private NewsImagePath As String = Nothing

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not IsPostBack Then
            ClearFileSession()
            Dim idStr As String = Request.QueryString("PID")
            Dim pid As Integer
            If Not Integer.TryParse(idStr, pid) Then
                Response.Redirect("/Modules/News/Manage_News.aspx")
            End If

            hfPID.Value = pid.ToString()
            FillData(pid)
        End If
    End Sub

    Private Sub FillData(pid As Integer)
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim row = db.Select_News_ByID(pid).FirstOrDefault()

            If row Is Nothing Then
                Response.Redirect("/Modules/News/Manage_News.aspx")
                Exit Sub
            End If

            txtTitleAr.Text = If(row.Title_AR, "")
            txtTitleEn.Text = If(row.Title_En, "")
            txtBriefAr.Text = If(row.Brief_Ar, "")
            txtBriefEn.Text = If(row.Brief_En, "")
            txtDetails.Text = If(row.Details, "")
            txtOrder.Text = If(row.Item_Order Is Nothing, "", row.Item_Order.ToString())
            chkIsActive.Checked = row.IsActive

            ' تاريخ الخبر (datetime-local)
            If row.Date IsNot Nothing Then
                Dim d As DateTime = CDate(row.Date)
                txtDate.Text = d.ToString("yyyy-MM-ddTHH:mm")
            Else
                txtDate.Text = ""
            End If

            hfImagePath.Value = If(row.Image, "")

            If Not String.IsNullOrWhiteSpace(hfImagePath.Value) Then
                litCurrentImage.Text =
                    "<div class='mt-2'><small class='text-muted'>الصورة الحالية:</small>" &
                    "<div><a target='_blank' href='" & hfImagePath.Value & "'>" & hfImagePath.Value & "</a></div></div>"
            Else
                litCurrentImage.Text = ""
            End If
        End Using
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim userId = SessionManager.GetInstance.Users.UserID
        Dim pid As Integer = Convert.ToInt32(hfPID.Value)

        Dim orderVal As Nullable(Of Integer) = Nothing
        If Not String.IsNullOrWhiteSpace(txtOrder.Text) Then
            Dim o As Integer
            If Integer.TryParse(txtOrder.Text.Trim(), o) Then orderVal = o
        End If

        Dim dateVal As Nullable(Of DateTime) = Nothing
        If Not String.IsNullOrWhiteSpace(txtDate.Text) Then
            Dim d As DateTime
            If DateTime.TryParseExact(txtDate.Text.Trim(), "yyyy-MM-ddTHH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then
                dateVal = d
            End If
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

            NewsImagePath = hfImagePath.Value

            Dim files = SaveFilesFromSession()
            If files IsNot Nothing AndAlso files.Count > 0 Then
                For Each f In files
                    NewsImagePath = f.Key
                    Exit For
                Next
            End If

            db.Update_News_ByID(
                pid,
                If(String.IsNullOrWhiteSpace(txtTitleAr.Text), Nothing, txtTitleAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtTitleEn.Text), Nothing, txtTitleEn.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtBriefAr.Text), Nothing, txtBriefAr.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtBriefEn.Text), Nothing, txtBriefEn.Text.Trim()),
                If(String.IsNullOrWhiteSpace(txtDetails.Text), Nothing, txtDetails.Text.Trim()),
                If(String.IsNullOrWhiteSpace(NewsImagePath), Nothing, NewsImagePath),
                If(dateVal.HasValue, dateVal.Value, CType(Nothing, DateTime?)),
                orderVal,
                chkIsActive.Checked,
                userId
            )
        End Using

        Response.Redirect("/Modules/News/Manage_News.aspx?updated=1")
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