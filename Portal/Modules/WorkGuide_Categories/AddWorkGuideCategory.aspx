<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddWorkGuideCategory.aspx.vb" Inherits="CRM.AddWorkGuideCategory" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">



    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة تصنيف جديد لدليل العمل</h5>

            <div class="card-body">
                <h6 class="fw-normal">1. بيانات التصنيف</h6>

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
                        <label class="form-label">التصنيف الأب</label>
                        <asp:DropDownList ID="ddlParentCategory" runat="server" CssClass="form-select">
                        </asp:DropDownList>
                        <small class="text-muted">اتركه بدون تحديد إذا كان التصنيف رئيسيًا.</small>
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

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالعربية</label>
                        <asp:TextBox ID="txtDescriptionAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالإنجليزية</label>
                        <asp:TextBox ID="txtDescriptionEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إلغاء" CssClass="btn btn-label-secondary"
                        CausesValidation="false" OnClick="btnCancel_Click" />
                </div>

            </div>
        </div>
    </div>

</asp:Content>