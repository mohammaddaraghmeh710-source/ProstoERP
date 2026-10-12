Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Web
Imports System.Text
Imports System.IO
Imports System.Globalization
Imports AjaxControlToolkit

Public Class Employee_Evaluation
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected EmployeeID As Integer
    Protected BrandID As Integer?
    Protected BranchID As Integer?
    Protected DepartmentID As Integer?
    Protected JobTitleID As Integer?
    Protected ShiftID As Integer?
    Protected UsersTypesID As Integer? ' لتغذية Insert_Checklist_Employee

    Protected Function JsString(value As Object) As String
        If value Is Nothing Then Return ""
        Return HttpUtility.JavaScriptStringEncode(value.ToString())
    End Function

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        ' صلاحيات حسب نظامك (عدّل إذا لزم)
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("/Default.aspx")
        End If

        LoadParameters()

        If Not IsPostBack Then
            BindEmployeeHeader()
            BindChecklistEmployee()
        End If
    End Sub

    Private Sub LoadParameters()
        If Not IsPostBack Then
            Integer.TryParse(Request.QueryString("EmployeeID"), EmployeeID)
            If EmployeeID = 0 Then Integer.TryParse(Request.QueryString("employeeID"), EmployeeID)
            ViewState("EmployeeID") = EmployeeID
        Else
            EmployeeID = If(ViewState("EmployeeID") IsNot Nothing, CInt(ViewState("EmployeeID")), 0)
        End If
    End Sub

    Private Sub BindEmployeeHeader()
        Dim emp = (From u In db.Select_UsersMembers_All
                   Where u.ID = EmployeeID AndAlso (u.IsDeleted = False OrElse u.IsDeleted Is Nothing)
                   Select u).FirstOrDefault()

        If emp Is Nothing Then
            EmployeeNameText.InnerText = "غير معروف"
            BranchNameText.InnerText = ""
            Return
        End If

        EmployeeNameText.InnerText = If(emp.FullName_Ar, "")
        UsersTypesID = If(emp.Type.HasValue, CType(emp.Type, Integer?), Nothing)

        BrandID = If(emp.Brand_ID.HasValue, CType(emp.Brand_ID, Integer?), Nothing)
        BranchID = If(emp.Branch_ID.HasValue, CType(emp.Branch_ID, Integer?), Nothing)
        DepartmentID = If(emp.Department_ID.HasValue, CType(emp.Department_ID, Integer?), Nothing)
        JobTitleID = If(emp.JobTitle_ID.HasValue, CType(emp.JobTitle_ID, Integer?), Nothing)
        ShiftID = If(emp.Shif_ID.HasValue, CType(emp.Shif_ID, Integer?), Nothing)

        If BranchID.HasValue Then
            Dim br = (From b In db.Select_Branches_All
                      Where b.ID = BranchID.Value
                      Select b.Title_Ar).FirstOrDefault()
            BranchNameText.InnerText = If(br, "")
        End If

        ViewState("UsersTypesID") = UsersTypesID
        ViewState("BrandID") = BrandID
        ViewState("BranchID") = BranchID
        ViewState("DepartmentID") = DepartmentID
        ViewState("JobTitleID") = JobTitleID
        ViewState("ShiftID") = ShiftID
    End Sub

    Private Sub BindChecklistEmployee()
        Dim usersType As Integer? = Nothing
        If ViewState("UsersTypesID") IsNot Nothing Then usersType = CType(ViewState("UsersTypesID"), Integer?)

        Dim q = From c In db.Select_Checklist_Employee_All
                Join cat In db.Checklist_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                Where (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                  AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing) _
                  AndAlso (Not usersType.HasValue OrElse c.Users_TypesID = usersType.Value)
                Order By c.ID
                Select New With {
                    .ID = c.ID,
                    .Title_Ar = c.Title_Ar,
                    .Brief_Ar = c.Brief_Ar,
                    .CheckList_CategoryID = c.CheckList_CategoryID,
                    .CategoryTitle_Ar = cat.Title_Ar,
                    .Weight = c.Weight
                }

        Dim list = q.ToList()

        rptChecklistEmployee.DataSource = list
        rptChecklistEmployee.DataBind()

        Dim hasAny = (list IsNot Nothing AndAlso list.Count > 0)
        pnlNoChecklist.Visible = Not hasAny
        pnlChecklistWrapper.Visible = hasAny
    End Sub

    Protected Function GetChecklistCss(cat As Object) As String
        Dim c As Integer = 0
        If cat IsNot Nothing AndAlso Integer.TryParse(cat.ToString(), c) Then
            Select Case c
                Case 1 : Return "eval-tag eval-red"
                Case 2 : Return "eval-tag eval-yellow"
                Case 3 : Return "eval-tag eval-green"
            End Select
        End If
        Return "eval-tag"
    End Function

    ' ===== ملفات المرفقات =====
    Protected Sub TaskFiles_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub TaskFiles_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' ===== حفظ عناصر تقييم جديدة إلى Checklist_Employee =====
    Private Sub InsertNewChecklistEmployee()
        Dim titlesAr = Request.Form.GetValues("newTitleAr[]")
        Dim briefsAr = Request.Form.GetValues("newBriefAr[]")
        Dim weights = Request.Form.GetValues("newWeight[]")
        Dim cats = Request.Form.GetValues("newCategory[]")

        If titlesAr Is Nothing OrElse titlesAr.Length = 0 Then Exit Sub

        Dim usersType As Integer? = If(ViewState("UsersTypesID") IsNot Nothing, CType(ViewState("UsersTypesID"), Integer?), Nothing)

        Dim brandId As Integer? = If(ViewState("BrandID") IsNot Nothing, CType(ViewState("BrandID"), Integer?), Nothing)
        Dim branchId As Integer? = If(ViewState("BranchID") IsNot Nothing, CType(ViewState("BranchID"), Integer?), Nothing)
        Dim deptId As Integer? = If(ViewState("DepartmentID") IsNot Nothing, CType(ViewState("DepartmentID"), Integer?), Nothing)
        Dim jobTitleId As Integer? = If(ViewState("JobTitleID") IsNot Nothing, CType(ViewState("JobTitleID"), Integer?), Nothing)
        Dim shiftId As Integer? = If(ViewState("ShiftID") IsNot Nothing, CType(ViewState("ShiftID"), Integer?), Nothing)

        For i As Integer = 0 To titlesAr.Length - 1
            Dim titleAr As String = If(titlesAr(i), "").Trim()
            If String.IsNullOrWhiteSpace(titleAr) Then Continue For

            Dim briefAr As String = Nothing
            If briefsAr IsNot Nothing AndAlso i < briefsAr.Length Then briefAr = If(briefsAr(i), "").Trim()

            Dim weightVal As Double = 0
            If weights IsNot Nothing AndAlso i < weights.Length Then
                Double.TryParse(weights(i), NumberStyles.Any, CultureInfo.InvariantCulture, weightVal)
            End If

            Dim catId As Integer = 3
            If cats IsNot Nothing AndAlso i < cats.Length Then Integer.TryParse(cats(i), catId)

            Try
                db.Insert_Checklist_Employee(
                    users_TypesID:=usersType,
                    title_Ar:=titleAr,
                    title_En:=Nothing,
                    brief_Ar:=briefAr,
                    brief_En:=Nothing,
                    brand_ID:=brandId,
                    branch_ID:=branchId,
                    department_ID:=deptId,
                    jobTitle_ID:=jobTitleId,
                    jobTitle_Items_ID:=Nothing,
                    shift_ID:=shiftId,
                    checkList_CategoryID:=catId,
                    weight:=weightVal,
                    addedUser:=SessionManager.GetInstance.Users.UserID
                )
            Catch
            End Try
        Next
    End Sub

    Protected Sub btnSaveNewChecklist_Click(sender As Object, e As EventArgs) Handles btnSaveNewChecklist.Click
        InsertNewChecklistEmployee()
        BindChecklistEmployee()

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeModalToast",
            "hidePageLoader(); try{bootstrap.Modal.getOrCreateInstance(document.getElementById('newChecklistModal')).hide();}catch(e){} showSavedToast();", True)
    End Sub

    ' =====================================================================
    ' ✅ حفظ تقييم الموظف + المرفقات باستخدام Stored Procedures التي أرسلتها
    ' =====================================================================
    Protected Sub btnSaveEval_Click(sender As Object, e As EventArgs) Handles btnSaveEval.Click
        evalErr.InnerText = ""

        ' 1) قراءة الـ Checklist المختارة (checkbox غير Server Control)
        Dim selectedIds As New List(Of Integer)()
        For Each k As String In Request.Form.AllKeys
            If k IsNot Nothing AndAlso k.StartsWith("chkEmp_") Then
                Dim idStr = k.Replace("chkEmp_", "")
                Dim idVal As Integer = 0
                If Integer.TryParse(idStr, idVal) Then selectedIds.Add(idVal)
            End If
        Next

        If selectedIds.Count = 0 Then
            evalErr.InnerText = "يجب اختيار عنصر تقييم واحد على الأقل قبل الحفظ."
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideL", "hidePageLoader();", True)
            Exit Sub
        End If

        Dim checklistCsv As String = String.Join(",", selectedIds.Distinct())
        Dim notes As String = If(txtNotes IsNot Nothing, txtNotes.Text, Nothing)

        ' 2) استدعاء Insert_Evaluation_Employee واسترجاع NewEvaluationID
        Dim newEvalId As Integer = 0
        Try
            ' LINQ to SQL عادةً يولّد SP بهذه الطريقة:
            ' Insert_Evaluation_Employee(EmployeeID, Checklist_IDs, Notes, AddedUser, ByRef NewEvaluationID)
            db.Insert_Evaluation_Employee(EmployeeID, checklistCsv, notes, SessionManager.GetInstance.Users.UserID, newEvalId)
        Catch ex As Exception
            evalErr.InnerText = "خطأ أثناء حفظ التقييم: " & ex.Message
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideL2", "hidePageLoader();", True)
            Exit Sub
        End Try

        If newEvalId <= 0 Then
            evalErr.InnerText = "لم يتم إنشاء رقم تقييم جديد."
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "hideL3", "hidePageLoader();", True)
            Exit Sub
        End If

        ' 3) حفظ المرفقات من Session على السيرفر ثم Insert_Evaluation_Employee_Attachment
        Try
            Dim filesDict = SaveFilesFromSession()
            If newEvalId > 0 AndAlso filesDict IsNot Nothing AndAlso filesDict.Count > 0 Then
                For Each kvp In filesDict
                    Dim filePath As String = kvp.Key
                    Dim title As String = kvp.Value
                    db.Insert_Evaluation_Employee_Attachment(newEvalId, title, filePath)
                Next
            End If
        Catch
            ' لا نوقف التقييم إذا حصل خطأ في المرفقات
        End Try

        ' 4) تحديث الواجهة + Toast
        txtNotes.Text = ""
        BindChecklistEmployee()

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "doneToast",
            "hidePageLoader(); showSavedToast();", True)



        Response.Redirect("/modules/Employees/MyProfile.aspx?EmployeeID=" + Request.QueryString("employeeID").ToString())
    End Sub

End Class
