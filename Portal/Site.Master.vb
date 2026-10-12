Public Class Site
    Inherits System.Web.UI.MasterPage
    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected Overrides Sub OnPreRender(e As EventArgs)
        litInformationPageLinks.Text = ""
        If SessionManager.GetInstance.Users IsNot Nothing Then
            Try
                Dim pages = InformationPagesData.Query("dbo.Select_Information_Pages", InformationPagesData.P("@Actor", System.Data.SqlDbType.Int, SessionManager.GetInstance.Users.UserID))
                Dim links As New System.Text.StringBuilder()
                Dim english = Request.QueryString("lang") = "en"
                For Each row As System.Data.DataRow In pages.Rows
                    Dim url = ResolveUrl("~/Modules/Information_Pages/View.aspx?ID=" & CInt(row("ID")).ToString() & If(english, "&lang=en", "&lang=ar"))
                    links.Append("<li class=""menu-item"" data-information-page=""1""><a class=""menu-link"" href=""").Append(Server.HtmlEncode(url)).Append("""><div>")
                    links.Append(Server.HtmlEncode(CStr(row(If(english, "Title_En", "Title_Ar"))))).Append("</div></a></li>")
                Next
                If pages.Rows.Count = 0 Then links.Append("<li class=""menu-item"" data-information-page=""1""><span class=""menu-link text-muted"">لا توجد صفحات متاحة حاليًا</span></li>")
                litInformationPageLinks.Text = links.ToString()
            Catch ex As Exception
                System.Diagnostics.Trace.TraceError("Information pages menu: {0}", ex)
            End Try
        End If
        Dim manager = ScriptManager.GetCurrent(Page)
        If manager IsNot Nothing AndAlso manager.IsInAsyncPostBack Then
            Dim html = Newtonsoft.Json.JsonConvert.SerializeObject(litInformationPageLinks.Text, New Newtonsoft.Json.JsonSerializerSettings With {.StringEscapeHandling = Newtonsoft.Json.StringEscapeHandling.EscapeHtml})
            ScriptManager.RegisterStartupScript(Page, Page.GetType(), "information-menu", "(function(){var menu=document.getElementById('informationPagesMenu');if(!menu)return;Array.prototype.forEach.call(menu.querySelectorAll('[data-information-page]'),function(item){item.remove();});menu.insertAdjacentHTML('afterbegin'," & html & ");})();", True)
        End If
        MyBase.OnPreRender(e)
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        tmCorrespondenceCount.Enabled = True
        If Not IsPostBack Then
            If Not SessionManager.GetInstance.Users Is Nothing Then
                FillUserData()
                If tmCorrespondenceCount.Enabled Then BindCorrespondenceCount()
                If SessionManager.GetInstance.Users.UserType <> 1 Then
                    divmenu.Visible = True
                    liNotification.Visible = False
                    liQuicklinks.Visible = False
                End If
            Else
                Session.Abandon()
                Session.Clear()
                Response.Redirect("~/Login.aspx")
            End If
        End If
    End Sub

    Protected Sub FillUserData()
        Try
            Dim user = SessionManager.GetInstance.Users

            If user IsNot Nothing Then

                Dim UserType As String = db.Select_Users_Types_ByID(user.UserType).FirstOrDefault().Title_Ar

                ' ===================== اسم و نوع المستخدم =====================
                ' عدّل أسماء الخصائص حسب الكلاس عندك (مثلاً Name, FullName, UserTypeTitle ...)
                lblUserFullName.Text = Convert.ToString(user.NameAr)
                lblUserType.Text = UserType

                ' ===================== صورة المستخدم =====================
                Dim imgPath As String = ""
                If user.UserImage IsNot Nothing Then
                    imgPath = Convert.ToString(user.UserImage)
                End If

                If String.IsNullOrWhiteSpace(imgPath) Then
                    ' لا يوجد صورة – نحدد Avatar حسب الجنس
                    Dim gender As String = Convert.ToString(user.Gender).ToLower()

                    ' عدّل القيم حسب ما تخزنها في قاعدة البيانات (m/f أو 1/2 إلخ)
                    If gender = "f" Or gender = "female" Or gender = "2" Or gender = "أنثى" Then
                        imgPath = "/assets/img/Prosto/avatar-female.png"
                    Else
                        imgPath = "/assets/img/Prosto/avatar-male.png"
                    End If
                End If

                imgUserAvatarNavbar.ImageUrl = imgPath
                imgUserAvatarDropdown.ImageUrl = imgPath

                ' ===================== رابط "ملفي الشخصي" =====================
                ' استعمال UserID من السيشن
                Dim employeeId As Integer = Convert.ToInt32(user.UserID)
                lnkMyProfile.HRef = "/modules/Employees/MyProfile.aspx?EmployeeID=" & employeeId.ToString()

            End If

        Catch ex As Exception
            ' ممكن تضيف Logging هنا إذا حاب
        End Try
    End Sub

    Protected Sub btnLogout_Click(ByVal sender As Object, ByVal e As EventArgs) Handles btnLogout.Click
        Session.Abandon()
        Session.Clear()
        Response.Redirect("~/Login.aspx")
    End Sub

    Protected Function CanUseCRM() As Boolean
        If SessionManager.GetInstance.Users Is Nothing Then Return False
        If Context.Items("CRM.Enabled") Is Nothing Then
            Try
                CRMData.Query("dbo.CRM_CheckUser", CRMData.P("@Actor_ID", System.Data.SqlDbType.Int, SessionManager.GetInstance.Users.UserID))
                Context.Items("CRM.Enabled") = True
            Catch ex As Exception
                Context.Items("CRM.Enabled") = False
            End Try
        End If
        Return CBool(Context.Items("CRM.Enabled"))
    End Function

    Protected Sub BindCorrespondenceCount()
        BindFeedbackCount()
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Try
            Using data As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                litCorrespondenceCount.Text = data.Select_Correspondence_UnreadCount(SessionManager.GetInstance.Users.UserID).First().UnreadThreads.ToString()
            End Using
        Catch ex As Exception
            System.Diagnostics.Trace.TraceError("Correspondence count: {0}", ex)
        End Try
    End Sub
    Protected Sub CorrespondenceCount_Tick(sender As Object, e As EventArgs)
        BindCorrespondenceCount()
    End Sub
    Protected Sub BindFeedbackCount()
        If SessionManager.GetInstance.Users Is Nothing Then Return
        Try
            Using data As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                litFeedbackCount.Text=data.Select_Employee_Feedback_UnreadCount(SessionManager.GetInstance.Users.UserID).Single().UnreadRequests.ToString()
                upFeedbackCount.Update()
            End Using
        Catch ex As Exception
            System.Diagnostics.Trace.TraceError("Feedback count: {0}",ex)
        End Try
    End Sub
End Class
