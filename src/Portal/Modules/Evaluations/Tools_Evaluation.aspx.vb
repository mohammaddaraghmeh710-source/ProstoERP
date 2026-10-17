Imports AjaxControlToolkit
Imports Prosto_ERP_ClassLibrary

Public Class Tools_Evaluation
    Inherits PageBase

    Private ReadOnly db As New Prosto_ERP_DataClassesDataContext()

    Protected JobTitle_ItemsID As Integer
    Protected BranchID As Integer
    Protected DepartmentID As Integer
    Protected JobTitleID As Integer
    Protected BrandID As Integer
    Protected ShiftID As Integer

    ' ✅ هذا المتغير لتحديد هل نفتح الـAccordion تلقائياً
    Private Property ShouldAutoOpenAccordion As Boolean
        Get
            Dim v = ViewState("AutoOpenAcc")
            If v Is Nothing Then Return False
            Return Convert.ToBoolean(v)
        End Get
        Set
            ViewState("AutoOpenAcc") = value
        End Set
    End Property

    Protected Function JsString(value As Object) As String
        If value Is Nothing Then Return ""
        Return HttpUtility.JavaScriptStringEncode(value.ToString())
    End Function

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
        End If

        LoadParameters()
        EnsureContextIds()

        ' ✅ دائماً مفتوحة
        ShouldAutoOpenAccordion = True

        If Not IsPostBack Then
            BindHeader()
            BindChecklist()
            BindEvaluatedBadge()
            ApplyAccordionState()
        Else
            ApplyAccordionState()
        End If
    End Sub


    Private Sub LoadParameters()
        Integer.TryParse(Request.QueryString("JobTitle_ItemsID"), JobTitle_ItemsID)
        If JobTitle_ItemsID = 0 Then
            Integer.TryParse(Request.QueryString("JobTitle_ItemsId"), JobTitle_ItemsID)
        End If

        If Not Integer.TryParse(Request.QueryString("ShiftID"), ShiftID) Then
            ShiftID = GetCurrentShiftId()
        End If
    End Sub

    Private Sub EnsureContextIds()
        If IsPostBack Then
            BrandID = SafeInt(ViewState("BrandID"))
            BranchID = SafeInt(ViewState("BranchID"))
            DepartmentID = SafeInt(ViewState("DepartmentID"))
            JobTitleID = SafeInt(ViewState("JobTitleID"))
        End If
    End Sub

    Private Function SafeInt(v As Object) As Integer
        If v Is Nothing Then Return 0
        Dim x = 0
        Integer.TryParse(v.ToString(), x)
        Return x
    End Function

    Private Function GetCurrentShiftId() As Integer
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

        Return 0
    End Function

    Private Property CurrentChecklistSearch As String
        Get
            Dim val = TryCast(ViewState("ChecklistSearch"), String)
            If val Is Nothing Then Return String.Empty
            Return val
        End Get
        Set
            ViewState("ChecklistSearch") = value
        End Set
    End Property

    Protected Sub btnSearchChecklist_Click(sender As Object, e As EventArgs) Handles btnSearchChecklist.Click
        CurrentChecklistSearch = txtSearchChecklist.Text.Trim()
        BindChecklist(CurrentChecklistSearch)
        ApplyAccordionState()
    End Sub

    Protected Sub btnClearChecklist_Click(sender As Object, e As EventArgs) Handles btnClearChecklist.Click
        txtSearchChecklist.Text = ""
        CurrentChecklistSearch = ""
        BindChecklist()
        ApplyAccordionState()
    End Sub

    ' ================= Header =================
    Private Sub BindHeader()

        Dim info = (From t In db.Select_JobTitle_Items_ByID(JobTitle_ItemsID)
                Join jt In db.Select_JobTitles_All On t.JobTitle_ID Equals jt.ID
                Join d In db.Select_Departments_All On jt.DepartmentID Equals d.ID
                Join b In db.Select_Branches_All On d.BranchID Equals b.ID
                Join br In db.Select_Brands_All On b.BrandID Equals br.ID
                Where (t.IsDeleted = False OrElse t.IsDeleted Is Nothing)
                Select New With {
                .ToolTitle = t.Title_Ar,
                .BrandName = br.Title_Ar,
                .BranchName = b.Title_Ar,
                .DepartmentName = d.Title_Ar,
                .JobTitleName = jt.Title_Ar,
                .BranchID = b.ID,
                .DepartmentID = d.ID,
                .JobTitleID = jt.ID,
                .BrandID = b.BrandID
                }).FirstOrDefault()

        If info Is Nothing Then
            litToolTitle.Text = "لم يتم العثور على الأداة المطلوبة."
            litToolHeaderTitle.Text = "الأداة غير موجودة"
            Return
        End If

        litToolTitle.Text = "الأداة: " & info.ToolTitle
        litToolHeaderTitle.Text = info.ToolTitle

        BrandNameText.InnerText = info.BrandName
        BranchNameText.InnerText = info.BranchName
        DepartmentNameText.InnerText = info.DepartmentName
        JobTitleNameText.InnerText = info.JobTitleName

        BranchID = info.BranchID
        DepartmentID = info.DepartmentID
        JobTitleID = info.JobTitleID
        BrandID = info.BrandID

        ViewState("BranchID") = BranchID
        ViewState("DepartmentID") = DepartmentID
        ViewState("JobTitleID") = JobTitleID
        ViewState("BrandID") = BrandID
    End Sub


    ' ================= Checklist =================
    ' ✅ فقط حسب JobTitle_Items_ID + IsDeleted=0 + IsActive=1
    Private Sub BindChecklist(Optional searchTerm As String = Nothing)
        Dim query = From c In db.Select_Checklist_All
                Join cat In db.Checklist_Categories_SelectAll On c.CheckList_CategoryID Equals cat.ID
                Where c.JobTitle_Items_ID = JobTitle_ItemsID And c.Shift_ID = GetCurrentShiftId() _
                      AndAlso (c.Type = CInt(Request.QueryString("type"))) _
                      AndAlso (c.IsDeleted = False OrElse c.IsDeleted Is Nothing) _
                      AndAlso (c.IsActive = True OrElse c.IsActive Is Nothing)
                Order By c.ID
                Select New With {
                .ID = c.ID,
                .Title_Ar = c.Title_Ar,
                .Brief_Ar = c.Brief_Ar,
                .CheckList_CategoryID = c.CheckList_CategoryID,
                .CategoryTitle_Ar = cat.Title_Ar,
                .Weight = c.Weight
                }

        If Not String.IsNullOrWhiteSpace(searchTerm) Then
            Dim term = searchTerm.Trim()
            query = From x In query
                Where (x.Title_Ar IsNot Nothing AndAlso x.Title_Ar.Contains(term)) _
                      OrElse (x.Brief_Ar IsNot Nothing AndAlso x.Brief_Ar.Contains(term))
                Select x
        End If

        Dim list = query.ToList()

        rptChecklist.DataSource = list
        rptChecklist.DataBind()

        pnlNoChecklist.Visible = (list Is Nothing OrElse list.Count = 0)
        pnlChecklistWrapper.Visible = Not pnlNoChecklist.Visible

        ' ✅ افتح الـAccordion دائماً
        ShouldAutoOpenAccordion = True
    End Sub


    Private Sub ApplyAccordionState()
        ' عناصر runat="server" في الـaspx
        If ShouldAutoOpenAccordion Then
            collapseTool.Attributes("class") = "accordion-collapse collapse show"
            btnToolAccordion.Attributes("class") = "accordion-button fw-semibold"
            btnToolAccordion.Attributes("aria-expanded") = "true"
        Else
            collapseTool.Attributes("class") = "accordion-collapse collapse"
            btnToolAccordion.Attributes("class") = "accordion-button collapsed fw-semibold"
            btnToolAccordion.Attributes("aria-expanded") = "false"
        End If
    End Sub

    Protected Function GetChecklistCss(cat As Object) As String
        Dim c = 0
        If cat IsNot Nothing AndAlso Integer.TryParse(cat.ToString(), c) Then
            Select Case c
                Case 1 : Return "eval-tag eval-red"
                Case 2 : Return "eval-tag eval-yellow"
                Case 3 : Return "eval-tag eval-green"
            End Select
        End If
        Return "eval-tag"
    End Function

    ' ================= Popups (AJAX ModalPopupExtender) =================

    Protected Sub lnkShowPolicies_Click(sender As Object, e As EventArgs)
        Dim tool = db.Select_JobTitle_Items_ByID(JobTitle_ItemsID).FirstOrDefault()

        If tool IsNot Nothing AndAlso Not String.IsNullOrWhiteSpace(tool.Policies_Ar) Then
            litToolPolicies.Text = tool.Policies_Ar
        Else
            litToolPolicies.Text = "<p class='mb-0 text-muted'>لم يتم تعريف سياسات لهذه الأداة بعد.</p>"
        End If

        mpeToolPolicies.Show()
        ShouldAutoOpenAccordion = True
        ApplyAccordionState()
    End Sub

    Protected Sub btnClosePolicies_Click(sender As Object, e As EventArgs)
        mpeToolPolicies.Hide()
        ShouldAutoOpenAccordion = True
        ApplyAccordionState()
    End Sub

    Protected Sub lnkShowWorking_Click(sender As Object, e As EventArgs)
        Dim tool = db.Select_JobTitle_Items_ByID(JobTitle_ItemsID).FirstOrDefault()

        If tool Is Nothing OrElse String.IsNullOrWhiteSpace(tool.Working_Method_Video_Ar) Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noToolWorkingVideo",
                                                "alert('لم يتم تعريف فيديو طريقة العمل لهذه الأداة.');", True)
            Return
        End If

        litVideoTitle.Text = "طريقة العمل"
        hfVideoUrl.Value = BuildSecureVideoUrl(tool.Working_Method_Video_Ar)

        mpeToolVideo.Show()

        ' ✅ بعد فتح البوب اب: حمّل الفيديو من hfVideoUrl
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "playToolVideo",
                                            "setTimeout(function(){ playToolVideoFromHidden(); }, 50);", True)

        ShouldAutoOpenAccordion = True
        ApplyAccordionState()
    End Sub

    Protected Sub lnkShowEvaluation_Click(sender As Object, e As EventArgs)
        Dim tool = db.Select_JobTitle_Items_ByID(JobTitle_ItemsID).FirstOrDefault()

        If tool Is Nothing OrElse String.IsNullOrWhiteSpace(tool.Evaluation_Method_Video_Ar) Then
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "noToolEvaluationVideo",
                                                "alert('لم يتم تعريف فيديو طريقة التقييم لهذه الأداة.');", True)
            Return
        End If

        litVideoTitle.Text = "طريقة التقييم"
        hfVideoUrl.Value = BuildSecureVideoUrl(tool.Evaluation_Method_Video_Ar)

        mpeToolVideo.Show()

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "playToolVideo",
                                            "setTimeout(function(){ playToolVideoFromHidden(); }, 50);", True)

        ShouldAutoOpenAccordion = True
        ApplyAccordionState()
    End Sub

    Protected Sub btnCloseVideo_Click(sender As Object, e As EventArgs)
        mpeToolVideo.Hide()
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "stopToolVideo", "stopToolVideo();", True)
        ShouldAutoOpenAccordion = True
        ApplyAccordionState()
    End Sub

    ' ================= AjaxFileUpload =================
    Protected Sub TaskFiles_UploadComplete(sender As Object, e As AjaxFileUploadEventArgs)
        Try
            SaveFileOnSession(e.FileName, e.ContentType, e.GetContents())
        Catch
        End Try
    End Sub

    Protected Sub TaskFiles_UploadStart(sender As Object, e As AjaxFileUploadStartEventArgs)
    End Sub

    ' ================= Insert new checklist items for the TOOL =================
    Protected Sub btnSaveChecklist_Click(sender As Object, e As EventArgs)
        EnsureContextIds()
        If BrandID = 0 OrElse BranchID = 0 OrElse DepartmentID = 0 OrElse JobTitleID = 0 Then
            BindHeader()
        End If

        InsertNewChecklistItems()
        Response.Redirect(Request.RawUrl)
    End Sub

    Private Sub InsertNewChecklistItems()
        Dim titlesAr = Request.Form.GetValues("newTitleAr[]")
        Dim titlesEn = Request.Form.GetValues("newTitleEn[]")
        Dim weights = Request.Form.GetValues("newWeight[]")
        Dim cats = Request.Form.GetValues("newCategory[]")
        Dim Type As Integer
        If Not Request.QueryString("Type") Is Nothing And Request.QueryString("Type") <> "" Then
            Type = CInt(Request.QueryString("Type"))
        End If

        If titlesAr Is Nothing OrElse titlesAr.Length = 0 Then Exit Sub

        For i = 0 To titlesAr.Length - 1
            Dim titleAr As String = If(titlesAr(i), "").Trim()
            If String.IsNullOrWhiteSpace(titleAr) Then Continue For

            Dim titleEn As String = Nothing
            If titlesEn IsNot Nothing AndAlso i < titlesEn.Length Then
                titleEn = If(titlesEn(i), "").Trim()
            End If

            Dim briefAr As String = titleEn

            Dim weightVal = 0D
            If weights IsNot Nothing AndAlso i < weights.Length Then
                Decimal.TryParse(weights(i), weightVal)
            End If

            Dim catId = 3
            If cats IsNot Nothing AndAlso i < cats.Length Then
                Integer.TryParse(cats(i), catId)
            End If


            Dim JobTitle_ItemTitle_Ar As String =
                    db.Select_JobTitle_Items_ByID(JobTitle_ItemsID).FirstOrDefault().Title_Ar
            Try
                'Start New Remove later 
                Dim JobTitle_items = db.Select_JobTitle_Items_All.Where(Function(x) x.Title_Ar = JobTitle_ItemTitle_Ar)
                For Each jobTit In JobTitle_items
                    Dim JobTitle_BrandID = jobTit.BranchID
                    Dim JobTitle_BranchID = jobTit.BranchID
                    Dim JobTitle_DepartmentID = jobTit.DepartmentID
                    Dim JobTitle_JobTitleID = jobTit.JobTitleID
                    Dim ItemsID = jobTit.ID

                    db.Insert_Checklist(Type,
                                        titleAr,
                                        Nothing,
                                        briefAr,
                                        Nothing,
                                        JobTitle_BrandID,
                                        JobTitle_BranchID,
                                        JobTitle_DepartmentID,
                                        JobTitle_JobTitleID,
                                        ItemsID,
                                        1,
                                        catId,
                                        weightVal,
                                        SessionManager.GetInstance.Users.UserID
                                        )

                    db.Insert_Checklist(Type,
                                        titleAr,
                                        Nothing,
                                        briefAr,
                                        Nothing,
                                        JobTitle_BrandID,
                                        JobTitle_BranchID,
                                        JobTitle_DepartmentID,
                                        JobTitle_JobTitleID,
                                        ItemsID,
                                        2,
                                        catId,
                                        weightVal,
                                        SessionManager.GetInstance.Users.UserID
                                        )

                    db.Insert_Checklist(Type,
                                        titleAr,
                                        Nothing,
                                        briefAr,
                                        Nothing,
                                        JobTitle_BrandID,
                                        JobTitle_BranchID,
                                        JobTitle_DepartmentID,
                                        JobTitle_JobTitleID,
                                        ItemsID,
                                        3,
                                        catId,
                                        weightVal,
                                        SessionManager.GetInstance.Users.UserID
                                        )

                Next


            Catch ex As Exception
            End Try


            'Try
            '    db.Insert_Checklist(
            '        titleAr,
            '        Nothing,
            '        briefAr,
            '        Nothing,
            '        BrandID,
            '        BranchID,
            '        DepartmentID,
            '        JobTitleID,
            '        JobTitle_ItemsID,
            '        ShiftID,
            '        catId,
            '        weightVal,
            '        SessionManager.GetInstance.Users.UserID
            '    )
            'Catch
            'End Try
        Next
    End Sub

    ' ================= Save Tool Evaluation =================
    Protected Sub btnSaveEval_Click(sender As Object, e As EventArgs)
        EnsureContextIds()
        If BrandID = 0 OrElse BranchID = 0 OrElse DepartmentID = 0 OrElse JobTitleID = 0 Then
            BindHeader()
        End If

        SaveToolEvaluation()
    End Sub

    Private Sub SaveToolEvaluation()

        Dim allChecklistIds = (From c In db.Select_Checklist_All
                Where c.JobTitle_Items_ID = JobTitle_ItemsID _
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

        Dim notes As String = If(txtNotes IsNot Nothing, txtNotes.Text, Nothing)

        If selectedChecklistIds.Count = 0 AndAlso String.IsNullOrWhiteSpace(notes) Then
            Return
        End If

        Dim checklistIdsStr As String = Nothing
        If selectedChecklistIds.Count > 0 Then
            checklistIdsStr = String.Join(",", selectedChecklistIds)
        End If

        Dim totalWeight As Double = 0D
        If selectedChecklistIds.Count > 0 Then
            Dim q = From c In db.Select_Checklist_All
                    Where selectedChecklistIds.Contains(c.ID)
                    Select WeightValue = If(c.Weight.HasValue, c.Weight.Value, 0D)
            totalWeight = q.Sum()
        End If

        Dim filesDict = SaveFilesFromSession()
        Dim newEvalId = 0

        Using ctx As New Prosto_ERP_DataClassesDataContext
            Const TOOL_EVAL_TYPE = 1

            Dim result = ctx.Insert_Evaluations(
                evaluation_Type := TOOL_EVAL_TYPE,
                brand_ID := BrandID,
                branch_ID := BranchID,
                department_ID := DepartmentID,
                jobTitle_ID := JobTitleID,
                jobTitle_Items_ID := JobTitle_ItemsID,
                shift_ID := ShiftID,
                employee_is_known := False,
                employee_ID := Nothing,
                checklist_IDs := checklistIdsStr,
                weight := totalWeight,
                notes := notes,
                addedUser := SessionManager.GetInstance.Users.UserID
                )

            For Each r In result
                If r IsNot Nothing AndAlso r.NewID IsNot Nothing Then
                    newEvalId = Convert.ToInt32(r.NewID)
                    Exit For
                End If
            Next

            If newEvalId > 0 AndAlso filesDict IsNot Nothing AndAlso filesDict.Count > 0 Then
                For Each kvp In filesDict
                    ctx.Insert_Evaluations_Attachments(newEvalId, kvp.Value, kvp.Key)
                Next
            End If
        End Using

        LBLPOP_ModalPopupExtender.Show()
    End Sub

    Protected Sub btnClosePopup_Click(sender As Object, e As EventArgs)
        Response.Redirect(
            "/Modules/QRCode/Tools_Viewer_QRCode.aspx?JobTitle_ItemsID=" &
            Request.QueryString("JobTitle_ItemsID").ToString())
    End Sub

    ' ================= Evaluated Today Badge =================
    Private Sub BindEvaluatedBadge()
        Dim today = DateTime.Today
        Dim tomorrow = today.AddDays(1)

        Dim q = From ev In db.Select_Evaluations_All
                Where ev.Evaluation_Type = 2 _
                      AndAlso ev.JobTitle_Items_ID = JobTitle_ItemsID _
                      AndAlso ev.Branch_ID = BranchID _
                      AndAlso ev.Department_ID = DepartmentID _
                      AndAlso ev.JobTitle_ID = JobTitleID _
                      AndAlso ev.Shift_ID = ShiftID _
                      AndAlso ev.AddedDate.HasValue _
                      AndAlso ev.AddedDate.Value >= today _
                      AndAlso ev.AddedDate.Value < tomorrow _
                      AndAlso (ev.IsDeleted = False OrElse ev.IsDeleted Is Nothing)
                Select ev.ID

        phEvaluatedToday.Visible = q.Any()
    End Sub

    ' ================= Secure Video =================
    Private Function BuildSecureVideoUrl(relativePath As String) As String
        If String.IsNullOrWhiteSpace(relativePath) Then Return String.Empty

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


