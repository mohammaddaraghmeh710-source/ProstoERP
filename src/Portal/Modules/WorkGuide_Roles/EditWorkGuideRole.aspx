<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="EditWorkGuideRole.aspx.vb" Inherits="CRM.EditWorkGuideRole" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">تعديل صلاحية دليل العمل</h5>

            <div class="card-body">
                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">الاسم بالعربية</label>
                        <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                            ControlToValidate="txtTitleAr"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الاسم بالإنجليزية</label>
                        <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الكود</label>
                        <asp:TextBox ID="txtCode" runat="server" CssClass="form-control" MaxLength="100"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvCode" runat="server"
                            ControlToValidate="txtCode"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label d-block">الحالة</label>
                        <label class="switch switch-primary">
                            <input type="checkbox" id="cbIsActive" runat="server" class="switch-input" checked="true" />
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

                    <div class="col-12 mt-4">
                        <h6 class="fw-normal">صلاحيات الاطلاع</h6>
                    </div>

                    <div class="col-md-3">
                        <div class="form-check">
                            <asp:CheckBox ID="chkViewCategory" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="<%=chkViewCategory.ClientID%>">عرض التصنيفات</label>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="form-check">
                            <asp:CheckBox ID="chkViewDocument" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="<%=chkViewDocument.ClientID%>">عرض الملفات</label>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="form-check">
                            <asp:CheckBox ID="chkPrintDocument" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="<%=chkPrintDocument.ClientID%>">طباعة الملف</label>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="form-check">
                            <asp:CheckBox ID="chkDownloadDocument" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="<%=chkDownloadDocument.ClientID%>">تحميل الملف</label>
                        </div>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ التعديلات" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إلغاء" CssClass="btn btn-label-secondary"
                        CausesValidation="false" OnClick="btnCancel_Click" />
                </div>

            </div>
        </div>
    </div>

</asp:Content>