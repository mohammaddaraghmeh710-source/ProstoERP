<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="EditJobTitles.aspx.vb" Inherits="CRM.EditJobTitles" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">تعديل المحطة التعريفية</h5>
            <div class="card-body">
                <h6 class="fw-normal">1. بيانات المحطة التعريفية</h6>

                <asp:HiddenField ID="hfWorkingMethodVideoPath" runat="server" />
                <asp:HiddenField ID="hfEvaluationMethodVideoPath" runat="server" />

                <div class="row g-3">



                    <!-- Brand -->
                            <asp:Panel ID="pnlBrand" runat="server" CssClass="col-md-4">
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

                            <!-- Branch -->
                            <asp:Panel ID="pnlBranch" runat="server" CssClass="col-md-4">
                                <label class="form-label">الفرع</label>
                                <asp:DropDownList ID="ddlBranch" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlBranch_SelectedIndexChanged">
                                </asp:DropDownList>
                                <asp:RequiredFieldValidator ID="rfvBranch" runat="server"
                                    ControlToValidate="ddlBranch"
                                    InitialValue=""
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red"
                                    Enabled="false" />
                            </asp:Panel>


                    <!-- اختيار القسم -->
                    <div class="col-md-4">
                        <div>
                            <label class="form-label">القسم</label>
                            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="form-select"></asp:DropDownList>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidatorDept" runat="server"
                                    ControlToValidate="ddlDepartment"
                                    InitialValue=""
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالعربية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الاسم بالعربية</label>
                            <asp:TextBox ID="txtTitleAr" runat="server" MaxLength="200" CssClass="form-control" placeholder="اسم المحطة التعريفية بالعربية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidatorTitleAr" runat="server"
                                    ControlToValidate="txtTitleAr"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالإنجليزية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الاسم بالإنجليزية</label>
                            <asp:TextBox ID="txtTitleEn" runat="server" MaxLength="200" CssClass="form-control" placeholder="اسم المحطة التعريفية بالإنجليزية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidatorTitleEn" runat="server"
                                    ControlToValidate="txtTitleEn"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- تفعيل المحطة التعريفية -->
                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                        <label class="switch switch-square">
                            <input type="checkbox" id="cbIsActive" runat="server" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"><i class="bx bx-check"></i></span>
                                <span class="switch-off"><i class="bx bx-x"></i></span>
                            </span>
                            <span class="switch-label">تفعيل المحطة التعريفية</span>
                        </label>
                    </div>

                    <!-- رابط فتح البلوك الإضافي -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="togglePoliciesSection()">
                                السياسات وطريقة العمل (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط هنا لعرض/إخفاء سياسات المحطة التعريفية وفيديوهات طريقة العمل والتقييم.</small>
                        </div>
                    </div>

                    <!-- البلوك المخفي للسياسات وطريقة العمل -->
                    <div id="policiesSection" style="display:none;">

                        <!-- سياسات العمل بالعربية -->
                        <div class="col-md-12 mt-4">
                            <div>
                                <label class="form-label">سياسات العمل بالعربية</label>
                                <CKEditor:CKEditorControl ID="txtPolicies_Ar" runat="server"
                                    Width="100%" Height="200px" ContentsLangDirection="Rtl"></CKEditor:CKEditorControl>
                            </div>
                        </div>

                        <!-- سياسات العمل بالإنجليزية -->
                        <div class="col-md-12 mt-4">
                            <div>
                                <label class="form-label">سياسات العمل بالإنجليزية</label>
                                <CKEditor:CKEditorControl ID="txtPolicies_En" runat="server"
                                    Width="100%" Height="200px" ContentsLangDirection="Ltr"></CKEditor:CKEditorControl>
                            </div>
                        </div>

                        <!-- فيديو طريقة العمل -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>طريقة تنفيذ المهام (فيديو) بالعربية </label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload AutoStartUpload="true" ID="WorkingMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="WorkingMethodVideo_UploadComplete"
                                                    OnUploadStart="WorkingMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">إذا لم ترفع ملفاً جديداً سيبقى الملف الحالي.</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- فيديو طريقة التقييم -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>طريقة تقييم المهام (فيديو) بالعربية </label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload AutoStartUpload="true" ID="EvaluationMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="EvaluationMethodVideo_UploadComplete"
                                                    OnUploadStart="EvaluationMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">إذا لم ترفع ملفاً جديداً سيبقى الملف الحالي.</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div> <!-- /policiesSection -->

                </div> <!-- /row -->

                <div class="pt-4">
                    <asp:Button ID="btnSave" OnClick="btnSave_Click" runat="server" ValidationGroup="SaveForm" CssClass="btn btn-primary me-sm-3 me-1" Text="حفظ" />
                    <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-label-secondary" Text="إغلاق" OnClick="btnCancel_Click" />
                </div>

                <%--Start_Popup--%>
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center">
                                    <asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal>
                                </h2>
                                <div class="swal2-html-container" id="swal2-html-container" style="display: block;">تم التعديل بنجاح!</div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" PopupControlID="PanelPopUp"
                    BackgroundCssClass="OpacityBG" runat="server" TargetControlID="LBLPOP">
                </cc11:ModalPopupExtender>
                <asp:Label ID="LBLPOP" runat="server" />
                <%--End_Popup--%>

            </div>
        </div>
    </div>

    <script type="text/javascript">
        function togglePoliciesSection() {
            var sec = document.getElementById('policiesSection');
            if (!sec) return;
            if (sec.style.display === 'none' || sec.style.display === '') {
                sec.style.display = 'block';
            } else {
                sec.style.display = 'none';
            }
        }
    </script>

</ContentTemplate></asp:UpdatePanel></asp:Content>
