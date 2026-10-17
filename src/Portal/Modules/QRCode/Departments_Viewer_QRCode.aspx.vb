Imports Prosto_ERP_ClassLibrary

Public Class Departments_Viewer_QRCode
    Inherits PageBase

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
            Return
        End If

        If Not IsPostBack Then

            Dim deptId = 0
            If Not Integer.TryParse(Request.QueryString("Departmentid"), deptId) OrElse deptId <= 0 Then
                ShowError("رقم القسم غير صحيح أو غير موجود في الرابط.")
                Return
            End If

            Dim shiftId As Integer = GetCurrentShiftId()

            ' Hidden fields
            hidDepartmentID.Value = deptId.ToString()
            hidShiftID.Value = shiftId.ToString()

            ' Header badges
            litDepartmentIdHeader.Text = deptId.ToString()
            litShiftIdHeader.Text = shiftId.ToString()

            litDepartmentId.Text = deptId.ToString()
            litShiftId.Text = shiftId.ToString()

            BindChecklistTypes()
            LoadDepartmentInfo(deptId)

        End If
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

    Private Sub LoadDepartmentInfo(deptId As Integer)
        Try
            Using db As New Prosto_ERP_DataClassesDataContext

                Dim dept = db.Select_Departments_ByID(deptId).FirstOrDefault()
                If dept Is Nothing Then
                    ShowError("لم يتم العثور على بيانات القسم المطلوبة.")
                    Return
                End If

                ' بيانات الفرع/العلامة
                Dim branchTitle = "-"
                Dim brandTitle = "-"

                ' لو عندك Logo بالـ Brands مثل جدول Brands.Logo
                Dim brandLogoUrl = "/assets/img/avatars/1.png" ' Default fallback

                If dept.BranchID.HasValue AndAlso dept.BranchID.Value > 0 Then
                    Dim br = db.Select_Branches_ByID(dept.BranchID.Value).FirstOrDefault()
                    If br IsNot Nothing Then
                        branchTitle = If(br.Title_Ar, "-")

                        If br.BrandID.HasValue AndAlso br.BrandID.Value > 0 Then
                            Dim brand = db.Select_Brands_ByID(br.BrandID.Value).FirstOrDefault()
                            If brand IsNot Nothing Then
                                brandTitle = If(brand.Title_Ar, "-")

                                ' لو جدول Brands فيه Logo
                                If Not String.IsNullOrWhiteSpace(Convert.ToString(brand.Logo)) Then
                                    brandLogoUrl = Convert.ToString(brand.Logo)
                                End If
                            End If
                        End If
                    End If
                End If

                ' تعبئة النصوص
                Dim deptTitleAr As String = If(dept.Title_Ar, "-")
                Dim deptTitleEn As String = If(dept.Title_En, "")

                litDeptTitle.Text = deptTitleAr
                litDeptTitle2.Text = deptTitleAr

                litBrand.Text = brandTitle
                litBranch.Text = branchTitle

                ' Org line مثل بروستو / فرع / قسم ...
                ' (تقدر تغيرها حسب تفضيلك)
                litOrgLine.Text = String.Format("بروستو / {0} / {1}", branchTitle, deptTitleAr)

                ' Logo
                imgBrandLogo.ImageUrl = brandLogoUrl

                ' حالة التفعيل
                Dim isActive As Boolean = If(dept.IsActive.HasValue, dept.IsActive.Value, True)
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
            ShowError("حدث خطأ أثناء تحميل بيانات القسم.")
        End Try
    End Sub

    Private Sub BindChecklistTypes()
        Try
            Using db As New Prosto_ERP_DataClassesDataContext

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

    ' نفس الفنكشن اللي زودتني فيها
    Private Function GetCurrentShiftId() As Integer
        Try
            Using db As New Prosto_ERP_DataClassesDataContext

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


