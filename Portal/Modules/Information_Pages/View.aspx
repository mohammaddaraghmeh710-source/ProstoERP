<%@ Page Title="صفحة معلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="View.aspx.vb" Inherits="CRM.ViewInformationPage" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/customer-detail.css?v=20261018d"/><style>.information-content{overflow-wrap:anywhere;overflow-x:auto;line-height:1.9}.information-content table{border-collapse:collapse;width:100%;margin:1rem 0}.information-content td,.information-content th{border:1px solid #ddd;padding:.6rem}.information-content blockquote{border-inline-start:3px solid #696cff;padding-inline-start:1rem}</style></asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
<asp:Literal ID="litMessage" runat="server" /><asp:Panel ID="pnlPage" runat="server" Visible="false"><input id="detailLanguage" type="hidden" runat="server" data-detail-language-value="1"/>
<asp:Panel ID="pnlPreview" runat="server" Visible="false" CssClass="alert alert-warning">معاينة إدارية — قد لا يكون هذا الإصدار متاحًا للمستخدمين. <a href="Manage.aspx" class="btn btn-sm btn-label-secondary ms-2">العودة إلى الإدارة</a> <asp:HyperLink ID="lnkHistory" runat="server" Text="الإصدارات" /></asp:Panel>
<article class="card">
    <header data-detail-header="1" class="card-header border-bottom p-lg-5 d-flex justify-content-between align-items-start flex-wrap gap-3">
        <div style="min-width:0;overflow-wrap:anywhere">
            <h2 class="mb-3" data-detail-lang="ar" data-detail-title="1" dir="rtl"><asp:Literal ID="litTitle" runat="server" Mode="Encode" /></h2><h2 class="mb-3" data-detail-lang="en" data-detail-title="1" dir="ltr"><asp:Literal ID="litTitleEn" runat="server" Mode="Encode" /></h2>
            <div class="d-flex flex-wrap align-items-center gap-3 text-muted" data-detail-metadata="1">
                <span class="badge bg-label-primary"><span data-detail-lang="ar"><asp:Literal ID="litVersion" runat="server" Mode="Encode" /></span><span data-detail-lang="en"><asp:Literal ID="litVersionEn" runat="server" Mode="Encode" /></span></span>
                <span><span data-detail-lang="ar">تاريخ الإصدار: </span><span data-detail-lang="en">Version date: </span><bdi><asp:Literal ID="litVersionDate" runat="server" Mode="Encode" /></bdi></span>
            </div>
        </div>
        <button type="button" class="btn btn-outline-primary flex-shrink-0" data-detail-language-toggle="1" aria-controls="employeeInformationAr employeeInformationEn"><asp:Literal ID="lnkLanguage" runat="server" Mode="Encode"/></button>
    </header>
    <div class="card-body p-lg-5"><div id="employeeInformationAr" class="information-content" data-detail-lang="ar" dir="rtl" lang="ar"><asp:Literal ID="litDetails" runat="server" /></div><div id="employeeInformationEn" class="information-content" data-detail-lang="en" dir="ltr" lang="en"><asp:Literal ID="litDetailsEn" runat="server" /></div></div>
</article>
</asp:Panel></div><script src="/assets/js/detail-language.js?v=20261018d"></script></asp:Content>
