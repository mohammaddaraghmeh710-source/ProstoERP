<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddBranches.aspx.vb" Inherits="CRM.AddBranches" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة فرع جديد</h5>
            <div class="card-body">
                <h6 class="fw-normal">1. بيانات الفرع</h6>

                <div class="row g-3">
                    <!-- اختيار العلامة التجارية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">العلامة التجارية</label>
                            <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select">
                            </asp:DropDownList>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidatorBrand" runat="server"
                                    ControlToValidate="ddlBrand"
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
                            <asp:TextBox ID="txtTitleAr" runat="server" MaxLength="200" CssClass="form-control" placeholder="اسم الفرع بالعربية"></asp:TextBox>
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
                            <asp:TextBox ID="txtTitleEn" runat="server" MaxLength="200" CssClass="form-control" placeholder="اسم الفرع بالإنجليزية"></asp:TextBox>
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

                    <!-- رابط فتح البلوك الإضافي -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="togglePoliciesSection()">
                                السياسات وطريقة العمل (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط هنا لعرض/إخفاء سياسات الفرع وفيديوهات طريقة العمل والتقييم.</small>
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
                                    <label>طريقة تنفيذ المهام (فيديو) </label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload ID="WorkingMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="WorkingMethodVideo_UploadComplete"
                                                    OnUploadStart="WorkingMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">يمكن تحميل ملفات فيديو (mp4, avi, mov, wmv,jpeg,png,jpg)</span>
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
                                    <label>طريقة تقييم المهام (فيديو) </label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload ID="EvaluationMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="EvaluationMethodVideo_UploadComplete"
                                                    OnUploadStart="EvaluationMethodVideo_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">يمكن تحميل ملفات فيديو (mp4, avi, mov, wmv,jpeg,png,jpg)</span>
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
                                <div class="swal2-html-container" id="swal2-html-container" style="display: block;">تمت الإضافة بنجاح!</div>
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
