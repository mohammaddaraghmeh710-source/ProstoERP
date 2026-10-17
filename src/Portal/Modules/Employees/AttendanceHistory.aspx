<%@ Page Title="سجل حركات الدوام" Language="vb" AutoEventWireup="false" Async="true" AsyncTimeout="150" MasterPageFile="~/Site.Master" CodeBehind="AttendanceHistory.aspx.vb" Inherits="CRM.AttendanceHistory" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
 <div class="container-xxl flex-grow-1 container-p-y" dir="rtl"><div class="card mb-4">
 <div class="card-header"><h5 class="card-title mb-0">سجل حركات الدوام</h5></div><div class="card-body">
 <asp:Literal ID="litMessage" runat="server" /><asp:Panel ID="pnlFilters" runat="server" CssClass="row g-3 mb-3" DefaultButton="btnSearch">
 <asp:Panel ID="pnlBrand" runat="server" CssClass="col-md-3"><asp:Label runat="server" AssociatedControlID="ddlBrand" CssClass="form-label" Text="العلامة التجارية" /><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select" /></asp:Panel>
 <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtEmployee" CssClass="form-label" Text="الرقم الوظيفي" /><asp:TextBox ID="txtEmployee" runat="server" CssClass="form-control" MaxLength="200" /></div>
 <div class="col-md-2"><asp:Label runat="server" AssociatedControlID="txtFrom" CssClass="form-label" Text="من تاريخ" /><asp:TextBox ID="txtFrom" runat="server" CssClass="form-control" TextMode="Date" /></div>
 <div class="col-md-2"><asp:Label runat="server" AssociatedControlID="txtTo" CssClass="form-label" Text="إلى تاريخ" /><asp:TextBox ID="txtTo" runat="server" CssClass="form-control" TextMode="Date" /></div>
 <div class="col-md-2 d-flex align-items-end"><asp:Button ID="btnSearch" runat="server" CssClass="btn btn-primary" Text="عرض الحركات" OnClick="Search" /></div>
 </asp:Panel><asp:Literal ID="litEmployee" runat="server" /><asp:Literal ID="litCount" runat="server" />
 <div class="table-responsive"><table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
 <thead><tr><th>وقت الحركة</th><th>الحركة</th><th>طريقة التحقق</th><th>الجهاز</th><th>المنطقة</th><th>المصدر</th></tr></thead><tbody>
 <asp:Repeater ID="rptAttendance" runat="server"><ItemTemplate><tr>
 <td data-title="وقت الحركة"><%#: Eval("PunchTime") %></td><td data-title="الحركة"><%#: Eval("PunchState") %></td><td data-title="طريقة التحقق"><%#: Eval("VerifyType") %></td><td data-title="الجهاز"><%#: Eval("Terminal") %></td><td data-title="المنطقة"><%#: Eval("Area") %></td><td data-title="المصدر"><%#: Eval("Source") %></td>
 </tr></ItemTemplate></asp:Repeater></tbody></table></div>
 <asp:Label ID="lblEmpty" runat="server" CssClass="d-block text-center text-muted py-3" Text="لا توجد حركات دوام خلال الفترة المحددة." Visible="false" />
 </div></div></div>
</asp:Content>
