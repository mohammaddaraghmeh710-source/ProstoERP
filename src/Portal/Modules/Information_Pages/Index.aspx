<%@ Page Title="الصفحات المعلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Index.aspx.vb" Inherits="CRM.InformationPagesIndex" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir='<%=If(English, "ltr", "rtl")%>' lang='<%=If(English, "en", "ar")%>'>
<div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4"><h4 class="mb-0"><%=If(English, "Information pages", "الصفحات المعلوماتية")%></h4><div><a href="Index.aspx?lang=ar" class="btn btn-outline-secondary">العربية</a> <a href="Index.aspx?lang=en" class="btn btn-outline-secondary">English</a><% If IsAdministrator Then%> <a href="Manage.aspx" class="btn btn-primary">إدارة الصفحات</a><% End If%></div></div>
<asp:Literal ID="litMessage" runat="server" />
<p><%=If(English, "Choose a page directly from the Information pages menu.", "اختر الصفحة مباشرة من قائمة الصفحات المعلوماتية لقراءة محتواها.")%></p>
<asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="alert alert-info"><%=If(English, "No published pages are currently available.", "لا توجد صفحات منشورة متاحة حاليًا.")%></asp:Panel>
</div></asp:Content>
