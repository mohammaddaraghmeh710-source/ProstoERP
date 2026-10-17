Imports System.IO
Imports AjaxControlToolkit
Imports System.Linq
Imports System.Collections.Generic

Public Class Add_JobTitle_Items
    Inherits PageBase

    '================= Session Keys =================
    Private Const SK_DRAFT As String = "JTItems_DraftList"
    Private Const SK_WM As String = "JTItems_WorkingVideoTemp"
    Private Const SK_EV As String = "JTItems_EvalVideoTemp"

    '================= Draft Model =================
    <Serializable()>
    Private Class DraftJobTitleItem
        Public Property TempId As String
        Public Property JobTitleId As Integer

        Public Property ToolNumber As String
        Public Property ItemTypeId As Integer?
        Public Property SupplierId As Integer?
        Public Property MaintenanceId As Integer?

        Public Property TitleAr As String
        Public Property TitleEn As String

        Public Property PoliciesAr As String
        Public Property PoliciesEn As String

        Public Property WorkingMethodVideoPath As String
        Public Property EvaluationMethodVideoPath As String

        ' For UI text
        Public Property ItemTypeText As String
        Public Property SupplierText As String
        Public Property MaintenanceText As String

        Public ReadOnly Property WorkingVideoLabel As String
            Get
                Return If(String.IsNullOrWhiteSpace(WorkingMethodVideoPath), "لا يوجد", "مرفق")
            End Get
        End Property

        Public ReadOnly Property EvalVideoLabel As String
            Get
                Return If(String.IsNullOrWhiteSpace(EvaluationMethodVideoPath), "لا يوجد", "مرفق")
            End Get
        End Property
    End Class

    '================= Page Load =================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("/login.aspx")
        If SessionManager.GetInstance.Users.UserType <> 1 Then Response.Redirect("/Default.aspx")

        If Not Page.IsPostBack Then
            FillBrands()
            ResetBranchDepartmentJob()
            FillSuppliers()
            FillMaintenanceCompanies()
            FillItemTypes()

            EnsureDraftSession()
            BindDraft()
        End If
    End Sub

    '================= Helpers =================
    Private Sub EnsureDraftSession()
        If Session(SK_DRAFT) Is Nothing Then
            Session(SK_DRAFT) = New List(Of DraftJobTitleItem)()
        End If
    End Sub

    Private Function GetDraftList() As List(Of DraftJobTitleItem)
        EnsureDraftSession()
        Return CType(Session(SK_DRAFT), List(Of DraftJobTitleItem))
    End Function

    Private Sub BindDraft()
        Dim list = GetDraftList()

        lvDraftItems.DataSource = list
        lvDraftItems.DataBind()

        lblDraftCount.Text = "عدد الأدوات: " & list.Count.ToString()

        ' في حال يوجد عناصر في الدفت، ممكن تقفل الهيكل التنظيمي لتجنب اختلاف JobTitle
        Dim hasDraft = (list.Count > 0)
        ddlBrand.Enabled = Not hasDraft
        ddlBranch.Enabled = Not hasDraft
        ddlDepartment.Enabled = Not hasDraft
        ddlJobTitle.Enabled = Not hasDraft
    End Sub

    Private Sub ClearItemInputs()
        ddlItemType.SelectedIndex = 0
        txtToolNumber.Text = ""
        ddlSupplier.SelectedIndex = 0
        ddlMaintenanceCompany.SelectedIndex = 0
        txtTitleAr.Text = ""
        txtTitleEn.Text = ""
        txtPolicies_Ar.Text = ""
        txtPolicies_En.Text = ""

        ' clear temp uploaded files markers
        Session(SK_WM) = Nothing
        Session(SK_EV) = Nothing
    End Sub

    Private Function SafeInt(value As String) As Integer?
        Dim n As Integer
        If Integer.TryParse(value, n) Then Return n
        Return Nothing
    End Function

    '================= الهيكل التنظيمي =================
    Private Sub FillBrands()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Brands_All().Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBrand.DataSource = data
            ddlBrand.DataTextField = "Title_Ar"
            ddlBrand.DataValueField = "ID"
            ddlBrand.DataBind()
        End Using
        ddlBrand.Items.Insert(0, New ListItem("اختر العلامة", ""))
    End Sub

    Private Sub FillBranches(Optional brandId As Integer? = Nothing)
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))

        If Not brandId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Branches_ByBrandID(brandId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlBranch.DataSource = data
            ddlBranch.DataTextField = "Title_Ar"
            ddlBranch.DataValueField = "ID"
            ddlBranch.DataBind()
            ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        End Using
    End Sub

    Private Sub FillDepartments(Optional branchId As Integer? = Nothing)
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))

        If Not branchId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Departments_ByBranchID(branchId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlDepartment.DataSource = data
            ddlDepartment.DataTextField = "Title_Ar"
            ddlDepartment.DataValueField = "ID"
            ddlDepartment.DataBind()
            ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        End Using
    End Sub

    Private Sub FillJobTitles(Optional departmentId As Integer? = Nothing)
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))

        If Not departmentId.HasValue Then Exit Sub

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitles_ByDepartmentID(departmentId.Value).Where(Function(x) x.IsDeleted = 0).ToList()
            ddlJobTitle.DataSource = data
            ddlJobTitle.DataTextField = "Title_Ar"
            ddlJobTitle.DataValueField = "ID"
            ddlJobTitle.DataBind()
            ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
        End Using
    End Sub

    Private Sub ResetBranchDepartmentJob()
        ddlBranch.Items.Clear()
        ddlBranch.Items.Insert(0, New ListItem("اختر الفرع", ""))
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlBrand_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillBranches(SafeInt(ddlBrand.SelectedValue))
        ddlDepartment.Items.Clear()
        ddlDepartment.Items.Insert(0, New ListItem("اختر القسم", ""))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlBranch_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillDepartments(SafeInt(ddlBranch.SelectedValue))
        ddlJobTitle.Items.Clear()
        ddlJobTitle.Items.Insert(0, New ListItem("اختر المحطة التعريفية", ""))
    End Sub

    Protected Sub ddlDepartment_SelectedIndexChanged(sender As Object, e As EventArgs)
        FillJobTitles(SafeInt(ddlDepartment.SelectedValue))
    End Sub

    '================= قوائم الشركات والأنواع =================
    Private Sub FillSuppliers()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Suppliers_All().ToList()
            ddlSupplier.DataSource = data
            ddlSupplier.DataTextField = "Title_Ar"
            ddlSupplier.DataValueField = "ID"
            ddlSupplier.DataBind()
        End Using
        ddlSupplier.Items.Insert(0, New ListItem("اختر الشركة الموردة", ""))
    End Sub

    Private Sub FillMaintenanceCompanies()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_Maintenance_Companies_All().ToList()
            ddlMaintenanceCompany.DataSource = data
            ddlMaintenanceCompany.DataTextField = "Title_Ar"
            ddlMaintenanceCompany.DataValueField = "ID"
            ddlMaintenanceCompany.DataBind()
        End Using
        ddlMaintenanceCompany.Items.Insert(0, New ListItem("اختر شركة الصيانة", ""))
    End Sub

    Private Sub FillItemTypes()
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Dim data = db.Select_JobTitle_Items_Types_All().ToList()
            ddlItemType.DataSource = data
            ddlItemType.DataTextField = "Title_Ar"
            ddlItemType.DataValueField = "ID"
            ddlItemType.DataBind()
        End Using
        ddlItemType.Items.Insert(0, New ListItem("اختر نوع الأداة", ""))
    End Sub

    '================= إضافة إلى Session (بدون Refresh كامل) =================
    Protected Sub btnAddToSession_Click(sender As Object, e As EventArgs)
        lblMsg.Text = ""

        ' لازم الهيكل التنظيمي يكون مختار (Org validation)
        Page.Validate("Org")
        If Not Page.IsValid Then
            lblMsg.Text = "يرجى اختيار الهيكل التنظيمي أولاً."
            Exit Sub
        End If

        ' تحقق من حقول الأداة
        Page.Validate("AddItem")
        If Not Page.IsValid Then Exit Sub

        Dim jobTitleId = CInt(ddlJobTitle.SelectedValue)

        Dim draft As New DraftJobTitleItem With {
            .TempId = Guid.NewGuid().ToString("N"),
            .JobTitleId = jobTitleId,
            .ToolNumber = txtToolNumber.Text.Trim(),
            .ItemTypeId = SafeInt(ddlItemType.SelectedValue),
            .SupplierId = SafeInt(ddlSupplier.SelectedValue),
            .MaintenanceId = SafeInt(ddlMaintenanceCompany.SelectedValue),
            .TitleAr = txtTitleAr.Text.Trim(),
            .TitleEn = txtTitleEn.Text.Trim(),
            .PoliciesAr = txtPolicies_Ar.Text,
            .PoliciesEn = txtPolicies_En.Text
        }

        ' نصوص للعرض (من الدروب داون)
        draft.ItemTypeText = ddlItemType.SelectedItem.Text
        draft.SupplierText = ddlSupplier.SelectedItem.Text
        draft.MaintenanceText = ddlMaintenanceCompany.SelectedItem.Text

        ' خذ مسارات الفيديوهات من Session المؤقتة (التي تحفظ عند UploadComplete)
        draft.WorkingMethodVideoPath = TryCast(Session(SK_WM), String)
        draft.EvaluationMethodVideoPath = TryCast(Session(SK_EV), String)

        ' احفظ في Session list
        Dim list = GetDraftList()

        ' أمان: لا تسمح بإضافة عناصر على JobTitle مختلف إذا كان لديك Draft سابق
        If list.Count > 0 AndAlso list(0).JobTitleId <> jobTitleId Then
            lblMsg.Text = "لا يمكن إضافة أدوات لمحطة تعريفية مختلف أثناء وجود أدوات في القائمة. قم بتفريغ القائمة أولاً."
            Exit Sub
        End If

        list.Add(draft)
        Session(SK_DRAFT) = list

        ' جهز فورم لأداة جديدة
        ClearItemInputs()

        BindDraft()
        upDraft.Update()
    End Sub

    Protected Sub lvDraftItems_ItemCommand(sender As Object, e As ListViewCommandEventArgs)
        If e.CommandName = "deleteDraft" Then
            Dim tempId = e.CommandArgument.ToString()
            Dim list = GetDraftList()

            Dim target = list.FirstOrDefault(Function(x) x.TempId = tempId)
            If target IsNot Nothing Then
                ' حذف ملفات مؤقتة إن وجدت
                Try
                    If Not String.IsNullOrWhiteSpace(target.WorkingMethodVideoPath) Then
                        Dim p = Server.MapPath(target.WorkingMethodVideoPath)
                        If File.Exists(p) Then File.Delete(p)
                    End If
                    If Not String.IsNullOrWhiteSpace(target.EvaluationMethodVideoPath) Then
                        Dim p = Server.MapPath(target.EvaluationMethodVideoPath)
                        If File.Exists(p) Then File.Delete(p)
                    End If
                Catch
                End Try

                list.Remove(target)
                Session(SK_DRAFT) = list
            End If

            BindDraft()
            upDraft.Update()
        End If
    End Sub

    Protected Sub btnClearDraft_Click(sender As Object, e As EventArgs)
        ' حذف كل الملفات المؤقتة
        Dim list = GetDraftList()
        For Each it In list
            Try
                If Not String.IsNullOrWhiteSpace(it.WorkingMethodVideoPath) Then
                    Dim p = Server.MapPath(it.WorkingMethodVideoPath)
                    If File.Exists(p) Then File.Delete(p)
                End If
                If Not String.IsNullOrWhiteSpace(it.EvaluationMethodVideoPath) Then
                    Dim p = Server.MapPath(it.EvaluationMethodVideoPath)
                    If File.Exists(p) Then File.Delete(p)
                End If
            Catch
            End Try
        Next

        Session(SK_DRAFT) = New List(Of DraftJobTitleItem)()
        BindDraft()
        upDraft.Update()
    End Sub

    '================= حفظ الكل إلى DB =================
    Protected Sub btnSaveAll_Click(sender As Object, e As EventArgs)
        lblMsg.Text = ""

        Page.Validate("Org")
        If Not Page.IsValid Then
            lblMsg.Text = "يرجى اختيار الهيكل التنظيمي أولاً."
            Exit Sub
        End If

        Dim list = GetDraftList()
        If list Is Nothing OrElse list.Count = 0 Then
            lblMsg.Text = "لا توجد أدوات في القائمة للحفظ."
            Exit Sub
        End If

        Dim jobTitleId = CInt(ddlJobTitle.SelectedValue)

        ' أمان
        If list.Any(Function(x) x.JobTitleId <> jobTitleId) Then
            lblMsg.Text = "خطأ: يوجد أدوات مرتبطة بمحطة تعريفية مختلف داخل القائمة."
            Exit Sub
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            For Each it In list
                db.Insert_JobTitle_Items(
                    jobTitleId,
                    it.TitleAr,
                    it.TitleEn,
                    it.ToolNumber,
                    it.SupplierId,
                    it.MaintenanceId,
                    it.ItemTypeId,
                    it.PoliciesAr,
                    it.PoliciesEn,
                    it.WorkingMethodVideoPath,
                    it.WorkingMethodVideoPath,
                    it.EvaluationMethodVideoPath,
                    it.EvaluationMethodVideoPath,
                    SessionManager.GetInstance.Users.UserID
                )
            Next
        End Using

        ' بعد الحفظ: صفّر السيشن
        Session(SK_DRAFT) = New List(Of DraftJobTitleItem)()
        BindDraft()
        upDraft.Update()

        LBLPOP_ModalPopupExtender.Show()
    End Sub


    Protected Sub btnSaveAllForAllJobTitle_Click(sender As Object, e As EventArgs)
        lblMsg.Text = ""

        Page.Validate("Org")
        If Not Page.IsValid Then
            lblMsg.Text = "يرجى اختيار الهيكل التنظيمي أولاً."
            Exit Sub
        End If

        Dim list = GetDraftList()
        If list Is Nothing OrElse list.Count = 0 Then
            lblMsg.Text = "لا توجد أدوات في القائمة للحفظ."
            Exit Sub
        End If

        Dim jobTitleId = CInt(ddlJobTitle.SelectedValue)

        ' أمان
        If list.Any(Function(x) x.JobTitleId <> jobTitleId) Then
            lblMsg.Text = "خطأ: يوجد أدوات مرتبطة بمحطة تعريفية مختلف داخل القائمة."
            Exit Sub
        End If

        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext


            For Each it In list

                Dim JobTitles = db.Select_JobTitles_All.Where(Function(x) x.Title_Ar = ddlJobTitle.SelectedItem.ToString())
                For Each jobTit In JobTitles


                    db.Insert_JobTitle_Items(
                    jobTit.ID,
                    it.TitleAr,
                    it.TitleEn,
                    it.ToolNumber,
                    it.SupplierId,
                    it.MaintenanceId,
                    it.ItemTypeId,
                    it.PoliciesAr,
                    it.PoliciesEn,
                    it.WorkingMethodVideoPath,
                    it.WorkingMethodVideoPath,
                    it.EvaluationMethodVideoPath,
                    it.EvaluationMethodVideoPath,
                    SessionManager.GetInstance.Users.UserID
                )

                Next


            Next
        End Using

        ' بعد الحفظ: صفّر السيشن
        Session(SK_DRAFT) = New List(Of DraftJobTitleItem)()
        BindDraft()
        upDraft.Update()

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
    End Sub

    Protected Sub btnCancel_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/JobTitle_Items/Manage_JobTitle_Items.aspx")
    End Sub

    '================= Ajax Upload (يحفظ الملف فوراً ويضع المسار في Session مؤقت) =================
    Private Function EnsureTempFolder() As String
        Dim rel = "~/Uploads/JobTitleItems/Temp/"
        Dim abs = Server.MapPath(rel)
        If Not Directory.Exists(abs) Then Directory.CreateDirectory(abs)
        Return rel
    End Function

    Private Function SaveTempFile(fileName As String, bytes() As Byte) As String
        Dim relFolder = EnsureTempFolder()
        Dim safeName = Guid.NewGuid().ToString("N") & "_" & Path.GetFileName(fileName)
        Dim relPath = relFolder.TrimEnd("/"c) & "/" & safeName
        Dim absPath = Server.MapPath(relPath)
        File.WriteAllBytes(absPath, bytes)
        Return relPath.Replace("~", "") ' نخزن مسار يبدأ بـ /...
    End Function

    Protected Sub WorkingMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            Dim rel = SaveTempFile(e.FileName, e.GetContents())
            Session(SK_WM) = rel
        Catch
        End Try
    End Sub

    Protected Sub WorkingMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Protected Sub EvaluationMethodVideo_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            Dim rel = SaveTempFile(e.FileName, e.GetContents())
            Session(SK_EV) = rel
        Catch
        End Try
    End Sub

    Protected Sub EvaluationMethodVideo_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub


End Class
