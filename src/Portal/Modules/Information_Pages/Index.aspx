<%@ Page Title="الصفحات المعلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Index.aspx.vb" Inherits="CRM.InformationPagesIndex" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir='<%= If(English,"ltr","rtl") %>' lang='<%= If(English,"en","ar") %>'>
<div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4"><h4 class="mb-0"><%= If(English,"Information pages","الصفحات المعلوماتية") %></h4><div><a href="Index.aspx?lang=ar" class="btn btn-outline-secondary">العربية</a> <a href="Index.aspx?lang=en" class="btn btn-outline-secondary">English</a><% If IsAdministrator Then %> <a href="Manage.aspx" class="btn btn-primary">إدارة الصفحات</a><% End If %></div></div>
<asp:Literal ID="litMessage" runat="server" />
<div class="row g-3"><asp:Repeater ID="pages" runat="server"><ItemTemplate><div class="col-12 col-md-6"><article class="card h-100"><div class="card-body"><h2 class="h5"><%#: Eval(If(English,"Title_En","Title_Ar")) %></h2><p class="text-muted"><%#: Eval(If(English,"Summary_En","Summary_Ar")) %></p><a class="btn btn-sm btn-label-primary" href='<%# "View.aspx?ID=" & Eval("ID").ToString() & If(English,"&lang=en","") %>'><%# If(English,"View page","عرض الصفحة") %></a></div></article></div></ItemTemplate></asp:Repeater></div>
<asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="alert alert-info"><%= If(English,"No published pages are currently available.","لا توجد صفحات منشورة متاحة حاليًا.") %></asp:Panel>
</div></asp:Content>
