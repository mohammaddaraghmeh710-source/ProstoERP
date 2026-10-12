<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="PrintQRCode.aspx.vb" Inherits="CRM.PrintQRCode" %>

<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head runat="server">
    <meta charset="utf-8" />
    <title>Print QR</title>
    <style>
        html, body { margin:0; padding:0; background:#fff; }
        .wrap{
            width:100vw; height:100vh;
            display:flex;
            align-items:center;
            justify-content:center;
        }
        img{
            width:320px; height:320px;
            object-fit:contain;
        }
        @media print{
            @page { margin: 0; }
            html, body { width:100%; height:100%; }
        }
    </style>
</head>
<body>
<form id="form1" runat="server">
    <div class="wrap">
        <asp:Image ID="imgQR" runat="server" />
    </div>

    <script>
        window.onload = function () { window.print(); };
    </script>
</form>
</body>
</html>