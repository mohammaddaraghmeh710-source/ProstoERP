<%@ Page Title="صفحة معلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="View.aspx.vb" Inherits="CRM.ViewInformationPage" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server"><style>.information-content{overflow-wrap:anywhere;overflow-x:auto;line-height:1.9}.information-content table{border-collapse:collapse;width:100%;margin:1rem 0}.information-content td,.information-content th{border:1px solid #ddd;padding:.6rem}.information-content blockquote{border-inline-start:3px solid #696cff;padding-inline-start:1rem}</style></asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><div class="container-xxl flex-grow-1 container-p-y" dir='<%= If(English,"ltr","rtl") %>' lang='<%= If(English,"en","ar") %>'>
<asp:Literal ID="litMessage" runat="server" /><asp:Panel ID="pnlPage" runat="server" Visible="false">
<asp:Panel ID="pnlPreview" runat="server" Visible="false" CssClass="alert alert-warning">معاينة إدارية — قد لا يكون هذا الإصدار متاحًا للمستخدمين. <asp:HyperLink ID="lnkHistory" runat="server" Text="الإصدارات والسجلات" /></asp:Panel>
<article class="card">
    <header class="card-header border-bottom p-lg-5 d-flex justify-content-between align-items-start flex-wrap gap-3">
        <div style="min-width:0;overflow-wrap:anywhere">
            <h2 class="mb-3"><asp:Literal ID="litTitle" runat="server" Mode="Encode" /></h2>
            <div class="d-flex flex-wrap align-items-center gap-3 text-muted">
                <span class="badge bg-label-primary"><asp:Literal ID="litVersion" runat="server" Mode="Encode" /></span>
                <span><%= If(English,"Version date: ","تاريخ الإصدار: ") %><bdi><asp:Literal ID="litVersionDate" runat="server" Mode="Encode" /></bdi></span>
            </div>
        </div>
        <asp:HyperLink ID="lnkLanguage" runat="server" CssClass="btn btn-outline-primary flex-shrink-0" />
    </header>
    <div class="card-body p-lg-5"><div class="information-content"><asp:Literal ID="litDetails" runat="server" /></div></div>
</article>
</asp:Panel></div></asp:Content>
