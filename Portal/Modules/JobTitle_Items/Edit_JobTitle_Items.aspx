<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Edit_JobTitle_Items.aspx.vb" Inherits="CRM.Edit_JobTitle_Items" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">تعديل أداة / عنصر لمحطة تعريفية</h5>

            <div class="card-body">

                <!-- ID -->
                <asp:HiddenField ID="hdnID" runat="server" />

                <!-- Hidden للفيديوهات الحالية -->
                <asp:HiddenField ID="hdnWorkingVideoAr" runat="server" />
                <asp:HiddenField ID="hdnWorkingVideoEn" runat="server" />
                <asp:HiddenField ID="hdnEvalVideoAr" runat="server" />
                <asp:HiddenField ID="hdnEvalVideoEn" runat="server" />

                <h6 class="fw-normal">1. الهيكل التنظيمي (إجباري)</h6>

                <div class="row g-3 mb-3">

                    <!-- Brand -->
                    <div class="col-md-3">
                        <label class="form-label">العلامة التجارية</label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                                ControlToValidate="ddlBrand" InitialValue=""
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
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
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
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
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
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
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                </div>

                <hr />

                <h6 class="fw-normal">2. بيانات الأداة</h6>

                <div class="row g-3">

                    <!-- رقم الأداة -->
                    <div class="col-md-4">
                        <label class="form-label">رقم الأداة</label>
                        <asp:TextBox ID="txtToolNumber" runat="server" CssClass="form-control" MaxLength="100" placeholder="رقم الأداة"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvToolNumber" runat="server"
                                ControlToValidate="txtToolNumber"
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <!-- نوع الأداة -->
                    <div class="col-md-4">
                        <label class="form-label">نوع الأداة</label>
                        <asp:DropDownList ID="ddlItemType" runat="server" CssClass="form-select"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvItemType" runat="server"
                                ControlToValidate="ddlItemType" InitialValue=""
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                    <!-- الشركة الموردة -->
                    <div class="col-md-4">
                        <label class="form-label">الشركة الموردة</label>
                        <asp:DropDownList ID="ddlSupplier" runat="server" CssClass="form-select"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvSupplier" runat="server"
                                ControlToValidate="ddlSupplier" InitialValue=""
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                    <!-- شركة الصيانة -->
                    <div class="col-md-4">
                        <label class="form-label">شركة الصيانة</label>
                        <asp:DropDownList ID="ddlMaintenanceCompany" runat="server" CssClass="form-select"></asp:DropDownList>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvMaintenance" runat="server"
                                ControlToValidate="ddlMaintenanceCompany" InitialValue=""
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic" />
                        </div>
                    </div>

                    <!-- العنوان بالعربية -->
                    <div class="col-md-4">
                        <label class="form-label">العنوان بالعربية</label>
                        <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="200"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                ControlToValidate="txtTitleAr"
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <!-- العنوان بالإنجليزية -->
                    <div class="col-md-4">
                        <label class="form-label">العنوان بالإنجليزية</label>
                        <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="200"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                ControlToValidate="txtTitleEn"
                                ErrorMessage="حقل اجباري" ValidationGroup="SaveForm"
                                ForeColor="Red" Display="Dynamic"></asp:RequiredFieldValidator>
                        </div>
                    </div>

                    <!-- IsActive -->
                    <div class="col-md-4">
                        <label class="form-label">الحالة</label>
                        <asp:DropDownList ID="ddlIsActive" runat="server" CssClass="form-select">
                            <asp:ListItem Text="نشط" Value="1"></asp:ListItem>
                            <asp:ListItem Text="غير نشط" Value="0"></asp:ListItem>
                        </asp:DropDownList>
                    </div>

                    <!-- رابط البلوك الإضافي -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="togglePoliciesSection()">
                                السياسات وطريقة العمل (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط لعرض/إخفاء السياسات وفيديوهات طريقة العمل والتقييم.</small>
                        </div>
                    </div>

                    <!-- البلوك المخفي -->
                    <div id="policiesSection" style="display:none;">

                        <div class="col-md-12 mt-4">
                            <label class="form-label">سياسات العمل بالعربية</label>
                            <CKEditor:CKEditorControl ID="txtPolicies_Ar" runat="server"
                                Width="100%" Height="200px" ContentsLangDirection="Rtl"></CKEditor:CKEditorControl>
                        </div>

                        <div class="col-md-12 mt-4">
                            <label class="form-label">سياسات العمل بالإنجليزية</label>
                            <CKEditor:CKEditorControl ID="txtPolicies_En" runat="server"
                                Width="100%" Height="200px" ContentsLangDirection="Ltr"></CKEditor:CKEditorControl>
                        </div>

                        <!-- فيديو طريقة العمل -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-group">
                                <label>تحديث فيديو طريقة تنفيذ المهام (اختياري)</label>
                                <div class="col-sm-9" style="width: 100%">
                                    <ajaxToolkit:AjaxFileUpload ID="WorkingMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                        MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                        OnUploadComplete="WorkingMethodVideo_UploadComplete"
                                        OnUploadStart="WorkingMethodVideo_UploadStart" />
                                    <br />
                                    <asp:Literal ID="litWorkingCurrent" runat="server"></asp:Literal>
                                </div>
                            </div>
                        </div>

                        <!-- فيديو التقييم -->
                        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-4">
                            <div class="form-group">
                                <label>تحديث فيديو طريقة تقييم المهام (اختياري)</label>
                                <div class="col-sm-9" style="width: 100%">
                                    <ajaxToolkit:AjaxFileUpload ID="EvaluationMethodVideo" AllowedFileTypes="mp4,avi,mov,wmv,jpeg,png,jpg"
                                        MaximumNumberOfFiles="1" MaxFileSize="102400" runat="server"
                                        OnUploadComplete="EvaluationMethodVideo_UploadComplete"
                                        OnUploadStart="EvaluationMethodVideo_UploadStart" />
                                    <br />
                                    <asp:Literal ID="litEvalCurrent" runat="server"></asp:Literal>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ التعديل" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />
                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق" CssClass="btn btn-label-secondary"
                        OnClick="btnCancel_Click" />
                </div>

                <%-- Popup --%>
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display:none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center"><asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal></h2>
                                <div class="swal2-html-container" style="display:block;">تم التعديل بنجاح!</div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary"
                                    OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" runat="server"
                    PopupControlID="PanelPopUp" TargetControlID="LBLPOP"
                    BackgroundCssClass="OpacityBG" />
                <asp:Label ID="LBLPOP" runat="server" />

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

</asp:Content>
