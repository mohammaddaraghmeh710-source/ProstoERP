<%@ Page Title="تعديل - أنواع الموظفين" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Edit_Users_Types.aspx.vb" Inherits="CRM.Edit_Users_Types" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="card-title mb-0">تعديل - أنواع الموظفين</h5>
                <a class="btn btn-outline-secondary" href="Manage_Users_Types.aspx">رجوع</a>
            </div>
            <div class="card-body">
                <asp:Literal ID="litMessage" runat="server" />
                <div class="row g-3">
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtOrder" CssClass="form-label" Text="الترتيب (اختياري)" />
                        <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" MaxLength="10" dir="ltr" />
                    </div>
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtNameAR" CssClass="form-label" Text="الاسم بالعربية" />
                        <asp:TextBox ID="txtNameAR" runat="server" CssClass="form-control" />
                    </div>
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtNameEn" CssClass="form-label" Text="الاسم بالإنجليزية" />
                        <asp:TextBox ID="txtNameEn" runat="server" CssClass="form-control" dir="ltr" />
                    </div>
                    <div class="col-12">
                        <asp:CheckBox ID="chkIsActive" runat="server" Text=" فعال" Checked="true" />
                    </div>
                </div>
                <hr class="my-4" />
                <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-primary" OnClick="btnSave_Click" Text="حفظ" />
                <a class="btn btn-outline-secondary" href="Manage_Users_Types.aspx">إلغاء</a>
            </div>
        </div>
    </div>
</asp:Content>