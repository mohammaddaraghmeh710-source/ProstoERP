<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Employee_Evaluation.aspx.vb" Inherits="CRM.Employee_Evaluation" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* ===== نفس ستايل صفحة تقييم القسم (الكاشير) ===== */
        .eval-tag {
            display: inline-block;
            min-width: 80px;
            padding: 2px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            text-align: center;
            line-height: 20px;
            white-space: nowrap;
        }
        .eval-red { background: #fde6e6; color: #d84646; }
        .eval-yellow { background: #fff6d6; color: #b58c00; }
        .eval-green { background: #e3f5e7; color: #3b7f4c; }

        .eval-list-item {
            border: 1px solid #eef2f7;
            border-radius: 12px;
            padding: 12px 14px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            background: #fff;
        }
        .eval-title {
            font-weight: 700;
            color: #111827;
        }
        .eval-info-btn {
            border: 0;
            background: transparent;
            padding: 0;
            color: #6b7280;
        }
        .eval-info-btn:hover { color: #111827; }

        /* ===== إضافة عنصر تقييم جديد (نفس المودال) ===== */
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
            font-weight: 700;
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

        /* ===== Toast (Alert) بدل Windows Message ===== */
        .toast-container {
            position: fixed;
            top: 16px;
            left: 16px;
            z-index: 10050;
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
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl container-p-y">

        <!-- ===== Header ===== -->
        <div class="card shadow-sm border-0 mb-3">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <div>
                    <h5 class="fw-bold mb-1">تقييم الموظف</h5>
                    <small class="text-muted">اختر عناصر التقييم، أضف ملاحظات ومرفقات، ثم احفظ التقييم.</small>
                </div>

                <div class="d-flex flex-wrap gap-2">
                    <span class="badge bg-label-primary">
                        <i class="bx bx-user ms-1"></i>
                        <span id="EmployeeNameText" runat="server">اسم الموظف</span>
                    </span>
                    <span class="badge bg-label-info">
                        <i class="bx bx-store-alt ms-1"></i>
                        <span id="BranchNameText" runat="server">اسم الفرع</span>
                    </span>
                </div>
            </div>

            <div class="card-body">

                <!-- ===== KEEP YOUR OLD SECTIONS HERE (Gauge / Violations / Tasks / Complaints...) ===== -->
                <!-- ضع أقسام الصفحة السابقة هنا بدون تعديل -->

                <!-- ===== عناصر التقييم (مطابق للكاشير) ===== -->
                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-2">
                    <div>
                        <div class="fw-bold">عناصر التقييم</div>
                        <small class="text-muted">يمكن اختيار عنصر واحد أو أكثر.</small>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="button"
                            class="btn btn-outline-primary btn-sm d-flex align-items-center"
                            onclick="onAddChecklistClicked();">
                            <i class="bx bx-plus-circle ms-1"></i>
                            إضافة عنصر تقييم جديد
                        </button>
                    </div>
                </div>

                <asp:Panel ID="pnlNoChecklist" runat="server" Visible="false" CssClass="alert alert-warning small mb-3">
                    لا يوجد عناصر تقييم لهذا الموظف حالياً.
                </asp:Panel>

                <asp:Panel ID="pnlChecklistWrapper" runat="server">
                    <div class="d-flex flex-column gap-2 mt-2">
                        <asp:Repeater ID="rptChecklistEmployee" runat="server">
                            <ItemTemplate>
                                <div class="eval-list-item">

                                    <!-- Checkbox بالبداية -->
                                    <div class="d-flex align-items-center gap-2" style="min-width: 0;">
                                        <input class="form-check-input mt-0"
                                            type="checkbox"
                                            name='chkEmp_<%# Eval("ID") %>' />

                                        <!-- العنوان فقط -->
                                        <div class="d-flex align-items-center gap-2" style="min-width: 0;">
                                            <span class="eval-title text-truncate" style="max-width: 520px;">
                                                <%# Eval("Title_Ar") %>
                                            </span>

                                            <!-- زر معلومات -->
                                            <button type="button"
                                                class="eval-info-btn"
                                                onclick="showInfo('<%# JsString(Eval("Title_Ar")) %>','<%# JsString(Eval("Brief_Ar")) %>')"
                                                title="عرض الوصف">
                                                <i class="bx bx-info-circle fs-5"></i>
                                            </button>
                                        </div>
                                    </div>

                                    <!-- تصنيف ملون -->
                                    <span class='<%# GetChecklistCss(Eval("CheckList_CategoryID")) %>'>
                                        <%# Eval("CategoryTitle_Ar") %>
                                    </span>

                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </asp:Panel>

                <!-- ملاحظات -->
                <div class="mt-3">
                    <label class="form-label fw-semibold">ملاحظات</label>
                    <asp:TextBox ID="txtNotes" runat="server"
                        CssClass="form-control"
                        TextMode="MultiLine"
                        Style="min-height: 90px;"
                        placeholder="اكتب ملاحظاتك هنا..."></asp:TextBox>
                </div>

                <!-- مرفقات -->
                <div class="mt-3">
                    <label class="form-label fw-semibold">مرفقات (صور / مستندات)</label>
                    <ajaxToolkit:AjaxFileUpload ID="TaskFiles" runat="server"
                        AllowedFileTypes="jpeg,jpg,png,pdf,doc,docx,xls,xlsx"
                        MaximumNumberOfFiles="5"
                        MaxFileSize="204800"
                        OnUploadComplete="TaskFiles_UploadComplete"
                        OnUploadStart="TaskFiles_UploadStart" />
                    <small class="text-muted d-block mt-1">يمكنك رفع حتى 5 ملفات.</small>
                </div>

                <div class="d-flex justify-content-between align-items-center mt-4">
                    <span id="evalErr" class="text-danger small" runat="server"></span>

                    <asp:LinkButton ID="btnSaveEval"
                        runat="server"
                        CssClass="btn btn-primary"
                        OnClientClick="return onSaveEvalClick();"
                        CommandName="SaveEmployeeEvaluation">
                        <i class="bx bx-check-circle ms-1"></i>
                        حفظ التقييم
                    </asp:LinkButton>
                </div>

            </div>
        </div>

    </div>

    <!-- ===== Modal تفاصيل عنصر التقييم (Popup للوصف) ===== -->
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

    <!-- ===== Modal إضافة عناصر تقييم جديدة (Checklist_Employee) ===== -->
    <div class="modal fade" id="newChecklistModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">

                <div class="modal-header">
                    <h5 class="modal-title fw-bold">إضافة عناصر تقييم جديدة</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                </div>

                <div class="modal-body">
                    <p class="text-muted small mb-2">يمكن إضافة عنصر واحد أو أكثر.</p>

                    <div id="newChecklistBody" class="d-flex flex-column gap-2"></div>

                    <div class="d-flex justify-content-between align-items-center mt-3">
                        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="addNewChecklistRow();">
                            <i class="bx bx-plus ms-1"></i> إضافة صف جديد
                        </button>

                        <asp:LinkButton ID="btnSaveNewChecklist"
                            runat="server"
                            CssClass="btn btn-outline-success btn-sm"
                            OnClientClick="return onSaveChecklistClick();"
                            CommandName="SaveChecklistEmployee">
                            <i class="bx bx-save ms-1"></i> حفظ عناصر التقييم
                        </asp:LinkButton>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">إغلاق</button>
                </div>

            </div>
        </div>
    </div>

    <!-- ===== Toast Alert (نجاح الحفظ) ===== -->
    <div class="toast-container">
        <div id="saveToast" class="toast align-items-center text-bg-success border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    تم الحفظ بنجاح ✅
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    </div>

    <!-- ===== Loader ===== -->
    <div id="pageLoader" class="page-loader-backdrop d-none">
        <div class="page-loader-box text-center">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">جاري التحميل...</span>
            </div>
            <div class="page-loader-text">جاري معالجة طلبك، الرجاء الانتظار...</div>
        </div>
    </div>

    <script type="text/javascript">

        // ===== Popup تفاصيل =====
        function showInfo(title, body) {
            var t = document.getElementById('InfoTitle');
            var b = document.getElementById('InfoBody');
            if (t) t.textContent = title || '';
            if (b) b.textContent = body || '';

            var modalEl = document.getElementById('InfoModal');
            if (!modalEl) return;

            if (window.bootstrap && bootstrap.Modal) {
                bootstrap.Modal.getOrCreateInstance(modalEl).show();
            } else if (window.$) {
                $(modalEl).modal('show');
            }
        }

        // ===== Loader =====
        function showPageLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.remove('d-none');
        }
        function hidePageLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.add('d-none');
        }

        // ===== Toast =====
        function showSavedToast() {
            var el = document.getElementById('saveToast');
            if (!el || !(window.bootstrap && bootstrap.Toast)) return;
            bootstrap.Toast.getOrCreateInstance(el, { delay: 2500 }).show();
        }

        // ===== Validate قبل حفظ التقييم =====
        function validateEvaluation() {
            var anyChecked = document.querySelectorAll('input[type="checkbox"][name^="chkEmp_"]:checked').length > 0;
            var notesBox = document.querySelector('textarea[id*="txtNotes"]');
            var notesVal = notesBox ? notesBox.value.trim() : "";

            var err = document.getElementById('<%= evalErr.ClientID %>');
            if (err) err.innerHTML = "";

            if (!anyChecked && notesVal === "") {
                if (err) err.innerHTML = "اختيار عنصر تقييم واحد على الأقل أو إدخال ملاحظات إجباري قبل الحفظ.";
                return false;
            }
            return true;
        }

        function onSaveEvalClick() {
            if (!validateEvaluation()) return false;
            showPageLoader();
            return true;
        }

        // ===== Modal إضافة عناصر جديدة =====
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
                '    <input type="text" class="form-control" name="newBriefAr[]">' +
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
            reIndexNewChecklistRows();
        }

        function removeNewChecklistRow(btn) {
            var row = btn.closest('.new-checklist-item');
            var container = document.getElementById('newChecklistBody');
            if (row && container) {
                container.removeChild(row);
                reIndexNewChecklistRows();
            }
        }

        function reIndexNewChecklistRows() {
            var container = document.getElementById('newChecklistBody');
            if (!container) return;
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
                // لا نستخدم alert() حسب طلبك، نستخدم Toast تحذير بسيط
                var err = document.getElementById('<%= evalErr.ClientID %>');
                if (err) err.innerHTML = "يجب إضافة عنصر تقييم واحد على الأقل قبل الحفظ.";
                return false;
            }

            showPageLoader();
            return true;
        }

        // عند تحميل الصفحة
        window.addEventListener('load', function () { hidePageLoader(); });
    </script>

</asp:Content>
