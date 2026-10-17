<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="JobTitles_Evaluation.aspx.vb" Inherits="CRM.JobTitles_Evaluation" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .eval-header-badges .badge {
            font-size: 0.85rem;
        }

        .job-accordion .accordion-item {
            border-radius: 0.5rem;
            overflow: hidden;
            border: none;
        }

        .job-accordion .accordion-button {
            background-color: #f8f9fa;
        }

        .job-accordion .accordion-button:not(.collapsed) {
            background-color: #e7f5ff;
        }

        .badge-evaluated-today {
            font-size: 0.8rem;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .eval-tag {
            display: inline-block;
            min-width: 80px;
            padding: 2px 12px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: 600;
            text-align: center;
            line-height: 20px;
            white-space: nowrap;
        }

        .eval-red {
            background: #fde6e6;
            color: #d84646;
        }

        .eval-yellow {
            background: #fff6d6;
            color: #b58c00;
        }

        .eval-green {
            background: #e3f5e7;
            color: #3b7f4c;
        }

        .eval-section-title {
            font-weight: 600;
            margin-bottom: 0.35rem;
        }

        .eval-help-text {
            font-size: 0.8rem;
        }

        .eval-notes-textarea {
            min-height: 80px;
        }

        .new-checklist-item {
            border-radius: .75rem;
            border: 1px solid #e5e7eb;
            padding: .75rem .75rem .5rem;
            background-color: #f9fafb;
        }

        .new-checklist-item .index-badge {
            width: 32px;
            height: 32px;
            border-radius: 999px;
            background-color: #eef2ff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: .9rem;
            color: #4f46e5;
        }

        .new-checklist-item .delete-btn {
            width: 32px;
            height: 32px;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .new-checklist-label {
            font-size: .8rem;
            margin-bottom: .15rem;
            color: #6b7280;
        }

        @media (min-width: 768px) {
            .new-checklist-item .form-control,
            .new-checklist-item .form-select {
                font-size: .85rem;
            }
        }

         /* ===== Loader عام للصفحة ===== */
        .page-loader-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(255, 255, 255, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }

        .page-loader-backdrop.d-none {
            display: none !important;
        }

        .page-loader-box {
            padding: 1.5rem 2rem;
            border-radius: .75rem;
            background: #ffffff;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .18);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: .75rem;
        }

        .page-loader-text {
            font-size: .9rem;
            color: #4b5563;
        }

        .page-loader.d-none {
            display: none !important;
        }

        /* نفس ستايل سياسات الفرع */
        .dept-policies-content {
            max-height: 420px;
            overflow-y: auto;
            font-size: .9rem;
            line-height: 1.7;
        }

        /* نفس ستايل الفيديو الآمن */
        .secure-video-wrapper {
            position: relative;
        }

        .secure-video-wrapper video {
            display: block;
            width: 100%;
            border-radius: .5rem;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl container-p-y">

        <div class="card shadow-sm border-0">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <div class="d-flex flex-column">
                    <h5 class="fw-bold mb-1">تقييم الموظفين حسب المحطة التعريفية</h5>
                    <small class="text-muted">
                        اختر المحطة التعريفية، ثم حدد عناصر التقييم ودوّن ملاحظاتك وارفق أي ملفات داعمة قبل الحفظ.
                    </small>
                </div>

                <div class="d-flex flex-wrap gap-2 eval-header-badges">
                    <span class="badge bg-label-primary d-flex align-items-center">
                        <i class="bx bx-store-alt ms-1"></i>
                        <span id="BranchNameText" runat="server">اسم الفرع</span>
                    </span>
                    <span class="badge bg-label-info d-flex align-items-center">
                        <i class="bx bx-grid-alt ms-1"></i>
                        <span id="DepartmentNameText" runat="server">اسم القسم</span>
                    </span>
                </div>
            </div>

            <div class="card-body">

                <div class="accordion job-accordion" id="JobTitlesAccordion">

                    <!-- 🔍 مربع البحث عن عناصر التقييم -->
                    <div class="row mb-3 align-items-end">
                        <div class="col-12 col-md-6">
                            <label class="form-label fw-semibold">البحث عن عنصر تقييم</label>
                            <asp:TextBox ID="txtSearchChecklist"
                                runat="server"
                                CssClass="form-control"
                                placeholder="اكتب جزء من اسم عنصر التقييم مثل: النظافة، المظهر العام..."></asp:TextBox>
                        </div>
                        <div class="col-12 col-md-6 mt-2 mt-md-0 d-flex gap-2 justify-content-md-start justify-content-center">
                            <asp:Button ID="btnSearchChecklist"
                                runat="server"
                                OnClientClick="showPageLoader();"
                                CssClass="btn btn-primary"
                                Text="بحث" />

                            <asp:Button ID="btnClearChecklist"
                                runat="server"
                                CssClass="btn btn-outline-secondary"
                                Text="إلغاء البحث"
                                OnClientClick="showPageLoader();"
                                CausesValidation="False"
                                UseSubmitBehavior="False" />
                        </div>
                    </div>

                    <asp:Repeater ID="rptJobTitles" runat="server">
                        <ItemTemplate>

                            <div class="accordion-item mb-3">
                                <h2 class="accordion-header" id='headingJob_<%# Eval("ID")%>'>
                                    <button class="accordion-button collapsed fw-semibold"
                                        type="button"
                                        style="background-color: cadetblue; color: white;"
                                        data-bs-toggle="collapse"
                                        data-bs-target='#collapseJob_<%# Eval("ID")%>'
                                        aria-expanded="false"
                                        aria-controls='collapseJob_<%# Eval("ID")%>'>

                                        <span class="me-1"><%# Eval("Title_Ar")%></span>

                                        <asp:PlaceHolder ID="phEvaluated" runat="server" Visible="false">
                                            <span class="badge bg-label-success badge-evaluated-today ms-2">
                                                <i class="bx bx-check-circle ms-1"></i>
                                                تم تقييمه اليوم
                                            </span>
                                        </asp:PlaceHolder>
                                    </button>
                                </h2>

                                <div id='collapseJob_<%# Eval("ID")%>' class="accordion-collapse collapse"
                                    aria-labelledby='headingJob_<%# Eval("ID")%>' data-bs-parent="#JobTitlesAccordion">
                                    <div class="accordion-body">

                                        <!-- نطاق التقييم (مخفي) -->
                                        <div class="mb-3" style="display: none">
                                            <label class="form-label fw-semibold">نطاق التقييم</label>
                                            <select class="form-select"
                                                name='scope_<%# Eval("ID")%>'
                                                onchange='toggleEmployees(<%# Eval("ID")%>)'>
                                                <option value="all" selected="selected">جميع موظفي هذا المحطة التعريفية</option>
                                                <option value="one">موظف محدد</option>
                                            </select>
                                            <small class="text-muted eval-help-text">
                                                يمكنك تقييم جميع الموظفين بهذا المسمى أو اختيار موظف واحد فقط.
                                            </small>
                                        </div>

                                        <div class="mb-3 d-none" id='employeeRow_<%# Eval("ID")%>'>
                                            <label class="form-label fw-semibold">اسم الموظف</label>
                                            <asp:DropDownList ID="ddlEmployees" runat="server"
                                                CssClass="form-select">
                                            </asp:DropDownList>
                                        </div>

                                        <br />

                                        <!-- عناصر التقييم -->
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between align-items-center mb-1 flex-wrap gap-2">

                                                <div class="d-flex align-items-center gap-2">
                                                    <label class="form-label fw-semibold mb-0">عناصر التقييم</label>
                                                </div>

                                                <div class="d-flex align-items-center gap-2">

                                                    <!-- 🔹 Dropdown معلومات إضافية (سياسات + فيديوهات) -->
                                                    <div class="dropdown">
                                                        <button class="btn btn-sm btn-outline-secondary"
                                                            type="button"
                                                            data-bs-toggle="dropdown"
                                                            aria-expanded="false">
                                                            <i class="bx bx-info-circle fs-5"></i>
                                                            <span class="d-none d-md-inline">معلومات إضافية</span>
                                                        </button>
                                                        <ul class="dropdown-menu dropdown-menu-end">

                                                            <li>
                                                                <asp:LinkButton ID="lnkShowPolicies"
                                                                    runat="server"
                                                                    CssClass="dropdown-item"
                                                                    CommandName="ShowJobPolicies"
                                                                    CommandArgument='<%# Eval("ID")%>'>
                                                                    سياسات المحطة التعريفية
                                                                </asp:LinkButton>
                                                            </li>

                                                            <li>
                                                                <asp:LinkButton ID="lnkShowWorking"
                                                                    runat="server"
                                                                    CssClass="dropdown-item"
                                                                    CommandName="ShowJobWorking"
                                                                    CommandArgument='<%# Eval("ID")%>'>
                                                                    طريقة العمل
                                                                </asp:LinkButton>
                                                            </li>

                                                            <li>
                                                                <asp:LinkButton ID="lnkShowEvaluation"
                                                                    runat="server"
                                                                    CssClass="dropdown-item"
                                                                    CommandName="ShowJobEvaluation"
                                                                    CommandArgument='<%# Eval("ID")%>'>
                                                                    طريقة التقييم
                                                                </asp:LinkButton>
                                                            </li>

                                                        </ul>
                                                    </div>

                                                    <!-- 🔹 زر إضافة عنصر تقييم جديد -->
                                                    <button type="button"
                                                        class="btn btn-outline-primary btn-sm d-flex align-items-center"
                                                        onclick="onAddChecklistClicked(<%# Eval("ID")%>)">
                                                        <i class="bx bx-plus-circle ms-1"></i>
                                                        <span class="d-none d-md-inline">إضافة عنصر تقييم جديد</span>
                                                    </button>

                                                </div>
                                            </div>

                                            <p class="text-muted small mb-2">
                                                يمكن اختيار عنصر تقييم واحد أو أكثر. استخدم سياسات المحطة التعريفية لمعرفة طريقة العمل والتقييم.
                                            </p>

                                            <asp:Panel ID="pnlNoChecklist" runat="server" Visible="false"
                                                CssClass="alert alert-warning small mb-0">
                                                لا يوجد عناصر للتقييم لهذا المحطة التعريفية في هذا الشفت.
                                            </asp:Panel>

                                            <asp:Panel ID="pnlChecklistWrapper" runat="server">
                                                <div class="list-group list-group-flush rounded mt-2">
                                                    <asp:Repeater ID="rptChecklist" runat="server">
                                                        <ItemTemplate>
                                                            <label class="list-group-item d-flex justify-content-between align-items-center">

                                                                <div class="d-flex align-items-center gap-2">
                                                                    <input class="form-check-input mt-0"
                                                                        type="checkbox"
                                                                        name='chk_<%# Eval("ID")%>' />

                                                                    <span class="fw-semibold">
                                                                        <%# Eval("Title_Ar")%>
                                                                    </span>

                                                                    <button type="button"
                                                                        class="btn btn-sm btn-text-secondary p-0 ms-1"
                                                                        onclick="showInfo('<%# JsString(Eval("Title_Ar"))%>',
                                                                                          '<%# JsString(Eval("Brief_Ar"))%>')">
                                                                        <i class="bx bx-info-circle fs-5"></i>
                                                                    </button>
                                                                </div>

                                                                <span class='<%# GetChecklistCss(Eval("CheckList_CategoryID"))%>'>
                                                                    <%# Eval("CategoryTitle_Ar")%>
                                                                </span>

                                                            </label>
                                                        </ItemTemplate>
                                                    </asp:Repeater>
                                                </div>
                                            </asp:Panel>
                                        </div>

                                        <!-- Modal إضافة عناصر جديدة -->
                                        <div class="modal fade" id='newChecklistModal_<%# Eval("ID")%>' tabindex="-1" aria-hidden="true">
                                            <div class="modal-dialog modal-lg modal-dialog-centered">
                                                <div class="modal-content">

                                                    <div class="modal-header">
                                                        <h5 class="modal-title fw-bold">
                                                            إضافة عناصر تقييم جديدة - <%# Eval("Title_Ar")%>
                                                        </h5>
                                                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                                                    </div>

                                                    <div class="modal-body">
                                                        <p class="text-muted small mb-2">
                                                            يمكن إضافة تقييم أو أكثر للمهمة.
                                                        </p>

                                                        <div id='newChecklistBody_<%# Eval("ID")%>' class="d-flex flex-column gap-2">
                                                        </div>

                                                        <div class="d-flex justify-content-between align-items-center mt-3">
                                                            <button type="button"
                                                                class="btn btn-outline-secondary btn-sm"
                                                                onclick="addNewChecklistRow(<%# Eval("ID")%>)">
                                                                <i class="bx bx-plus ms-1"></i>
                                                                إضافة صف جديد
                                                            </button>

                                                            <asp:LinkButton ID="btnSaveChecklist"
                                                                runat="server"
                                                                CssClass="btn btn-outline-success btn-sm"
                                                                CommandName="SaveChecklist"
                                                                CommandArgument='<%# Eval("ID")%>'
                                                                OnClientClick='<%# "return onSaveChecklistClick(" & Eval("ID") & ");"%>'>
                                                                <i class="bx bx-save ms-1"></i>
                                                                حفظ عناصر التقييم
                                                            </asp:LinkButton>
                                                        </div>
                                                    </div>

                                                    <div class="modal-footer">
                                                        <button type="button"
                                                            class="btn btn-secondary"
                                                            data-bs-dismiss="modal">
                                                            إغلاق
                                                        </button>
                                                    </div>

                                                </div>
                                            </div>
                                        </div>

                                        <div class="mb-3">
                                            <label class="form-label fw-semibold" for="txtNotes">ملاحظات عامة</label>
                                            <asp:TextBox ID="txtNotes" runat="server" Style="font-size: 13px;"
                                                CssClass="form-control eval-notes-textarea"
                                                TextMode="MultiLine"
                                                placeholder="أدخل الملاحظات العامة على أداء الموظفين ضمن هذا المحطة التعريفية..."></asp:TextBox>
                                        </div>

                                        <div class="mb-3" style="display: none">
                                            <label class="form-label fw-semibold" for="txtEvaluationDate">تاريخ التقييم</label>
                                            <asp:TextBox ID="txtEvaluationDate" runat="server"
                                                CssClass="form-control"
                                                placeholder="MM/DD/YYYY"></asp:TextBox>
                                        </div>

                                        <div class="mb-3">
                                            <label class="form-label fw-semibold">مرفقات (صور / مستندات)</label>
                                            <div>
                                                <ajaxToolkit:AjaxFileUpload ID="TaskFiles"
                                                    runat="server"
                                                    AllowedFileTypes="jpeg,jpg,png,pdf,doc,docx,xls,xlsx"
                                                    MaximumNumberOfFiles="5"
                                                    MaxFileSize="204800"
                                                    OnUploadComplete="TaskFiles_UploadComplete"
                                                    OnUploadStart="TaskFiles_UploadStart" />
                                                <small class="text-muted d-block mt-1">
                                                    يمكنك إرفاق صور، ملفات PDF أو مستندات مرتبطة بالملاحظة (حتى 5 ملفات).
                                                </small>
                                            </div>
                                        </div>

                                        <div class="text-end">
                                            <div class="d-flex justify-content-between align-items-center mt-3">
                                                <span id='evalErr_<%# Eval("ID")%>' class="text-danger small" style="text-align: right"></span>

                                                <asp:LinkButton ID="btnSaveEval"
                                                    runat="server"
                                                    CssClass="btn btn-primary"
                                                    CommandName="SaveEvaluation"
                                                    CommandArgument='<%# Eval("ID")%>'
                                                    OnClientClick='<%# "return onSaveEvalClick(" & Eval("ID") & ");"%>'>
                                                    <i class="bx bx-check-circle ms-1"></i>
                                                    إضافة التقييم
                                                </asp:LinkButton>
                                            </div>
                                        </div>

                                    </div>
                                </div>
                            </div>

                        </ItemTemplate>
                    </asp:Repeater>

                </div>

            </div>
        </div>

        <!-- Modal تفاصيل عنصر التقييم -->
        <div class="modal fade" id="InfoModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">

                    <div class="modal-header">
                        <h5 class="modal-title fw-bold" id="InfoTitle">تفاصيل عنصر التقييم</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                    </div>

                    <div class="modal-body" id="InfoBody">
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إغلاق</button>
                    </div>

                </div>
            </div>
        </div>

        <!-- Job Title Policies Modal -->
        <div class="modal fade" id="jobPoliciesModal" tabindex="-1"
             aria-labelledby="jobPoliciesModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 id="jobPoliciesModalLabel" class="modal-title">سياسات المحطة التعريفية</h5>
                         <asp:Button ID="Button1" runat="server" 
                            CssClass="btn-close" OnClick="btnClosePopup_Click"
                            OnClientClick="showPageLoader();" />
                    </div>
                    <div class="modal-body">
                        <div class="dept-policies-content">
                            <asp:Literal ID="litJobPolicies" runat="server" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Video Modal (طريقة العمل / طريقة التقييم للمسمى الوظيفي) -->
        <div class="modal fade" id="jobVideoModal" tabindex="-1"
             aria-labelledby="jobVideoModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 id="jobVideoModalLabel" class="modal-title">فيديو توضيحي</h5>
                         <asp:Button ID="Button2" runat="server" 
                            CssClass="btn-close" OnClick="btnClosePopup_Click"
                            OnClientClick="showPageLoader();" />
                    </div>
                    <div class="modal-body">
                        <div class="secure-video-wrapper" oncontextmenu="return false;">
                            <video id="jobTrainingVideo"
                                   controls
                                   controlsList="nodownload noplaybackrate"
                                   preload="metadata">
                                <source id="jobTrainingSource" src="" type="video/mp4" />
                                المتصفح لا يدعم تشغيل الفيديو.
                            </video>
                        </div>
                        <small class="d-block mt-2 text-center text-muted">
                            هذا الفيديو مخصص للاستخدام الداخلي لموظفي بروستو فقط.
                        </small>
                    </div>
                </div>
            </div>
        </div>

        <!-- Popup النجاح -->
        <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="text-center m-4">
                        <img src="/assets/img/Prosto/Success_Icon.png" alt="تم بنجاح" />
                    </div>
                    <div class="modal-body">
                        <h2 class="text-center">
                            <asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal>
                        </h2>
                        <div class="swal2-html-container" id="swal2-html-container" style="display: block;">
                            تمت إضافة التقييم بنجاح.
                        </div>
                    </div>
                    <div class="text-center m-4">
                        <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق"
                            CssClass="btn btn-primary" OnClick="btnClosePopup_Click"
                            OnClientClick="showPageLoader();" />
                    </div>
                </div>
            </div>
        </asp:Panel>

        <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender"
            PopupControlID="PanelPopUp"
            BackgroundCssClass="OpacityBG"
            runat="server"
            TargetControlID="LBLPOP">
        </cc11:ModalPopupExtender>
        <asp:Label ID="LBLPOP" runat="server" />

    </div>

  <!-- Loader عام للصفحة -->
    <div id="pageLoader" class="page-loader-backdrop d-none">
        <div class="page-loader-box text-center">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">جاري التحميل...</span>
            </div>
            <div class="page-loader-text">
                جاري معالجة طلبك، الرجاء الانتظار...
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function toggleEmployees(jobId) {
            var row = document.getElementById('employeeRow_' + jobId);
            if (!row) return;

            var selectName = 'scope_' + jobId;
            var selects = document.getElementsByName(selectName);
            if (!selects || selects.length === 0) return;

            var val = selects[0].value;
            if (val === 'one') {
                row.classList.remove('d-none');
            } else {
                row.classList.add('d-none');
            }
        }

        function showInfo(title, body) {
            var t = document.getElementById('InfoTitle');
            var b = document.getElementById('InfoBody');
            if (!t || !b) return;

            t.textContent = title || '';
            b.textContent = body || '';

            var modalEl = document.getElementById('InfoModal');
            if (!modalEl) return;

            if (window.bootstrap && bootstrap.Modal) {
                var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
                modal.show();
            } else if (window.$) {
                $(modalEl).modal('show');
            } else {
                modalEl.classList.add('show');
                modalEl.style.display = 'block';
            }
        }

        function validateEvaluation(jobId) {
            var acc = document.getElementById('collapseJob_' + jobId);
            if (!acc) return true;

            var errSpan = document.getElementById('evalErr_' + jobId);
            if (errSpan) errSpan.textContent = '';

            var checks = acc.querySelectorAll('input[type="checkbox"][name^="chk_"]');
            var hasChecked = false;
            checks.forEach(function (c) {
                if (c.checked) hasChecked = true;
            });

            var notesBox = acc.querySelector('textarea[id*="txtNotes"]');
            var notesVal = notesBox ? notesBox.value.trim() : "";

            if (!hasChecked && notesVal === "") {
                if (errSpan) {
                    errSpan.textContent = 'اختيار عنصر تقييم واحد على الأقل أو إدخال ملاحظات إجباري قبل الحفظ.';
                } else {
                    alert('اختيار عنصر تقييم واحد على الأقل أو إدخال ملاحظات إجباري قبل الحفظ.');
                }
                return false;
            }

            return true;
        }

        function onAddChecklistClicked(jobId) {
            var modalEl = document.getElementById('newChecklistModal_' + jobId);
            if (!modalEl) return;

            var container = document.getElementById('newChecklistBody_' + jobId);
            if (container && container.children.length === 0) {
                addNewChecklistRow(jobId);
            }

            if (window.bootstrap && bootstrap.Modal) {
                var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
                modal.show();
            } else if (window.$) {
                $(modalEl).modal('show');
            } else {
                modalEl.classList.add('show');
                modalEl.style.display = 'block';
            }
        }

        function addNewChecklistRow(jobId) {
            var container = document.getElementById('newChecklistBody_' + jobId);
            if (!container) return;

            var index = container.children.length + 1;

            var row = document.createElement('div');
            row.className = 'new-checklist-item d-flex flex-column gap-2';

            row.innerHTML =
                '<div class="d-flex justify-content-between align-items-center">' +
                '  <div class="index-badge">' + index + '</div>' +
                '  <button type="button" class="btn btn-outline-danger btn-sm delete-btn" onclick="removeNewChecklistRow(this,' + jobId + ')">' +
                '    <i class="bx bx-trash"></i>' +
                '  </button>' +
                '</div>' +
                '<div class="row g-2 mt-1">' +
                '  <div class="col-12 col-md-4">' +
                '    <div class="new-checklist-label">عنوان التقييم (بالعربية)</div>' +
                '    <input type="text" class="form-control" name="newTitleAr_' + jobId + '[]">' +
                '  </div>' +
                '  <div class="col-12 col-md-4">' +
                '    <div class="new-checklist-label">الوصف (بالعربية)</div>' +
                '    <input type="text" class="form-control" name="newTitleEn_' + jobId + '[]">' +
                '  </div>' +
                '  <div class="col-6 col-md-2">' +
                '    <div class="new-checklist-label">الوزن</div>' +
                '    <input type="number" class="form-control" min="0" step="0.01" value="0" name="newWeight_' + jobId + '[]">' +
                '  </div>' +
                '  <div class="col-6 col-md-2">' +
                '    <div class="new-checklist-label">التصنيف</div>' +
                '    <select class="form-select" name="newCategory_' + jobId + '[]">' +
                '      <option value="1">مهام خطيرة</option>' +
                '      <option value="2">مهام متوسطة</option>' +
                '      <option value="3" selected>مهام عادية</option>' +
                '    </select>' +
                '  </div>' +
                '</div>';

            container.appendChild(row);
            reIndexNewChecklistRows(container);
        }

        function removeNewChecklistRow(btn, jobId) {
            var row = btn.closest('.new-checklist-item');
            var container = document.getElementById('newChecklistBody_' + jobId);
            if (row && container) {
                container.removeChild(row);
                reIndexNewChecklistRows(container);
            }
        }

        function reIndexNewChecklistRows(container) {
            var rows = container.querySelectorAll('.new-checklist-item');
            rows.forEach(function (r, idx) {
                var badge = r.querySelector('.index-badge');
                if (badge) badge.textContent = (idx + 1);
            });
        }

        function showPageLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.remove('d-none');
        }

        function onSaveChecklistClick(jobId) {
            var errSpan = document.getElementById('evalErr_' + jobId);
            if (errSpan) errSpan.textContent = '';

            var container = document.getElementById('newChecklistBody_' + jobId);
            if (!container) {
                return false;
            }

            var inputs = container.querySelectorAll('input[name="newTitleAr_' + jobId + '[]"]');
            var hasAny = false;
            inputs.forEach(function (inp) {
                if (inp.value.trim() !== '') hasAny = true;
            });

            if (!hasAny) {
                if (errSpan) {
                    errSpan.textContent = 'يجب إضافة عنصر تقييم واحد على الأقل قبل الحفظ.';
                } else {
                    alert('يجب إضافة عنصر تقييم واحد على الأقل قبل الحفظ.');
                }
                return false;
            }

            showPageLoader();
            return true;
        }

        function onSaveEvalClick(jobId) {
            if (!validateEvaluation(jobId)) {
                return false;
            }
            showPageLoader();
            return true;
        }

        // ===== نفس منطق صفحة تقييم الفرع للفيديو =====
        document.addEventListener('DOMContentLoaded', function () {
            var videoModal = document.getElementById('jobVideoModal');
            if (videoModal) {
                videoModal.addEventListener('hidden.bs.modal', function () {
                    var video = document.getElementById('jobTrainingVideo');
                    if (video) {
                        video.pause();
                        video.currentTime = 0;
                    }
                });
            }
        });

        function showJobPoliciesModal() {
            var modalEl = document.getElementById('jobPoliciesModal');
            if (!modalEl) return;

            if (window.bootstrap && bootstrap.Modal) {
                var m = bootstrap.Modal.getOrCreateInstance(modalEl);
                m.show();
            } else if (window.$) {
                $(modalEl).modal('show');
            } else {
                modalEl.classList.add('show');
                modalEl.style.display = 'block';
            }
        }

        function openJobVideoModal(title, url) {
            var modalEl = document.getElementById('jobVideoModal');
            if (!modalEl) return;

            var titleEl = document.getElementById('jobVideoModalLabel');
            if (titleEl) titleEl.textContent = title;

            var video = document.getElementById('jobTrainingVideo');
            var source = document.getElementById('jobTrainingSource');

            if (video && source) {
                video.pause();
                source.src = url;
                video.load();
            }

            if (window.bootstrap && bootstrap.Modal) {
                var m = bootstrap.Modal.getOrCreateInstance(modalEl);
                m.show();
            } else if (window.$) {
                $(modalEl).modal('show');
            } else {
                modalEl.classList.add('show');
                modalEl.style.display = 'block';
            }
        }

        function openJobWorkingVideo(url) {
            if (!url) {
                alert('لم يتم تعريف فيديو طريقة العمل لهذا المحطة التعريفية.');
                return;
            }
            openJobVideoModal('طريقة العمل', url);
        }

        function openJobEvaluationVideo(url) {
            if (!url) {
                alert('لم يتم تعريف فيديو طريقة التقييم لهذا المحطة التعريفية.');
                return;
            }
            openJobVideoModal('طريقة التقييم', url);
        }
    </script>

</asp:Content>
