<%@ Page Title="مراجعة طلب صلاحيات" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ReviewWorkGuideAccessRequest.aspx.vb" Inherits="CRM.ReviewWorkGuideAccessRequest" %>
<%@ Import Namespace="CRM" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/work-guide-access.css?v=20260912b" /></asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir="rtl"><div class="card">
    <div class="card-header d-flex justify-content-between gap-2 flex-wrap"><h5>مراجعة طلب صلاحيات</h5><a href="ManageWorkGuideAccessRequests.aspx" class="btn btn-label-secondary">رجوع</a></div>
    <div class="card-body"><asp:Literal ID="litMessage" runat="server" /><asp:Literal ID="litSummary" runat="server" />
        <p class="text-muted">حدد قرار كل تصنيف ودور الموافقة. يظل «بدون قرار» معلقًا. تطبّق الموافقة على التصنيف نفسه، دون منح تلقائي للتصنيفات الفرعية.</p>
        <asp:ListView ID="lstReview" runat="server" DataKeyNames="ID,Status" OnItemDataBound="lstReview_ItemDataBound">
            <LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate>
            <ItemTemplate><div class="wg-review-row">
                <h6><%#: Eval("Category_Name")%> <span class="text-muted">— <asp:Label runat="server" CssClass='<%# WorkGuideAccess.StatusCss(Eval("Status"))%>' Text='<%# WorkGuideAccess.StatusText(Eval("Status"))%>' /></span></h6>
                <asp:Panel ID="pnlDecision" runat="server" CssClass="row g-3" Visible='<%# Convert.ToString(Eval("Status")) = "P"%>'>
                    <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="ddlDecision" CssClass="form-label" Text="القرار" /><asp:DropDownList ID="ddlDecision" runat="server" CssClass="form-select wg-decision"><asp:ListItem Value="P" Text="بدون قرار" /><asp:ListItem Value="A" Text="موافقة" /><asp:ListItem Value="R" Text="رفض" /></asp:DropDownList></div>
                    <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="ddlRole" CssClass="form-label" Text="الدور عند الموافقة" /><asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select wg-review-role" /><div class="wg-role-preview text-muted" aria-live="polite"></div></div>
                    <div class="col-md-5"><asp:Label runat="server" AssociatedControlID="txtNote" CssClass="form-label" Text="ملاحظة للمستخدم (مطلوبة للرفض)" /><asp:TextBox ID="txtNote" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2" MaxLength="1000" /></div>
                </asp:Panel>
                <asp:Panel runat="server" Visible='<%# Convert.ToString(Eval("Status")) <> "P"%>'><div>الدور: <%#: Eval("Role_Name")%> · <%#: Eval("ReviewedDate", "{0:dd/MM/yyyy HH:mm}")%></div><div><%#: Eval("ReviewNote")%></div></asp:Panel>
            </div></ItemTemplate>
        </asp:ListView>
        <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-primary mt-4" OnClick="btnSave_Click" Text="حفظ القرارات ومنح الصلاحيات" />
    </div>
</div></div>
<script>
document.addEventListener('DOMContentLoaded',function(){ document.querySelectorAll('.wg-review-role').forEach(function(select){
    function preview(){var option=select.options[select.selectedIndex];select.parentElement.querySelector('.wg-role-preview').textContent=option ? option.getAttribute('data-permissions') || '' : '';}
    select.addEventListener('change',preview);preview();
});});
</script>
</asp:Content>
