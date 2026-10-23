<%@ Page Title="لوحة إدارة الشكاوى" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Dashboard.aspx.vb" Inherits="CRM.EmployeeFeedbackDashboard" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
 <link rel="stylesheet" href="/assets/vendor/fonts/fontawesome.css"/><link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css"/><link rel="stylesheet" href="/assets/css/crm.css"/><link rel="stylesheet" href="/assets/css/crm-list.css"/>
 <link rel="stylesheet" href="/assets/css/feedback-dashboard.css?v=20261021a" />
</asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
 <div class="container-xxl flex-grow-1 container-p-y feedback-admin crm-shell crm-types" dir="rtl">
  <div class="feedback-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
   <div><h1 class="h4 mb-1">لوحة إدارة الشكاوى والاقتراحات</h1><p class="text-muted mb-0 small">متابعة الطلبات وإجراءات المعالجة وإعداداتها من مكان واحد.</p></div>
   <a class="btn btn-primary" href="ManageEmployeeFeedback.aspx"><i class="bx bx-list-ul me-1" aria-hidden="true"></i>متابعة الطلبات</a>
  </div>
  <asp:Literal ID="litMessage" runat="server" />
  <asp:Literal ID="litMetrics" runat="server" />
  <div class="row g-3 mb-4" aria-label="إدارة الشكاوى">
   <asp:Repeater ID="rptLinks" runat="server"><ItemTemplate>
    <div class="col-12 col-sm-6 col-xl-4"><section class="card h-100 feedback-entry"><div class="card-body feedback-flex align-items-center gap-3 p-3">
     <span class='avatar flex-shrink-0'><span class='<%# "avatar-initial rounded bg-label-" & Eval("Color") %>'><i class='<%# "bx " & Eval("Icon") %>' aria-hidden="true"></i></span></span>
     <div class="flex-grow-1"><h2 class="h6 mb-1"><a class="stretched-link text-body" href='<%# Eval("Url") %>'><%#: Eval("Title") %></a></h2><p class="small text-muted mb-0"><%#: Eval("Description") %></p></div><i class="bx bx-chevron-left text-muted" aria-hidden="true"></i>
    </div></section></div>
   </ItemTemplate></asp:Repeater>
  </div>
  <div class="row g-3 mb-4"><div class="col-12 col-lg-7"><section class="card h-100"><div class="card-header py-3"><h2 class="h6 mb-0">حالة الطلبات</h2></div><div class="card-body pt-0"><asp:Literal ID="litDistribution" runat="server" /></div></section></div><div class="col-12 col-lg-5"><section class="card h-100"><div class="card-header py-3"><h2 class="h6 mb-0">مصادر الطلبات</h2></div><div class="card-body pt-0"><asp:Literal ID="litSources" runat="server" /></div></section></div></div>
  <section class="card"><div class="card-header py-3 feedback-flex justify-content-between flex-wrap gap-2 align-items-center"><div><h2 class="h5 mb-1">الأولوية للطلبات بانتظار إجرائك</h2><p class="small text-muted mb-0">أحدث 20 طلبًا، مع إبراز ما يستلزم إجراءً منك.</p></div><a class="btn btn-sm btn-label-primary" href="ManageEmployeeFeedback.aspx?view=todo">عرض طلبات الإجراء</a></div>
   <div class="card-datatable table-responsive"><table id="ERPTable" data-enhanced="1" class="ERP_ProstoTBL table border-top crm-table card-list-table feedback-admin-table mb-0"><thead><tr><th>الطلب</th><th>مقدّم الطلب / الفرع</th><th>الحالة</th><th>الجهة الحالية</th><th>التاريخ</th><th data-orderable="false">الإجراءات</th></tr></thead><tbody>
    <asp:Repeater ID="rptRequests" runat="server"><ItemTemplate><tr class='<%# If(NeedsAction(Eval("ID")),"feedback-action-required","") %>'>
     <td data-title="الطلب"><div class="type-record-name"><a class="fw-semibold text-body" href='<%# DetailLink(Eval("ID")) %>'>#<%#: Eval("ID") %> · <%#: Eval("Title") %></a><div class="small text-muted mt-1"><%#: CRM.EmployeeFeedbackData.TypeText(Eval("Type")) %></div><asp:Label runat="server" Visible='<%# NeedsAction(Eval("ID")) %>' CssClass="badge bg-label-warning mt-1" Text="بانتظار إجرائك" /></div></td>
     <td data-title="مقدّم الطلب / الفرع"><div class="type-cell-details"><%#: Eval("EmployeeName") %><div class="small text-muted"><%#: Eval("BrandName") %> · <%#: Eval("BranchName") %></div></div></td>
     <td data-title="الحالة"><span class='<%# CRM.EmployeeFeedbackData.StatusCss(Eval("Status")) %>'><%#: CRM.EmployeeFeedbackData.StatusText(Eval("Status")) %></span></td>
     <td data-title="الجهة الحالية"><%#: Eval("CurrentRecipient") %></td><td data-title="التاريخ"><%#: CRM.CorrespondenceData.DisplayDate(Eval("AddedDate")) %></td>
     <td data-title="الإجراءات"><div class="type-flex type-row-actions"><a class="btn btn-sm btn-icon type-row-action text-secondary" href='<%# DetailLink(Eval("ID")) %>' title="تفاصيل الطلب" aria-label="تفاصيل الطلب" data-bs-toggle="tooltip"><i class="fa-solid fa-eye" aria-hidden="true"></i></a></div></td>
    </tr></ItemTemplate></asp:Repeater>
   </tbody></table></div><asp:Panel ID="pnlEmpty" runat="server" Visible="false" hidden="hidden" CssClass="text-center text-muted p-4">لا توجد طلبات حتى الآن.</asp:Panel>
  </section>
 </div>
<script src="/assets/js/crm-list.js?v=20261021suppliers"></script></asp:Content>
