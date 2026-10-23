<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Add_JobTitle_Items.aspx.vb" Inherits="CRM.Add_JobTitle_Items" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <script defer src="/assets/js/tool-suppliers.js?v=20261021ba"></script>
    <style>
        .hint-box {
            background: #f7fbff;
            border: 1px dashed rgba(105,108,255,.35);
            border-radius: 12px;
            padding: 12px 14px;
            display: flex;
            gap: 10px;
            align-items: flex-start;
        }
        .hint-icon {
            width: 34px; height: 34px;
            border-radius: 10px;
            display: inline-flex;
            align-items: center; justify-content: center;
            background: rgba(105,108,255,.12);
            color: #696cff;
            flex: 0 0 auto;
        }
        .draft-wrap { margin-top: 16px; }
        .draft-card {
            border-radius: 16px;
            border: 1px solid rgba(0,0,0,.08);
            padding: 12px;
            background: #fff;
        }
        .draft-meta { font-size: 12px; color: #6c757d; }
        .draft-title { font-weight: 800; font-size: 15px; color: #32475c; margin: 6px 0 8px; }
        .draft-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px 10px;
        }
        .kv { background: #f8f9fa; border-radius: 12px; padding: 8px 10px; }
        .kv b { display:block; font-size: 11px; color:#6c757d; margin-bottom: 2px; }
        .kv span { font-size: 13px; color:#2f3a45; word-break: break-word; }
        .draft-actions { display:flex; gap:8px; justify-content:flex-end; margin-top: 10px; }
        .section-title { display:flex; align-items:center; justify-content:space-between; gap: 10px; }
        .sticky-save {
            position: sticky;
            bottom: 10px;
            z-index: 10;
            background: rgba(255,255,255,.85);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(0,0,0,.08);
            border-radius: 16px;
            padding: 10px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap: 10px;
            margin-top: 14px;
        }

        @media (max-width: 576px) {
            .draft-grid { grid-template-columns: 1fr; }
            .sticky-save { flex-direction: column; align-items: stretch; }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة أدوات / عناصر لمحطة تعريفية</h5>

            <div class="card-body">

                <!-- ====== 1) الهيكل التنظيمي (بدون Refresh) ====== -->

<asp:UpdatePanel ID="upOrg" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
    <ContentTemplate>

        <h6 class="fw-normal">1. الهيكل التنظيمي (إجباري)</h6>

        <div class="row g-3 mb-2">
            <!-- Brand -->
            <div class="col-md-3">
                <label class="form-label">العلامة التجارية</label>
                <asp:DropDownList ID="ddlBrand" runat="server" data-tool-brand="true" CssClass="form-select"
                    AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged"></asp:DropDownList>
                <div class="form-text">
                    <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                        ControlToValidate="ddlBrand" InitialValue=""
                        ErrorMessage="حقل اجباري" ValidationGroup="Org"
                        ForeColor="Red" Display="Dynamic" />
                </div>
            </div>

            <!-- Branch -->
            <div class="col-md-3">
                <label class="form-label">الفرع</label>
                <asp:DropDownList ID="ddlBranch" runat="server" CssClass="form-select"
                    AutoPostBack="true" OnSelectedIndexChanged="ddlBranch_SelectedIndexChanged"></asp:DropDownList>
                <div class="form-text">
                    <asp:RequiredFieldValidator ID="rfvBranch" runat="server"
                        ControlToValidate="ddlBranch" InitialValue=""
                        ErrorMessage="حقل اجباري" ValidationGroup="Org"
                        ForeColor="Red" Display="Dynamic" />
                </div>
            </div>

            <!-- Department -->
            <div class="col-md-3">
                <label class="form-label">القسم</label>
                <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="form-select"
                    AutoPostBack="true" OnSelectedIndexChanged="ddlDepartment_SelectedIndexChanged"></asp:DropDownList>
                <div class="form-text">
                    <asp:RequiredFieldValidator ID="rfvDepartment" runat="server"
                        ControlToValidate="ddlDepartment" InitialValue=""
                        ErrorMessage="حقل اجباري" ValidationGroup="Org"
                        ForeColor="Red" Display="Dynamic" />
                </div>
            </div>

            <!-- JobTitle -->
            <div class="col-md-3">
                <label class="form-label">المحطة التعريفية</label>
                <asp:DropDownList ID="ddlJobTitle" runat="server" CssClass="form-select"></asp:DropDownList>
                <div class="form-text">
                    <asp:RequiredFieldValidator ID="rfvJobTitle" runat="server"
                        ControlToValidate="ddlJobTitle" InitialValue=""
                        ErrorMessage="حقل اجباري" ValidationGroup="Org"
                        ForeColor="Red" Display="Dynamic" />
                </div>
            </div>
        </div>

    </ContentTemplate>

   <%--نخلي تغييرات الدروب داون تعمل Async PostBack--%> 
    <Triggers>
        <asp:AsyncPostBackTrigger ControlID="ddlBrand" EventName="SelectedIndexChanged" />
        <asp:AsyncPostBackTrigger ControlID="ddlBranch" EventName="SelectedIndexChanged" />
        <asp:AsyncPostBackTrigger ControlID="ddlDepartment" EventName="SelectedIndexChanged" />
    </Triggers>
</asp:UpdatePanel>

                <div class="hint-box mt-2">
                    <div class="hint-icon">
                        <i class="bx bx-info-circle"></i>
                    </div>
                    <div>
                        <div class="fw-bold">ملاحظة</div>
                        <div class="text-muted" style="font-size:13px;">
                            بعد اختيار الهيكل التنظيمي بالأعلى، يمكنك إضافة <b>أداة واحدة أو أكثر</b> لنفس المحطة التعريفية.
                            اضغط <b>إضافة</b> لكل أداة، ثم اضغط <b>حفظ الكل</b> لإدخالها دفعة واحدة.
                        </div>
                    </div>
                </div>

                <hr class="my-4" />

                <!-- ====== UpdatePanel: إضافة وعرض بدون Refresh كامل ====== -->
                <asp:UpdatePanel ID="upDraft" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>

                        <!-- ====== 2) بيانات الأداة ====== -->
                        <div class="section-title">
                            <h6 class="fw-normal m-0">2. بيانات الأداة</h6>
                            <asp:Label ID="lblDraftCount" runat="server" CssClass="badge bg-label-primary"></asp:Label>
                        </div>

                        <div class="row g-3 mt-1">

                            <div class="col-md-4">
                                <label class="form-label">نوع الأداة</label>
                                <asp:DropDownList ID="ddlItemType" runat="server" CssClass="form-select"></asp:DropDownList>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvItemType" runat="server" ControlToValidate="ddlItemType"
                                        InitialValue="" ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">رقم الأداة</label>
                                <asp:TextBox ID="txtToolNumber" runat="server" CssClass="form-control" MaxLength="100" placeholder="رقم الأداة"></asp:TextBox>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvToolNumber" runat="server" ControlToValidate="txtToolNumber"
                                        ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">الشركة الموردة</label>
                                <asp:DropDownList ID="ddlSupplier" runat="server" data-tool-suppliers="true" CssClass="form-select"></asp:DropDownList>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvSupplier" runat="server" ControlToValidate="ddlSupplier"
                                        InitialValue="" ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">شركة الصيانة</label>
                                <asp:DropDownList ID="ddlMaintenanceCompany" runat="server" CssClass="form-select"></asp:DropDownList>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvMaintenance" runat="server" ControlToValidate="ddlMaintenanceCompany"
                                        InitialValue="" ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">العنوان بالعربية</label>
                                <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="200" placeholder="العنوان بالعربية"></asp:TextBox>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server" ControlToValidate="txtTitleAr"
                                        ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">العنوان بالإنجليزية</label>
                                <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="200" placeholder="العنوان بالإنجليزية"></asp:TextBox>
                                <div class="form-text">
                                    <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server" ControlToValidate="txtTitleEn"
                                        ErrorMessage="حقل اجباري" ValidationGroup="AddItem" ForeColor="Red" Display="Dynamic" />
                                </div>
                            </div>

                            <!-- Toggle optional -->
                            <div class="col-12">
                                <div class="mt-2 mb-1">
                                    <a href="javascript:void(0)" class="fw-bold text-primary" onclick="togglePoliciesSection()">
                                        السياسات وطريقة العمل (اختياري)
                                    </a>
                                    <small class="text-muted d-block">اضغط لعرض/إخفاء السياسات وفيديوهات طريقة العمل والتقييم.</small>
                                </div>
                            </div>

                            <div id="policiesSection" style="display:none;">
                                <div class="col-md-12 mt-3">
                                    <label class="form-label">سياسات العمل بالعربية</label>
                                    <CKEditor:CKEditorControl ID="txtPolicies_Ar" runat="server" Width="100%" Height="200px" ContentsLangDirection="Rtl"></CKEditor:CKEditorControl>
                                </div>

                                <div class="col-md-12 mt-3">
                                    <label class="form-label">سياسات العمل بالإنجليزية</label>
                                    <CKEditor:CKEditorControl ID="txtPolicies_En" runat="server" Width="100%" Height="200px" ContentsLangDirection="Ltr"></CKEditor:CKEditorControl>
                                </div>

                                <div class="col-12 mt-3">
                                    <label class="form-label">طريقة تنفيذ المهام (فيديو) بالعربية (اختياري)</label>
                                    <ajaxToolkit:AjaxFileUpload AutoStartUpload="true" ID="WorkingMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                        MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                        OnUploadComplete="WorkingMethodVideo_UploadComplete"
                                        OnUploadStart="WorkingMethodVideo_UploadStart" />
                                    <span class="text-danger" style="font-size:12px;">اختياري</span>
                                </div>

                                <div class="col-12 mt-3">
                                    <label class="form-label">طريقة تقييم المهام (فيديو) بالعربية (اختياري)</label>
                                    <ajaxToolkit:AjaxFileUpload AutoStartUpload="true" ID="EvaluationMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                        MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                        OnUploadComplete="EvaluationMethodVideo_UploadComplete"
                                        OnUploadStart="EvaluationMethodVideo_UploadStart" />
                                    <span class="text-danger" style="font-size:12px;">اختياري</span>
                                </div>
                            </div>

                        </div>

                        <!-- زر إضافة إلى Session -->
                        <div class="pt-3 d-flex gap-2 flex-wrap">
                            <asp:Button ID="btnAddToSession" runat="server" Text="إضافة"
                                CssClass="btn btn-success"
                                ValidationGroup="AddItem"
                                OnClick="btnAddToSession_Click" />
                            <asp:Button ID="btnClearDraft" runat="server" Text="تفريغ القائمة"
                                CssClass="btn btn-label-danger"
                                CausesValidation="false"
                                OnClick="btnClearDraft_Click" />
                        </div>

                        <!-- رسائل بسيطة -->
                        <asp:Label ID="lblMsg" runat="server" CssClass="text-danger d-block mt-2"></asp:Label>

                        <!-- ====== قائمة الأدوات المضافة (Session) ====== -->
                        <div class="draft-wrap">
                            <h6 class="fw-normal mt-4 mb-2">الأدوات المضافة (قبل الحفظ)</h6>

                            <asp:ListView ID="lvDraftItems" runat="server" OnItemCommand="lvDraftItems_ItemCommand">
                                <EmptyDataTemplate>
                                    <div class="text-muted">لا توجد أدوات مضافة بعد.</div>
                                </EmptyDataTemplate>

                                <ItemTemplate>
                                    <div class="draft-card mb-3">
                                        <div class="draft-meta">
                                            أداة رقم: <b><%# Eval("ToolNumber") %></b> — نوع: <b><%# Eval("ItemTypeText") %></b>
                                        </div>

                                        <div class="draft-title">
                                            <%# Eval("TitleAr") %> <span class="text-muted" style="font-weight:600;">/</span> <%# Eval("TitleEn") %>
                                        </div>

                                        <div class="draft-grid">
                                            <div class="kv"><b>المورد</b><span><%# Eval("SupplierText") %></span></div>
                                            <div class="kv"><b>الصيانة</b><span><%# Eval("MaintenanceText") %></span></div>
                                            <div class="kv"><b>فيديو طريقة العمل</b><span><%# Eval("WorkingVideoLabel") %></span></div>
                                            <div class="kv"><b>فيديو التقييم</b><span><%# Eval("EvalVideoLabel") %></span></div>
                                        </div>

                                        <div class="draft-actions">
                                            <asp:LinkButton ID="btnDelete" runat="server"
                                                CommandName="deleteDraft"
                                                CommandArgument='<%# Eval("TempId") %>'
                                                CssClass="btn btn-sm btn-danger">
                                                <i class="bx bx-trash"></i> حذف
                                            </asp:LinkButton>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:ListView>
                        </div>

                        <!-- Sticky save bar -->
                        <div class="sticky-save">
                            <div class="text-muted" style="font-size:13px;">
                                سيتم حفظ جميع الأدوات المضافة أعلاه على المحطة التعريفية المحدد.
                            </div>

                            <div class="d-flex gap-2 flex-wrap">
                                <asp:Button ID="btnSaveAll" runat="server" Text="حفظ "
                                    CssClass="btn btn-primary"
                                    ValidationGroup="Org"
                                    OnClick="btnSaveAll_Click" />
                                  <asp:Button ID="btnSaveAllForAllJobTitle" runat="server" Text="حفظ لكل المحطات التعريفية"
                                    CssClass="btn btn-primary"
                                    ValidationGroup="Org"
                                    OnClick="btnSaveAllForAllJobTitle_Click" />

                                <asp:Button ID="btnCancel" runat="server" Text="إغلاق"
                                    CssClass="btn btn-label-secondary"
                                    CausesValidation="false"
                                    OnClick="btnCancel_Click" />
                            </div>
                        </div>

                        <!-- Popup نجاح -->
                        <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display:none;" DefaultButton="btnClosePopup">
                            <div class="modal-dialog modal-dialog-centered" role="document">
                                <div class="modal-content">
                                    <div class="text-center m-4">
                                        <img src="/assets/img/Prosto/Success_Icon.png" />
                                    </div>
                                    <div class="modal-body">
                                        <h2 class="text-center"><asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal></h2>
                                        <div class="swal2-html-container" style="display:block;">تم الحفظ بنجاح!</div>
                                    </div>
                                    <div class="text-center m-4">
                                        <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary"
                                            OnClick="btnClosePopup_Click" />
                                    </div>
                                </div>
                            </div>
                        </asp:Panel>

                        <ajaxToolkit:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" runat="server"
                            PopupControlID="PanelPopUp" TargetControlID="LBLPOP"
                            BackgroundCssClass="OpacityBG" />
                        <asp:Label ID="LBLPOP" runat="server" />

                    </ContentTemplate>

                    <Triggers>
                     <%--مهم: زر الإضافة يكون Async--%> 
                        <asp:AsyncPostBackTrigger ControlID="btnAddToSession" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="btnClearDraft" EventName="Click" />
                        <asp:AsyncPostBackTrigger ControlID="lvDraftItems" EventName="ItemCommand" />
                        <asp:AsyncPostBackTrigger ControlID="btnSaveAll" EventName="Click" />
                    </Triggers>

                </asp:UpdatePanel>

            </div>
        </div>
    </div>

    <script type="text/javascript">
        function togglePoliciesSection() {
            var sec = document.getElementById('policiesSection');
            if (!sec) return;
            sec.style.display = (sec.style.display === 'none' || sec.style.display === '') ? 'block' : 'none';
        }
    </script>

</ContentTemplate></asp:UpdatePanel></asp:Content>
