<%@ Page Title="لوحة إدارة المراسلات" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Dashboard.aspx.vb" Inherits="CRM.CorrespondenceDashboard" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
 <link rel="stylesheet" href="/assets/css/crm.css?v=20261017" />
 <link rel="stylesheet" href="/assets/css/crm-list.css?v=20261017c" />
</asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
 <div class="container-xxl flex-grow-1 container-p-y crm-shell crm-types" dir="rtl">
  <div class="type-flex type-page-header align-items-center justify-content-between">
   <div><h1 class="h4 mb-1">لوحة إدارة المراسلات</h1><p class="text-muted small mb-0">إحصائيات المراسلات والتكليفات وإعداداتها من مكان واحد.</p></div>
   <a class="btn btn-primary" href="ManageCorrespondence.aspx"><i class="fa-solid fa-comments me-1" aria-hidden="true"></i>مراسلاتي</a>
  </div>
  <asp:Literal ID="litMessage" runat="server" />
  <asp:Literal ID="litMetrics" runat="server" />
  <div class="row g-3 mb-3" aria-label="إدارة المراسلات"><asp:Repeater ID="rptLinks" runat="server"><ItemTemplate>
   <div class="col-12 col-md-4"><section class="card h-100"><div class="card-body type-flex align-items-center gap-3 p-3">
    <span class="avatar flex-shrink-0"><span class='<%# "avatar-initial rounded bg-label-" & Eval("Color") %>'><i class='<%# "fa-solid " & Eval("Icon") %>' aria-hidden="true"></i></span></span>
    <div class="flex-grow-1"><h2 class="h6 mb-1"><a class="stretched-link text-body" href='<%# Eval("Url") %>'><%#: Eval("Title") %></a></h2><p class="small text-muted mb-0"><%#: Eval("Description") %></p></div>
   </div></section></div>
  </ItemTemplate></asp:Repeater></div>
  <div class="row g-3">
   <div class="col-12 col-lg-6"><section class="card h-100"><div class="card-header py-3"><h2 class="h6 mb-1"><i class="fa-solid fa-chart-pie text-primary me-1" aria-hidden="true"></i>حالة المراسلات</h2><p class="small text-muted mb-0">توزيع المراسلات حسب الحالة الحالية.</p></div><div class="card-body pt-0"><asp:Literal ID="litStatusChart" runat="server" /></div></section></div>
   <div class="col-12 col-lg-6"><section class="card h-100"><div class="card-header py-3"><h2 class="h6 mb-1"><i class="fa-solid fa-envelope text-info me-1" aria-hidden="true"></i>أنواع المراسلات</h2><p class="small text-muted mb-0">المراسلات العادية والتكليفات من إجمالي المراسلات.</p></div><div class="card-body pt-0"><asp:Literal ID="litKindChart" runat="server" /></div></section></div>
  </div>
 </div><script src="/assets/js/correspondence-dashboard.js?v=20261022a"></script>
</asp:Content>
