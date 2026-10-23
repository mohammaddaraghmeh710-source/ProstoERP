<%@ Page Title="إعدادات تكامل API" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageAttendanceIntegration.aspx.vb" Inherits="CRM.ManageAttendanceIntegration" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>
 <div class="container-xxl flex-grow-1 container-p-y" dir="rtl"><div class="card mb-4" data-admin-settings-panel>
 <div class="card-header"><h5 class="card-title mb-0">إعدادات تكامل API حسب العلامة التجارية</h5></div>
 <div class="card-body"><asp:Literal ID="litMessage" runat="server" />
 <div class="row g-3">
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="ddlBrand" CssClass="form-label" Text="العلامة التجارية" /><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="BrandChanged" /></div>
 <div class="col-md-6 d-flex align-items-end"><div class="form-check form-switch"><asp:CheckBox ID="chkEnabled" runat="server" Text="تفعيل خدمات ERP وBioTime" /></div></div>
 <div class="col-12"><h6 class="mb-0">بيانات دخول ERP System</h6></div>
 <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtApiUrl" CssClass="form-label" Text="API URL" /><asp:TextBox ID="txtApiUrl" runat="server" CssClass="form-control" MaxLength="2000" dir="ltr" /><small class="text-muted">عنوان التطبيق الأساسي، مثال: http://92.253.126.181:1098/</small></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtApiUser" CssClass="form-label" Text="اسم المستخدم للـAPI" /><asp:TextBox ID="txtApiUser" runat="server" CssClass="form-control" MaxLength="200" autocomplete="off" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtApiPassword" CssClass="form-label" Text="كلمة المرور للـAPI" /><div class="input-group input-group-merge api-password"><asp:TextBox ID="txtApiPassword" runat="server" CssClass="form-control" TextMode="Password" MaxLength="1000" EnableViewState="false" autocomplete="new-password" /><button type="button" class="input-group-text cursor-pointer" aria-label="إظهار كلمة المرور" aria-pressed="false" onclick="toggleApiPassword(this)"><i class="bx bx-hide" aria-hidden="true"></i></button></div></div>
 <div class="col-12"><h6 class="mb-0">بيانات دخول BioTime</h6></div>
 <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtBioUrl" CssClass="form-label" Text="API URL" /><asp:TextBox ID="txtBioUrl" runat="server" CssClass="form-control" MaxLength="2000" dir="ltr" /><small class="text-muted">عنوان النظام الأساسي فقط، مثال: http://127.0.0.1:8089/</small></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtBioUser" CssClass="form-label" Text="اسم المستخدم في BioTime" /><asp:TextBox ID="txtBioUser" runat="server" CssClass="form-control" MaxLength="200" autocomplete="off" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtBioPassword" CssClass="form-label" Text="كلمة المرور في BioTime" /><div class="input-group input-group-merge api-password"><asp:TextBox ID="txtBioPassword" runat="server" CssClass="form-control" TextMode="Password" MaxLength="1000" EnableViewState="false" autocomplete="new-password" /><button type="button" class="input-group-text cursor-pointer" aria-label="إظهار كلمة المرور" aria-pressed="false" onclick="toggleApiPassword(this)"><i class="bx bx-hide" aria-hidden="true"></i></button></div></div>
 <div class="col-12"><h6 class="mb-0">بيانات دخول HR System</h6><small class="text-muted">اختياري؛ لحفظ بيانات الاتصال فقط.</small></div>
 <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtHrUrl" CssClass="form-label" Text="API URL" /><asp:TextBox ID="txtHrUrl" runat="server" CssClass="form-control" MaxLength="2000" dir="ltr" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtHrUser" CssClass="form-label" Text="اسم المستخدم لنظام HR" /><asp:TextBox ID="txtHrUser" runat="server" CssClass="form-control" MaxLength="200" autocomplete="off" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtHrPassword" CssClass="form-label" Text="كلمة المرور لنظام HR" /><div class="input-group input-group-merge api-password"><asp:TextBox ID="txtHrPassword" runat="server" CssClass="form-control" TextMode="Password" MaxLength="1000" EnableViewState="false" autocomplete="new-password" /><button type="button" class="input-group-text cursor-pointer" aria-label="إظهار كلمة المرور" aria-pressed="false" onclick="toggleApiPassword(this)"><i class="bx bx-hide" aria-hidden="true"></i></button></div></div>
 <div class="col-12"><p class="text-muted mb-0">كلمات المرور مطلوبة عند الإعداد لأول مرة لكل خدمة مستخدمة. اترك حقل كلمة المرور فارغًا عند التعديل للاحتفاظ بالكلمة الحالية؛ تظهر كلمات المرور المحفوظة مخفية؛ استخدم زر العين لإظهارها.</p></div>
 <div class="col-12 d-flex gap-2"><asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary" Text="حفظ الإعدادات" OnClick="SaveSettings" /><a class="btn btn-outline-secondary" href="/Modules/Users/ManageUsers.aspx">إدارة الموظفين</a></div>
 <div class="col-12"><hr class="my-3" /><h6>إعدادات إرسال البريد — Gmail SMTP</h6><small class="text-muted">تُحفظ مستقلة لكل علامة تجارية. smtp.gmail.com — المنفذ 465 — SSL/TLS. استخدم App Password من حساب Gmail.</small></div>
 <div class="col-12"><asp:Literal ID="litEmailMessage" runat="server" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtSenderEmail" CssClass="form-label" Text="بريد Gmail المرسل" /><asp:TextBox ID="txtSenderEmail" runat="server" CssClass="form-control" MaxLength="254" dir="ltr" autocomplete="off" /></div>
 <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtSmtpPassword" CssClass="form-label" Text="Gmail App Password" /><div class="input-group input-group-merge api-password"><asp:TextBox ID="txtSmtpPassword" runat="server" CssClass="form-control" TextMode="Password" EnableViewState="false" MaxLength="100" autocomplete="new-password" /><button type="button" class="input-group-text cursor-pointer" aria-label="إظهار كلمة المرور" aria-pressed="false" onclick="toggleApiPassword(this)"><i class="bx bx-hide" aria-hidden="true"></i></button></div><small class="text-muted">اتركه فارغًا للاحتفاظ بالقيمة المحفوظة؛ تغيير البريد يتطلب App Password جديدًا.</small></div>
 <div class="col-12"><div class="form-check form-switch"><asp:CheckBox ID="chkEmailEnabled" runat="server" Text="تفعيل إرسال البريد لهذه العلامة" /></div></div>
 <div class="col-12"><asp:Button ID="btnSaveEmail" runat="server" Text="حفظ إعدادات البريد" CssClass="btn btn-primary" OnClick="SaveEmailSettings" /></div>
 </div></div></div></div>
<div class='card' data-admin-summary><div class='card-body'><%= CRM.SystemAdministrationUI.IntegrationRows(Me) %></div></div><script>
function toggleApiPassword(button) {
 const input = button.parentElement.querySelector('input');
 const show = input.type === 'password';
 input.type = show ? 'text' : 'password';
 button.setAttribute('aria-pressed', String(show));
 button.setAttribute('aria-label', show ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور');
 button.querySelector('i').className = show ? 'bx bx-show' : 'bx bx-hide';
}
</script>
</ContentTemplate></asp:UpdatePanel></asp:Content>
