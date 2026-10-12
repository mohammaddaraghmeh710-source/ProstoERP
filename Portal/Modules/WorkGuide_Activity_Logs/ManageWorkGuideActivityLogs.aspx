<%@ Page Title="سجل نشاط دليل العمل" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuideActivityLogs.aspx.vb" Inherits="CRM.ManageWorkGuideActivityLogs" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/work-guide-access.css?v=20260912c" />
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir="rtl"><div class="card">
    <div class="card-header"><h4 class="mb-1">سجل نشاط دليل العمل</h4><p class="text-muted mb-0">تتبّع عمليات مشاهدة الوثائق وتحميلها.</p></div>
    <div class="card-body"><asp:Literal ID="litMessage" runat="server" />
        <asp:Panel ID="pnlFilters" runat="server" DefaultButton="btnSearch" CssClass="row g-3 mb-4">
            <div class="col-12 col-md-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="txtUser" CssClass="form-label" Text="اسم المستخدم" /><asp:TextBox ID="txtUser" runat="server" CssClass="form-control" MaxLength="200" placeholder="الاسم العربي أو الإنجليزي" /></div>
            <div class="col-12 col-md-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="txtDocument" CssClass="form-label" Text="اسم الوثيقة" /><asp:TextBox ID="txtDocument" runat="server" CssClass="form-control" MaxLength="200" /></div>
            <div class="col-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="txtFrom" CssClass="form-label" Text="من تاريخ" /><asp:TextBox ID="txtFrom" runat="server" CssClass="form-control" TextMode="Date" /></div>
            <div class="col-6 col-xl-3"><asp:Label runat="server" AssociatedControlID="txtTo" CssClass="form-label" Text="إلى تاريخ" /><asp:TextBox ID="txtTo" runat="server" CssClass="form-control" TextMode="Date" /></div>
            <div class="col-12">
                <asp:Label runat="server" AssociatedControlID="ddlCategory" CssClass="form-label" Text="التصنيف" />
                <div class="row g-2 align-items-center">
                    <div class="col-12 col-lg"><asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select" /></div>
                    <div class="col-12 col-lg-auto d-flex flex-wrap gap-2">
                        <asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-primary" Text="بحث" OnClick="btnSearch_Click" CausesValidation="false" />
                        <asp:LinkButton ID="btnReset" runat="server" CssClass="btn btn-label-secondary" Text="إعادة تعيين" OnClick="btnReset_Click" CausesValidation="false" />
                        <asp:LinkButton ID="btnExport" runat="server" CssClass="btn btn-success" Text="تصدير إلى Excel" OnClick="btnExport_Click" OnClientClick="if (!prepareWorkGuideLogExport()) return false;" CausesValidation="false" />
                        <asp:HiddenField ID="hfExportLogIDs" ClientIDMode="Static" runat="server" />
                    </div>
                </div>
                <small class="text-muted">يُطبّق الفلتر على التصنيف المحدد نفسه. تاريخ النهاية يشمل اليوم كاملًا.</small>
            </div>
        </asp:Panel>
        <table id="ERPTable" data-enhanced="1" data-wg-datatable="true" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap"><thead><tr><th>التاريخ</th><th>المستخدم</th><th>العلامة التجارية</th><th>التصنيف</th><th>الوثيقة</th><th>النشاط</th><th data-orderable="false">التفاصيل</th></tr></thead><tbody>
            <asp:ListView ID="lstLogs" runat="server"><LayoutTemplate><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></LayoutTemplate>
                <ItemTemplate><tr data-log-id='<%#: Eval("ID") %>'>
                    <td data-title="التاريخ" data-order='<%#: Eval("AddedDate", "{0:yyyyMMddHHmmss}") %>'><%#: Eval("AddedDate", "{0:dd/MM/yyyy HH:mm:ss}") %></td>
                    <td data-title="المستخدم"><%#: Eval("User_Name") %> <small class="text-muted">#<%#: Eval("User_ID") %></small></td>
                    <td data-title="العلامة التجارية"><%#: Eval("Brand_Name") %></td>
                    <td data-title="التصنيف"><%#: Eval("Category_Name") %></td>
                    <td data-title="الوثيقة"><%#: Eval("Document_Name") %></td>
                    <td data-title="النشاط"><%#: ActionText(Eval("Action_Type")) %></td>
                    <td data-title="التفاصيل"><details><summary>عرض التفاصيل</summary><div class="wg-log-details"><%#: Eval("Action_Details") %></div><div class="small mt-2">عنوان IP: <bdi><%#: Eval("IPAddress") %></bdi></div><div class="small">رقم السجل: <%#: Eval("ID") %></div></details></td>
                </tr></ItemTemplate>
            </asp:ListView>
        </tbody></table>
    </div>
</div></div>
<script src="/assets/js/work-guide-datatables.js?v=20260912b"></script>
</asp:Content>
