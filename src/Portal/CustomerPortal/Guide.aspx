<%@ Page Title="دليل العمل" Language="vb" AutoEventWireup="false" MasterPageFile="~/Customer.Master" CodeBehind="Guide.aspx.vb" Inherits="CRM.CustomerGuide" %>
<%@ Import Namespace="CRM" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/work-guide-access.css?v=20260913b" /></asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y wg-documents-page" dir="rtl">
    <div class="card mb-4"><div class="card-body d-flex justify-content-between align-items-center flex-wrap gap-3">
        <div><h4 class="mb-1">دليل العمل</h4><p class="text-muted mb-0">استعرض وثائق التشغيل المتاحة لك، واطلب الوصول إلى تصنيفات إضافية.</p></div>
        <asp:LinkButton ID="btnRequestAccess" runat="server" CssClass="btn btn-primary" CausesValidation="false" OnClientClick="openRequestAccessModal(); return false;" Text="طلب صلاحيات إضافية" />
    </div></div>
    <div class="row g-4">
        <div class="col-12"><div class="card"><div class="card-body">
            <div class="mb-3"><asp:Label runat="server" AssociatedControlID="ddlBrand" CssClass="form-label" Text="العلامة التجارية"/><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="BrandChanged"/></div><asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="row g-3 mb-4">
<div class="col-12 col-lg-5"><asp:Label runat="server" AssociatedControlID="txtSearch" CssClass="form-label" Text="اسم الملف أو الوصف" /><asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" MaxLength="500" /></div>
<div class="col-12 col-lg-5"><asp:Label runat="server" AssociatedControlID="ddlCategory" CssClass="form-label" Text="التصنيفات" /><asp:ListBox ID="ddlCategory" runat="server" SelectionMode="Multiple" CssClass="form-select wg-category-select" data-wg-multiselect="true" /></div>
<div class="col-12 col-lg-2 d-flex gap-2 align-items-end"><asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-primary" OnClick="btnSearch_Click" Text="بحث" CausesValidation="false" /><asp:LinkButton ID="btnReset" runat="server" CssClass="btn btn-outline-secondary" OnClick="btnReset_Click" Text="إعادة تعيين" CausesValidation="false" /></div>
</asp:Panel>
            <div class="d-flex justify-content-between mb-3"><h5 class="mb-0">الوثائق</h5><asp:Label ID="lblDocumentsCount" runat="server" CssClass="badge bg-label-primary" /></div>
<div class="table-responsive"><table id="ERPTable" data-enhanced="1" data-wg-datatable="true" class="ERP_ProstoTBL card-list-table table table-bordered wg-data-table"><thead><tr><th>اسم الملف</th><th>التصنيف</th><th>تاريخ الإضافة</th><th>الحجم</th><th data-orderable="false">الإجراءات</th></tr></thead><tbody>
<asp:ListView ID="lstDocuments" runat="server"><LayoutTemplate><asp:PlaceHolder runat="server" ID="ItemPlaceHolder" /></LayoutTemplate><ItemTemplate><tr>
<td data-title="اسم الملف"><%#: Eval("Title_Ar")%></td>
<td data-title="التصنيف"><%#: Eval("Category_Title_Ar")%></td>
<td data-title="تاريخ الإضافة" data-order='<%#: Eval("AddedDate", "{0:yyyyMMddHHmmss}")%>'><%#: FormatDate(Eval("AddedDate"))%></td>
<td data-title="الحجم" data-order='<%#: Eval("File_Size")%>'><%#: FormatFileSize(Eval("File_Size"))%></td>
<td data-title="الإجراءات"><div class="d-flex flex-wrap gap-2"><asp:HyperLink runat="server" CssClass="btn btn-sm btn-label-primary" Target="_blank" rel="noopener" Text="مشاهدة" Visible='<%# Convert.ToBoolean(Eval("Can_View_Document"))%>' NavigateUrl='<%# "/CustomerPortal/GuideFile.aspx?type=document&id=" & Convert.ToString(Eval("ID"))%>' /><asp:HyperLink runat="server" CssClass="btn btn-sm btn-label-secondary" Text="تحميل" Visible='<%# Convert.ToBoolean(Eval("Can_Download_Document"))%>' NavigateUrl='<%# "/CustomerPortal/Download.aspx?id=" & Convert.ToString(Eval("ID"))%>' /></div></td>
</tr></ItemTemplate></asp:ListView></tbody></table></div>
        </div></div></div>
    </div>
    <asp:Panel ID="pnlRequestArea" runat="server">
        <div class="card mt-4" id="my-access-requests">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2"><h5 class="mb-0">طلباتي للحصول على صلاحيات</h5><asp:LinkButton ID="btnRefreshRequests" runat="server" OnClick="btnRefreshRequests_Click" CssClass="btn btn-label-secondary" Text="تحديث الحالة" CausesValidation="false" /></div>
            <div class="card-body"><asp:Literal ID="litAccessMessage" runat="server" />
                <div class="mb-3 wg-request-filter"><asp:Label runat="server" AssociatedControlID="ddlRequestStatus" CssClass="form-label" Text="عرض الطلبات" /><asp:DropDownList ID="ddlRequestStatus" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="ddlRequestStatus_SelectedIndexChanged"><asp:ListItem Value="P" Text="بانتظار المراجعة" /><asp:ListItem Value="H" Text="الطلبات السابقة" /><asp:ListItem Value="A" Text="تمت الموافقة" /><asp:ListItem Value="R" Text="مرفوضة" /></asp:DropDownList></div>
                <div class="wg-history-scroll"><table class="table table-bordered wg-data-table" data-enhanced="1" data-wg-datatable="true"><thead><tr><th>العلامة التجارية</th><th>التصنيف</th><th>تاريخ الطلب</th><th>الحالة</th><th>الدور المعتمد</th><th>ملاحظة المدير</th></tr></thead><tbody>
                    <asp:ListView ID="lstRequests" runat="server"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate>
                        <ItemTemplate><tr><td data-title="العلامة التجارية"><%#: Eval("Brand_Name")%></td><td data-title="التصنيف"><%#: Eval("Category_Name")%></td><td data-title="تاريخ الطلب"><%#: Eval("AddedDate", "{0:dd/MM/yyyy HH:mm}")%></td><td data-title="الحالة"><asp:Label runat="server" CssClass='<%# WorkGuideAccess.StatusCss(Eval("Status"))%>' Text='<%# WorkGuideAccess.StatusText(Eval("Status"))%>' /></td><td data-title="الدور المعتمد"><%#: Eval("Role_Name")%></td><td data-title="ملاحظة المدير"><%#: Eval("ReviewNote")%></td></tr></ItemTemplate>
                    </asp:ListView></tbody></table></div>
            </div>
        </div>
        <div class="modal fade wg-responsive-modal" id="requestAccessModal" tabindex="-1" aria-labelledby="requestAccessTitle" aria-hidden="true"><div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable modal-fullscreen-sm-down"><div class="modal-content">
            <div class="modal-header"><h5 class="modal-title" id="requestAccessTitle">طلب صلاحيات إضافية</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div>
            <div class="modal-body"><asp:Literal ID="litRequestMessage" runat="server" />
                <asp:ListBox ID="lstRequestCategories" runat="server" CssClass="form-select" SelectionMode="Multiple" data-wg-tree="multiple" />
                <asp:Label runat="server" AssociatedControlID="txtRequestReason" CssClass="form-label mt-3" Text="سبب الطلب" />
                <asp:TextBox ID="txtRequestReason" runat="server" MaxLength="1000" CssClass="form-control" TextMode="MultiLine" Rows="3" />
                <small class="text-muted">يراجع المدير كل تصنيف ويحدد دوره عند الموافقة. تابع القرار والملاحظات في «طلباتي».</small>
            </div>
            <div class="modal-footer"><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إغلاق</button><asp:LinkButton ID="btnSubmitAccessRequest" runat="server" OnClick="btnSubmitAccessRequest_Click" CssClass="btn btn-primary" CausesValidation="false" Text="إرسال الطلب" /></div>
        </div></div></div>
    </asp:Panel>
</div>
<script src="/assets/js/work-guide-tree.js?v=20260912b"></script><script src="/assets/js/work-guide-datatables.js?v=20260913b"></script><script src="/assets/js/work-guide-documents.js?v=20260913b"></script>
<script>function openRequestAccessModal() { var element = document.getElementById('requestAccessModal'); if(element) bootstrap.Modal.getOrCreateInstance(element).show(); }</script>
</asp:Content>
