<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="PrintQRCode1.aspx.vb" Inherits="CRM.PrintQRCode1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">

     <style>
        .qr-print-wrap { direction: rtl; text-align: center; }
        .qr-card {
            max-width: 520px;
            margin: 0 auto;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            padding: 18px;
            background: #fff;
        }
        .qr-img { width: 280px; height: 280px; object-fit: contain; }
        .qr-meta { margin-top: 10px; color: #444; font-size: 14px; line-height: 1.6; }
        .qr-actions { margin-top: 14px; display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; }
        .qr-hint { margin-top: 10px; color:#6b7280; font-size: 12px; }

        @media print {
            .no-print { display: none !important; }
            .qr-card { border: none; }
            body { background: #fff; }
        }
    </style>

</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y qr-print-wrap">

        <div class="qr-card">

            <h5 class="mb-2">QR Code</h5>

            <asp:Image ID="imgQR" runat="server" CssClass="qr-img" />

            <div class="qr-meta">
                <asp:Literal ID="litInfo" runat="server"></asp:Literal>
            </div>

            <div class="qr-actions no-print">
                <asp:LinkButton ID="btnPrint" runat="server" CssClass="btn btn-primary" OnClientClick="window.print(); return false;">
                    طباعة
                </asp:LinkButton>

                <asp:LinkButton ID="btnBack" runat="server" CssClass="btn btn-label-secondary" OnClick="btnBack_Click">
                    رجوع
                </asp:LinkButton>
            </div>

            <div class="qr-hint">
                * هذا الـ QR لا يحتوي رابط، ويعمل فقط عند قراءته من داخل النظام عبر صفحة QRCode_Reader.
            </div>

        </div>


    </div>
</asp:Content>
