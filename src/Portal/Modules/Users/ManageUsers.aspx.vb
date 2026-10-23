Imports System.Data.SqlClient
Imports Prosto_ERP_ClassLibrary

Public Class ManageUsers
    Inherits PageBase

    Protected Overrides Sub OnInit(e As EventArgs)
        ViewStateUserKey = Session.SessionID
        MyBase.OnInit(e)
    End Sub

    Private Function DeviceQuery(procedure As String, ParamArray args() As SqlParameter) _
        As DataSet
        Using db As New Prosto_ERP_DataClassesDataContext,
            cn As New SqlConnection(db.Connection.ConnectionString),
            cmd As New SqlCommand(procedure, cn),
            adapter As New SqlDataAdapter(cmd)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@Actor", SessionManager.GetInstance.Users.UserID)
            cmd.Parameters.AddRange(args)
            Dim data As New DataSet()
            adapter.Fill(data)
            Return data
        End Using
    End Function

    Private Property DeviceUserID As Integer
        Get
            Return If(ViewState("DeviceUserID") Is Nothing, 0, CInt(ViewState("DeviceUserID")))
        End Get
        Set
            ViewState("DeviceUserID") = value
        End Set
    End Property

    Protected Function DeviceLabel(value As Object) As String
        Select Case Convert.ToString(value)
            Case "Pending" : Return "بانتظار الموافقة"
            Case "Approved" : Return "تمت الموافقة"
            Case "Rejected", "Reject" : Return "رفض الطلب"
            Case "Cancelled" : Return "أُلغي الطلب"
            Case "ApproveReplace" : Return "اعتماد الجهاز وإلغاء الأجهزة القديمة"
            Case "ApproveAdd" : Return "اعتماد الجهاز مع الإبقاء على الأجهزة"
            Case "ResetAll" : Return "إلغاء الجميع والسماح بتسجيل جهاز عند الدخول التالي"
            Case "Revoke", "MigratedRevoked" : Return "إلغاء الجهاز"
            Case "AutoEnrolled" : Return "اعتماد الجهاز عند الدخول"
            Case "MigratedApproved" : Return "اعتماد الجهاز المسجل سابقًا"
            Case "Requested" : Return "طلب السماح بجهاز جديد"
            Case Else : Return "—"
        End Select
    End Function

    Protected Function DeviceDate(value As Object) As String
        If value Is Nothing OrElse Convert.IsDBNull(value) Then Return "—"
        Return _
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(CDate(value), DateTimeKind.Utc),
                                            TimeZoneInfo.FindSystemTimeZoneById("Jordan Standard Time")).ToString(
                                                "dd/MM/yyyy HH:mm")
    End Function

    Private Sub ShowDevices()
        Dim data = DeviceQuery("dbo.MobileApi_DeviceAdminView",
                               New SqlParameter("@UserID", DeviceUserID))
        If data.Tables(0).Rows.Count = 0 Then Return
        Dim employee = data.Tables(0).Rows(0)
        litDeviceEmployee.Text = Server.HtmlEncode(Convert.ToString(employee("FullName_Ar"))) & " · الرقم الوظيفي " &
                                 Server.HtmlEncode(Convert.ToString(employee("Employee_Number"))) & " · ID " &
                                 DeviceUserID.ToString()
        litDeviceSummary.Text =
            "<div class='d-flex flex-wrap gap-2 mb-3'><span class='badge bg-label-success'>الأجهزة المسموحة: " &
            employee("ApprovedCount").ToString() &
            "</span><span class='badge bg-label-warning'>طلبات بانتظار الموافقة: " & employee("PendingCount").ToString() &
            "</span><span class='badge bg-label-info'>" &
            If _
                (CBool(employee("AllowNextEnrollment")), "سيُعتمد أول جهاز عند الدخول التالي",
                 "الدخول للأجهزة المعتمدة فقط") & "</span></div>"
        lstDevices.DataSource = data.Tables(1)
        lstDevices.DataBind()
        lstDeviceRequests.DataSource = data.Tables(2)
        lstDeviceRequests.DataBind()
        Dim history As New StringBuilder()
        For Each row As DataRow In data.Tables(3).Rows
            history.Append(
                "<div class='device-event'><div class='d-flex flex-wrap justify-content-between gap-2'><strong>" &
                DeviceLabel(row("Action")) & "</strong><small class='text-muted'>" & DeviceDate(row("CreatedUtc")) &
                "</small></div><div class='small text-muted mt-1'>" &
                Server.HtmlEncode(Convert.ToString(row("ActorName"))) & " · " &
                Server.HtmlEncode(Convert.ToString(row("DeviceModel"))) & "</div><div class='device-id'>" &
                Server.HtmlEncode(Convert.ToString(row("DeviceID"))) & "</div><div class='small'>" &
                Server.HtmlEncode(Convert.ToString(row("Comment"))) & "</div></div>")
        Next
        litDeviceHistory.Text =
            If(history.Length = 0, "<p class='text-muted'>لا توجد قرارات مسجلة بعد.</p>", history.ToString())
        pnlDevices.Visible = True
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "deviceModal", "if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',function(){bootstrap.Modal.getOrCreateInstance(document.getElementById('deviceModal')).show();},{once:true});}else{bootstrap.Modal.getOrCreateInstance(document.getElementById('deviceModal')).show();}", True)
    End Sub

    Protected Sub DeviceFilterChanged(sender As Object, e As EventArgs)
        pnlDevices.Visible = False
        FillData()
    End Sub

    Protected Sub DeviceCommand(sender As Object, e As ListViewCommandEventArgs)
        Dim itemID As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), itemID) Then Return
        ApplyDeviceDecision(e.CommandName, itemID)
    End Sub

    Protected Sub ResetDevices(sender As Object, e As EventArgs)
        ApplyDeviceDecision("ResetAll", 0)
    End Sub

    Private Sub ApplyDeviceDecision(action As String, itemID As Integer)
        Try
            If _
                DeviceUserID <= 0 OrElse
                Not {"ApproveReplace", "ApproveAdd", "Reject", "Revoke", "ResetAll"}.Contains(action) Then _
                Throw New InvalidOperationException()
            If txtDeviceComment.Text.Length > 500 Then Throw New ArgumentException()
            DeviceQuery("dbo.MobileApi_ManageDevices",
                        New SqlParameter("@UserID", DeviceUserID),
                        New SqlParameter("@Action", action),
                        New SqlParameter("@RequestID",
                                         If _
                                            (action = "Revoke" OrElse action = "ResetAll",
                                             CType(DBNull.Value, Object), itemID)),
                        New SqlParameter("@DeviceRegistrationID",
                                         If _
                                            (action = "Revoke", CType(itemID, Object),
                                             DBNull.Value)),
                        New SqlParameter("@Comment", txtDeviceComment.Text.Trim()))
            litDeviceMessage.Text = "تم حفظ القرار وتحديث صلاحية الدخول بنجاح."
            pnlDeviceMessage.CssClass = "alert alert-success"
            txtDeviceComment.Text = ""
        Catch ex As SqlException When ex.Number = 51712
            litDeviceMessage.Text =
                "تغيرت حالة الجهاز أو الطلب. تم تحديث البيانات؛ راجع الحالة الحالية قبل اتخاذ إجراء."
            pnlDeviceMessage.CssClass = "alert alert-warning"
        Catch ex As Exception
            litDeviceMessage.Text = "تعذر حفظ القرار. تحقق من الصلاحية والبيانات وحاول مرة أخرى."
            pnlDeviceMessage.CssClass = "alert alert-danger"
            Diagnostics.Trace.TraceError("Device administration failed ({0}).", ex.GetType().Name)
        End Try
        pnlDeviceMessage.Visible = True
        FillData()
        ShowDevices()
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        SystemAdministrationUI.RegisterRefresh(Me, AddressOf FillData)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        If Not Page.IsPostBack Then
            FillUserTypes()
            FillStatuses()
            FillData()
        End If
    End Sub

    Private Sub FillUserTypes()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Users_Types_All().ToList()

            ddlUserType.DataSource = data
            ddlUserType.DataTextField = "Title_Ar"
            ddlUserType.DataValueField = "ID"
            ddlUserType.DataBind()

            ddlUserType.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    Private Sub FillStatuses()
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Users_Status_All().ToList()

            ddlStatus.DataSource = data
            ddlStatus.DataTextField = "Title_Ar"
            ddlStatus.DataValueField = "ID"
            ddlStatus.DataBind()

            ddlStatus.Items.Insert(0, New ListItem("الكل", ""))
        End Using
    End Sub

    Protected Sub FillData()
        Dim deviceRows =
                DeviceQuery("dbo.MobileApi_DeviceAdminView").Tables(0).Rows.Cast (Of DataRow)().ToList()
        Dim pending = deviceRows.ToDictionary(Function(r) CInt(r("ID")), Function(r) CInt(r("PendingCount")))
        litDeviceOverview.Text = "<div class='row g-3 mb-3'>" &
                                 DeviceMetric("bx-mobile-alt", "الأجهزة المسموحة",
                                              deviceRows.Sum(Function(r) CInt(r("ApprovedCount"))), "primary") &
                                 DeviceMetric("bx-time-five", "طلبات أجهزة بانتظار الموافقة",
                                              deviceRows.Sum(Function(r) CInt(r("PendingCount"))), "warning") &
                                 DeviceMetric("bx-user-check", "موظفون بأكثر من جهاز",
                                              deviceRows.Where(Function(r) CInt(r("ApprovedCount")) > 1).Count(),
                                              "success") & "</div>"
        Using db As New Prosto_ERP_DataClassesDataContext
            Dim users = db.Select_UsersMembers_All().AsQueryable()
            If chkPendingDevices.Checked Then
                Dim pendingIDs = pending.Where(Function(p) p.Value > 0).Select(Function(p) p.Key).ToList()
                users = users.Where(Function(u) pendingIDs.Contains(u.ID))
            End If

            If Not String.IsNullOrEmpty(ddlUserType.SelectedValue) Then
                Dim typeId = CInt(ddlUserType.SelectedValue)
                users = users.Where(Function(u) u.Type = typeId)
            End If

            If Not String.IsNullOrEmpty(ddlStatus.SelectedValue) Then
                Dim statusId = CInt(ddlStatus.SelectedValue)
                users = users.Where(Function(u) u.Status = statusId)
            End If

            If Not String.IsNullOrEmpty(txtSearch.Text.Trim()) Then
                Dim term As String = txtSearch.Text.Trim().ToLower()
                users = users.Where(Function(u) _
                                       (If(u.FullName_Ar, "").ToLower().Contains(term) OrElse
                                        If(u.Fullname_En, "").ToLower().Contains(term) OrElse
                                        If(u.UserName, "").ToLower().Contains(term)))
            End If

            Dim types = db.Select_Users_Types_All().ToList()
            Dim statuses = db.Select_Users_Status_All().ToList()
            Dim genders = db.Select_Genders_All().ToList()

            Dim result = (From u In users
                          Let typeTitle = (From t In types Where t.ID = u.Type Select t.Title_Ar).FirstOrDefault()
                          Let statusTitle = (From s In statuses Where s.ID = u.Status Select s.Title_Ar).FirstOrDefault()
                          Let genderTitle = (From g In genders Where g.ID = u.Gender Select g.Title_Ar).FirstOrDefault()
                          Let img = u.User_Image
                          Let imgUrl =
                              If(Not String.IsNullOrEmpty(img),
                                 img,
                                 If(genderTitle IsNot Nothing AndAlso genderTitle.Trim() = "ذكر",
                                    "../../assets/img/Prosto/avatar-male.png",
                                    If(genderTitle IsNot Nothing AndAlso (genderTitle.Trim() = "أنثى" OrElse genderTitle.Trim() = "انثى"),
                                       "../../assets/img/Prosto/avatar-female.png",
                                       "../../assets/img/Prosto/avatar.png")))
                          Select New With {
                              .ID = u.ID,
                 .IsActive = u.IsActive,
                              .PendingDevices = If(pending.ContainsKey(u.ID), pending(u.ID), 0),
                              .FullName_Ar = u.FullName_Ar,
                              .Fullname_En = u.Fullname_En,
                              .Employee_Number = u.Employee_Number,
                              .UserName = u.UserName,
                              .UserTypeTitle = If(typeTitle, ""),
                              .StatusTitle = If(statusTitle, ""),
                              .AddedDate = u.AddedDate,
                              .UserImageUrl = imgUrl
                          }).OrderByDescending(Function(x) x.ID).ToList()

            lstData.DataSource = result
            lstData.DataBind()
        End Using
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        pnlDevices.Visible = False
        FillData()
    End Sub

    Protected Sub lstData_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        Using db As New Prosto_ERP_DataClassesDataContext
            Try
                Select Case e.CommandName
                    Case "Devices"
                        DeviceUserID = CInt(e.CommandArgument)
                        pnlDeviceMessage.Visible = False
                        txtDeviceComment.Text = ""
                        ShowDevices()

                    Case "QRCode"
                        Dim ID = CType(e.CommandArgument, Integer)
                        Response.Redirect("/modules/QRCode/PrintQRCode.aspx?Type=employees&ID=" & ID.ToString())

                    Case "Edit"
                        Dim ID = CInt(e.CommandArgument)
                        Response.Redirect("/Modules/Users/EditUsers.aspx?ID=" & ID.ToString())
                    Case "DeleteItem"
                        Dim ID = CInt(e.CommandArgument)
                        db.Update_UsersMembers_IsDeleted_ByID(ID, True, SessionManager.GetInstance.Users.UserID)
                        FillData()
                End Select
            Catch ex As Exception
                ' log لو حبيت
            End Try
        End Using
    End Sub

    Protected Sub btnAddNewItem_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Users/AddUsers.aspx")
    End Sub

    Private Function DeviceMetric(icon As String, title As String, number As Integer, color As String) As String
        Return _
            "<div class='col-md-4'><div class='card h-100'><div class='card-body d-flex align-items-center justify-content-between py-3'><div><div class='text-muted small'>" &
            title & "</div><h4 class='mb-0 mt-1'>" & number.ToString() &
            "</h4></div><span class='avatar'><span class='avatar-initial rounded bg-label-" & color & "'><i class='bx " &
            icon & "'></i></span></span></div></div></div>"
    End Function
End Class


