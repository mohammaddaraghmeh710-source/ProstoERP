Imports System
Imports System.Linq
Imports System.Collections.Generic
Imports System.Web
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports AjaxControlToolkit
Imports System.Text
Imports System.Web.Security

Public Class JobTitles_Evaluation
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()

    Protected DepartmentID As Integer
    Protected ShiftID As Integer
    Protected BranchID As Integer

    Protected Function JsString(value As Object) As String
        If value Is Nothing Then Return ""
        Return HttpUtility.JavaScriptStringEncode(value.ToString())
    End Function

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()

        If Not IsPostBack Then
            BindHeader()
            BindJobTitles()
        End If
    End Sub

    Private Sub LoadParameters()
        If Not IsPostBack Then
            Integer.TryParse(Request.QueryString("DepartmentID"), DepartmentID)
            If DepartmentID = 0 Then
                Integer.TryParse(Request.QueryString("Departmentid"), DepartmentID)
            End If

            Integer.TryParse(Request.QueryString("ShiftID"), ShiftID)
            If ShiftID = 0 Then
                Integer.TryParse(Request.QueryString("shiftID"), ShiftID)
            End If

            Integer.TryParse(Request.QueryString("BranchID"), BranchID)

            ViewState("DepartmentID") = DepartmentID
            ViewState("ShiftID") = ShiftID
            ViewState("BranchID") = BranchID
        Else
            DepartmentID = If(ViewState("DepartmentID") IsNot Nothing, CInt(ViewState("DepartmentID")), 0)
            ShiftID = If(ViewState("ShiftID") IsNot Nothing, CInt(ViewState("ShiftID")), 0)
            BranchID = If(ViewState("BranchID") IsNot Nothing, CInt(ViewState("BranchID")), 0)
        End If
    End Sub

    Private Property CurrentChecklistSearch As String
        Get
            Dim val = TryCast(ViewState("ChecklistSearch"), String)
            If val Is Nothing Then Return String.Empty
            Return val
        End Get
        Set(value As String)
            ViewState("ChecklistSearch") = value
        End Set
    End Property

    Protected Sub btnSearchChecklist_Click(sender As Object, e As EventArgs) Handles btnSearchChecklist.Click
        Dim term As String = txtSearchChecklist.Text.Trim()
        CurrentChecklistSearch = term
        BindJobTitles(term)
    End Sub

    Protected Sub btnClearChecklist_Click(sender As Object, e As EventArgs) Handles btnClearChecklist.Click
        txtSearchChecklist.Text = String.Empty
        CurrentChecklistSearch = String.Empty
        BindJobTitles()
    End Sub

    Private Sub BindHeader()
        Dim info = (From d In db.Select_Departments_All
                    Join b In db.Select_Branches_All On d.BranchID Equals b.ID
                    Where d.ID = DepartmentID AndAlso (d.IsDeleted = False OrElse d.IsDeleted Is Nothing)
                    Select New With {
                        .BranchID = b.ID,
                        .BranchName = b.Title_Ar,
                        .DepartmentName = d.Title_Ar,
                        .BrandID = b.BrandID
                    }).FirstOrDefault()

        If info IsNot Nothing Then
            BranchNameText.InnerText = info.BranchName
            DepartmentNameText.InnerText = info.DepartmentName

            BranchID = info.BranchID
            ViewState("BranchID") = BranchID
            ViewState("BrandID") = info.BrandID
        End If
    End Sub

    ' تعبئة المحطات التعريفية 
    Private Sub BindJobTitles(Optional searchTerm As String = Nothing)
        If Request.QueryString("JobTitleID") Is Nothing Then
            Dim baseQuery = From jt In db.Select_JobTitles_All
                            Where jt.DepartmentID = DepartmentID _
                    AndAlso (jt.IsDeleted = False OrElse jt.IsDeleted Is Nothing) _
                    AndAlso (jt.IsActive = True OrElse jt.IsActive Is Nothing)

            If Not String.IsNullOrWhiteSpace(searchTerm) Then
                Dim term = searchTerm.Trim()

                ' فلترة المحطات التعريفية بحيث تحتوي على عنصر تقييم فيه نص البحث
                Dim filteredQuery = From jt In baseQuery
                                    Join c In db.Select_Checklist_All On jt.ID Equals c.JobTitle_ID
                                    Where c.Shift_ID = ShiftID _
                                  AndAlso (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                                  AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing) _
                                  AndAlso (
                                      (c.Title_Ar IsNot Nothing AndAlso c.Title_Ar.Contains(term)) _
                                      OrElse (c.Brief_Ar IsNot Nothing AndAlso c.Brief_Ar.Contains(term))
                                  )
                                    Order By jt.Title_Ar
                                    Select New With {
                                    .ID = jt.ID,
                                    .Title_Ar = jt.Title_Ar,
                                    .Policies_Ar = jt.Policies_Ar,
                                    .Working_Method_Ar = jt.Working_Method_Video_Ar,
                                    .Evaluation_Method_Ar = jt.Evaluation_Method_Video_Ar
                                }

                Dim jobTitles = filteredQuery.Distinct().ToList()

                rptJobTitles.DataSource = jobTitles
                rptJobTitles.DataBind()
            Else
                ' الحالة العادية بدون بحث
                Dim jobTitles = (From jt In baseQuery
                                 Order By jt.Title_Ar
                                 Select New With {
                                 .ID = jt.ID,
                                 .Title_Ar = jt.Title_Ar,
                                 .Policies_Ar = jt.Policies_Ar,
                                 .Working_Method_Ar = jt.Working_Method_Video_Ar,
                                 .Evaluation_Method_Ar = jt.Evaluation_Method_Video_Ar
                             }).ToList()

                rptJobTitles.DataSource = jobTitles
                rptJobTitles.DataBind()
            End If
        Else

            Dim baseQuery = From jt In db.Select_JobTitles_All
                            Where jt.DepartmentID = DepartmentID And jt.ID = CInt(Request.QueryString("JobTitleID")) _
                              AndAlso (jt.IsDeleted = False OrElse jt.IsDeleted Is Nothing) _
                              AndAlso (jt.IsActive = True OrElse jt.IsActive Is Nothing)

            If Not String.IsNullOrWhiteSpace(searchTerm) Then
                Dim term = searchTerm.Trim()

                ' فلترة المحطات التعريفية بحيث تحتوي على عنصر تقييم فيه نص البحث
                Dim filteredQuery = From jt In baseQuery
                                    Join c In db.Select_Checklist_All On jt.ID Equals c.JobTitle_ID
                                    Where c.Shift_ID = ShiftID _
                                      AndAlso (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                                      AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing) _
                                      AndAlso (
                                          (c.Title_Ar IsNot Nothing AndAlso c.Title_Ar.Contains(term)) _
                                          OrElse (c.Brief_Ar IsNot Nothing AndAlso c.Brief_Ar.Contains(term))
                                      )
                                    Order By jt.Title_Ar
                                    Select New With {
                                        .ID = jt.ID,
                                        .Title_Ar = jt.Title_Ar,
                                        .Policies_Ar = jt.Policies_Ar,
                                        .Working_Method_Ar = jt.Working_Method_Video_Ar,
                                        .Evaluation_Method_Ar = jt.Evaluation_Method_Video_Ar
                                    }

                Dim jobTitles = filteredQuery.Distinct().ToList()

                rptJobTitles.DataSource = jobTitles
                rptJobTitles.DataBind()
            Else
                ' الحالة العادية بدون بحث
                Dim jobTitles = (From jt In baseQuery
                                 Order By jt.Title_Ar
                                 Select New With {
                                     .ID = jt.ID,
                                     .Title_Ar = jt.Title_Ar,
                                     .Policies_Ar = jt.Policies_Ar,
                                     .Working_Method_Ar = jt.Working_Method_Video_Ar,
                                     .Evaluation_Method_Ar = jt.Evaluation_Method_Video_Ar
                                 }).ToList()

                rptJobTitles.DataSource = jobTitles
                rptJobTitles.DataBind()
            End If
        End If

    End Sub

    Private Function IsJobTitleEvaluatedToday(jobTitleId As Integer) As Boolean
        Dim today = DateTime.Today
        Dim tomorrow = today.AddDays(1)

        Dim brandId As Integer? = Nothing
        If ViewState("BrandID") IsNot Nothing Then
            brandId = CInt(ViewState("BrandID"))
        End If

        Dim q = From ev In db.Select_Evaluations_All
                Where ev.Evaluation_Type = 1 _
                  AndAlso (Not brandId.HasValue OrElse ev.Brand_ID = brandId.Value) _
                  AndAlso ev.Branch_ID = BranchID _
                  AndAlso ev.Department_ID = DepartmentID _
                  AndAlso ev.JobTitle_ID = jobTitleId _
                  AndAlso ev.Shift_ID = ShiftID _
                  AndAlso ev.AddedDate.HasValue _
                  AndAlso ev.AddedDate.Value >= today _
                  AndAlso ev.AddedDate.Value < tomorrow _
                  AndAlso (ev.IsDeleted = False OrElse ev.IsDeleted Is Nothing)
                Select ev.ID

        Return q.Any()
    End Function

    Protected Sub rptJobTitles_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rptJobTitles.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso
           e.Item.ItemType <> ListItemType.AlternatingItem Then
            Return
        End If

        Dim jobId As Integer = Convert.ToInt32(DataBinder.Eval(e.Item.DataItem, "ID"))

        Dim rptChecklist As Repeater = TryCast(e.Item.FindControl("rptChecklist"), Repeater)
        Dim pnlNoChecklist As Panel = TryCast(e.Item.FindControl("pnlNoChecklist"), Panel)
        Dim pnlChecklistWrapper As Panel = TryCast(e.Item.FindControl("pnlChecklistWrapper"), Panel)

        Dim checklist As List(Of ChecklistItemDto) = GetChecklistItems(DepartmentID, jobId, ShiftID)
        Dim hasChecklist As Boolean = (checklist IsNot Nothing AndAlso checklist.Count > 0)

        If rptChecklist IsNot Nothing Then
            rptChecklist.DataSource = checklist
            rptChecklist.DataBind()
        End If

        If pnlNoChecklist IsNot Nothing AndAlso pnlChecklistWrapper IsNot Nothing Then
            pnlNoChecklist.Visible = Not hasChecklist
            pnlChecklistWrapper.Visible = hasChecklist
        End If

        Dim ddlEmployees As DropDownList = TryCast(e.Item.FindControl("ddlEmployees"), DropDownList)
        If ddlEmployees IsNot Nothing Then
            Dim employees = GetEmployees(DepartmentID, jobId, ShiftID)
            ddlEmployees.DataSource = employees
            ddlEmployees.DataTextField = "FullName_Ar"
            ddlEmployees.DataValueField = "ID"
            ddlEmployees.DataBind()
            ddlEmployees.Items.Insert(0, New ListItem("يرجى اختيار الموظف", ""))
        End If

        Dim txtEvalDate As TextBox = TryCast(e.Item.FindControl("txtEvaluationDate"), TextBox)
        If txtEvalDate IsNot Nothing Then
            txtEvalDate.Text = DateTime.Now.ToString("MM/dd/yyyy")
        End If

        Dim isToday As Boolean = IsJobTitleEvaluatedToday(jobId)
        Dim phEvaluated As PlaceHolder = TryCast(e.Item.FindControl("phEvaluated"), PlaceHolder)
        If phEvaluated IsNot Nothing Then
            phEvaluated.Visible = isToday
        End If
    End Sub

    Private Function GetChecklistItems(deptId As Integer,
                                       jobTitleId As Integer,
                                       shiftId As Integer) As List(Of ChecklistItemDto)

        Dim query = From c In db.Select_Checklist_All
                    Join cat In db.Checklist_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                    Where c.Type = CInt(Request.QueryString("Type")) AndAlso c.Department_ID = deptId _
                      AndAlso c.JobTitle_ID = jobTitleId _
                      AndAlso c.Shift_ID = shiftId _
                      AndAlso (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                      AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing)
                    Order By c.ID
                    Select New ChecklistItemDto With {
                        .ID = c.ID,
                        .Title_Ar = c.Title_Ar,
                        .Brief_Ar = c.Brief_Ar,
                        .CheckList_CategoryID = c.CheckList_CategoryID,
                        .CategoryTitle_Ar = cat.Title_Ar,
                        .Weight = c.Weight
                    }

        Return query.ToList()
    End Function

    Private Function GetEmployees(deptId As Integer,
                                  jobTitleId As Integer,
                                  shiftId As Integer) As Object

        Dim query = From u In db.Select_UsersMembers_All
                    Where u.Department_ID = deptId _
                          AndAlso u.JobTitle_ID = jobTitleId _
                          AndAlso u.Shif_ID = shiftId _
                          AndAlso (u.IsDeleted = False OrElse u.IsDeleted Is Nothing) _
                          AndAlso (u.IsActive = True OrElse u.IsActive Is Nothing)
                    Order By u.FullName_Ar
                    Select New With {
                        .ID = u.ID,
                        .FullName_Ar = u.FullName_Ar
                    }

        Return query.ToList()
    End Function

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

    Protected Sub TaskFiles_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub TaskFiles_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    Private Sub InsertNewChecklistItems(jobId As Integer, brandId As Integer?)
        Dim titlesAr = Request.Form.GetValues("newTitleAr_" & jobId & "[]")
        Dim titlesEn = Request.Form.GetValues("newTitleEn_" & jobId & "[]")
        Dim weights = Request.Form.GetValues("newWeight_" & jobId & "[]")
        Dim cats = Request.Form.GetValues("newCategory_" & jobId & "[]")
        Dim Type As Integer
        If Not Request.QueryString("Type") Is Nothing And Request.QueryString("Type") <> "" Then
            Type = CInt(Request.QueryString("Type"))
        End If


        If titlesAr Is Nothing OrElse titlesAr.Length = 0 Then
            Exit Sub
        End If

        For i As Integer = 0 To titlesAr.Length - 1
            Dim titleAr As String = If(titlesAr(i), "").Trim()
            If String.IsNullOrEmpty(titleAr) Then
                Continue For
            End If

            Dim titleEn As String = Nothing
            If titlesEn IsNot Nothing AndAlso i < titlesEn.Length Then
                titleEn = If(titlesEn(i), "").Trim()
            End If

            Dim briefAr As String = titleEn

            Dim weightVal As Decimal = 0D
            If weights IsNot Nothing AndAlso i < weights.Length Then
                Decimal.TryParse(weights(i), weightVal)
            End If

            Dim catId As Integer = 0
            If cats IsNot Nothing AndAlso i < cats.Length Then
                Integer.TryParse(cats(i), catId)
            End If

            Dim JobTitle_Ar As String = db.Select_JobTitles_ByID(jobId).FirstOrDefault().Title_Ar
            Try
                'Start New Remove later 
                Dim JobTitles = db.Select_JobTitles_All.Where(Function(x) x.Title_Ar = JobTitle_Ar)
                For Each jobTit In JobTitles
                    Dim JobTitle_BrandID = jobTit.BrandID
                    Dim JobTitle_BranchID = jobTit.BranchID
                    Dim JobTitle_DepartmentID = jobTit.DepartmentID
                    Dim JobTitle_ID = jobTit.ID



                    db.Insert_Checklist(Type, titleAr,
                                   Nothing,
                                   briefAr,
                                   Nothing,
                                   JobTitle_BrandID,
                                   JobTitle_BranchID,
                                   JobTitle_DepartmentID,
                                   JobTitle_ID,
                                   Nothing,
                                   1,
                                   catId,
                                   weightVal,
                                   SessionManager.GetInstance.Users.UserID)


                    db.Insert_Checklist(Type, titleAr,
                                  Nothing,
                                  briefAr,
                                  Nothing,
                                  JobTitle_BrandID,
                                  JobTitle_BranchID,
                                  JobTitle_DepartmentID,
                                  JobTitle_ID,
                                  Nothing,
                                  2,
                                  catId,
                                  weightVal,
                                  SessionManager.GetInstance.Users.UserID)

                    db.Insert_Checklist(Type, titleAr,
                                  Nothing,
                                  briefAr,
                                  Nothing,
                                  JobTitle_BrandID,
                                  JobTitle_BranchID,
                                  JobTitle_DepartmentID,
                                  JobTitle_ID,
                                  Nothing,
                                  3,
                                  catId,
                                  weightVal,
                                  SessionManager.GetInstance.Users.UserID)
                Next



            Catch ex As Exception
            End Try

            'End New Remove later 

            'Try
            '    db.Insert_Checklist(titleAr,
            '                        Nothing,
            '                        briefAr,
            '                        Nothing,
            '                        brandId,
            '                        BranchID,
            '                        DepartmentID,
            '                        jobId,
            '                        Nothing,
            '                        ShiftID,
            '                        catId,
            '                        weightVal,
            '                        SessionManager.GetInstance.Users.UserID)
            'Catch ex As Exception
            'End Try
        Next
    End Sub

    Protected Sub rptJobTitles_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptJobTitles.ItemCommand
        Dim jobId As Integer = Convert.ToInt32(e.CommandArgument)

        Dim brandId As Integer? = Nothing
        If ViewState("BrandID") IsNot Nothing Then
            brandId = CInt(ViewState("BrandID"))
        Else
            brandId = (From d In db.Select_Departments_All
                       Join b In db.Select_Branches_All On d.BranchID Equals b.ID
                       Where d.ID = DepartmentID
                       Select CType(b.BrandID, Integer?)).FirstOrDefault()
            ViewState("BrandID") = brandId
        End If

        ' أولاً: دائماً نحاول إدخال عناصر التقييم الجديدة إن وجدت
        InsertNewChecklistItems(jobId, brandId)

        ' ===== 1) سياسات المحطة التعريفية =====
        If e.CommandName = "ShowJobPolicies" Then
            Dim jt = (From j In db.Select_JobTitles_All
                      Where j.ID = jobId
                      Select j).FirstOrDefault()

            If jt IsNot Nothing AndAlso Not String.IsNullOrWhiteSpace(jt.Policies_Ar) Then
                'Dim encoded As String = Server.HtmlEncode(jt.Policies_Ar)
                'encoded = encoded.Replace(Environment.NewLine, "<br />")
                litJobPolicies.Text = jt.Policies_Ar
            Else
                litJobPolicies.Text = "<p class='mb-0 text-muted'>لم يتم تعريف سياسات لهذا المحطة التعريفية بعد.</p>"
            End If

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "showJobPoliciesModal", "showJobPoliciesModal();", True)
            Return
        End If

        ' ===== 2) فيديو طريقة العمل للمسمى الوظيفي =====
        If e.CommandName = "ShowJobWorking" Then
            Dim jt = (From j In db.Select_JobTitles_All
                      Where j.ID = jobId
                      Select j).FirstOrDefault()

            If jt Is Nothing OrElse String.IsNullOrWhiteSpace(jt.Working_Method_Video_Ar) Then
                ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noJobWorkingVideo",
                                                    "alert('لم يتم تعريف فيديو طريقة العمل لهذا المحطة التعريفية.');", True)
                Return
            End If

            Dim url As String = BuildSecureVideoUrl(jt.Working_Method_Video_Ar)
            Dim script As String = "openJobWorkingVideo('" & url.Replace("'", "\'") & "');"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openJobWorkingVideo", script, True)
            Return
        End If

        ' ===== 3) فيديو طريقة التقييم للمسمى الوظيفي =====
        If e.CommandName = "ShowJobEvaluation" Then
            Dim jt = (From j In db.Select_JobTitles_ByID(jobId)
                      Select j).FirstOrDefault()

            If jt Is Nothing OrElse String.IsNullOrWhiteSpace(jt.Evaluation_Method_Video_Ar) Then
                ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noJobEvaluationVideo",
                                                    "alert('لم يتم تعريف فيديو طريقة التقييم لهذا المحطة التعريفية.');", True)
                Return
            End If

            Dim url As String = BuildSecureVideoUrl(jt.Evaluation_Method_Video_Ar)
            Dim script As String = "openJobEvaluationVideo('" & url.Replace("'", "\'") & "');"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "openJobEvaluationVideo", script, True)
            Return
        End If

        ' ===== الحفظ القديم كما هو =====
        If e.CommandName = "SaveChecklist" Then
            Response.Redirect(Request.RawUrl)
            Return
        End If

        If e.CommandName <> "SaveEvaluation" Then Return

        Dim scopeValue As String = Request.Form("scope_" & jobId)

        Dim employeeKnown As Boolean = False
        Dim employeeIdsStr As String = Nothing

        Dim ddlEmployees As DropDownList = TryCast(e.Item.FindControl("ddlEmployees"), DropDownList)

        If scopeValue = "one" AndAlso ddlEmployees IsNot Nothing AndAlso Not String.IsNullOrEmpty(ddlEmployees.SelectedValue) Then
            employeeKnown = True
            employeeIdsStr = ddlEmployees.SelectedValue.Trim()
        Else
            Dim employeesQuery = From u In db.Select_UsersMembers_All
                                 Where (Not brandId.HasValue OrElse u.Brand_ID = brandId.Value) _
                                       AndAlso (BranchID = 0 OrElse u.Branch_ID = BranchID) _
                                       AndAlso u.Department_ID = DepartmentID _
                                       AndAlso u.JobTitle_ID = jobId _
                                       AndAlso u.Shif_ID = ShiftID _
                                       AndAlso u.Type = 4 _
                                       AndAlso (u.IsDeleted = False OrElse u.IsDeleted Is Nothing) _
                                       AndAlso (u.IsActive = True OrElse u.IsActive Is Nothing)
                                 Select u.ID

            Dim allIds = employeesQuery.ToList()
            If allIds.Count > 0 Then
                employeeIdsStr = String.Join(",", allIds)
            End If
        End If

        Dim txtNotes As TextBox = TryCast(e.Item.FindControl("txtNotes"), TextBox)
        Dim notes As String = If(txtNotes IsNot Nothing, txtNotes.Text, Nothing)

        Dim txtEvalDate As TextBox = TryCast(e.Item.FindControl("txtEvaluationDate"), TextBox)
        Dim evalDate As DateTime = DateTime.Now
        If txtEvalDate IsNot Nothing Then
            DateTime.TryParse(txtEvalDate.Text, evalDate)
        End If

        Dim allChecklistIds = (From c In db.Select_Checklist_All
                               Where c.Type = CInt(Request.QueryString("Type")) AndAlso c.Department_ID = DepartmentID _
                                     AndAlso c.JobTitle_ID = jobId _
                                     AndAlso c.Shift_ID = ShiftID _
                                     AndAlso (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                                     AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing)
                               Select c.ID).ToList()

        Dim selectedChecklistIds As New List(Of Integer)()
        For Each cid In allChecklistIds
            Dim key As String = "chk_" & cid
            If Not String.IsNullOrEmpty(Request.Form(key)) Then
                selectedChecklistIds.Add(cid)
            End If
        Next

        Dim checklistIdsStr As String = Nothing
        If selectedChecklistIds.Count > 0 Then
            checklistIdsStr = String.Join(",", selectedChecklistIds)
        End If

        Dim totalWeight As Double? = Nothing
        If selectedChecklistIds.Count > 0 Then
            Dim q = From c In db.Select_Checklist_All
                    Where selectedChecklistIds.Contains(c.ID)
                    Select WeightValue = If(c.Weight.HasValue, c.Weight.Value, 0D)

            Dim sumWeight As Double = q.Sum()
            totalWeight = sumWeight
        Else
            totalWeight = 0D
        End If

        If selectedChecklistIds.Count = 0 AndAlso String.IsNullOrWhiteSpace(notes) Then
            Return
        End If

        Dim filesDict = SaveFilesFromSession()

        Dim newEvalId As Integer = 0

        Using ctx As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext
            Const JOBTITLE_EVAL_TYPE As Integer = 1

            Dim result = ctx.Insert_Evaluations(
                evaluation_Type:=JOBTITLE_EVAL_TYPE,
                brand_ID:=brandId,
                branch_ID:=BranchID,
                department_ID:=DepartmentID,
                jobTitle_ID:=jobId,
                jobTitle_Items_ID:=Nothing,
                shift_ID:=ShiftID,
                employee_is_known:=employeeKnown,
                employee_ID:=employeeIdsStr,
                checklist_IDs:=checklistIdsStr,
                weight:=totalWeight,
                notes:=notes,
                addedUser:=SessionManager.GetInstance.Users.UserID
            )

            For Each r In result
                If r IsNot Nothing AndAlso r.NewID IsNot Nothing Then
                    newEvalId = Convert.ToInt32(r.NewID)
                    Exit For
                End If
            Next

            If newEvalId > 0 AndAlso filesDict IsNot Nothing AndAlso filesDict.Count > 0 Then
                For Each kvp In filesDict
                    Dim filePath As String = kvp.Key
                    Dim title As String = kvp.Value
                    ctx.Insert_Evaluations_Attachments(newEvalId, title, filePath)
                Next
            End If
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect("/Modules/Branch_Shift_Manager/Branch_Shift_Manager_Dashboard.aspx?BranchID=" + BranchID.ToString() + "&ShiftID=" + Request.QueryString("ShiftID").ToString())
        'LBLPOP_ModalPopupExtender.Hide()
    End Sub

    Private Class ChecklistItemDto
        Public Property ID As Integer
        Public Property Title_Ar As String
        Public Property Brief_Ar As String
        Public Property CheckList_CategoryID As Integer?
        Public Property CategoryTitle_Ar As String
        Public Property Weight As Double?
    End Class

    ' ===== نفس دوال الفيديو الآمن من صفحة تقييم الفرع =====
    Private Function BuildSecureVideoUrl(relativePath As String) As String
        If String.IsNullOrWhiteSpace(relativePath) Then
            Return String.Empty
        End If

        Dim normPath As String = relativePath.Trim()
        If Not normPath.StartsWith("~") AndAlso Not normPath.StartsWith("/") Then
            normPath = "~" & normPath
        End If

        Dim token As String = GenerateVideoToken(normPath, 60)
        Return ResolveUrl("~/DeptVideoHandler.ashx?t=" & token)
    End Function

    Private Function GenerateVideoToken(virtualPath As String, expiryMinutes As Integer) As String
        Dim expires As Long = DateTime.UtcNow.AddMinutes(expiryMinutes).Ticks
        Dim payload As String = virtualPath & "|" & expires.ToString()

        Dim bytes As Byte() = Encoding.UTF8.GetBytes(payload)
        Dim protectedBytes As Byte() = MachineKey.Protect(bytes, "DeptVideoToken")

        Return HttpServerUtility.UrlTokenEncode(protectedBytes)
    End Function


End Class
