<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Tools_Evaluation.aspx.vb" Inherits="CRM.Tools_Evaluation" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .eval-header-badges .badge { font-size: 0.85rem; }

        .job-accordion .accordion-item {
            border-radius: 0.5rem;
            overflow: hidden;
            border: none;
        }

        .job-accordion .accordion-button { background-color: #f8f9fa; }
        .job-accordion .accordion-button:not(.collapsed) { background-color: #e7f5ff; }

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

        .eval-red { background: #fde6e6; color: #d84646; }
        .eval-yellow { background: #fff6d6; color: #b58c00; }
        .eval-green { background: #e3f5e7; color: #3b7f4c; }

        .eval-notes-textarea { min-height: 80px; }

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
        .new-checklist-label { font-size: .8rem; margin-bottom: .15rem; color: #6b7280; }

        /* ===== Loader ===== */
        .page-loader-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(255, 255, 255, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }
        .page-loader-backdrop.d-none { display: none !important; }

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

        .page-loader-text { font-size: .9rem; color: #4b5563; }

        /* محتوى السياسات */
        .dept-policies-content {
            max-height: 420px;
            overflow-y: auto;
            font-size: .9rem;
            line-height: 1.7;
        }

        /* فيديو */
        .secure-video-wrapper { position: relative; }
        .secure-video-wrapper video {
            display: block;
            width: 100%;
            border-radius: .5rem;
        }

        /* === ModalPopupExtender backdrop === */
        .OpacityBG {
            background-color: rgba(0,0,0,.55);
            position: fixed;
            inset: 0;
            z-index: 9998;
        }

        .prosto-modal {
            position: fixed;
            inset: 0;
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 12px;
        }

        .prosto-modal-card {
            width: min(920px, 96vw);
            max-height: 92vh;
            overflow: hidden;
            border-radius: 14px;
            background: #fff;
            box-shadow: 0 20px 60px rgba(0,0,0,.35);
        }

        .prosto-modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 12px 16px;
            border-bottom: 1px solid #e5e7eb;
            background: #f8fafc;
        }

        .prosto-modal-title {
            font-weight: 800;
            margin: 0;
            font-size: 1rem;
            color: #0f172a;
        }

        .prosto-modal-close {
            border: none;
            background: transparent;
            width: 36px;
            height: 36px;
            border-radius: 10px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .prosto-modal-close:hover { background: rgba(0,0,0,.06); }

        .prosto-modal-body {
            padding: 16px;
            max-height: calc(92vh - 120px);
            overflow: auto;
        }

        .prosto-modal-footer {
            padding: 12px 16px;
            border-top: 1px solid #e5e7eb;
            display: flex;
            justify-content: flex-end;
            gap: 8px;
            background: #fff;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl container-p-y">

        <div class="card shadow-sm border-0">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <div class="d-flex flex-column">
                    <h5 class="fw-bold mb-1">تقييم الأداة</h5>
                    <small class="text-muted">
                        <asp:Literal ID="litToolTitle" runat="server" />
                    </small>
                </div>

                <div class="d-flex flex-wrap gap-2 eval-header-badges">

                    <!-- ✅ Brand -->
                    <span class="badge bg-label-danger d-flex align-items-center">
                        <i class="bx bx-buildings ms-1"></i>
                        <span id="BrandNameText" runat="server">اسم العلامة</span>
                    </span>

                    <span class="badge bg-label-primary d-flex align-items-center">
                        <i class="bx bx-store-alt ms-1"></i>
                        <span id="BranchNameText" runat="server">اسم الفرع</span>
                    </span>

                    <span class="badge bg-label-info d-flex align-items-center">
                        <i class="bx bx-grid-alt ms-1"></i>
                        <span id="DepartmentNameText" runat="server">اسم القسم</span>
                    </span>

                    <span class="badge bg-label-warning d-flex align-items-center">
                        <i class="bx bx-briefcase-alt-2 ms-1"></i>
                        <span id="JobTitleNameText" runat="server">المحطة التعريفية</span>
                    </span>
                </div>
            </div>

            <div class="card-body">

                <div class="accordion job-accordion" id="ToolsAccordion">

                    <!-- 🔍 البحث عن عناصر تقييم الأداة -->
                    <div class="row mb-3 align-items-end">
                        <div class="col-12 col-md-6">
                            <label class="form-label fw-semibold">البحث عن عنصر تقييم</label>
                            <asp:TextBox ID="txtSearchChecklist" runat="server"
                                CssClass="form-control"
                                placeholder="اكتب جزء من اسم عنصر التقييم..."></asp:TextBox>
                        </div>

                        <div class="col-12 col-md-6 mt-2 mt-md-0 d-flex gap-2 justify-content-md-start justify-content-center">
                            <asp:Button ID="btnSearchChecklist" runat="server"
                                OnClientClick="showPageLoader();"
                                CssClass="btn btn-primary" Text="بحث" />

                            <asp:Button ID="btnClearChecklist" runat="server"
                                CssClass="btn btn-outline-secondary" Text="إلغاء البحث"
                                OnClientClick="showPageLoader();"
                                CausesValidation="False" UseSubmitBehavior="False" />
                        </div>
                    </div>

                    <!-- Accordion item واحد (أداة واحدة) -->
                    <div class="accordion-item mb-3">
                        <h2 class="accordion-header" id="headingTool">
                            <button id="btnToolAccordion" runat="server"
                                class="accordion-button collapsed fw-semibold"
                                type="button"
                                style="background-color: cadetblue; color: white;"
                                data-bs-toggle="collapse"
                                data-bs-target="#collapseTool"
                                aria-expanded="false"
                                aria-controls="collapseTool">

                                <asp:Literal ID="litToolHeaderTitle" runat="server" />

                                <asp:PlaceHolder ID="phEvaluatedToday" runat="server" Visible="false">
                                    <span class="badge bg-label-success badge-evaluated-today ms-2">
                                        <i class="bx bx-check-circle ms-1"></i>
                                        تم تقييمها اليوم
                                    </span>
                                </asp:PlaceHolder>

                            </button>
                        </h2>

                        <!-- ✅ فتح تلقائي: class يتم ضبطها من السيرفر -->
                        <div id="collapseTool" runat="server"
                            class="accordion-collapse collapse"
                            aria-labelledby="headingTool" data-bs-parent="#ToolsAccordion">
                            <div class="accordion-body">

                                <!-- عناصر التقييم -->
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1 flex-wrap gap-2 mt-3">

                                        <div class="d-flex align-items-center gap-2">
                                            <label class="form-label fw-semibold mb-0">عناصر تقييم الأداة</label>
                                        </div>

                                        <div class="d-flex align-items-center gap-2">

                                            <!-- معلومات إضافية -->
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
                                                        <asp:LinkButton ID="lnkShowPolicies" runat="server"
                                                            CssClass="dropdown-item"
                                                            OnClick="lnkShowPolicies_Click"
                                                            CausesValidation="false">
                                                            سياسات الأداة
                                                        </asp:LinkButton>
                                                    </li>

                                                    <li>
                                                        <asp:LinkButton ID="lnkShowWorking" runat="server"
                                                            CssClass="dropdown-item"
                                                            OnClick="lnkShowWorking_Click"
                                                            CausesValidation="false">
                                                            طريقة العمل
                                                        </asp:LinkButton>
                                                    </li>

                                                    <li>
                                                        <asp:LinkButton ID="lnkShowEvaluation" runat="server"
                                                            CssClass="dropdown-item"
                                                            OnClick="lnkShowEvaluation_Click"
                                                            CausesValidation="false">
                                                            طريقة التقييم
                                                        </asp:LinkButton>
                                                    </li>
                                                </ul>
                                            </div>

                                            <!-- زر إضافة عنصر تقييم جديد -->
                                            <button type="button"
                                                class="btn btn-outline-primary btn-sm d-flex align-items-center"
                                                onclick="onAddChecklistClicked()">
                                                <i class="bx bx-plus-circle ms-1"></i>
                                                <span class="d-none d-md-inline">إضافة عنصر تقييم جديد</span>
                                            </button>

                                        </div>
                                    </div>

                                    <p class="text-muted small mb-2">
                                        سيتم عرض عناصر التقييم الخاصة بهذه الأداة.
                                    </p>

                                    <asp:Panel ID="pnlNoChecklist" runat="server" Visible="false"
                                        CssClass="alert alert-warning small mb-0">
                                        لا يوجد عناصر تقييم لهذه الأداة حالياً.
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

                                                            <span class="fw-semibold"><%# Eval("Title_Ar")%></span>

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

                                <!-- Modal إضافة عناصر جديدة (Bootstrap عادي) -->
                                <div class="modal fade" id="newChecklistModal" tabindex="-1" aria-hidden="true">
                                    <div class="modal-dialog modal-lg modal-dialog-centered">
                                        <div class="modal-content">

                                            <div class="modal-header">
                                                <h5 class="modal-title fw-bold">إضافة عناصر تقييم جديدة</h5>
                                                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                                            </div>

                                            <div class="modal-body">
                                                <p class="text-muted small mb-2">يمكن إضافة تقييم أو أكثر للأداة.</p>

                                                <div id="newChecklistBody" class="d-flex flex-column gap-2"></div>

                                                <div class="d-flex justify-content-between align-items-center mt-3">
                                                    <button type="button"
                                                        class="btn btn-outline-secondary btn-sm"
                                                        onclick="addNewChecklistRow()">
                                                        <i class="bx bx-plus ms-1"></i>
                                                        إضافة صف جديد
                                                    </button>

                                                    <asp:LinkButton ID="btnSaveChecklist" runat="server"
                                                        CssClass="btn btn-outline-success btn-sm"
                                                        OnClick="btnSaveChecklist_Click"
                                                        OnClientClick="return onSaveChecklistClick();">
                                                        <i class="bx bx-save ms-1"></i>
                                                        حفظ عناصر التقييم
                                                    </asp:LinkButton>
                                                </div>
                                            </div>

                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إغلاق</button>
                                            </div>

                                        </div>
                                    </div>
                                </div>

                                <!-- ملاحظات -->
                                <div class="mb-3">
                                    <label class="form-label fw-semibold" for="txtNotes">ملاحظات عامة</label>
                                    <asp:TextBox ID="txtNotes" runat="server" Style="font-size: 13px;"
                                        CssClass="form-control eval-notes-textarea"
                                        TextMode="MultiLine"
                                        placeholder="أدخل الملاحظات العامة على الأداة..."></asp:TextBox>
                                </div>

                                <!-- مرفقات -->
                                <div class="mb-3">
                                    <label class="form-label fw-semibold">مرفقات (صور / مستندات)</label>
                                    <div>
                                        <ajaxToolkit:AjaxFileUpload ID="TaskFiles" runat="server"
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

                                <!-- حفظ التقييم -->
                                <div class="text-end">
                                    <div class="d-flex justify-content-between align-items-center mt-3">
                                        <span id="evalErr" class="text-danger small" style="text-align: right"></span>

                                        <asp:LinkButton ID="btnSaveEval" runat="server"
                                            CssClass="btn btn-primary"
                                            OnClick="btnSaveEval_Click"
                                            OnClientClick="return onSaveEvalClick();">
                                            <i class="bx bx-check-circle ms-1"></i>
                                            إضافة التقييم
                                        </asp:LinkButton>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>

                </div>

            </div>
        </div>

        <!-- Info Modal (Bootstrap) -->
        <div class="modal fade" id="InfoModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">

                    <div class="modal-header">
                        <h5 class="modal-title fw-bold" id="InfoTitle">تفاصيل عنصر التقييم</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                    </div>

                    <div class="modal-body" id="InfoBody"></div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إغلاق</button>
                    </div>

                </div>
            </div>
        </div>

        <!-- =========================
             ✅ Popups بديلة (Ajax ModalPopupExtender)
             ========================= -->

        <!-- سياسات الأداة -->
        <asp:Panel ID="pnlToolPolicies" runat="server" Style="display:none;">
            <div class="prosto-modal">
                <div class="prosto-modal-card">
                    <div class="prosto-modal-header">
                        <h5 class="prosto-modal-title">سياسات الأداة</h5>
                        <asp:LinkButton ID="btnClosePoliciesX" runat="server" CssClass="prosto-modal-close" CausesValidation="false"
                            OnClick="btnClosePolicies_Click" ToolTip="إغلاق">
                            <i class="bx bx-x fs-3"></i>
                        </asp:LinkButton>
                    </div>
                    <div class="prosto-modal-body">
                        <div class="dept-policies-content">
                            <asp:Literal ID="litToolPolicies" runat="server" />
                        </div>
                    </div>
                    <div class="prosto-modal-footer">
                        <asp:Button ID="btnClosePolicies" runat="server" Text="إغلاق" CssClass="btn btn-secondary"
                            CausesValidation="false" OnClick="btnClosePolicies_Click" />
                    </div>
                </div>
            </div>
        </asp:Panel>

        <cc11:ModalPopupExtender ID="mpeToolPolicies" runat="server"
            TargetControlID="lnkDummyPolicies"
            PopupControlID="pnlToolPolicies"
            BackgroundCssClass="OpacityBG" />
        <asp:LinkButton ID="lnkDummyPolicies" runat="server" Style="display:none;" CausesValidation="false"></asp:LinkButton>

        <!-- فيديو (طريقة العمل / طريقة التقييم) -->
        <asp:Panel ID="pnlToolVideo" runat="server" Style="display:none;">
            <div class="prosto-modal">
                <div class="prosto-modal-card">
                    <div class="prosto-modal-header">
                        <h5 class="prosto-modal-title">
                            <asp:Literal ID="litVideoTitle" runat="server" />
                        </h5>
                        <asp:LinkButton ID="btnCloseVideoX" runat="server" CssClass="prosto-modal-close" CausesValidation="false"
                            OnClick="btnCloseVideo_Click" ToolTip="إغلاق">
                            <i class="bx bx-x fs-3"></i>
                        </asp:LinkButton>
                    </div>

                    <div class="prosto-modal-body">
                        <div class="secure-video-wrapper" oncontextmenu="return false;">
                            <video id="toolTrainingVideo" controls controlsList="nodownload noplaybackrate" preload="metadata" style="width:100%;">
                                <source id="toolTrainingSource" src="" type="video/mp4" />
                                المتصفح لا يدعم تشغيل الفيديو.
                            </video>
                        </div>

                        <asp:HiddenField ID="hfVideoUrl" runat="server" />

                        <small class="d-block mt-2 text-center text-muted">
                            هذا الفيديو مخصص للاستخدام الداخلي لموظفي بروستو فقط.
                        </small>
                    </div>

                    <div class="prosto-modal-footer">
                        <asp:Button ID="btnCloseVideo" runat="server" Text="إغلاق" CssClass="btn btn-secondary"
                            CausesValidation="false" OnClick="btnCloseVideo_Click" />
                    </div>
                </div>
            </div>
        </asp:Panel>

        <cc11:ModalPopupExtender ID="mpeToolVideo" runat="server"
            TargetControlID="lnkDummyVideo"
            PopupControlID="pnlToolVideo"
            BackgroundCssClass="OpacityBG" />
        <asp:LinkButton ID="lnkDummyVideo" runat="server" Style="display:none;" CausesValidation="false"></asp:LinkButton>

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

    <!-- Loader -->
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
        function showPageLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.remove('d-none');
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
                bootstrap.Modal.getOrCreateInstance(modalEl).show();
            } else if (window.$) {
                $(modalEl).modal('show');
            }
        }

        function validateEvaluation() {
            var errSpan = document.getElementById('evalErr');
            if (errSpan) errSpan.textContent = '';

            var acc = document.getElementById('collapseTool');
            if (!acc) return true;

            var checks = acc.querySelectorAll('input[type="checkbox"][name^="chk_"]');
            var hasChecked = false;
            checks.forEach(function (c) { if (c.checked) hasChecked = true; });

            var notesBox = document.querySelector('textarea[id*="txtNotes"]');
            var notesVal = notesBox ? notesBox.value.trim() : "";

            if (!hasChecked && notesVal === "") {
                if (errSpan) errSpan.textContent = 'اختيار عنصر تقييم واحد على الأقل أو إدخال ملاحظات إجباري قبل الحفظ.';
                else alert('اختيار عنصر تقييم واحد على الأقل أو إدخال ملاحظات إجباري قبل الحفظ.');
                return false;
            }
            return true;
        }

        function onAddChecklistClicked() {
            var modalEl = document.getElementById('newChecklistModal');
            if (!modalEl) return;

            var container = document.getElementById('newChecklistBody');
            if (container && container.children.length === 0) addNewChecklistRow();

            if (window.bootstrap && bootstrap.Modal) {
                bootstrap.Modal.getOrCreateInstance(modalEl).show();
            } else if (window.$) {
                $(modalEl).modal('show');
            }
        }

        function addNewChecklistRow() {
            var container = document.getElementById('newChecklistBody');
            if (!container) return;

            var index = container.children.length + 1;

            var row = document.createElement('div');
            row.className = 'new-checklist-item d-flex flex-column gap-2';

            row.innerHTML =
                '<div class="d-flex justify-content-between align-items-center">' +
                '  <div class="index-badge">' + index + '</div>' +
                '  <button type="button" class="btn btn-outline-danger btn-sm delete-btn" onclick="removeNewChecklistRow(this)">' +
                '    <i class="bx bx-trash"></i>' +
                '  </button>' +
                '</div>' +
                '<div class="row g-2 mt-1">' +
                '  <div class="col-12 col-md-4">' +
                '    <div class="new-checklist-label">عنوان التقييم (بالعربية)</div>' +
                '    <input type="text" class="form-control" name="newTitleAr[]">' +
                '  </div>' +
                '  <div class="col-12 col-md-4">' +
                '    <div class="new-checklist-label">الوصف (بالعربية)</div>' +
                '    <input type="text" class="form-control" name="newTitleEn[]">' +
                '  </div>' +
                '  <div class="col-6 col-md-2">' +
                '    <div class="new-checklist-label">الوزن</div>' +
                '    <input type="number" class="form-control" min="0" step="0.01" value="0" name="newWeight[]">' +
                '  </div>' +
                '  <div class="col-6 col-md-2">' +
                '    <div class="new-checklist-label">التصنيف</div>' +
                '    <select class="form-select" name="newCategory[]">' +
                '      <option value="1">مهام خطيرة</option>' +
                '      <option value="2">مهام متوسطة</option>' +
                '      <option value="3" selected>مهام عادية</option>' +
                '    </select>' +
                '  </div>' +
                '</div>';

            container.appendChild(row);
            reIndexNewChecklistRows(container);
        }

        function removeNewChecklistRow(btn) {
            var row = btn.closest('.new-checklist-item');
            var container = document.getElementById('newChecklistBody');
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

        function onSaveChecklistClick() {
            var container = document.getElementById('newChecklistBody');
            if (!container) return false;

            var inputs = container.querySelectorAll('input[name="newTitleAr[]"]');
            var hasAny = false;
            inputs.forEach(function (inp) { if (inp.value.trim() !== '') hasAny = true; });

            if (!hasAny) {
                var errSpan = document.getElementById('evalErr');
                if (errSpan) errSpan.textContent = 'يجب إضافة عنصر تقييم واحد على الأقل قبل الحفظ.';
                else alert('يجب إضافة عنصر تقييم واحد على الأقل قبل الحفظ.');
                return false;
            }

            showPageLoader();
            return true;
        }

        function onSaveEvalClick() {
            if (!validateEvaluation()) return false;
            showPageLoader();
            return true;
        }

        // ✅ تشغيل الفيديو بعد فتح Popup (ModalPopupExtender)
        function playToolVideoFromHidden() {
            try {
                var hf = document.getElementById('<%=hfVideoUrl.ClientID%>');
                var url = hf ? hf.value : '';
                if (!url) return;

                var video = document.getElementById('toolTrainingVideo');
                var source = document.getElementById('toolTrainingSource');

                if (video && source) {
                    video.pause();
                    source.src = url;
                    video.load();
                }
            } catch (e) { }
        }

        // ✅ إيقاف الفيديو عند الإغلاق
        function stopToolVideo() {
            try {
                var video = document.getElementById('toolTrainingVideo');
                var source = document.getElementById('toolTrainingSource');
                if (video) { video.pause(); video.currentTime = 0; }
                if (source) { source.src = ""; }
            } catch (e) { }
        }
    </script>

</asp:Content>
