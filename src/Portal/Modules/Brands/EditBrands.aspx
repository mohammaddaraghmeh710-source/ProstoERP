<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="EditBrands.aspx.vb" Inherits="CRM.EditBrands" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">تعديل العلامة التجارية</h5>
            <div class="card-body">
                <h6 class="fw-normal">1. بيانات العلامة التجارية</h6>

                <!-- للاحتفاظ بالمسارات القديمة -->
                <asp:HiddenField ID="hfLogoPath" runat="server" />
                <asp:HiddenField ID="hfWorkingMethodVideoPath" runat="server" />
                <asp:HiddenField ID="hfEvaluationMethodVideoPath" runat="server" />

                <div class="row g-3">

                    <!-- الاسم بالعربية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الاسم بالعربية</label>
                            <asp:TextBox ID="txtFullNameAr" runat="server" MaxLength="50" CssClass="form-control" placeholder="اسم العلامة التجارية بالعربية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidator8" runat="server"
                                    ControlToValidate="txtFullNameAr"
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
                            <asp:TextBox ID="txtFullNameEn" runat="server" MaxLength="50" CssClass="form-control" placeholder="اسم العلامة التجارية بالإنجليزية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server"
                                    ControlToValidate="txtFullNameEn"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- تفعيل العلامة التجارية -->
                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                        <label class="switch switch-square">
                            <input type="checkbox" id="cbIsActive" runat="server" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"><i class="bx bx-check"></i></span>
                                <span class="switch-off"><i class="bx bx-x"></i></span>
                            </span>
                            <span class="switch-label">تفعيل العلامة التجارية</span>
                        </label>
                    </div>

                    <!-- شعار العلامة التجارية -->
                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-2">
                        <div class="form-example-int">
                            <div class="form-group">
                                <label>شعار العلامة التجارية (اختياري)</label>
                                <div class="nk-int-st">
                                    <div class="form-group">
                                        <div class="col-sm-9" style="width: 100%">
                                            <ajaxToolkit:AjaxFileUpload ID="TaskVideoAr" AllowedFileTypes="jpeg,jpg,png"
                                                MaximumNumberOfFiles="1" MaxFileSize="100024" runat="server"
                                                OnUploadComplete="TaskVideoAr_UploadComplete"
                                                OnUploadStart="TaskVideoAr_UploadStart" />
                                            <br />
                                            <span class="text-danger" style="font-size:12px;">إذا لم ترفع شعاراً جديداً سيبقى الشعار الحالي.</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- رابط فتح البلوك الإضافي -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="togglePoliciesSection()">
                                السياسات وطريقة العمل (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط هنا لعرض/إخفاء السياسات وفيديوهات طريقة العمل والتقييم.</small>
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
                                                <ajaxToolkit:AjaxFileUpload ID="WorkingMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
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
                                                <ajaxToolkit:AjaxFileUpload ID="EvaluationMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
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

</asp:Content>
