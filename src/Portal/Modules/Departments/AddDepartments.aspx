<%@ Page Title="" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="AddDepartments.aspx.vb"
    Inherits="CRM.AddDepartments" %>

<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <script type="text/javascript">
        function togglePoliciesDept() {
            var pnl = document.getElementById('<%= pnlPolicies.ClientID %>');
            if (pnl) {
                if (pnl.style.display === "none" || pnl.style.display === "") {
                    pnl.style.display = "block";
                } else {
                    pnl.style.display = "none";
                }
            }
        }
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة قسم جديد</h5>

            <div class="card-body">
                <h6 class="fw-normal">1. بيانات القسم</h6>

                <div class="row g-3">
                       <asp:Panel ID="pnlBrand" runat="server" CssClass="col-md-6">
                                <label class="form-label">العلامة التجارية</label>
                                <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged">
                                </asp:DropDownList>
                                <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                                    ControlToValidate="ddlBrand"
                                    InitialValue=""
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red"
                                    Enabled="false" />
                            </asp:Panel>

                    <!-- الفرع -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الفرع</label>
                            <asp:DropDownList ID="ddlBranch" runat="server" CssClass="form-select">
                            </asp:DropDownList>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvBranch" runat="server"
                                    ControlToValidate="ddlBranch"
                                    InitialValue="0"
                                    ErrorMessage="حقل الفرع إجباري"
                                    ForeColor="Red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic" />
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالعربية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">اسم القسم بالعربية</label>
                            <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control"
                                MaxLength="200" placeholder="اسم القسم بالعربية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                    ControlToValidate="txtTitleAr"
                                    ErrorMessage="حقل إجباري"
                                    ForeColor="Red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic" />
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالإنجليزية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">اسم القسم بالإنجليزية</label>
                            <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control"
                                MaxLength="200" placeholder="اسم القسم بالإنجليزية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                    ControlToValidate="txtTitleEn"
                                    ErrorMessage="حقل إجباري"
                                    ForeColor="Red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic" />
                            </div>
                        </div>
                    </div>

                    <!-- مفتاح تفعيل -->
                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                        <label class="switch switch-square">
                            <asp:CheckBox ID="cbIsActive" runat="server" CssClass="switch-input" Checked="true" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"><i class="bx bx-check"></i></span>
                                <span class="switch-off"><i class="bx bx-x"></i></span>
                            </span>
                            <span class="switch-label">تفعيل القسم</span>
                        </label>
                    </div>

                    <!-- رابط إظهار/إخفاء السياسات -->
                    <div class="col-12">
                        <a href="javascript:void(0)" onclick="togglePoliciesDept()">
                            <i class="bx bx-chevron-down"></i>
                            السياسات وطريقة العمل (اختياري)
                        </a>
                    </div>

                    <!-- بلوك السياسات والطرق -->
                    <asp:Panel ID="pnlPolicies" runat="server" Style="display:none;">
                        <div class="col-md-12 mt-3">
                            <label class="form-label">سياسات العمل بالعربية (اختياري)</label>
                            <CKEditor:CKEditorControl ID="txtPolicies_Ar" runat="server"
                                Width="100%" Height="200px" ContentsLangDirection="Rtl" />
                        </div>

                        <div class="col-md-12">
                            <label class="form-label">سياسات العمل بالإنجليزية (اختياري)</label>
                            <CKEditor:CKEditorControl ID="txtPolicies_En" runat="server"
                                Width="100%" Height="200px" ContentsLangDirection="Ltr" />
                        </div>

                        <!-- طريقة تنفيذ المهام -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>طريقة تنفيذ المهام (فيديو / ملف) - اختياري</label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <cc1:AjaxFileUpload AutoStartUpload="true" ID="WorkingMethodVideo"
                                                    runat="server"
                                                    AllowedFileTypes="mp4,avi,mov,wmv,flv,webm"
                                                    MaximumNumberOfFiles="1"
                                                    MaxFileSize="104857600"
                                                    OnUploadComplete="WorkingMethodVideo_UploadComplete"
                                                    OnUploadStart="WorkingMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger">
                                                    يمكن تحميل ملفات الفيديو فقط (mp4, avi, mov, wmv, flv, webm)
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- طريقة تقييم المهام -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>طريقة تقييم المهام (فيديو / ملف) - اختياري</label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <cc1:AjaxFileUpload AutoStartUpload="true" ID="EvaluationMethodVideo"
                                                    runat="server"
                                                    AllowedFileTypes="mp4,avi,mov,wmv,flv,webm"
                                                    MaximumNumberOfFiles="1"
                                                    MaxFileSize="104857600"
                                                    OnUploadComplete="EvaluationMethodVideo_UploadComplete"
                                                    OnUploadStart="EvaluationMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger">
                                                    يمكن تحميل ملفات الفيديو فقط (mp4, avi, mov, wmv, flv, webm)
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </asp:Panel>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary me-sm-3 me-1"
                        Text="حفظ" ValidationGroup="SaveForm" OnClick="btnSave_Click" />
                     <asp:Button ID="btnSaveforAllBranches" runat="server" CssClass="btn btn-primary me-sm-3 me-1"
                        Text="حفظ لكل الافرع" ValidationGroup="SaveForm" OnClick="btnSaveforAllBranches_Click" />
                    <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-label-secondary"
                        Text="إغلاق" OnClick="btnCancel_Click" />
                </div>

                <!-- Popup -->
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;"
                    DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center">
                                    <asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal>
                                </h2>
                                <div class="swal2-html-container" id="swal2-html-container" style="display: block;">
                                    تمت الإضافة بنجاح!
                                </div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق"
                                    CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc1:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" runat="server"
                    PopupControlID="PanelPopUp" BackgroundCssClass="OpacityBG"
                    TargetControlID="LBLPOP" />
                <asp:Label ID="LBLPOP" runat="server" />

            </div>
        </div>
    </div>

</ContentTemplate></asp:UpdatePanel></asp:Content>
