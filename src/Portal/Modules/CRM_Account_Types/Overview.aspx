<%@ Page Title="مركز إدارة العملاء" Language="vb" AutoEventWireup="false" MaintainScrollPositionOnPostBack="true" MasterPageFile="~/Site.Master" CodeBehind="Overview.aspx.vb" Inherits="CRM.CRMOverview" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">

<link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css" />
<link rel="stylesheet" href="/assets/css/crm.css?v=20260913c" />
<link rel="stylesheet" href="/assets/css/crm-list.css?v=20261017c" />
<style>
.crm-activity .crm-activity-details { min-width: 155px; max-width: 260px; white-space: normal; }
.crm-activity .crm-activity-details summary { cursor: pointer; }
.crm-activity .crm-activity-field { overflow-wrap: anywhere; }
.crm-activity .crm-activity-field dd { white-space: pre-wrap; font-size: .875rem; }
@media(min-width:769px) { .crm-activity #ERPTable td[data-title="التاريخ"] { white-space: nowrap; min-width: 140px; } }
@media(max-width:768px) { .crm-activity .crm-activity-details { flex: 1; min-width: 0; max-width: 70%; text-align: right; } }
</style>

<style>
.erp-ui .crm-overview .crm-flex { display: flex !important; }
.crm-overview .crm-overview-header { gap: .5rem 1rem; flex-wrap: wrap; margin-bottom: 1rem; }
.crm-overview .crm-stat .card-body { padding: 1.25rem; }
.crm-overview .crm-stat-content { min-width: 0; }
.crm-overview .crm-stat-title { font-size: 1rem; font-weight: 500; line-height: 1.5; }
.crm-overview .crm-stat-title a { color: inherit; }
.crm-overview .crm-stat-title a:focus-visible { outline: 2px solid var(--bs-primary, #3565bd); outline-offset: 4px; }
.crm-overview .crm-number { margin: .35rem 0 .15rem; font-size: 1.65rem; font-weight: 600; line-height: 1.25; font-variant-numeric: tabular-nums; color: var(--bs-heading-color, #39495e); }
.crm-overview .crm-stat-icon { display: grid; place-items: center; width: 48px; height: 48px; flex-shrink: 0; }
.crm-overview .crm-stat-icon i { font-size: 1.65rem; }
.crm-overview .crm-stat:focus-within { outline: 2px solid var(--bs-primary, #3565bd); outline-offset: 2px; }
</style>
</asp:Content>
<asp:Content ID="body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y crm-overview crm-shell crm-types crm-activity" dir="rtl">
  <div class="crm-overview-header crm-flex align-items-center justify-content-between">
    <h1 class="h4 mb-0">مركز إدارة العملاء</h1>
    <nav aria-label="مسار التنقل"><ol class="breadcrumb mb-0"><% If IsCRMAdministrator Then %><li class="breadcrumb-item"><a href="/modules/Brands_Dashboards/Brands_Dashboards.aspx">الرئيسية</a></li><% End If %><li class="breadcrumb-item active" aria-current="page">إدارة العملاء</li></ol></nav>
  </div>
  <asp:Literal ID="litMessage" runat="server" />
  <div class="row g-3">
    <% If IsCRMAdministrator Then %>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="ManageCRMAccountTypes.aspx">أنواع العملاء</a></h2><div class="crm-number"><asp:Literal ID="litTypes" runat="server" Text="—" /></div><small class="text-muted">إجمالي الأنواع</small></div>
        <span class="crm-stat-icon badge bg-label-primary rounded"><i class="bx bx-category" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <% End If %>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="/Modules/CRM_Accounts/ManageCRMAccounts.aspx">العملاء</a></h2><div class="crm-number"><asp:Literal ID="litAccounts" runat="server" Text="—" /></div><small class="text-muted">إجمالي العملاء</small></div>
        <span class="crm-stat-icon badge bg-label-success rounded"><i class="bx bx-buildings" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="/Modules/CRM_Contacts/ManageCRMContacts.aspx">جهات الاتصال</a></h2><div class="crm-number"><asp:Literal ID="litContacts" runat="server" Text="—" /></div><small class="text-muted">إجمالي جهات الاتصال</small></div>
        <span class="crm-stat-icon badge bg-label-warning rounded"><i class="bx bx-user" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <% If IsCRMAdministrator Then %>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="/Modules/CRM_Contract_Types/ManageCRMContractTypes.aspx">أنواع العقود</a></h2><div class="crm-number"><asp:Literal ID="litContractTypes" runat="server" Text="—" /></div><small class="text-muted">إجمالي أنواع العقود</small></div>
        <span class="crm-stat-icon badge bg-label-primary rounded"><i class="bx bx-file" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="/Modules/CRM_Payment_Methods/ManageCRMPaymentMethods.aspx">طرق الدفع</a></h2><div class="crm-number"><asp:Literal ID="litPaymentMethods" runat="server" Text="—" /></div><small class="text-muted">إجمالي طرق الدفع</small></div>
        <span class="crm-stat-icon badge bg-label-success rounded"><i class="bx bx-wallet" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="/Modules/CRM_WorkGuide/ManageCRMWorkGuide.aspx">دليل العمل</a></h2><div class="crm-number"><asp:Literal ID="litWorkGuide" runat="server" Text="—" /></div><small class="text-muted">الأدلة المشتركة</small></div>
        <span class="crm-stat-icon badge bg-label-warning rounded"><i class="bx bx-book-open" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
    <% End If %>
    <div class="col-12 col-sm-6 col-xl-3"><div class="card crm-stat h-100"><div class="card-body">
      <div class="crm-flex align-items-start justify-content-between gap-3">
        <div class="crm-stat-content"><h2 class="crm-stat-title mb-0"><a class="stretched-link" href="#crmActivity">سجل النشاطات</a></h2><div class="crm-number"><asp:Literal ID="litActivity" runat="server" Text="—" /></div><small class="text-muted">الإدارة وبوابة العميل</small></div>
        <span class="crm-stat-icon badge bg-label-info rounded"><i class="bx bx-history" aria-hidden="true"></i></span>
      </div>
    </div></div></div>
  </div>
  <p class="text-muted small mt-2 mb-0">أعداد العناصر للسجلات غير المحذوفة، بما فيها الموقوفة. سجل النشاطات يعرض العمليات المتاحة لك.</p>
<section id="crmActivity" class="mt-4" aria-labelledby="crmActivityTitle">
 <asp:Panel ID="pnlBody" runat="server"><div class="card">
  <div class="card-header type-filter-header"><h2 class="card-title h5 mb-0" id="crmActivityTitle">سجل النشاطات — الإدارة وبوابة العميل</h2>
   <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="row g-3 align-items-end">
    <div class="col-12 col-md-6 col-xl-4"><asp:DropDownList ID="filterAccount" runat="server" data-crm-search-select="بحث باسم العميل..." CssClass="form-select" aria-label="العميل" /></div>
    <div class="col-12 col-md-6 col-xl-4"><asp:DropDownList ID="filterActor" runat="server" CssClass="form-select" aria-label="المنفّذ" /></div>
    <div class="col-12 col-md-6 col-xl-4"><asp:DropDownList ID="filterSource" runat="server" CssClass="form-select" aria-label="المصدر"><asp:ListItem Value="" Text="كل المصادر" /><asp:ListItem Value="إدارة النظام" Text="إدارة النظام" /><asp:ListItem Value="بوابة العميل" Text="بوابة العميل" /></asp:DropDownList></div>
    <div class="col-12 col-md-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="filterFrom" CssClass="form-label" Text="من تاريخ" /><asp:TextBox ID="filterFrom" runat="server" CssClass="form-control" TextMode="Date" /></div>
    <div class="col-12 col-md-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="filterTo" CssClass="form-label" Text="إلى تاريخ" /><asp:TextBox ID="filterTo" runat="server" CssClass="form-control" TextMode="Date" /></div>
    <div class="col-12 col-md-6 col-xl-4"><asp:DropDownList ID="filterEntity" runat="server" CssClass="form-select" aria-label="القسم"><asp:ListItem Value="" Text="كل الأقسام" /><asp:ListItem Value="Account_Types" Text="أنواع العملاء" /><asp:ListItem Value="Contract_Types" Text="أنواع العقود" /><asp:ListItem Value="Payment_Methods" Text="طرق الدفع" /><asp:ListItem Value="Accounts" Text="العملاء" /><asp:ListItem Value="Contacts" Text="جهات الاتصال" /><asp:ListItem Value="WorkGuide_Items" Text="دليل العمل" /><asp:ListItem Value="WorkGuide_Permissions" Text="صلاحيات دليل العمل" /><asp:ListItem Value="WorkGuide_Categories" Text="تصنيفات دليل العمل" /><asp:ListItem Value="News" Text="الأخبار" /><asp:ListItem Value="Customer_Session" Text="دخول العملاء" /></asp:DropDownList></div>
    <div class="col-12 col-md-6 col-xl-2 type-flex gap-2"><asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-icon btn-label-secondary" OnClick="Search_Click" CausesValidation="false" ToolTip="بحث" aria-label="بحث" data-bs-toggle="tooltip"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i></asp:LinkButton><a class="btn btn-icon btn-label-secondary" href="Overview.aspx#crmActivity" title="إعادة تعيين" aria-label="إعادة تعيين" data-bs-toggle="tooltip"><i class="fa-solid fa-rotate-left" aria-hidden="true"></i></a></div>
   </asp:Panel>
   <p class="small text-muted mt-3 mb-0">تُعرض الأوقات بتوقيت الأردن. افتح تفاصيل قبل وبعد؛ الحقول المتغيّرة مميزة باللون.</p>
  </div>
  <div class="card-datatable table-responsive"><table id="ERPTable" data-enhanced="1" class="ERP_ProstoTBL card-list-table table border-top crm-table"><thead><tr><th>التاريخ</th><th>المنفّذ</th><th>المصدر</th><th>العميل</th><th>القسم</th><th>رقم السجل</th><th>الإجراء</th><th>ملاحظات</th><th data-orderable="false">قبل التعديل</th><th data-orderable="false">بعد التعديل</th></tr></thead><tbody><asp:ListView ID="lstData" runat="server" DataKeyNames="ID"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate><ItemTemplate><tr><td data-order='<%# Eval("AddedDate", "{0:yyyyMMddHHmmss}") %>' data-title="التاريخ"><%#: Eval("AddedDate", "{0:dd/MM/yyyy HH:mm:ss}") %></td><td data-title="المنفّذ"><%#: Eval("User_Name") %></td><td data-title="المصدر"><%#: Eval("Source_Name") %></td><td data-title="العميل"><%#: Eval("Account_Name") %></td><td data-title="القسم"><%#: EntityTitle(Eval("Entity")) %></td><td data-title="رقم السجل"><%#: Eval("Record_ID") %></td><td data-title="الإجراء"><%#: ActivityActionTitle(Eval("Action")) %></td><td data-title="ملاحظات"><%#: Eval("Note") %></td><td data-title="قبل التعديل"><%# SnapshotDetails(Eval("Before_Data"), Eval("After_Data")) %></td><td data-title="بعد التعديل"><%# SnapshotDetails(Eval("After_Data"), Eval("Before_Data")) %></td></tr></ItemTemplate></asp:ListView></tbody></table></div>
 </div></asp:Panel>
</section>
</div>
<script src="/assets/js/crm-list.js?v=20261021suppliers"></script>
</asp:Content>
