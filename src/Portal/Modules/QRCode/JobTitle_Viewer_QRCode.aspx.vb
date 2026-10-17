Imports System
Imports System.Linq

Public Class JobTitle_Viewer_QRCode
    Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
            Return
        End If

        If Not IsPostBack Then

            Dim jobTitleId As Integer = 0
            If Not Integer.TryParse(Request.QueryString("JobTitle"), jobTitleId) OrElse jobTitleId <= 0 Then
                ShowError("رقم المحطة التعريفية غير صحيح أو غير موجود في الرابط.")
                Return
            End If

            Dim shiftId As Integer = GetCurrentShiftId()

            ' Hidden
            hidJobTitleID.Value = jobTitleId.ToString()
            hidShiftID.Value = shiftId.ToString()

            ' Header
            litJobTitleIdHeader.Text = jobTitleId.ToString()
            litShiftIdHeader.Text = shiftId.ToString()

            litJobTitleId.Text = jobTitleId.ToString()
            litShiftId.Text = shiftId.ToString()

            ' Types
            BindChecklistTypes()

            ' Data
            LoadJobTitleInfo(jobTitleId)

        End If

    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    Private Sub LoadJobTitleInfo(jobTitleId As Integer)
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                ' جلب JobTitle
                Dim jt = db.Select_JobTitles_ByID(jobTitleId).FirstOrDefault()
                If jt Is Nothing Then
                    ShowError("لم يتم العثور على بيانات المحطة التعريفية المطلوبة.")
                    Return
                End If

                Dim deptId As Integer = 0
                If jt.DepartmentID.HasValue Then deptId = jt.DepartmentID.Value
                hidDepartmentID.Value = deptId.ToString()

                Dim deptTitle As String = "-"
                Dim branchTitle As String = "-"
                Dim brandTitle As String = "-"
                Dim brandLogoUrl As String = "/assets/img/avatars/1.png" ' fallback

                ' Department
                If jt.DepartmentID.HasValue AndAlso jt.DepartmentID.Value > 0 Then
                    Dim dept = db.Select_Departments_ByID(jt.DepartmentID.Value).FirstOrDefault()
                    If dept IsNot Nothing Then
                        deptTitle = If(dept.Title_Ar, "-")

                        ' Branch
                        If dept.BranchID.HasValue AndAlso dept.BranchID.Value > 0 Then
                            Dim br = db.Select_Branches_ByID(dept.BranchID.Value).FirstOrDefault()
                            If br IsNot Nothing Then
                                branchTitle = If(br.Title_Ar, "-")

                                ' Brand
                                If br.BrandID.HasValue AndAlso br.BrandID.Value > 0 Then
                                    Dim brand = db.Select_Brands_ByID(br.BrandID.Value).FirstOrDefault()
                                    If brand IsNot Nothing Then
                                        brandTitle = If(brand.Title_Ar, "-")

                                        If Not String.IsNullOrWhiteSpace(Convert.ToString(brand.Logo)) Then
                                            brandLogoUrl = Convert.ToString(brand.Logo)
                                        End If
                                    End If
                                End If
                            End If
                        End If

                    End If
                End If

                Dim jtTitleAr As String = If(jt.Title_Ar, "-")
                Dim jtTitleEn As String = If(jt.Title_En, "")

                ' UI
                litJobTitleName.Text = jtTitleAr
                litJobTitleName2.Text = jtTitleAr

                litBrand.Text = brandTitle
                litBranch.Text = branchTitle
                litDepartment.Text = deptTitle

                imgBrandLogo.ImageUrl = brandLogoUrl

                ' Org line (بنفس منطق صفحاتك)
                litOrgLine.Text = String.Format("بروستو / {0} / {1} / {2}", branchTitle, deptTitle, jtTitleAr)

                ' Active
                Dim isActive As Boolean = If(jt.IsActive.HasValue, jt.IsActive.Value, True)
                If isActive Then
                    lblActive.Text = "مفعّل"
                    lblActive.CssClass = "badge bg-label-success"
                Else
                    lblActive.Text = "غير مفعّل"
                    lblActive.CssClass = "badge bg-label-danger"
                End If

                pnlError.Visible = False

            End Using
        Catch ex As Exception
            ShowError("حدث خطأ أثناء تحميل بيانات المحطة التعريفية.")
        End Try
    End Sub

    Private Sub BindChecklistTypes()
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim types = db.Select_Checklist_Types_All().ToList()
                types = types.Where(Function(t) (t.IsActive = True OrElse t.IsActive Is Nothing)).ToList()

                If types Is Nothing OrElse types.Count = 0 Then
                    pnlNoChecklistTypes.Visible = True
                    rptChecklistTypes.DataSource = Nothing
                    rptChecklistTypes.DataBind()
                Else
                    pnlNoChecklistTypes.Visible = False
                    rptChecklistTypes.DataSource = types
                    rptChecklistTypes.DataBind()
                End If

            End Using
        Catch
            pnlNoChecklistTypes.Visible = True
            rptChecklistTypes.DataSource = Nothing
            rptChecklistTypes.DataBind()
        End Try
    End Sub

    ' نفس دالة الوردية
    Private Function GetCurrentShiftId() As Integer
        Try
            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim nowTime As TimeSpan = DateTime.Now.TimeOfDay

                Dim shifts = (From s In db.Select_Shift_All()
                              Where (s.IsDeleted = False OrElse s.IsDeleted Is Nothing) _
                                AndAlso (s.IsActive = True OrElse s.IsActive Is Nothing)
                              Select s).ToList()

                For Each s In shifts
                    If Not s.Start_Time.HasValue OrElse Not s.End_Time.HasValue Then Continue For

                    Dim startT As TimeSpan = s.Start_Time.Value
                    Dim endT As TimeSpan = s.End_Time.Value

                    Dim isMatch As Boolean
                    If startT <= endT Then
                        isMatch = (nowTime >= startT AndAlso nowTime <= endT)
                    Else
                        isMatch = (nowTime >= startT OrElse nowTime <= endT)
                    End If

                    If isMatch Then Return s.ID
                Next

            End Using
        Catch
        End Try

        Return 0
    End Function

End Class
