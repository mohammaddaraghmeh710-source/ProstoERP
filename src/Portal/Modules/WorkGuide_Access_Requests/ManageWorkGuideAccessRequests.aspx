<%@ Page Title="طلبات صلاحيات دليل العمل" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuideAccessRequests.aspx.vb" Inherits="CRM.ManageWorkGuideAccessRequests" %>
<%@ Import Namespace="CRM" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/work-guide-access.css?v=20260912c" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir="rtl"><div class="card">
    <div class="card-header"><h5>طلبات صلاحيات دليل العمل</h5><span class="text-muted">راجع تصنيفات كل طلب وحدد دورًا لكل موافقة.</span></div>
    <div class="card-body"><asp:Literal ID="litMessage" runat="server" />
        <asp:Panel ID="pnlFilter" runat="server" DefaultButton="btnSearch" CssClass="row g-3 mb-3">
            <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="txtKeyword" Text="العميل / الحساب السابق أو التصنيف" CssClass="form-label" /><asp:TextBox ID="txtKeyword" runat="server" MaxLength="200" CssClass="form-control" /></div>
            <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="ddlBrand" Text="العلامة التجارية" CssClass="form-label" /><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select" /></div>
            <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="ddlStatus" Text="الحالة" CssClass="form-label" /><asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select"><asp:ListItem Value="P" Text="بانتظار المراجعة" /><asp:ListItem Value="A" Text="تمت الموافقة" /><asp:ListItem Value="R" Text="مرفوض" /><asp:ListItem Value="" Text="الكل" /></asp:DropDownList></div>
            <div class="col-md-2 d-flex align-items-end"><asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-primary" Text="بحث" OnClick="btnSearch_Click" /></div>
        </asp:Panel>
        <table id="ERPTable" data-enhanced="1" data-wg-datatable="true" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap"><thead><tr><th>العميل / الحساب السابق</th><th>العلامة التجارية</th><th>التصنيف</th><th>تاريخ الطلب</th><th>الحالة</th><th data-orderable="false">مراجعة</th></tr></thead><tbody>
            <asp:ListView ID="lstRequests" runat="server" DataKeyNames="ID,Batch_ID" OnItemCommand="lstRequests_ItemCommand"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate>
                <ItemTemplate><tr><td data-title="العميل / الحساب السابق"><%#: Eval("User_Name")%></td><td data-title="العلامة التجارية"><%#: Eval("Brand_Name")%></td><td data-title="التصنيف"><%#: Eval("Category_Name")%></td><td data-title="تاريخ الطلب" data-order='<%#: Eval("AddedDate", "{0:yyyyMMddHHmmss}")%>'><%#: Eval("AddedDate", "{0:dd/MM/yyyy HH:mm}")%></td><td data-title="الحالة"><asp:Label runat="server" CssClass='<%# WorkGuideAccess.StatusCss(Eval("Status"))%>' Text='<%# WorkGuideAccess.StatusText(Eval("Status"))%>' /></td><td data-title="مراجعة"><div class="d-flex flex-wrap gap-2 align-items-center">
                    <asp:LinkButton runat="server" CommandName="ApproveRequest" CausesValidation="false" CssClass="btn btn-success p-0" style="width:44px;height:44px;font-size:1.4rem" ToolTip="الموافقة وتحديد الصلاحيات" aria-label="الموافقة وتحديد الصلاحيات" Visible='<%# Convert.ToString(Eval("Status")) = "P"%>'><span aria-hidden="true">&#10003;</span></asp:LinkButton>
                    <asp:LinkButton runat="server" CommandName="RejectRequest" CausesValidation="false" CssClass="btn btn-danger p-0" style="width:44px;height:44px;font-size:1.4rem" ToolTip="رفض الطلب وكتابة السبب" aria-label="رفض الطلب وكتابة السبب" Visible='<%# Convert.ToString(Eval("Status")) = "P"%>'><span aria-hidden="true">&#10005;</span></asp:LinkButton>
                    <asp:HyperLink runat="server" CssClass="btn btn-sm btn-label-primary" Text="فتح الطلب" NavigateUrl='<%# "ReviewWorkGuideAccessRequest.aspx?batch=" & Convert.ToString(Eval("Batch_ID"))%>' />
                </div></td></tr></ItemTemplate>
            </asp:ListView></tbody></table>
    </div>
</div></div>
<div class="modal fade wg-responsive-modal" id="reviewRequestModal" tabindex="-1" aria-labelledby="reviewRequestTitle" aria-hidden="true" dir="rtl">
    <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable modal-fullscreen-sm-down"><div class="modal-content">
        <div class="modal-header"><h5 class="modal-title" id="reviewRequestTitle">مراجعة طلب صلاحيات</h5><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div>
        <div class="modal-body">
            <asp:Literal ID="litReviewMessage" runat="server" />
            <asp:Literal ID="litReviewSummary" runat="server" />
            <p class="text-muted small">يُحفظ القرار للتصنيف المعروض فقط. لا تُمنح الصلاحيات إلا بعد الحفظ.</p>
            <asp:Label runat="server" AssociatedControlID="ddlReviewDecision" CssClass="form-label" Text="القرار" />
            <asp:DropDownList ID="ddlReviewDecision" runat="server" CssClass="form-select mb-3" data-wg-review-decision="true"><asp:ListItem Value="A" Text="موافقة" /><asp:ListItem Value="R" Text="رفض" /></asp:DropDownList>
            <div data-wg-review-role-area>
                <asp:Label runat="server" AssociatedControlID="ddlReviewRole" CssClass="form-label" Text="الدور والصلاحيات عند الموافقة" />
                <asp:DropDownList ID="ddlReviewRole" runat="server" CssClass="form-select" data-wg-role="true" />
            </div>
            <p class="text-danger small" data-wg-review-rejection hidden>لن تُمنح أي صلاحيات عند الرفض. يرجى توضيح السبب للمستخدم.</p>
            <asp:Label runat="server" AssociatedControlID="txtReviewNote" CssClass="form-label mt-3" Text="الشروحات / سبب الرفض" />
            <asp:TextBox ID="txtReviewNote" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" MaxLength="1000" />
            <small class="text-muted">تظهر الشروحات للمستخدم. سبب الرفض مطلوب، بحد أقصى 1000 حرف.</small>
        </div>
        <div class="modal-footer"><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إلغاء</button><asp:LinkButton ID="btnSaveReview" runat="server" CssClass="btn btn-primary" Text="حفظ القرار" OnClick="btnSaveReview_Click" CausesValidation="false" /></div>
    </div></div>
</div>
<script src="/assets/js/work-guide-tree.js?v=20260912b"></script>
<script>
function openReviewRequestModal() { bootstrap.Modal.getOrCreateInstance(document.getElementById('reviewRequestModal')).show(); }
document.addEventListener('DOMContentLoaded', function () {
    var modal = document.getElementById('reviewRequestModal'), decision = modal.querySelector('[data-wg-review-decision]');
    function updateDecision() {
        var approving = decision.value === 'A';
        modal.querySelector('[data-wg-review-role-area]').hidden = !approving;
        modal.querySelector('[data-wg-review-rejection]').hidden = approving;
    }
    decision.addEventListener('change', updateDecision);
    updateDecision();
});
</script>
<script src="/assets/js/work-guide-datatables.js?v=20260912b"></script>
</asp:Content>
