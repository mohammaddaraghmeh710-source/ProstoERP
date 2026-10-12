<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="EditWorkGuide_Documents.aspx.vb" Inherits="CRM.EditWorkGuide_Documents" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">تعديل ملف دليل العمل</h5>

            <div class="card-body">

                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">العلامة التجارية</label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                            ControlToValidate="ddlBrand"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">التصنيف</label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvCategory" runat="server"
                            ControlToValidate="ddlCategory"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">العنوان بالعربية</label>
                        <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>

                        <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                            ControlToValidate="txtTitleAr"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">العنوان بالإنجليزية</label>
                        <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الترتيب</label>
                        <asp:TextBox ID="txtItemOrder" runat="server" CssClass="form-control" TextMode="Number"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label d-block">الحالة</label>
                        <label class="switch switch-primary">
                            <input type="checkbox" id="cbIsActive" runat="server" class="switch-input" checked="checked" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"></span>
                                <span class="switch-off"></span>
                            </span>
                            <span class="switch-label">فعال</span>
                        </label>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالعربية</label>
                        <asp:TextBox ID="txtDescriptionAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالإنجليزية</label>
                        <asp:TextBox ID="txtDescriptionEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الملف الحالي</label>
                        <div class="alert alert-secondary mb-0">
                          <asp:HyperLink ID="lnkCurrentFile" runat="server"
    CssClass="btn btn-label-primary"
    Target="_blank"
    Text="اضغط لمشاهدة الملف">
</asp:HyperLink>
                        </div>
                    </div>

                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-3">
                        <div class="form-group">
                            <label class="form-label">استبدال ملف PDF</label>

                            <ajaxToolkit:AjaxFileUpload ID="WorkGuidePDF"
                                AllowedFileTypes="pdf"
                                MaximumNumberOfFiles="1"
                                MaxFileSize="51200"
                                runat="server"
                                OnUploadComplete="WorkGuidePDF_UploadComplete"
                                OnUploadStart="WorkGuidePDF_UploadStart" />

                            <br />
                            <span class="text-danger">اترك هذا الحقل فارغًا إذا كنت لا تريد تغيير الملف الحالي.</span>
                        </div>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ التعديلات" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق" CssClass="btn btn-label-secondary"
                        CausesValidation="false" OnClick="btnCancel_Click" />
                </div>

            </div>
        </div>
    </div>

</asp:Content>