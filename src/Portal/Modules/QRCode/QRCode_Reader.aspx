<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="QRCode_Reader.aspx.vb" Inherits="CRM.QRCode_Reader" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .qr-reader-wrap { direction: rtl; text-align: right; }
        .qr-box {
            max-width: 520px;
            margin: 0 auto;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            padding: 16px;
            background: #fff;
        }
        #qr-reader { width: 100%; max-width: 420px; margin: 10px auto 0; }
        #qrResult { margin-top: 10px; text-align: center; font-weight: 600; }
        .qr-actions { display:flex; gap:10px; justify-content:center; flex-wrap:wrap; margin-top:10px; }
        .qr-note { color:#6b7280; font-size:12px; margin-top:8px; text-align:center; }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    

    <div class="container-xxl flex-grow-1 container-p-y qr-reader-wrap">
        <div class="qr-box">

            <h5 class="mb-2">قراءة QR Code</h5>

            <div class="qr-actions">
                <button type="button" id="btnScanQr" class="btn btn-primary">
                    فتح الكاميرا ومسح QR
                </button>

                <button type="button" id="btnStopQr" class="btn btn-label-secondary" disabled>
                    إيقاف الكاميرا
                </button>

                <asp:Button runat="server" ID="btnback" Visible="false" CssClass="btn btn-label-danger" Text="رجوع" OnClick="btnback_Click" />

               

            </div>

            <div id="qrSection" style="margin-top:12px; display:none;">
                <div id="qr-reader"></div>
                <p id="qrResult"></p>
            </div>

            <div class="qr-note">
                * سيتم قبول QR فقط إذا كان تابعاً للنظام (CRMQR) وتم التحقق منه عبر السيرفر.
            </div>

        </div>
    </div>

    <script src="https://unpkg.com/html5-qrcode" type="text/javascript"></script>

    <script type="text/javascript">
        let html5QrCode = null;
        let isRunning = false;

        const btnScan = document.getElementById("btnScanQr");
        const btnStop = document.getElementById("btnStopQr");
        const qrSection = document.getElementById("qrSection");
        const qrResult = document.getElementById("qrResult");

        function setStatus(msg, isError) {
            qrResult.innerText = msg || "";
            qrResult.style.color = isError ? "#b42318" : "#111827";
        }

        btnScan.addEventListener("click", function () {
            qrSection.style.display = "block";
            setStatus("", false);

            if (!html5QrCode) {
                html5QrCode = new Html5Qrcode("qr-reader");
            }

            if (isRunning) return;

            const config = { fps: 10, qrbox: { width: 250, height: 250 } };

            html5QrCode.start(
                { facingMode: "environment" },
                config,
                (decodedText) => {

                    if (!decodedText || !decodedText.startsWith("CRMQR:")) {
                        setStatus("هذا QR غير تابع للنظام.", true);
                        return;
                    }

                    const token = decodedText.replace("CRMQR:", "").trim();
                    if (!token) {
                        setStatus("QR غير صالح.", true);
                        return;
                    }

                    setStatus("جارٍ التحقق من QR ...", false);

                    // نوقف الكاميرا قبل التوجيه
                    html5QrCode.stop().then(() => {
                        isRunning = false;
                        btnStop.disabled = true;
                        btnScan.disabled = false;

                        // حلّ الـ token عبر السيرفر (WebMethod)
                        PageMethods.ResolveCrmQr(token,
                            function (res) {
                                if (res && res.ok && res.url) {
                                    window.location.href = res.url;
                                } else {
                                    setStatus((res && res.msg) ? res.msg : "QR غير معتمد داخل النظام.", true);
                                }
                            },
                            function () {
                                setStatus("فشل الاتصال بالسيرفر للتحقق من QR.", true);
                            }
                        );

                    }).catch(err => {
                        console.error(err);
                        setStatus("حدث خطأ أثناء إيقاف الكاميرا.", true);
                    });

                },
                (errorMessage) => {
                    // نتجاهل أخطاء القراءة المتكررة أثناء المسح
                }
            ).then(() => {
                isRunning = true;
                btnStop.disabled = false;
                btnScan.disabled = true;
            }).catch((err) => {
                console.error(err);
                setStatus("تعذر فتح الكاميرا. تأكد من إعطاء الصلاحية للمتصفح.", true);
            });
        });

        btnStop.addEventListener("click", function () {
            if (!html5QrCode || !isRunning) return;

            html5QrCode.stop().then(() => {
                isRunning = false;
                btnStop.disabled = true;
                btnScan.disabled = false;
                setStatus("تم إيقاف الكاميرا.", false);
            }).catch(err => {
                console.error(err);
                setStatus("تعذر إيقاف الكاميرا.", true);
            });
        });
    </script>


    <script type="text/javascript">
        function autoStartQr() {
            // شغّل المسح تلقائياً إذا لم يكن شغال
            try {
                if (btnScan && !isRunning && !btnScan.disabled) {
                    btnScan.click();
                }
            } catch (e) { }
        }

        document.addEventListener("DOMContentLoaded", function () {
            // تأخير بسيط حتى تجهز الصفحة + عناصر الكاميرا
            setTimeout(autoStartQr, 350);
        });

        // مهم جداً لو عندك UpdatePanel (حتى لا يتعطل بعد AsyncPostBack)
        if (window.Sys && Sys.WebForms) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
                setTimeout(autoStartQr, 200);
            });
        }
    </script>



</asp:Content>

