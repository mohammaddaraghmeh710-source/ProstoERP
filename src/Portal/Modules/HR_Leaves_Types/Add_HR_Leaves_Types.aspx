<%@ Page Title="إضافة - أنواع المغادرات" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Add_HR_Leaves_Types.aspx.vb" Inherits="CRM.Add_HR_Leaves_Types" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="card-title mb-0">إضافة - أنواع المغادرات</h5>
                <a class="btn btn-outline-secondary" href="Manage_HR_Leaves_Types.aspx">رجوع</a>
            </div>
            <div class="card-body">
                <asp:Literal ID="litMessage" runat="server" />
                <div class="row g-3">
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtCoreID" CssClass="form-label" Text="رقم النوع في النظام الأساسي (Core_ID)" />
                        <asp:TextBox ID="txtCoreID" runat="server" CssClass="form-control" MaxLength="11" dir="ltr" />
                    </div>
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtMaxValue" CssClass="form-label" Text="الحد الأقصى (ساعات)" />
                        <asp:TextBox ID="txtMaxValue" runat="server" CssClass="form-control" MaxLength="12" dir="ltr" />
                        <small class="text-muted">ساعات أكبر من صفر؛ مثال: 1.50 تعني ساعة ونصف.</small>
                    </div>
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtNameAR" CssClass="form-label" Text="الاسم بالعربية" />
                        <asp:TextBox ID="txtNameAR" runat="server" CssClass="form-control" MaxLength="200" />
                    </div>
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtNameEn" CssClass="form-label" Text="الاسم بالإنجليزية" />
                        <asp:TextBox ID="txtNameEn" runat="server" CssClass="form-control" MaxLength="200" dir="ltr" />
                    </div>
                    <div class="col-12">
                        <asp:CheckBox ID="chkIsActive" runat="server" Text=" فعال" Checked="true" />
                    </div>
                </div>
                <hr class="my-4" />
                <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-primary" OnClick="btnSave_Click" Text="حفظ" />
                <a class="btn btn-outline-secondary" href="Manage_HR_Leaves_Types.aspx">إلغاء</a>
            </div>
        </div>
    </div>
</asp:Content>