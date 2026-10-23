<%@ Page Title="إعدادات المراسلات" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Catalogs.aspx.vb" Inherits="CRM.CorrespondenceCatalogs" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
 <style>#correspondenceCatalogEditor > div { display: flex; flex-direction: column; height: 100%; min-height: 0; }</style>
 <link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css" />
 <link rel="stylesheet" href="/assets/css/crm.css?v=20261017" /><link rel="stylesheet" href="/assets/css/crm-list.css?v=20261017c" />
</asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y crm-shell crm-types" dir="rtl" id="correspondenceCatalogs">
 <div class="type-flex type-page-header align-items-center justify-content-between"><h1 class="h4 mb-0"><asp:Literal ID="litTitle" runat="server" /></h1><a href="Dashboard.aspx" class="btn btn-sm btn-label-secondary"><i class="bx bx-arrow-back me-1" aria-hidden="true"></i>لوحة إدارة المراسلات</a></div>
 <asp:UpdatePanel ID="upCatalog" runat="server" UpdateMode="Conditional"><ContentTemplate>
  <asp:Literal ID="litNotice" runat="server" /><asp:Literal ID="litMetrics" runat="server" />
  <section class="card"><div class="card-header type-filter-header"><h2 class="card-title h6 mb-3">فلاتر البحث</h2><div class="row g-3">
   <div class="col-md-6"><input id="catalogName" type="search" class="form-control" placeholder="اسم الخيار" aria-label="اسم الخيار" /></div>
   <div class="col-md-6"><select id="catalogState" class="form-select" aria-label="الحالة"><option value="">جميع الحالات</option><option value="1">فعال</option><option value="0">موقوف</option></select></div>
  </div></div>
  <div class="card-datatable"><div id="pnlTableActions" class="type-flex type-toolbar-controls"><asp:LinkButton ID="btnNew" runat="server" CssClass="btn btn-primary" OnClick="New_Click" CausesValidation="false"><i class="fa-solid fa-plus me-1" aria-hidden="true"></i>إضافة خيار</asp:LinkButton></div>
  <asp:GridView ID="ERPTable" ClientIDMode="Static" runat="server" AutoGenerateColumns="false" CssClass="ERP_ProstoTBL card-list-table table border-top crm-table" GridLines="None" OnRowCommand="Catalog_Command" OnRowDataBound="Catalog_RowDataBound" ShowHeaderWhenEmpty="true" UseAccessibleHeader="true" data-enhanced="1"><Columns>
   <asp:BoundField DataField="Title" HeaderText="الاسم" /><asp:BoundField DataField="SortOrder" HeaderText="الترتيب" />
   <asp:TemplateField HeaderText="الحالة"><ItemTemplate><span class='<%# If(CBool(Eval("IsActive")),"badge bg-label-success","badge bg-label-secondary") %>'><%#: If(CBool(Eval("IsActive")),"فعال","موقوف") %></span></ItemTemplate></asp:TemplateField>
   <asp:TemplateField HeaderText="الاستخدام"><ItemTemplate><%#: If(CBool(Eval("IsUsed")),"مرتبط بمراسلات","غير مستخدم") %></ItemTemplate></asp:TemplateField>
   <asp:TemplateField HeaderText="الإجراءات"><HeaderStyle CssClass="no-sort" /><ItemTemplate><div class="type-flex type-row-actions">
    <asp:LinkButton ID="btnEditOption" runat="server" CssClass="btn btn-sm btn-icon type-row-action text-secondary" CommandName="EditOption" CommandArgument='<%# Token(Container.DataItem) %>' ToolTip="تعديل" aria-label="تعديل" data-bs-toggle="tooltip" CausesValidation="false"><i class="fa-solid fa-pen-to-square" aria-hidden="true"></i></asp:LinkButton>
    <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-secondary" CommandName='<%# If(CBool(Eval("IsActive")),"deactivate","activate") %>' CommandArgument='<%# Token(Container.DataItem) %>' ToolTip='<%# If(CBool(Eval("IsActive")),"إيقاف","تفعيل") %>' aria-label='<%# If(CBool(Eval("IsActive")),"إيقاف","تفعيل") %>' data-bs-toggle="tooltip" CausesValidation="false"><i class='<%# If(CBool(Eval("IsActive")),"fa-solid fa-toggle-on","fa-solid fa-toggle-off") %>' aria-hidden="true"></i></asp:LinkButton>
    <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-danger" CommandName="RemoveOption" Enabled='<%# Not CBool(Eval("IsUsed")) %>' CommandArgument='<%# Token(Container.DataItem) %>' ToolTip="حذف" aria-label="حذف" data-bs-toggle="tooltip" OnClientClick="return CorrespondenceCatalogUI.confirmDelete(this);" CausesValidation="false"><i class="fa-solid fa-trash-can" aria-hidden="true"></i></asp:LinkButton>
   </div></ItemTemplate></asp:TemplateField>
  </Columns></asp:GridView></div></section>
 </ContentTemplate></asp:UpdatePanel>
 <div class="offcanvas offcanvas-end type-editor" tabindex="-1" id="correspondenceCatalogEditor" aria-labelledby="catalogEditorTitle">
  <asp:UpdatePanel ID="upEditor" runat="server" UpdateMode="Conditional"><ContentTemplate>
   <div class="offcanvas-header border-bottom"><h2 class="offcanvas-title h5" id="catalogEditorTitle"><asp:Literal ID="litEditor" runat="server" Text="إضافة خيار" /></h2><button type="button" class="btn-close text-reset" data-bs-dismiss="offcanvas" aria-label="إغلاق"></button></div>
   <div class="offcanvas-body"><asp:Literal ID="litEditorNotice" runat="server" /><div class="row g-3">
    <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtTitle" Text="الاسم *" CssClass="form-label" /><asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" MaxLength="200" /></div>
    <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtOrder" Text="الترتيب (الأكبر أولًا)" CssClass="form-label" /><asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number" Text="10" min="0" max="999" /></div>
    <asp:Panel ID="pnlReason" runat="server" CssClass="col-12"><asp:Label runat="server" AssociatedControlID="ddlBehavior" Text="الإجراء المرتبط بالسبب" CssClass="form-label" /><asp:DropDownList ID="ddlBehavior" runat="server" CssClass="form-select"><asp:ListItem Value="normal">إنهاء المراسلة</asp:ListItem><asp:ListItem Value="transfer">نقل المسؤولية</asp:ListItem></asp:DropDownList><div class="form-text">نقل المسؤولية متاح للتكليف فقط، مع توضيح وإمكانية إنشاء تكليف بديل مرتبط.</div></asp:Panel>
    <div class="col-12"><p class="form-text mb-0">تظهر الخيارات الفعالة عند الإنشاء أو الإنهاء، وتبقى المسميات السابقة محفوظة. يمكن حذف الخيار غير المستخدم فقط.</p></div>
    <asp:Panel ID="pnlPriority" runat="server" CssClass="col-12"><div class="form-check"><asp:CheckBox ID="chkUrgent" runat="server" Text=" إبراز هذه الأولوية باللون الأحمر" /></div></asp:Panel>
    <div class="col-12"><div class="form-check"><asp:CheckBox ID="chkActive" runat="server" Text=" فعال" Checked="true" /></div></div>
    <div class="col-12 type-flex gap-2"><asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary" OnClick="Save_Click" /><asp:Button ID="btnCancel" runat="server" Text="إلغاء" CssClass="btn btn-label-secondary" OnClick="Cancel_Click" CausesValidation="false" /></div>
   </div></div>
  </ContentTemplate></asp:UpdatePanel>
 </div>
 <div class="modal fade" id="catalogDeleteModal" tabindex="-1" aria-labelledby="catalogDeleteTitle" aria-hidden="true"><div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-header"><h2 id="catalogDeleteTitle" class="modal-title h5">تأكيد الحذف</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div><div class="modal-body">هل تريد حذف هذا الخيار؟ يمكن حذف الخيار غير المستخدم فقط.</div><div class="modal-footer"><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إلغاء</button><button type="button" class="btn btn-danger" id="catalogDeleteConfirm">حذف</button></div></div></div></div>
</div><script src="/assets/js/crm-list.js?v=20261017c"></script><script src="/assets/js/correspondence-catalogs.js?v=20261022a"></script>
</asp:Content>
