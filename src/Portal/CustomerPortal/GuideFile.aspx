<%@ Page Title="مشاهدة دليل العمل"
    Language="vb"
    AutoEventWireup="false"
    MasterPageFile="~/Customer.Master"
    CodeBehind="GuideFile.aspx.vb"
    Inherits="CRM.CustomerGuideFile" %>

<asp:Content ID="Content1"
    ContentPlaceHolderID="HeadContent"
    runat="server">

    <style>
        .work-guide-viewer-page {
            direction: rtl;
            padding-top: 20px;
            padding-bottom: 30px;
        }

        .work-guide-viewer-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 18px;
            padding: 16px 20px;
            border: 1px solid #e7eaf3;
            border-radius: 14px;
            background: #ffffff;
            box-shadow: 0 2px 10px rgba(67, 89, 113, 0.08);
        }

        .work-guide-viewer-title-wrapper {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .work-guide-viewer-icon {
            width: 45px;
            height: 45px;
            border-radius: 12px;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: rgba(134, 38, 51, 0.1);
            color: #862633;
            font-size: 25px;
            flex-shrink: 0;
        }

        .work-guide-viewer-title {
            margin: 0;
            color: #384551;
            font-size: 18px;
            font-weight: 700;
            line-height: 1.6;
        }

        .work-guide-viewer-note {
            margin: 3px 0 0;
            color: #8592a3;
            font-size: 13px;
        }

        .work-guide-viewer-container {
            position: relative;
            min-height: 500px;
            padding: 20px;
            overflow-x: auto;
            border: 1px solid #e7eaf3;
            border-radius: 14px;
            background-color: #525659;
            box-shadow: 0 2px 10px rgba(67, 89, 113, 0.08);
            user-select: none;
            -webkit-user-select: none;
        }

        .pdf-pages-container {
            width: 100%;
        }

        .pdf-page-wrapper {
            position: relative;
            width: fit-content;
            max-width: 100%;
            margin: 0 auto 20px auto;
            background-color: #ffffff;
            box-shadow: 0 3px 14px rgba(0, 0, 0, 0.35);
        }

        .pdf-page-wrapper canvas {
            display: block;
            max-width: 100%;
            height: auto;
        }

        .pdf-watermark {
            position: absolute;
            inset: 0;
            z-index: 2;
            pointer-events: none;
            overflow: hidden;
        }

        .pdf-watermark-text {
            position: absolute;
            top: 50%;
            left: 50%;
            width: 90%;
            transform: translate(-50%, -50%) rotate(-30deg);
            text-align: center;
            font-size: 28px;
            font-weight: 700;
            color: rgba(80, 80, 80, 0.12);
            white-space: nowrap;
        }

        .pdf-loading-container {
            min-height: 400px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            color: #ffffff;
            text-align: center;
        }

        .pdf-loading-container i {
            margin-bottom: 12px;
            font-size: 45px;
        }

        .pdf-error-container {
            min-height: 350px;
            display: none;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 25px;
            color: #ffffff;
            text-align: center;
        }

        .pdf-error-container i {
            margin-bottom: 12px;
            font-size: 50px;
            color: #ffb4ab;
        }

        .viewer-security-note {
            display: flex;
            align-items: center;
            gap: 7px;
            color: #8592a3;
            font-size: 13px;
        }

        @media (max-width: 767.98px) {
            .work-guide-viewer-page {
                padding: 10px;
            }

            .work-guide-viewer-header {
                display: block;
                padding: 15px;
            }

            .work-guide-viewer-title-wrapper {
                align-items: flex-start;
            }

            .viewer-security-note {
                margin-top: 12px;
                padding-top: 12px;
                border-top: 1px solid #edf0f5;
            }

            .work-guide-viewer-container {
                min-height: 400px;
                padding: 8px;
                border-radius: 10px;
            }

            .pdf-page-wrapper {
                margin-bottom: 10px;
            }

            .pdf-watermark-text {
                font-size: 17px;
            }
        }

        @media print {
            body { <%=If(AllowDocumentPrint, "visibility:hidden;", "display:none !important;")%> }
            .work-guide-viewer-page, .work-guide-viewer-page * { visibility:visible; }
            .work-guide-viewer-page { position:absolute; top:0; left:0; width:100%; }
            .viewer-security-note, #wgPrintButton, .pdf-loading-container { display:none !important; }
            .pdf-page-wrapper { break-inside:avoid; }
        }
    </style>

</asp:Content>

<asp:Content ID="Content2"
    ContentPlaceHolderID="ContentPlaceHolder1"
    runat="server">

    <asp:HiddenField ID="hfPdfStreamUrl" runat="server" />
    <asp:HiddenField ID="hfWatermarkText" runat="server" />

    <div class="container-xxl flex-grow-1 container-p-y work-guide-viewer-page">

        <div class="work-guide-viewer-header">

            <div class="work-guide-viewer-title-wrapper">

                <div class="work-guide-viewer-icon">
                    <i class="bx bxs-file-pdf"></i>
                </div>

                <div>
                    <h5 class="work-guide-viewer-title">
                        <asp:Label ID="lblDocumentTitle"
                            runat="server"
                            Text="مشاهدة الملف">
                        </asp:Label>
                    </h5>

                    <p class="work-guide-viewer-note">
                        هذا الملف متاح للمشاهدة داخل النظام فقط.
                    </p>
                </div>

            </div>

            <div class="viewer-security-note">
                <i class="bx bx-lock-alt"></i>
                <%=If(AllowDocumentPrint, "الطباعة متاحة حسب الدور المعتمد", "الطباعة غير متاحة حسب الدور المعتمد")%>
                <button id="wgPrintButton" type="button" class="btn btn-sm btn-label-primary" disabled style='<%=If(AllowDocumentPrint, "", "display:none;")%>' onclick="window.print()">طباعة</button>
            </div>

        </div>

        <div id="pdfViewerContainer"
            class="work-guide-viewer-container"
            oncontextmenu="return false;">

            <div id="pdfLoadingContainer" class="pdf-loading-container">
                <i class="bx bx-loader-alt bx-spin"></i>
                <strong>جاري تحميل الملف...</strong>
                <small class="mt-2">يرجى عدم إغلاق الصفحة</small>
            </div>

            <div id="pdfErrorContainer" class="pdf-error-container">
                <i class="bx bx-error-circle"></i>
                <strong>تعذر عرض الملف</strong>
                <small id="pdfErrorMessage" class="mt-2"></small>
            </div>

            <div id="pdfPagesContainer"
                class="pdf-pages-container">
            </div>

        </div>

    </div>

    <script src="<%=ResolveUrl("/assets/js/pdf.min.js")%>"></script>

    <script>
        (function () {
            "use strict";

            const pdfStreamUrl =
                document.getElementById("<%=hfPdfStreamUrl.ClientID%>").value;

            const watermarkText =
                document.getElementById("<%=hfWatermarkText.ClientID%>").value;

            const loadingContainer =
                document.getElementById("pdfLoadingContainer");

            const errorContainer =
                document.getElementById("pdfErrorContainer");

            const errorMessage =
                document.getElementById("pdfErrorMessage");

            const pagesContainer =
                document.getElementById("pdfPagesContainer");

            if (typeof pdfjsLib === "undefined") {
                showError("لم يتم تحميل مكتبة عرض ملفات PDF.");
                return;
            }

            pdfjsLib.GlobalWorkerOptions.workerSrc =
                "<%=ResolveUrl("/assets/js/pdf.worker.min.js")%>";

            const allowPrint = <%=If(AllowDocumentPrint, "true", "false")%>;
            disableDownloadAndPrintShortcuts();
            loadPdf();

            async function loadPdf() {
                try {
                    const loadingTask = pdfjsLib.getDocument({
                        url: pdfStreamUrl,
                        withCredentials: true,
                        disableAutoFetch: false,
                        disableStream: false
                    });

                    const pdfDocument = await loadingTask.promise;

                    loadingContainer.style.display = "none";

                    for (let pageNumber = 1;
                        pageNumber <= pdfDocument.numPages;
                        pageNumber++) {

                        await renderPage(pdfDocument, pageNumber);
                    }
                    if (allowPrint) document.getElementById('wgPrintButton').disabled = false;
                }
                catch (error) {
                    console.error(error);
                    showError("لا تملك صلاحية مشاهدة الملف أو أن الملف غير متاح.");
                }
            }

            async function renderPage(pdfDocument, pageNumber) {
                const page = await pdfDocument.getPage(pageNumber);

                const baseViewport = page.getViewport({
                    scale: 1
                });

                const viewerWidth =
                    document.getElementById("pdfViewerContainer").clientWidth - 30;

                let scale = 1.4;

                if (baseViewport.width * scale > viewerWidth) {
                    scale = viewerWidth / baseViewport.width;
                }

                if (scale < 0.5) {
                    scale = 0.5;
                }

                const viewport = page.getViewport({
                    scale: scale
                });

                const pageWrapper = document.createElement("div");
                pageWrapper.className = "pdf-page-wrapper";

                const canvas = document.createElement("canvas");
                const context = canvas.getContext("2d", {
                    alpha: false
                });

                const outputScale = window.devicePixelRatio || 1;

                canvas.width = Math.floor(viewport.width * outputScale);
                canvas.height = Math.floor(viewport.height * outputScale);

                canvas.style.width = Math.floor(viewport.width) + "px";
                canvas.style.height = Math.floor(viewport.height) + "px";

                const watermark = document.createElement("div");
                watermark.className = "pdf-watermark";

                const watermarkLabel = document.createElement("div");
                watermarkLabel.className = "pdf-watermark-text";
                watermarkLabel.textContent = watermarkText;

                watermark.appendChild(watermarkLabel);

                pageWrapper.appendChild(canvas);
                pageWrapper.appendChild(watermark);
                pagesContainer.appendChild(pageWrapper);

                const transform =
                    outputScale !== 1
                        ? [outputScale, 0, 0, outputScale, 0, 0]
                        : null;

                await page.render({
                    canvasContext: context,
                    viewport: viewport,
                    transform: transform
                }).promise;
            }

            function showError(message) {
                loadingContainer.style.display = "none";
                pagesContainer.style.display = "none";
                errorContainer.style.display = "flex";
                errorMessage.textContent = message;
            }

            function disableDownloadAndPrintShortcuts() {
                document.addEventListener("keydown", function (event) {
                    const key = String(event.key || "").toLowerCase();

                    const isSave =
                        (event.ctrlKey || event.metaKey) && key === "s";

                    const isPrint =
                        (event.ctrlKey || event.metaKey) && key === "p";

                    const isViewSource =
                        (event.ctrlKey || event.metaKey) && key === "u";

                    if (isSave || (isPrint && !allowPrint) || isViewSource) {
                        event.preventDefault();
                        event.stopPropagation();
                        return false;
                    }
                }, true);

                document.addEventListener("contextmenu", function (event) {
                    event.preventDefault();
                    return false;
                });
            }
        })();
    </script>

</asp:Content>