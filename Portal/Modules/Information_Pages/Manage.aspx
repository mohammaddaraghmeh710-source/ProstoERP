<%@ Page Title="إدارة الصفحات المعلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Manage.aspx.vb" Inherits="CRM.ManageInformationPages" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
<asp:Literal ID="litMessage" runat="server" /><section class="card"><div class="card-header d-flex justify-content-between flex-wrap gap-2"><h4 class="mb-0">إدارة الصفحات المعلوماتية</h4><div><a href="Logs.aspx" class="btn btn-outline-secondary">سجل العمليات والزيارات</a> <a href="Edit.aspx" class="btn btn-primary">إضافة صفحة</a></div></div><div class="card-body">
<div class="row g-3 align-items-end mb-4"><div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtSearch" Text="بحث بالعنوان" CssClass="form-label" /><asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" MaxLength="250" /></div><div class="col-md-4"><asp:Label runat="server" AssociatedControlID="ddlDeleted" Text="العرض" CssClass="form-label" /><asp:DropDownList ID="ddlDeleted" runat="server" CssClass="form-select"><asp:ListItem Value="0">الصفحات غير المحذوفة</asp:ListItem><asp:ListItem Value="1">أرشيف الصفحات المحذوفة</asp:ListItem></asp:DropDownList></div><div class="col-md-2"><asp:Button ID="btnSearch" runat="server" Text="بحث" OnClick="Search_Click" CssClass="btn btn-primary" /></div></div>
<div class="table-responsive"><table class="table table-bordered"><thead><tr><th>الترتيب</th><th>العنوان</th><th>العلامات التجارية</th><th>الحالة</th><th>فترة العرض</th><th>الإصدار</th><th>الإجراءات</th></tr></thead><tbody>
<asp:ListView ID="lstPages" runat="server" OnItemCommand="Page_Command"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate><ItemTemplate><tr>
<td><%#: Eval("Item_Order") %></td><td><div><%#: Eval("Title_Ar") %></div><small dir="ltr"><%#: Eval("Title_En") %></small></td>
<td><%#: Eval("BrandNames") %></td>
<td><span class="badge bg-label-primary"><%#: CRM.InformationPagesData.StatusText(Eval("DisplayStatus")) %></span></td>
<td><%#: If(CStr(Eval("PublishMode"))="immediate","نشر فوري",CRM.InformationPagesData.LocalDate(Eval("StartUtc")) & " — " & CRM.InformationPagesData.LocalDate(Eval("EndUtc"))) %></td>
<td><%#: Eval("VersionNumber") %></td><td><div class="d-flex flex-wrap gap-2">
<a href='<%# "View.aspx?preview=1&ID=" & Eval("ID").ToString() %>' class="btn btn-sm btn-outline-secondary">معاينة</a>
<button type="button" class="btn btn-sm btn-outline-primary" data-page-link='<%# ResolveUrl("~/Modules/Information_Pages/View.aspx?ID=" & Eval("ID").ToString()) %>' onclick="copyInformationPageLink(this)">نسخ الرابط</button>
<asp:HyperLink ID="lnkEdit" runat="server" NavigateUrl='<%# "Edit.aspx?ID=" & Eval("ID").ToString() %>' Visible='<%# Not CBool(Eval("IsDeleted")) %>' CssClass="btn btn-sm btn-outline-primary" Text="تعديل" />
<a href='<%# "History.aspx?ID=" & Eval("ID").ToString() %>' class="btn btn-sm btn-outline-secondary">الإصدارات</a>
<a href='<%# "Logs.aspx?ID=" & Eval("ID").ToString() %>' class="btn btn-sm btn-outline-secondary">السجلات</a>
<asp:LinkButton ID="btnDelete" runat="server" CommandName="SoftDelete" CommandArgument='<%# Eval("ID").ToString() & ":" & Eval("VersionNumber").ToString() %>' Visible='<%# Not CBool(Eval("IsDeleted")) %>' CssClass="btn btn-sm btn-outline-danger" OnClientClick="return confirm('هل تريد حذف الصفحة منطقيًا؟ ستبقى الإصدارات والسجلات محفوظة.');" Text="حذف" />
</div></td></tr></ItemTemplate><EmptyDataTemplate><tr><td colspan="7" class="text-center py-4">لا توجد صفحات مطابقة.</td></tr></EmptyDataTemplate></asp:ListView>
</tbody></table></div><p id="copyInformationPageStatus" class="text-muted mt-3" role="status" aria-live="polite"></p></div></section></div>
<script>
async function copyInformationPageLink(button) {
    var url = new URL(button.getAttribute('data-page-link'), window.location.origin).href;
    var status = document.getElementById('copyInformationPageStatus');
    try {
        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(url);
        } else {
            var field = document.createElement('textarea');
            field.value = url; field.style.position = 'fixed'; field.style.opacity = '0';
            document.body.appendChild(field); field.select();
            var copied = false;
            try { copied = document.execCommand('copy'); } finally { field.remove(); button.focus(); }
            if (!copied) throw new Error('Copy unavailable');
        }
        status.textContent = 'تم نسخ رابط الصفحة. يمكن لصقه في رابط داخل محرر صفحة أخرى.';
    } catch (error) {
        status.textContent = 'تعذّر النسخ التلقائي. انسخ الرابط التالي: ' + url;
    }
}
</script></asp:Content>
