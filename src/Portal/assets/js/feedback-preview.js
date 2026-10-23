(function () {
 'use strict';
 function ready() {
  var root = document.getElementById('feedback-preview');
  if (!root || root.dataset.previewBound) return;
  root.dataset.previewBound = '1';
  var status = document.getElementById('feedback-preview-status'), controls = document.getElementById('feedback-preview-controls');
  var surface = document.getElementById('feedback-preview-surface'), canvas = document.getElementById('feedback-preview-canvas'), image = document.getElementById('feedback-preview-image');
  var previous = document.getElementById('feedback-preview-previous'), next = document.getElementById('feedback-preview-next'), label = document.getElementById('feedback-preview-page');
  var generation = 0, controller = null, loadingTask = null, pdf = null, renderTask = null, imageURL = null, page = 1, busy = false, resizeTimer;
  var closing = false, closed = Promise.resolve(), resolveClosed = null, lastTrigger = null;
  function message(text, failed) { status.hidden = !text; status.textContent = text; status.className = failed ? 'alert alert-danger mb-3' : 'text-muted small py-3'; status.setAttribute('role', failed ? 'alert' : 'status'); }
  function buttons() { previous.disabled = busy || !pdf || page <= 1; next.disabled = busy || !pdf || page >= pdf.numPages; }
  async function release() {
   var oldRender = renderTask, oldLoading = loadingTask, oldPdf = pdf;
   renderTask = loadingTask = pdf = null;
   var jobs = [];
   if (oldRender) { oldRender.cancel(); jobs.push(oldRender.promise.catch(function () {})); }
   if (oldLoading) jobs.push(Promise.resolve(oldLoading.destroy()).catch(function () {}));
   else if (oldPdf) jobs.push(Promise.resolve(oldPdf.destroy()).catch(function () {}));
   image.onload = image.onerror = null; image.removeAttribute('src');
   if (imageURL) { URL.revokeObjectURL(imageURL); imageURL = null; }
   canvas.width = canvas.height = 0;
   await Promise.all(jobs);
  }
  function reset() { controls.hidden = surface.hidden = true; canvas.hidden = image.hidden = true; label.textContent = '—'; buttons(); }
  function dialog(ticket) {
   if (root.classList.contains('show')) return Promise.resolve();
   return new Promise(function (resolve) {
    function finish() { root.removeEventListener('shown.bs.modal', finish); root.removeEventListener('hide.bs.modal', finish); resolve(); }
    root.addEventListener('shown.bs.modal', finish); root.addEventListener('hide.bs.modal', finish);
    window.bootstrap.Modal.getOrCreateInstance(root).show();
   });
  }
  async function render(ticket) {
   if (!pdf || ticket !== generation) return;
   var documentPdf = pdf, pdfPage = await documentPdf.getPage(page);
   if (ticket !== generation) return;
   var base = pdfPage.getViewport({ scale: 1 }), width = Math.max(40, surface.clientWidth - 18);
   var scale = Math.min(width / base.width, 4, Math.sqrt(5000000 / (base.width * base.height)), 16384 / base.width, 16384 / base.height);
   if (!Number.isFinite(scale) || scale <= 0) throw new Error('أبعاد صفحة PDF غير صالحة.');
   var viewport = pdfPage.getViewport({ scale: scale });
   canvas.width = Math.ceil(viewport.width); canvas.height = Math.ceil(viewport.height);
   var task = pdfPage.render({ canvasContext: canvas.getContext('2d'), viewport: viewport, background: 'rgb(255,255,255)' }); renderTask = task;
   try { await task.promise; } finally { if (renderTask === task) renderTask = null; }
   if (ticket === generation) label.textContent = page + ' / ' + documentPdf.numPages;
  }
  function showImage(data, mime, signal) {
   imageURL = URL.createObjectURL(new Blob([data], { type: mime }));
   return new Promise(function (resolve, reject) {
    function cleanup() { image.onload = image.onerror = null; signal.removeEventListener('abort', aborted); }
    function aborted() { cleanup(); var error = new Error('Cancelled'); error.name = 'AbortError'; reject(error); }
    image.onload = function () { cleanup(); resolve(); }; image.onerror = function () { cleanup(); reject(new Error('تعذر عرض الصورة. يمكنك تنزيل المرفق من القائمة.')); };
    signal.addEventListener('abort', aborted, { once: true });
    if (signal.aborted) { aborted(); return; }
    image.src = imageURL;
   });
  }
  async function open(href) {
   var ticket = ++generation;
   if (controller) controller.abort(); controller = null;
   clearTimeout(resizeTimer); busy = true; reset(); message('جارٍ تحميل المرفق للمعاينة…', false);
   try {
    await release(); if (ticket !== generation) return;
    if (closing) { await closed; if (ticket !== generation) return; }
    var url = new URL(href, location.href);
    if (url.origin !== location.origin) throw new Error('رابط المرفق غير صالح.');
    if (!window.bootstrap) throw new Error('تعذر فتح نافذة المعاينة. أعد تحميل الصفحة.');
    var shown = dialog(ticket);
    controller = new AbortController(); var signal = controller.signal;
    var response = await fetch(url.href, { credentials: 'same-origin', cache: 'no-store', signal: signal });
    if (!response.ok) throw new Error(response.status === 401 || response.status === 403 ? 'انتهت جلسة الدخول أو لم تعد تملك صلاحية المرفق.' : 'تعذر تحميل المرفق. تحقق من صلاحيته وأعد المحاولة.');
    var mime = (response.headers.get('Content-Type') || '').split(';')[0].trim().toLowerCase();
    if (!['application/pdf', 'image/png', 'image/jpeg', 'image/gif'].includes(mime)) throw new Error('المعاينة غير متاحة أو انتهت جلسة الدخول. يمكنك إعادة تسجيل الدخول أو تنزيل المرفق.');
    var data = await response.arrayBuffer(); if (ticket !== generation) return;
    if (!data.byteLength) throw new Error('المرفق فارغ أو لم يكتمل تحميله.');
    if (mime === 'application/pdf') {
     if (!window.pdfjsLib) throw new Error('تعذر تحميل عارض PDF. أعد تحميل الصفحة.');
     window.pdfjsLib.GlobalWorkerOptions.workerSrc = '/assets/js/pdf.worker.min.js';
     var task = window.pdfjsLib.getDocument({ data: new Uint8Array(data), isEvalSupported: false, enableScripting: false, disableFontFace: true, useSystemFonts: false, standardFontDataUrl: '/assets/vendor/libs/pdfjs/standard_fonts/' }); loadingTask = task;
     var loaded = await task.promise; if (ticket !== generation) { await loaded.destroy(); return; }
     pdf = loaded; loadingTask = null; page = 1;
     await shown; if (ticket !== generation) return;
     surface.hidden = canvas.hidden = false; controls.hidden = false;
     await new Promise(function (resolve) { requestAnimationFrame(resolve); });
     if (ticket !== generation) return;
     await render(ticket);
    } else {
     await shown; if (ticket !== generation) return;
     surface.hidden = image.hidden = false; await showImage(data, mime, signal);
    }
    if (ticket === generation) message('', false);
   } catch (error) {
    if (ticket === generation && error.name !== 'AbortError' && error.name !== 'RenderingCancelledException') { reset(); message(error.message || 'تعذر عرض المرفق.', true); }
   } finally { if (ticket === generation) { busy = false; controller = null; buttons(); } }
  }
  async function changePage(delta) {
   if (busy || !pdf || page + delta < 1 || page + delta > pdf.numPages) return;
   var ticket = generation; page += delta; busy = true; buttons(); message('جارٍ عرض الصفحة…', false);
   try { await render(ticket); if (ticket === generation) message('', false); }
   catch (error) { if (ticket === generation && error.name !== 'RenderingCancelledException') message('تعذر عرض الصفحة. أعد فتح المرفق للمحاولة مجددًا.', true); }
   finally { if (ticket === generation) { busy = false; buttons(); } }
  }
  previous.addEventListener('click', function () { changePage(-1); }); next.addEventListener('click', function () { changePage(1); });
  root.addEventListener('hide.bs.modal', function () {
   if (!closing) { closing = true; closed = new Promise(function (resolve) { resolveClosed = resolve; }); }
   generation++; if (controller) controller.abort(); controller = null; clearTimeout(resizeTimer); busy = false; reset(); release().catch(function () {});
  });
  root.addEventListener('hidden.bs.modal', function () { closing = false; var resolve = resolveClosed; resolveClosed = null; if (resolve) resolve(); if (lastTrigger && lastTrigger.isConnected) lastTrigger.focus(); });
  window.addEventListener('resize', function () { clearTimeout(resizeTimer); resizeTimer = setTimeout(function () { if (pdf && !busy && root.classList.contains('show')) changePage(0); }, 150); });
  // Window capture precedes Bootstrap's delegated document capture/toggle handler.
  window.addEventListener('click', function (event) { var link = event.target.closest('[data-feedback-preview]'); if (!link) return; event.preventDefault(); event.stopPropagation(); lastTrigger = link; open(link.href); }, true);
 }
 if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', ready); else ready();
}());
