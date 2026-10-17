<%@ Page Title="إعدادات المراسلات" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Catalogs.aspx.vb" Inherits="CRM.CorrespondenceCatalogs" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
<div class="d-flex flex-wrap gap-2 mb-4"><a href="ManageCorrespondence.aspx" class="btn btn-label-secondary">المراسلات</a><a href="Catalogs.aspx?kind=P" class="btn btn-label-primary">الأولويات</a><a href="Catalogs.aspx?kind=R" class="btn btn-label-primary">أسباب الإنهاء</a></div>
<h4><asp:Literal ID="litTitle" runat="server" /></h4>
<p class="text-muted">تظهر الخيارات الفعالة عند إنشاء المراسلة أو إنهائها. تبقى المسميات السابقة محفوظة في سجل المراسلات. يمكن حذف الخيار غير المستخدم، وإيقاف الخيار المستخدم.</p>
<asp:Literal ID="litNotice" runat="server" />
<div class="card mb-4"><div class="card-header"><h5 class="mb-0"><asp:Literal ID="litEditor" runat="server" Text="إضافة خيار" /></h5></div><div class="card-body"><div class="row g-3">
<div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtTitle" Text="الاسم" CssClass="form-label" /><asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" MaxLength="200" /></div>
<div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtOrder" Text="الترتيب (الأكبر أولًا)" CssClass="form-label" /><asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number" Text="10" min="0" max="999" /></div>
<div class="col-md-3 d-flex align-items-center"><asp:CheckBox ID="chkActive" runat="server" Text=" فعال" Checked="true" /></div>
<asp:Panel ID="pnlPriority" runat="server" CssClass="col-12"><asp:CheckBox ID="chkUrgent" runat="server" Text=" إبراز هذه الأولوية باللون الأحمر" /></asp:Panel>
<asp:Panel ID="pnlReason" runat="server" CssClass="col-md-6"><asp:Label runat="server" AssociatedControlID="ddlBehavior" Text="الإجراء المرتبط بالسبب" CssClass="form-label" /><asp:DropDownList ID="ddlBehavior" runat="server" CssClass="form-select"><asp:ListItem Value="normal">إنهاء المراسلة</asp:ListItem><asp:ListItem Value="transfer">نقل المسؤولية</asp:ListItem></asp:DropDownList><div class="form-text">نقل المسؤولية متاح للتكليف فقط، ويتطلب توضيحًا ويتيح إنشاء تكليف بديل مرتبط.</div></asp:Panel>
<div class="col-12 d-flex gap-2"><asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary" OnClick="Save_Click" /><asp:Button ID="btnCancel" runat="server" Text="إلغاء التعديل" CssClass="btn btn-label-secondary" OnClick="Cancel_Click" CausesValidation="false" /></div>
</div></div></div>
<div class="card"><div class="card-header"><h5 class="mb-0">الخيارات المعرفة</h5></div><div class="table-responsive"><asp:GridView ID="grid" runat="server" AutoGenerateColumns="false" CssClass="table table-bordered mb-0" GridLines="None" OnRowCommand="Catalog_Command" EmptyDataText="لا توجد خيارات. أضف خيارًا للبدء."><Columns>
<asp:BoundField DataField="Title" HeaderText="الاسم" /><asp:BoundField DataField="SortOrder" HeaderText="الترتيب" />
<asp:TemplateField HeaderText="الحالة"><ItemTemplate><span class='<%# If(CBool(Eval("IsActive")), "badge bg-label-success", "badge bg-label-secondary")%>'><%#: If(CBool(Eval("IsActive")), "فعال", "موقوف")%></span></ItemTemplate></asp:TemplateField>
<asp:TemplateField HeaderText="الاستخدام"><ItemTemplate><%#: If(CBool(Eval("IsUsed")), "مرتبط بمراسلات", "غير مستخدم")%></ItemTemplate></asp:TemplateField>
<asp:TemplateField HeaderText="الإجراءات"><ItemTemplate><div class="d-flex flex-wrap gap-2"><asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-primary" Text="تعديل" CommandName="EditOption" CommandArgument="<%# Token(Container.DataItem)%>" /><asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-secondary" Text='<%# If(CBool(Eval("IsActive")), "إيقاف", "تفعيل")%>' CommandName='<%# If(CBool(Eval("IsActive")), "deactivate", "activate")%>' CommandArgument="<%# Token(Container.DataItem)%>" /><asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-danger" Text="حذف" CommandName="RemoveOption" Enabled='<%# Not CBool(Eval("IsUsed"))%>' CommandArgument="<%# Token(Container.DataItem)%>" /></div></ItemTemplate></asp:TemplateField>
</Columns></asp:GridView></div></div></div>
</asp:Content>
