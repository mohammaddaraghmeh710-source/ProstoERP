<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="EditUsers.aspx.vb" Inherits="CRM.EditUsers" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <%-- تأكد من وجود ScriptManager في الماستر --%>

    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div class="container-xxl flex-grow-1 container-p-y">
                <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
                    <h5 class="card-header">تعديل بيانات المستخدم</h5>
                    <div class="card-body">

                        <h6 class="fw-normal">1. نوع المستخدم</h6>
                        <div class="row g-3 mb-4">
                            <div class="col-md-4">
                                <label class="form-label">نوع المستخدم</label>
                                <asp:DropDownList ID="ddlUserType" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlUserType_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>
                        </div>

                        <h6 class="fw-normal">2. بيانات المستخدم</h6>

                        <asp:Panel ID="pnlBasicInfo" runat="server" Visible="true">
                            <div class="row g-3">

                                <div class="col-md-4">
                                    <label class="form-label">رقم الموظف</label>
                                    <asp:TextBox ID="txtEmployeeNumber" runat="server" CssClass="form-control" />
                                    <asp:RequiredFieldValidator ID="rfvEmpNo" runat="server"
                                        ControlToValidate="txtEmployeeNumber"
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">الاسم بالعربية</label>
                                    <asp:TextBox ID="txtFullNameAr" runat="server" CssClass="form-control" />
                                    <asp:RequiredFieldValidator ID="rfvNameAr" runat="server"
                                        ControlToValidate="txtFullNameAr"
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">الاسم بالإنجليزية</label>
                                    <asp:TextBox ID="txtFullNameEn" runat="server" CssClass="form-control" />
                                    <asp:RequiredFieldValidator ID="rfvNameEn" runat="server"
                                        ControlToValidate="txtFullNameEn"
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">رقم الهاتف</label>
                                    <asp:TextBox ID="txtPhone" runat="server" CssClass="form-control" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">رقم الجوال</label>
                                    <asp:TextBox ID="txtMobile" runat="server" CssClass="form-control" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">البريد الإلكتروني</label>
                                    <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">اسم المستخدم</label>
                                    <asp:TextBox ID="txtUserName" runat="server" CssClass="form-control" />
                                    <asp:RequiredFieldValidator ID="rfvUserName" runat="server"
                                        ControlToValidate="txtUserName"
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <div class="col-md-4">
                                    <label class="form-label">كلمة المرور</label>
                                    <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" />
                                    <asp:RequiredFieldValidator ID="rfvPassword" runat="server"
                                        ControlToValidate="txtPassword"
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                    <!-- نخزن الباسورد الحقيقية هنا -->
                                    <asp:HiddenField ID="hdnPassword" runat="server" />
                                </div>


                                <!-- الحالة -->
                                <div class="col-md-4">
                                    <label class="form-label">حالة المستخدم</label>
                                    <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select"></asp:DropDownList>
                                    <asp:RequiredFieldValidator ID="rfvStatus" runat="server"
                                        ControlToValidate="ddlStatus"
                                        InitialValue=""
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <!-- الجنس -->
                                <div class="col-md-4">
                                    <label class="form-label">الجنس</label>
                                    <asp:DropDownList ID="ddlGender" runat="server" CssClass="form-select"></asp:DropDownList>
                                    <asp:RequiredFieldValidator ID="rfvGender" runat="server"
                                        ControlToValidate="ddlGender"
                                        InitialValue=""
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <!-- الجنسية -->
                                <div class="col-md-4">
                                    <label class="form-label">الجنسية</label>
                                    <asp:DropDownList ID="ddlNationality" runat="server" CssClass="form-select"></asp:DropDownList>
                                    <asp:RequiredFieldValidator ID="rfvNationality" runat="server"
                                        ControlToValidate="ddlNationality"
                                        InitialValue=""
                                        ErrorMessage="حقل إجباري"
                                        ValidationGroup="SaveForm"
                                        Display="Dynamic"
                                        ForeColor="Red" />
                                </div>

                                <!-- صورة المستخدم الحالية + تغيير -->
                                <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                                    <asp:HiddenField ID="hdnUserImage" runat="server" />
                                    <div class="form-group mb-2">
                                        <label>صورة المستخدم الحالية</label><br />
                                        <asp:Image ID="imgUser" runat="server" Width="120" CssClass="img-thumbnail" />
                                    </div>

                                    <div class="form-group">
                                        <label>تغيير صورة المستخدم (اختياري)</label>
                                        <div style="width:100%">
                                            <cc1:AjaxFileUpload AutoStartUpload="true" ID="UserImageUpload"
                                                runat="server"
                                                AllowedFileTypes="jpeg,jpg,png"
                                                MaximumNumberOfFiles="1"
                                                MaxFileSize="100024"
                                                OnUploadComplete="UserImageUpload_UploadComplete"
                                                OnUploadStart="UserImageUpload_UploadStart" />
                                            <br />
                                            <span class="text-danger">يمكن تحميل الملفات من نوع (jpeg,jpg,png)</span>
                                        </div>
                                    </div>
                                </div>

                                <!-- تفعيل الحساب -->
                                <div class="col-md-4">
                                    <label class="form-label d-block">تفعيل المستخدم</label>
                                    <label class="switch switch-square">
                                        <input id="cbIsActive" runat="server" type="checkbox" class="switch-input" />
                                        <span class="switch-toggle-slider">
                                            <span class="switch-on"><i class="bx bx-check"></i></span>
                                            <span class="switch-off"><i class="bx bx-x"></i></span>
                                        </span>
                                        <span class="switch-label">فعال</span>
                                    </label>
                                </div>


                            </div>
                        </asp:Panel>

                        <!-- الهيكل التنظيمي -->
                        <div class="row g-3 mt-2">

                            <asp:Panel ID="pnlBrand" runat="server" Visible="false" CssClass="col-md-4">
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

                            <asp:Panel ID="pnlBranch" runat="server" Visible="false" CssClass="col-md-4">
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

                            <asp:Panel ID="pnlDepartment" runat="server" Visible="false" CssClass="col-md-4">
                                <label class="form-label">القسم</label>
                                <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlDepartment_SelectedIndexChanged">
                                </asp:DropDownList>
                                <asp:RequiredFieldValidator ID="rfvDepartment" runat="server"
                                    ControlToValidate="ddlDepartment"
                                    InitialValue=""
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red"
                                    Enabled="false" />
                            </asp:Panel>

                            <asp:Panel ID="pnlJobTitle" runat="server" Visible="false" CssClass="col-md-4">
                                <label class="form-label">المحطة التعريفية</label>
                                <asp:DropDownList ID="ddlJobTitle" runat="server" CssClass="form-select"></asp:DropDownList>
                                <asp:RequiredFieldValidator ID="rfvJobTitle" runat="server"
                                    ControlToValidate="ddlJobTitle"
                                    InitialValue=""
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red"
                                    Enabled="false" />
                            </asp:Panel>

                            <asp:Panel ID="pnlShift" runat="server" Visible="false" CssClass="col-md-4">
                                <label class="form-label">الوردية</label>
                                <asp:DropDownList ID="ddlShift" runat="server" CssClass="form-select"></asp:DropDownList>
                                <asp:RequiredFieldValidator ID="rfvShift" runat="server"
                                    ControlToValidate="ddlShift"
                                    InitialValue=""
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red"
                                    Enabled="false" />
                            </asp:Panel>

                        </div>

                        <div class="pt-4">
                            <asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary me-sm-3 me-1"
                                ValidationGroup="SaveForm" OnClick="btnSave_Click" />
                            <asp:Button ID="btnCancel" runat="server" Text="إغلاق" CssClass="btn btn-label-secondary"
                                OnClick="btnCancel_Click" />
                        </div>

                        <!-- Popup -->
                        <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display:none;" DefaultButton="btnClosePopup">
                            <div class="modal-dialog modal-dialog-centered" role="document">
                                <div class="modal-content">
                                    <div class="text-center m-4">
                                        <img src="/assets/img/Prosto/Success_Icon.png" />
                                    </div>
                                    <div class="modal-body">
                                        <h2 class="text-center">
                                            <asp:Literal ID="Literal1" runat="server">شكراً لك!</asp:Literal>
                                        </h2>
                                        <div class="swal2-html-container" style="display:block;">تم التعديل بنجاح!</div>
                                    </div>
                                    <div class="text-center m-4">
                                        <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق"
                                            CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                                    </div>
                                </div>
                            </div>
                        </asp:Panel>
                        <cc1:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" runat="server"
                            PopupControlID="PanelPopUp"
                            TargetControlID="LBLPOP"
                            BackgroundCssClass="OpacityBG" />
                        <asp:Label ID="LBLPOP" runat="server" />

                    </div>
                </div>
            </div>

        </ContentTemplate>
    </asp:UpdatePanel>

</ContentTemplate></asp:UpdatePanel></asp:Content>
