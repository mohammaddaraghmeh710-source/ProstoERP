<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="CircularReader.ascx.vb" Inherits="CRM.CircularReader" %>
<link rel="stylesheet" href="/assets/css/circular-reader.css?v=20261021c" />
<div id="circularReader" class="modal fade circular-reader" tabindex="-1" aria-labelledby="readerTitle" aria-hidden="true" data-kind="<%= ReaderMode %>" data-csrf="<%= Global.System.Web.HttpUtility.HtmlAttributeEncode(CurrentToken) %>" data-endpoint="/CircularReader.aspx" data-initial-id="<%= InitialID %>">
 <div class="modal-dialog modal-xl modal-dialog-scrollable modal-fullscreen-lg-down"><div class="modal-content">
  <div class="modal-header border-bottom"><h2 class="modal-title h5 mb-0" id="readerTitle">عرض التعميم</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div>
  <div class="modal-body">
   <div class="reader-metadata" id="readerMetadata" dir="rtl" hidden>
    <div class="reader-heading"><div class="reader-text"><h3 class="h5 mb-2" id="readerDocumentTitle"></h3><div class="reader-details text-muted small"><span id="readerBrand"></span><time id="readerDate"></time><span id="readerVersion"></span></div></div><button type="button" class="btn btn-sm btn-label-primary reader-language" id="readerLanguage" aria-label="عرض التعميم باللغة الإنجليزية">English</button></div>
    <p id="readerSummary" class="reader-summary mb-3 mt-3"></p>
    <div class="reader-filebar border-top pt-3"><span class="reader-filename text-muted small"><i class="bx bxs-file-pdf text-danger me-1" aria-hidden="true"></i><span id="readerFileName"></span></span><div class="reader-file-actions"><span class="badge bg-label-warning" id="readerReadState"></span><button type="button" class="btn btn-sm btn-label-primary" id="readerDownload" hidden disabled><i class="bx bx-download me-1" aria-hidden="true"></i>تحميل PDF</button></div></div>
   </div>
   <div id="readerStatus" class="text-muted small py-3" role="status" aria-live="polite"></div>
   <div id="readerPdfControls" class="reader-pdf-controls border-top border-bottom py-2" hidden>
    <button type="button" id="readerPrevious" class="btn btn-sm btn-label-secondary" disabled aria-label="الصفحة السابقة"><i class="bx bx-chevron-right" aria-hidden="true"></i><span>السابق</span></button><span id="readerPageLabel" class="small" dir="ltr">—</span><button type="button" id="readerNext" class="btn btn-sm btn-label-secondary" disabled aria-label="الصفحة التالية"><span>التالي</span><i class="bx bx-chevron-left" aria-hidden="true"></i></button>
    <span class="reader-control-divider" aria-hidden="true"></span><button type="button" id="readerZoomOut" class="btn btn-sm btn-icon btn-label-secondary" disabled aria-label="تصغير"><i class="bx bx-zoom-out" aria-hidden="true"></i></button><span id="readerZoomLabel" class="small" dir="ltr">100%</span><button type="button" id="readerZoomIn" class="btn btn-sm btn-icon btn-label-secondary" disabled aria-label="تكبير"><i class="bx bx-zoom-in" aria-hidden="true"></i></button>
   </div>
   <div class="reader-canvas-wrap" id="readerCanvasWrap" hidden><canvas id="readerPdfCanvas" aria-label="صفحة ملف التعميم"></canvas></div>
   <button type="button" id="readerRetry" class="btn btn-sm btn-label-primary mt-2" hidden><i class="bx bx-refresh me-1" aria-hidden="true"></i>إعادة المحاولة</button>
  </div>
 </div></div>
</div>
<script src="/assets/js/pdf.min.js"></script><script src="/assets/js/circular-reader.js?v=20261021b"></script>
