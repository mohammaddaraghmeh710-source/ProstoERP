<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Edit_LMS_TR_Training_Videos.aspx.vb"
    Inherits="CRM.Edit_LMS_TR_Training_Videos" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">

            <h5 class="card-header d-flex justify-content-between align-items-center">
                <span>تعديل فيديو تدريبي</span>
                <a class="btn btn-outline-secondary" href="/Modules/LMS_Training_Videos/Manage_TR_Training_Videos.aspx">رجوع</a>
            </h5>

             <!-- للاحتفاظ بالمسارات القديمة في حال لم يتم رفع ملفات جديدة -->
                <asp:HiddenField ID="hfVideoARPath" runat="server" />
                <asp:HiddenField ID="hfVideoEnPath" runat="server" />

            <div class="card-body">

                <asp:HiddenField ID="hfID" runat="server" />
                <asp:HiddenField ID="hfVideoImagePath" runat="server" />

                <h6 class="fw-normal">1. بيانات الفيديو</h6>

                <div class="row g-3">

                    <!-- ✅ العلامة التجارية -->
                    <div class="col-md-6">
                        <label class="form-label">العلامة التجارية <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                                ControlToValidate="ddlBrand" InitialValue=""
                                ErrorMessage="حقل اجباري" ForeColor="red"
                                ValidationGroup="SaveForm" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <!-- ✅ المستوى -->
                    <div class="col-md-6">
                        <label class="form-label">المستوى <span class="text-danger">*</span></label>
                        <asp:DropDownList ID="ddlLevel" runat="server" CssClass="form-select"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvLevel" runat="server"
                                ControlToValidate="ddlLevel" InitialValue=""
                                ErrorMessage="حقل اجباري" ForeColor="red"
                                ValidationGroup="SaveForm" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الترتيب</label>
                        <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">المدة بالثواني</label>
                        <asp:TextBox ID="txtDuration" runat="server" CssClass="form-control" TextMode="Number"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">عنوان الفيديو بالعربية <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                ControlToValidate="txtTitleAr"
                                ErrorMessage="حقل اجباري" ForeColor="red"
                                ValidationGroup="SaveForm" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">عنوان الفيديو بالإنجليزية <span class="text-danger">*</span></label>
                        <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                ControlToValidate="txtTitleEn"
                                ErrorMessage="حقل اجباري" ForeColor="red"
                                ValidationGroup="SaveForm" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">ملخص بالعربية</label>
                        <asp:TextBox ID="txtSummaryAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">ملخص بالإنجليزية</label>
                        <asp:TextBox ID="txtSummaryEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                    </div>

                     <!-- الفيديو باللغة العربية -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>الفيديو باللغة العربية</label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload ID="VideoAR" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="VideoAR_UploadComplete"
                                                    OnUploadStart="VideoAR_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">إذا لم ترفع ملفاً جديداً سيبقى الملف الحالي.</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- الفيديو باللغة الانجليزية-->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-example-int">
                                <div class="form-group">
                                    <label>الفيديو باللغة الانجليزية </label>
                                    <div class="nk-int-st">
                                        <div class="form-group">
                                            <div class="col-sm-9" style="width: 100%">
                                                <ajaxToolkit:AjaxFileUpload ID="VideoEn" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                                    MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                                    OnUploadComplete="VideoEn_UploadComplete"
                                                    OnUploadStart="VideoEn_UploadStart" />
                                                <br />
                                                <span class="text-danger" style="font-size:12px;">إذا لم ترفع ملفاً جديداً سيبقى الملف الحالي.</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    <!-- ✅ Checkbox -->
                    <div class="col-12 mt-2">
                        <div class="form-check">
                            <asp:CheckBox ID="cbIsActive" style="border:none" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="cbIsActive">تفعيل الفيديو</label>
                        </div>
                    </div>

                    <!-- Upload Image toggle -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="toggleVideoImageSection()">
                                صورة الفيديو (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط هنا لرفع صورة جديدة، وإذا لم ترفع سيبقى الحالي.</small>
                        </div>
                    </div>

                    <div id="videoImageSection" style="display:none;" class="col-12">
                        <div class="row g-3">
                            <div class="col-12">
                                <label>صورة الفيديو (اختياري)</label>
                                <ajaxToolkit:AjaxFileUpload ID="VideoImageUploader"
                                    AllowedFileTypes="jpeg,jpg,png,webp"
                                    MaximumNumberOfFiles="1"
                                    MaxFileSize="100024"
                                    runat="server"
                                    OnUploadComplete="VideoImageUploader_UploadComplete"
                                    OnUploadStart="VideoImageUploader_UploadStart" />
                                <br />
                                <span class="text-danger" style="font-size:12px;">إذا لم ترفع صورة جديدة سيبقى الملف الحالي.</span>

                                <asp:Literal ID="litCurrentImage" runat="server"></asp:Literal>
                            </div>
                        </div>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ"
                        CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm"
                        OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق"
                        CssClass="btn btn-label-secondary"
                        OnClick="btnCancel_Click" />
                </div>

                <%-- Popup Success --%>
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center"><asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal></h2>
                                <div class="swal2-html-container" style="display: block;">تم التعديل بنجاح!</div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender"
                    PopupControlID="PanelPopUp"
                    BackgroundCssClass="OpacityBG"
                    runat="server"
                    TargetControlID="LBLPOP" />
                <asp:Label ID="LBLPOP" runat="server" />

                <asp:Label ID="lblMsg" runat="server" Visible="false" CssClass="alert alert-danger d-block mt-3"></asp:Label>

            </div>
        </div>
    </div>

    <script type="text/javascript">
        function toggleVideoImageSection() {
            var sec = document.getElementById('videoImageSection');
            if (!sec) return;
            sec.style.display = (sec.style.display === 'none' || sec.style.display === '') ? 'block' : 'none';
        }
    </script>

</asp:Content>
