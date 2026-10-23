<%@ Page Title="بيانات HR" Language="vb" AutoEventWireup="false" Async="true" AsyncTimeout="150" MasterPageFile="~/Site.Master" CodeBehind="HRProfile.aspx.vb" Inherits="CRM.HRProfile" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Body" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
 <div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
  <asp:UpdatePanel ID="updHR" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true"><ContentTemplate>
  <asp:Panel ID="pnlHR" runat="server" EnableViewState="false">
   <div class="card mb-4"><div class="card-body d-flex justify-content-between align-items-center flex-wrap gap-3">
    <div><h4 class="mb-2">بيانات HR</h4><asp:Literal ID="litIdentity" runat="server" /><p class="text-muted small mb-0">بيانات للعرض من نظام الموارد البشرية، وفق صلاحيات ملف الموظف.</p></div>
    <div class="d-flex flex-wrap gap-2"><asp:HyperLink ID="lnkProfile" runat="server" CssClass="btn btn-outline-secondary" Text="العودة إلى ملف الموظف" /><asp:Button ID="btnRefresh" runat="server" CssClass="btn btn-primary" Text="تحديث البيانات" OnClick="RefreshData" CausesValidation="false" /></div>
   </div></div>
   <asp:Literal ID="litMessage" runat="server" />
   <ul class="nav nav-pills flex-column flex-sm-row mb-4 gap-1" aria-label="أقسام بيانات الموظف">
    <li class="nav-item"><a class="nav-link" href="#hr-personal"><i class="bx bx-user me-1"></i>بيانات الموظف</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-shift"><i class="bx bx-time me-1"></i>الوردية</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-finance"><i class="bx bx-wallet me-1"></i>البيانات المالية</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-salary"><i class="bx bx-receipt me-1"></i>العلاوات والاقتطاعات</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-custody"><i class="bx bx-package me-1"></i>عهد الموظف</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-qualification"><i class="bx bx-book me-1"></i>المؤهلات والعائلة</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-attendance"><i class="bx bx-calendar me-1"></i>الدوام والعطل</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-penalties"><i class="bx bx-error-circle me-1"></i>الجزاءات والإنذارات</a></li>
    <li class="nav-item"><a class="nav-link" href="#hr-files"><i class="bx bx-folder me-1"></i>ملفات الموظف</a></li>
   </ul>
   <div class="row">
    <div class="col-lg-7">
     <div class="card mb-4" id="hr-personal"><h5 class="card-header">بيانات الموظف</h5><div class="card-body"><asp:Literal ID="litPersonal" runat="server" /></div></div>
     <div class="card mb-4" id="hr-finance"><h5 class="card-header">بيانات الموظف المالية</h5><div class="card-body"><asp:Literal ID="litFinance" runat="server" /></div></div>
    </div>
    <div class="col-lg-5">
     <div class="card mb-4" id="hr-shift"><h5 class="card-header">الوردية</h5><div class="card-body"><asp:Literal ID="litShift" runat="server" /></div></div>
    </div>
   </div>
   <div class="card mb-4" id="hr-salary"><h5 class="card-header">قسيمة الراتب الشهرية</h5><div class="card-body">
    <div class="row g-3 align-items-end mb-3"><div class="col-sm-5 col-lg-3"><asp:Label runat="server" AssociatedControlID="txtSalaryMonth" CssClass="form-label" Text="الشهر والسنة" /><asp:TextBox ID="txtSalaryMonth" runat="server" TextMode="Month" CssClass="form-control" /></div><div class="col-sm-auto"><asp:Button ID="btnSalary" runat="server" Text="عرض قسيمة الراتب" CssClass="btn btn-outline-primary" OnClick="ShowSalary" CausesValidation="false" /></div></div>
    <asp:Literal ID="litSalary" runat="server" />
   </div></div>
   <div class="row">
    <div class="col-lg-6"><div class="card mb-4" id="hr-qualification"><h5 class="card-header">المؤهلات العلمية</h5><div class="card-body"><asp:Literal ID="litQualification" runat="server" /></div></div></div>
    <div class="col-lg-6"><div class="card mb-4" id="hr-specialization"><h5 class="card-header">التخصصات</h5><div class="card-body"><asp:Literal ID="litSpecialization" runat="server" /></div></div></div>
    <div class="col-lg-6"><div class="card mb-4" id="hr-children"><h5 class="card-header">الأولاد</h5><div class="card-body"><asp:Literal ID="litChildren" runat="server" /></div></div></div>
    <div class="col-lg-6"><div class="card mb-4" id="hr-wives"><h5 class="card-header">الزوجات</h5><div class="card-body"><asp:Literal ID="litWives" runat="server" /></div></div></div>
    <div class="col-lg-6"><div class="card mb-4" id="hr-references"><h5 class="card-header">المعرّفون</h5><div class="card-body"><asp:Literal ID="litReferences" runat="server" /></div></div></div>
    <div class="col-lg-6"><div class="card mb-4" id="hr-education"><h5 class="card-header">التعليم</h5><div class="card-body"><asp:Literal ID="litEducation" runat="server" /></div></div></div>
    <div class="col-12"><div class="card mb-4" id="hr-experience"><h5 class="card-header">الخبرات</h5><div class="card-body"><asp:Literal ID="litExperience" runat="server" /></div></div></div>
   </div>
   <div class="card mb-4" id="hr-attendance"><h5 class="card-header">كشف الدوام</h5><div class="card-body">
    <asp:Panel ID="pnlAttendanceFilters" runat="server" CssClass="mb-3"><div class="row g-3">
     <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="txtAttendanceFrom" CssClass="form-label" Text="الدوام من تاريخ" /><asp:TextBox ID="txtAttendanceFrom" runat="server" TextMode="Date" CssClass="form-control" /></div>
     <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="txtAttendanceTo" CssClass="form-label" Text="الدوام إلى تاريخ" /><asp:TextBox ID="txtAttendanceTo" runat="server" TextMode="Date" CssClass="form-control" /></div>
    </div></asp:Panel>
    <asp:Button ID="btnAttendance" runat="server" CssClass="btn btn-outline-primary mb-3" Text="عرض كشف الدوام" OnClick="ShowAttendance" CausesValidation="false" />
    <asp:Literal ID="litAttendance" runat="server" />
   </div></div>
   <div class="card mb-4" id="hr-offdates"><h5 class="card-header">عطل الموظف</h5><div class="card-body">
    <asp:Panel ID="pnlOffFilters" runat="server" CssClass="mb-3"><p class="text-muted small">خدمة العطل تتطلب التسلسل والشهر وتاريخ العطلة وتاريخ البداية للاستعلام.</p><div class="row g-3">
     <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtOffSerial" CssClass="form-label" Text="تسلسل العطلة" /><asp:TextBox ID="txtOffSerial" runat="server" TextMode="Number" CssClass="form-control" /></div>
     <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtOffMonth" CssClass="form-label" Text="شهر العطلة" /><asp:TextBox ID="txtOffMonth" runat="server" TextMode="Month" CssClass="form-control" /></div>
     <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtOffDate" CssClass="form-label" Text="تاريخ العطلة" /><asp:TextBox ID="txtOffDate" runat="server" TextMode="Date" CssClass="form-control" /></div>
     <div class="col-md-3"><asp:Label runat="server" AssociatedControlID="txtOffStart" CssClass="form-label" Text="تاريخ البداية" /><asp:TextBox ID="txtOffStart" runat="server" TextMode="Date" CssClass="form-control" /></div>
    </div></asp:Panel>
    <asp:Button ID="btnOffDates" runat="server" CssClass="btn btn-outline-primary mb-3" Text="عرض العطلة" OnClick="ShowOffDates" CausesValidation="false" />
    <asp:Literal ID="litOffDates" runat="server" />
   </div></div>
   <div class="card mb-4" id="hr-penalties"><h5 class="card-header">الجزاءات والإنذارات</h5><div class="card-body">
    <asp:Panel ID="pnlPenaltyFilters" runat="server" CssClass="mb-3"><p class="text-muted small">خدمة الجزاءات تستعلم برقم الجزاء أو الإنذار.</p><asp:Label runat="server" AssociatedControlID="txtPenaltyNo" CssClass="form-label" Text="رقم الجزاء أو الإنذار" /><asp:TextBox ID="txtPenaltyNo" runat="server" TextMode="Number" CssClass="form-control" /></asp:Panel>
    <asp:Button ID="btnPenalties" runat="server" CssClass="btn btn-outline-primary mb-3" Text="عرض الجزاء أو الإنذار" OnClick="ShowPenalties" CausesValidation="false" />
    <asp:Literal ID="litPenalties" runat="server" />
   </div></div>
   <div class="card mb-4" id="hr-custody"><h5 class="card-header">عهد الموظف</h5><div class="card-body"><asp:Literal ID="litCustody" runat="server" /></div></div>
   <div class="card mb-4" id="hr-files"><h5 class="card-header">ملفات الموظف</h5><div class="card-body">
    <asp:Literal ID="litFilesMessage" runat="server" />
    <div class="table-responsive"><table class="table table-bordered card-list-table mb-0"><thead><tr><th>اسم الملف</th><th>تاريخ الإضافة</th><th>تاريخ الانتهاء</th><th>عرض</th></tr></thead><tbody>
     <asp:Repeater ID="rptFiles" runat="server"><ItemTemplate><tr>
      <td data-title="اسم الملف"><%#: Eval("Name") %></td><td data-title="تاريخ الإضافة"><%#: Eval("EntryDate") %></td><td data-title="تاريخ الانتهاء"><%#: Eval("ExpiryDate") %></td>
      <td data-title="عرض"><asp:HyperLink runat="server" NavigateUrl='<%# Eval("Url") %>' Visible='<%# CStr(Eval("Url")).Length > 0 %>' Target="_blank" rel="noopener noreferrer" referrerpolicy="no-referrer" CssClass="btn btn-sm btn-outline-primary" Text="فتح الملف" /><asp:Label runat="server" Visible='<%# CStr(Eval("Url")).Length = 0 %>' Text="رابط غير متاح" CssClass="text-muted" /></td>
     </tr></ItemTemplate></asp:Repeater>
    </tbody></table></div>
   </div></div>
  </asp:Panel>
  </ContentTemplate></asp:UpdatePanel>
  <asp:UpdateProgress runat="server" AssociatedUpdatePanelID="updHR" DisplayAfter="150"><ProgressTemplate><div class="alert alert-info" role="status">جارٍ تحميل بيانات الموارد البشرية…</div></ProgressTemplate></asp:UpdateProgress>
 </div>
</asp:Content>
