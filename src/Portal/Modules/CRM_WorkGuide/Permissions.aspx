<%@ Page Title="صلاحيات دليل العمل" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Permissions.aspx.vb" Inherits="CRM.CRMWorkGuidePermissions" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="stylesheet" href="/assets/vendor/libs/jstree/jstree.css"/><link rel="stylesheet" href="/assets/css/crm-workguide.css?v=20261018c"/><link rel="stylesheet" href="/assets/css/crm.css"/><link rel="stylesheet" href="/assets/css/crm-list.css"/>
</asp:Content>
<asp:Content ID="body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl container-p-y crm-shell crm-types" dir="rtl">
 <div class="type-page-header type-flex align-items-center justify-content-between"><h1 class="h4 mb-0">صلاحيات دليل العمل</h1><a href="ManageCRMWorkGuide.aspx">دليل العمل</a></div>
 <asp:Literal ID="litMessage" runat="server" EnableViewState="false"/>
 <asp:Panel ID="pnlBody" runat="server">
  <div class="card mb-4"><div class="card-body"><div class="row g-3 align-items-center"><div class="col-12 col-md-8"><asp:DropDownList ID="account" runat="server" data-crm-search-select="بحث باسم العميل..." CssClass="form-select" aria-label="اختر العميل"/></div><div class="col-12 col-md-4"><asp:LinkButton ID="btnLoad" runat="server" CssClass="btn btn-primary" OnClick="Load_Click" Text="عرض صلاحيات العميل" CausesValidation="false"/></div></div></div></div>
  <asp:Panel ID="pnlPermissions" runat="server" Visible="false">
   <div class="row g-4 mb-4">
    <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body type-flex align-items-start justify-content-between"><div><span>التصنيفات المتاحة</span><div class="type-stat-count"><asp:Literal ID="statCategories" runat="server"/></div></div><span class="badge bg-label-primary type-stat-icon"><i class="bx bx-folder" aria-hidden="true"></i></span></div></div></div>
    <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body type-flex align-items-start justify-content-between"><div><span>تصنيفات مسموحة للعميل</span><div class="type-stat-count"><asp:Literal ID="statGranted" runat="server"/></div></div><span class="badge bg-label-success type-stat-icon"><i class="bx bx-check-shield" aria-hidden="true"></i></span></div></div></div>
    <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body"><span>العميل</span><h5 class="mb-0 mt-2"><asp:Literal ID="litAccount" runat="server" Mode="Encode"/></h5></div></div></div>
   </div>
   <div class="card"><div class="card-header"><h2 class="h5 mb-2">صلاحيات التصنيفات</h2><p class="text-muted small mb-0">تظهر تصنيفات جميع العلامات التجارية المرتبطة بالعميل، مجمعة حسب العلامة التجارية. كل تصنيف مستقل. لا تشمل الصلاحية التصنيفات الفرعية ولا تُجمع مع صلاحيات تصنيف آخر.</p></div>
   <div class="card-body">
    <div class="row g-3 align-items-center mb-3"><div class="col-12 col-md-8"><div class="input-group input-group-merge"><span class="input-group-text"><i class="bx bx-search" aria-hidden="true"></i></span><input type="search" id="grantTreeSearch" class="form-control" placeholder="بحث باسم التصنيف بالعربية أو الإنجليزية..." aria-label="بحث في شجرة الصلاحيات" /></div></div><div class="col-12 col-md-4 type-flex justify-content-md-end"><asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-primary" OnClick="Save_Click" Text="حفظ الصلاحيات" CausesValidation="false"/></div></div>
    <div id="guidePermissionsTree" class="guide-permissions-tree guide-tree" aria-label="تصنيفات العميل وصلاحيات كل تصنيف"></div>
    <div id="guideGrantControls" class="d-none"><asp:Repeater ID="permissions" runat="server"><ItemTemplate><span class="guide-grant-options" data-category='<%# Eval("ID") %>'><span class="form-check form-check-inline mb-0"><asp:CheckBox ID="canView" runat="server" Text=" اطلاع" Checked='<%# CBool(Eval("Can_View")) %>' /></span><span class="form-check form-check-inline mb-0"><asp:CheckBox ID="canDownload" runat="server" Text=" تحميل" Checked='<%# CBool(Eval("Can_Download")) %>' /></span></span></ItemTemplate></asp:Repeater></div>
   </div></div>
   <script type="application/json" id="guideGrantTreeData"><asp:Literal ID="litGrantTreeData" runat="server" /></script>
  </asp:Panel>
 </asp:Panel>
</div>
<script src="/assets/js/crm-list.js?v=20261021suppliers" defer></script><script src="/assets/vendor/libs/jstree/jstree.js" defer></script><script src="/assets/js/crm-guide-tree-search.js?v=20261021multibrandb" defer></script><script src="/assets/js/crm-guide-permissions.js?v=20261021multibrand" defer></script>
</asp:Content>
