<%@ Page Title="طرق الدفع" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageCRMPaymentMethods.aspx.vb" Inherits="CRM.ManageCRMPaymentMethods" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css" />
<link rel="stylesheet" href="/assets/css/crm.css?v=20260913c" />
<link rel="stylesheet" href="/assets/css/crm-list.css?v=20261017c" />
</asp:Content>
<asp:Content ID="body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y crm-shell crm-types" dir="rtl">
  <div class="type-page-header type-flex align-items-center justify-content-between"><h1 class="h4 mb-0">طرق الدفع</h1><nav aria-label="مسار التنقل"><ol class="breadcrumb mb-0"><li class="breadcrumb-item"><a href="/Modules/CRM_Account_Types/Overview.aspx">إدارة العملاء</a></li><li class="breadcrumb-item active" aria-current="page">طرق الدفع</li></ol></nav></div>
  <asp:Literal ID="litMessage" runat="server" EnableViewState="false" />
  <asp:Panel ID="pnlBody" runat="server">
    <div class="row g-4 mb-4" aria-label="إحصائيات طرق الدفع">
      <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body type-flex align-items-start justify-content-between"><div><span>إجمالي العناصر</span><div class="type-stat-count"><asp:Literal ID="statTotal" runat="server" Text="—" /></div></div><span class="badge bg-label-primary rounded type-stat-icon"><i class="bx bx-category" aria-hidden="true"></i></span></div></div></div>
      <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body type-flex align-items-start justify-content-between"><div><span>العناصر الفعالة</span><div class="type-stat-count"><asp:Literal ID="statActive" runat="server" Text="—" /></div></div><span class="badge bg-label-success rounded type-stat-icon"><i class="bx bx-check-circle" aria-hidden="true"></i></span></div></div></div>
      <div class="col-12 col-md-4"><div class="card type-stat-card"><div class="card-body type-flex align-items-start justify-content-between"><div><span>العناصر الموقوفة</span><div class="type-stat-count"><asp:Literal ID="statInactive" runat="server" Text="—" /></div></div><span class="badge bg-label-warning rounded type-stat-icon"><i class="bx bx-pause-circle" aria-hidden="true"></i></span></div></div></div>
    </div>
    <div class="card">
      <div class="card-header type-filter-header">
        <h2 class="card-title h5 mb-0">تصفية البحث</h2>
      <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="row g-3 align-items-center" ClientIDMode="Static">
        <div class="col-12 col-md-5">
        <asp:Label runat="server" AssociatedControlID="filterName" CssClass="visually-hidden" Text="البحث بالاسم العربي أو الإنجليزي" />
        <asp:TextBox ID="filterName" runat="server" CssClass="form-control" MaxLength="200" placeholder="الاسم بالعربية أو الإنجليزية" aria-label="البحث بالاسم العربي أو الإنجليزي" />
        </div>
        <div class="col-12 col-md-5"><asp:DropDownList ID="filterStatus" runat="server" CssClass="form-select" aria-label="الحالة" AutoPostBack="true" CausesValidation="false" OnSelectedIndexChanged="Search_Click"><asp:ListItem Value="" Text="اختر الحالة" /><asp:ListItem Value="1" Text="فعال" /><asp:ListItem Value="0" Text="موقوف" /></asp:DropDownList></div>
        <div class="col-12 col-md-2 type-flex gap-2">
        <asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-icon btn-label-secondary" OnClick="Search_Click" CausesValidation="false" ToolTip="بحث" aria-label="بحث" data-bs-toggle="tooltip"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i></asp:LinkButton>
        <asp:LinkButton ID="btnReset" runat="server" CssClass="btn btn-icon btn-label-secondary" OnClick="ResetSearch_Click" CausesValidation="false" ToolTip="إعادة تعيين" aria-label="إعادة تعيين" data-bs-toggle="tooltip"><i class="fa-solid fa-rotate-left" aria-hidden="true"></i></asp:LinkButton>
        </div>
      </asp:Panel>
      </div>
      <asp:Panel ID="pnlTableActions" runat="server" CssClass="type-flex type-toolbar-controls align-items-center" ClientIDMode="Static">
        <asp:LinkButton ID="btnNewType" runat="server" CssClass="btn btn-primary" OnClick="NewType_Click" CausesValidation="false"><i class="fa-solid fa-plus me-2" aria-hidden="true"></i>إضافة طريقة دفع</asp:LinkButton>
      </asp:Panel>
      <div class="card-datatable table-responsive">
        <table id="ERPTable" data-enhanced="1" class="ERP_ProstoTBL card-list-table table border-top crm-table"><thead><tr><th>الرقم</th><th>طريقة الدفع</th><th>ملاحظات</th><th>الحالة</th><th data-orderable="false">الإجراءات</th></tr></thead><tbody>
          <asp:ListView ID="lstData" runat="server" DataKeyNames="ID,Row_Version" OnItemCommand="Type_RowCommand"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate><ItemTemplate>
            <tr><td data-title="الرقم"><%#: Eval("ID") %></td><td data-title="طريقة الدفع"><div class="type-flex align-items-center gap-3"><span class="type-record-icon badge bg-label-primary rounded"><i class="bx bx-category fs-4" aria-hidden="true"></i></span><div class="type-record-name"><span class="fw-semibold"><%#: Eval("Name_AR") %></span><small class="d-block text-muted" dir="auto"><%#: Eval("Name_EN") %></small></div></div></td><td data-title="ملاحظات" class="type-notes"><%#: Eval("Notes") %></td><td data-title="الحالة"><span class='<%# If(Convert.ToBoolean(Eval("Is_Active")), "badge bg-label-success", "badge bg-label-secondary") %>'><%#: If(Convert.ToBoolean(Eval("Is_Active")), "فعال", "موقوف") %></span></td><td data-title="الإجراءات"><div class="type-flex type-row-actions">
              <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-secondary" CommandName="EditType" CommandArgument='<%# Eval("ID") %>' ToolTip="تعديل" aria-label="تعديل" data-bs-toggle="tooltip" CausesValidation="false"><i class="fa-solid fa-pen-to-square" aria-hidden="true"></i></asp:LinkButton>
              <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-warning" CommandName="Deactivate" CommandArgument='<%# Eval("ID") %>' Visible='<%# Convert.ToBoolean(Eval("Is_Active")) %>' ToolTip="إيقاف" aria-label="إيقاف" data-bs-toggle="tooltip" CausesValidation="false"><i class="fa-solid fa-pause" aria-hidden="true"></i></asp:LinkButton>
              <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-success" CommandName="Activate" CommandArgument='<%# Eval("ID") %>' Visible='<%# Not Convert.ToBoolean(Eval("Is_Active")) %>' ToolTip="تفعيل" aria-label="تفعيل" data-bs-toggle="tooltip" CausesValidation="false"><i class="fa-solid fa-play" aria-hidden="true"></i></asp:LinkButton>
              <asp:LinkButton runat="server" CssClass="btn btn-sm btn-icon type-row-action text-danger" CommandName="AskDelete" CommandArgument='<%# Eval("ID") %>' ToolTip="حذف" aria-label="حذف" data-bs-toggle="tooltip" CausesValidation="false"><i class="fa-solid fa-trash-can" aria-hidden="true"></i></asp:LinkButton>
            </div></td></tr>
          </ItemTemplate></asp:ListView>
        </tbody></table>
      </div>
    </div>
    <div class="modal fade" id="typeDeleteModal" tabindex="-1" aria-labelledby="typeDeleteTitle" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
        <div class="modal-header"><h2 class="modal-title h5" id="typeDeleteTitle">حذف طريقة الدفع</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div>
        <div class="modal-body"><p class="mb-0">هل تريد حذف طريقة الدفع «<strong><asp:Literal ID="litDeleteName" runat="server" Mode="Encode" /></strong>»؟</p></div>
        <div class="modal-footer"><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إلغاء</button><asp:LinkButton ID="btnConfirmDelete" runat="server" CssClass="btn btn-danger" CausesValidation="false" OnClick="ConfirmDelete_Click"><i class="fa-solid fa-trash-can me-2" aria-hidden="true"></i>تأكيد الحذف</asp:LinkButton></div>
      </div></div>
    </div>
    <div class="offcanvas offcanvas-end type-editor" tabindex="-1" id="typeEditor" aria-labelledby="typeEditorTitle">
      <div class="offcanvas-header border-bottom"><h2 class="offcanvas-title h5" id="typeEditorTitle"><asp:Literal ID="litEditorTitle" runat="server" Text="إضافة طريقة دفع" /></h2><button type="button" class="btn-close text-reset" data-bs-dismiss="offcanvas" aria-label="إغلاق"></button></div>
      <div class="offcanvas-body">
        <asp:Panel ID="pnlTypeEditor" runat="server" DefaultButton="btnSaveType">
          <asp:Literal ID="litEditorMessage" runat="server" EnableViewState="false" />
          <asp:ValidationSummary runat="server" ValidationGroup="TypeEditor" CssClass="alert alert-danger" HeaderText="يرجى مراجعة البيانات التالية:" />
          <div class="mb-3"><asp:Label runat="server" AssociatedControlID="editNameAr" CssClass="form-label" Text="الاسم بالعربية *" /><asp:TextBox ID="editNameAr" runat="server" CssClass="form-control" MaxLength="200" /><asp:RequiredFieldValidator runat="server" ControlToValidate="editNameAr" ValidationGroup="TypeEditor" ErrorMessage="أدخل الاسم بالعربية." CssClass="text-danger small" Display="Dynamic" /></div>
          <div class="mb-3"><asp:Label runat="server" AssociatedControlID="editNameEn" CssClass="form-label" Text="الاسم بالإنجليزية" /><asp:TextBox ID="editNameEn" runat="server" CssClass="form-control" MaxLength="200" dir="ltr" /></div>
          <div class="mb-3"><asp:Label runat="server" AssociatedControlID="editNotes" CssClass="form-label" Text="ملاحظات" /><asp:TextBox ID="editNotes" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" MaxLength="2000" /></div>
          <div class="mb-4 type-flex align-items-center"><asp:CheckBox ID="editActive" runat="server" Text=" فعال" Checked="true" /></div>
          <div class="type-flex flex-wrap gap-2"><asp:LinkButton ID="btnSaveType" runat="server" CssClass="btn btn-primary" OnClick="SaveType_Click" ValidationGroup="TypeEditor" Text="حفظ" /><button type="button" class="btn btn-label-secondary" data-bs-dismiss="offcanvas">إلغاء</button></div>
        </asp:Panel>
      </div>
    </div>
  </asp:Panel>
</div>
<script src="/assets/js/crm-list.js?v=20261021suppliers"></script>
</asp:Content>
