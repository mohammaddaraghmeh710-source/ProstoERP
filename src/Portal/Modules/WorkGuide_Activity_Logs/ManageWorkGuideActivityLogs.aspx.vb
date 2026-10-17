Imports System.Data.SqlClient
Imports System.Globalization

Public Class ManageWorkGuideActivityLogs
    Inherits HRTypePageBase

    Private Const PageSize As Integer = 50
    Private ExportResponse As Boolean

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Try
                ddlCategory.DataSource = WorkGuideAccess.Query("dbo.Select_Work_Guide_Log_Categories",
                                                               WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int,
                                                                                         SessionManager.GetInstance.
                                                                                            Users.UserID))
                ddlCategory.DataTextField = "Category_Name"
                ddlCategory.DataValueField = "ID"
                ddlCategory.DataBind()
                ddlCategory.Items.Insert(0, New ListItem("جميع التصنيفات", "0"))
                BindLogs()
            Catch ex As SqlException
                ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
            End Try
        End If
    End Sub

    Private Function ReadDate(input As TextBox, ByRef value As DateTime?) As Boolean
        value = Nothing
        If String.IsNullOrWhiteSpace(input.Text) Then Return True
        Dim parsed As DateTime
        If _
            Not _
            DateTime.TryParseExact(input.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None,
                                   parsed) Then Return False
        value = parsed.Date
        Return True
    End Function

    Private Function ReadFilters(ByRef fromDate As DateTime?, ByRef toDate As DateTime?) As Boolean
        litMessage.Text = ""
        If Not ReadDate(txtFrom, fromDate) OrElse Not ReadDate(txtTo, toDate) Then
            ClearResults()
            ShowMessage(litMessage, "أدخل تاريخًا صالحًا في حقلي البحث.")
            Return False
        End If
        If fromDate.HasValue AndAlso toDate.HasValue AndAlso fromDate.Value > toDate.Value Then
            ClearResults()
            ShowMessage(litMessage, "يجب أن يكون تاريخ البداية قبل تاريخ النهاية أو مساويًا له.")
            Return False
        End If
        Return True
    End Function

    Private Function FetchLogs(fromDate As DateTime?, toDate As DateTime?, exportAll As Boolean) As DataTable
        Dim category As Integer? = Nothing
        If ddlCategory.SelectedValue <> "0" AndAlso ddlCategory.SelectedValue <> "" Then _
            category = Integer.Parse(ddlCategory.SelectedValue)
        Return WorkGuideAccess.Query("dbo.Select_Work_Guide_Activity_Logs_Admin",
                                     WorkGuideAccess.Parameter("@Admin_ID", SqlDbType.Int,
                                                               SessionManager.GetInstance.Users.UserID),
                                     WorkGuideAccess.Parameter("@User_Name", SqlDbType.NVarChar, txtUser.Text.Trim(),
                                                               200),
                                     WorkGuideAccess.Parameter("@Document_Name", SqlDbType.NVarChar,
                                                               txtDocument.Text.Trim(), 200),
                                     WorkGuideAccess.Parameter("@Date_From", SqlDbType.Date, fromDate),
                                     WorkGuideAccess.Parameter("@Date_To", SqlDbType.Date, toDate),
                                     WorkGuideAccess.Parameter("@Category_ID", SqlDbType.Int, category),
                                     WorkGuideAccess.Parameter("@PageNumber", SqlDbType.Int, 1),
                                     WorkGuideAccess.Parameter("@PageSize", SqlDbType.Int, PageSize),
                                     WorkGuideAccess.Parameter("@Export_All", SqlDbType.Bit, exportAll))
    End Function

    Private Sub BindLogs()
        Dim fromDate As DateTime? = Nothing, toDate As DateTime? = Nothing
        If Not ReadFilters(fromDate, toDate) Then Return
        Try
            Dim data = FetchLogs(fromDate, toDate, True)
            lstLogs.DataSource = data
            lstLogs.DataBind()
        Catch ex As SqlException
            ClearResults()
            ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
        End Try
    End Sub

    Protected Sub btnExport_Click(sender As Object, e As EventArgs)
        Dim fromDate As DateTime? = Nothing, toDate As DateTime? = Nothing
        If Not ReadFilters(fromDate, toDate) Then Return
        Dim bytes As Byte()
        Try
            Dim data = FetchLogs(fromDate, toDate, True)
            If data.Rows.Count = 0 Then
                ShowMessage(litMessage, "لا توجد نتائج مطابقة لفلاتر البحث لتصديرها.")
                Return
            End If
            If Not String.IsNullOrWhiteSpace(hfExportLogIDs.Value) Then
                data = WorkGuideLogExport.FilterRows(data, hfExportLogIDs.Value)
                If data.Rows.Count = 0 Then
                    ShowMessage(litMessage, "لا توجد نتائج مطابقة لبحث الجدول لتصديرها.")
                    Return
                End If
            End If
            bytes = WorkGuideLogExport.CreateWorkbook(data)
        Catch ex As SqlException
            ShowMessage(litMessage, WorkGuideAccess.ErrorText(ex))
            Return
        Catch ex As InvalidOperationException
            Diagnostics.Trace.TraceError("Work guide Excel export: {0}", ex.ToString())
            ShowMessage(litMessage,
                        "تعذّر إنشاء الملف. قلّل عدد النتائج أو طول تفاصيلها باستخدام فلاتر البحث ثم أعد المحاولة.")
            Return
        End Try
        Response.Clear()
        Response.BufferOutput = True
        Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        Response.AddHeader("Content-Disposition",
                           "attachment; filename=work-guide-logs-" &
                           DateTime.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture) & ".xlsx")
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Cache.SetNoStore()
        Response.BinaryWrite(bytes)
        ExportResponse = True
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        ' CompleteRequest does not skip Page.Render; keep HTML out of the XLSX response.
        If Not ExportResponse Then MyBase.Render(writer)
    End Sub

    Private Sub ClearResults()
        lstLogs.DataSource = Nothing
        lstLogs.DataBind()
    End Sub

    Public Function ActionText(value As Object) As String
        Select Case Convert.ToString(value)
            Case "1" : Return "مشاهدة وثيقة"
            Case "2" : Return "تحميل وثيقة"
            Case Else : Return Convert.ToString(value)
        End Select
    End Function

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindLogs()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs)
        txtUser.Text = ""
        txtDocument.Text = ""
        txtFrom.Text = ""
        txtTo.Text = ""
        ddlCategory.SelectedIndex = 0
        BindLogs()
    End Sub
End Class


