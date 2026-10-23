Imports Prosto_ERP_ClassLibrary

Public Class Tools_Viewer_QRCode
    Inherits PageBase

    ' DTO لقراءة نتيجة الـ SP بسرعة
    Private Class ToolFullDetailsDTO
        Public Property JobTitle_ItemsID As Integer
        Public Property JobTitle_ID As Integer

        Public Property Item_Title_Ar As String
        Public Property Item_Title_En As String
        Public Property Tool_Number As String

        Public Property Supplier_Account_ID As Integer?
        Public Property Supplier_Title_Ar As String
        Public Property Supplier_Title_En As String

        Public Property MaintenanceCompanyID As Integer
        Public Property MaintenanceCompany_Title_Ar As String
        Public Property MaintenanceCompany_Title_En As String

        Public Property ItemTypeID As Integer
        Public Property ItemType_Title_Ar As String
        Public Property ItemType_Title_En As String

        Public Property DepartmentID As Integer
        Public Property Department_Title_Ar As String
        Public Property Department_Title_En As String

        Public Property BranchID As Integer
        Public Property Branch_Title_Ar As String
        Public Property Branch_Title_En As String

        Public Property BrandID As Integer
        Public Property Brand_Title_Ar As String
        Public Property Brand_Title_En As String
        Public Property Brand_Logo As String

        Public Property JobTitle_Title_Ar As String
        Public Property JobTitle_Title_En As String

        Public Property OrgStructure_Ar As String
        Public Property OrgStructure_En As String
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        ' (اختياري) لو بدك تكون الصفحة عامة من QR بدون Login خليها كما هي بدون فحص Session
        ' إذا بدك تمنع الوصول لغير المسجلين فعّل التالي:
        'If SessionManager.GetInstance.Users Is Nothing Then
        '    Response.Redirect("/login.aspx")
        'End If

        If Not IsPostBack Then

            Dim id = 0
            If Not Integer.TryParse(Request.QueryString("JobTitle_ItemsID"), id) OrElse id <= 0 Then
                ShowError("المعرف غير صحيح أو غير موجود.")
                Return
            End If

            ' ✅ حفظ JobTitle_ItemsID في HiddenField لاستخدامه عند اختيار نوع التقييم
            hidJobTitleItemsID.Value = id.ToString()

            ' ✅ Bind أنواع التقييم من جدول Checklist_Types عبر الإجراء Select_Checklist_Types_All
            BindChecklistTypes()

            LoadToolData_FromSP(id)
        End If
    End Sub

    Private Sub BindChecklistTypes()
        Try
            Using db As New Prosto_ERP_DataClassesDataContext

                Dim types = db.Select_Checklist_Types_All().ToList()

                ' عرض فقط المفعّل (إن رغبت)
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
        Catch ex As Exception
            pnlNoChecklistTypes.Visible = True
            rptChecklistTypes.DataSource = Nothing
            rptChecklistTypes.DataBind()
        End Try
    End Sub

    Private Sub LoadToolData_FromSP(jobTitleItemsId As Integer)
        Try
            Using db As New Prosto_ERP_DataClassesDataContext

                Dim sql = "EXEC dbo.Select_JobTitle_Items_FullDetails_ByID {0}"
                Dim q = db.ExecuteQuery (Of ToolFullDetailsDTO)(sql, jobTitleItemsId).FirstOrDefault()

                If q Is Nothing Then
                    ShowError("لم يتم العثور على بيانات لهذه الأداة.")
                    Return
                End If

                ' ========== Bind UI (Arabic) ==========
                Dim itemTitleAr As String = SafeText(q.Item_Title_Ar)
                Dim toolNumber As String = SafeText(q.Tool_Number)

                litItemTitle.Text = itemTitleAr
                litItemTitle2.Text = itemTitleAr

                litToolNumber.Text = toolNumber
                litToolNumberHeader.Text = toolNumber

                litItemType.Text = SafeText(q.ItemType_Title_Ar)

                litBrand.Text = SafeText(q.Brand_Title_Ar)
                litBranch.Text = SafeText(q.Branch_Title_Ar)
                litDepartment.Text = SafeText(q.Department_Title_Ar)
                litJobTitle.Text = SafeText(q.JobTitle_Title_Ar)

                litSupplier.Text = SafeText(q.Supplier_Title_Ar)
                litMaintenance.Text = SafeText(q.MaintenanceCompany_Title_Ar)

                ' Org line
                If Not String.IsNullOrWhiteSpace(SafeText(q.OrgStructure_Ar)) Then
                    litOrgLine.Text = SafeText(q.OrgStructure_Ar)
                Else
                    litOrgLine.Text =
                        $"{SafeText(q.Brand_Title_Ar)} / {SafeText(q.Branch_Title_Ar)} / { _
                            SafeText(q.Department_Title_Ar)} / {SafeText(q.JobTitle_Title_Ar)}"
                End If

                ' Logo
                Dim logoPath As String = SafeText(q.Brand_Logo)
                If String.IsNullOrWhiteSpace(logoPath) Then
                    imgBrandLogo.ImageUrl = "/assets/img/avatars/brand-placeholder.png"
                Else
                    imgBrandLogo.ImageUrl = NormalizeImageUrl(logoPath)
                End If

                pnlError.Visible = False
            End Using

        Catch ex As Exception
            ShowError("حدث خطأ أثناء تحميل البيانات: " & ex.Message)
        End Try
    End Sub

#Region "Helpers"

    Private Function SafeText(v As Object) As String
        If v Is Nothing Then Return ""
        Return Convert.ToString(v).Trim()
    End Function

    Private Function NormalizeImageUrl(path As String) As String
        If String.IsNullOrWhiteSpace(path) Then Return ""
        If path.StartsWith("http", StringComparison.OrdinalIgnoreCase) Then Return path
        If path.StartsWith("/") Then Return path
        Return "/" & path
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

#End Region
End Class


