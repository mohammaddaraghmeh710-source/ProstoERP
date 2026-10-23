(function () {
  'use strict';
  if (window.CorrespondenceChat) return;

  var root, active = '0', drafts = Object.create(null), scrolls = Object.create(null), unseen = Object.create(null);
  var manager, hooksBound = false, request = null, navigation = null, uploadActive = false;
  var currentUrl = window.location.href, uploadCount = 0, stickyBottom = true, resizeFrame = 0, tableState = null, localFilterBound = false, editorToken = null, createdThread = null, editorCompleted = false;

  function byId(id) { return document.getElementById(id); }
  function threadId(value) { return /^\d+$/.test(String(value || '')) ? String(parseInt(value, 10)) : '0'; }
  function replyBox() { return byId('txtReply') || root.querySelector('[id$="txtReply"]'); }
  function field(id, value) { var node = byId(id); if (node && value !== undefined) node.value = value; return node; }
  function visible() { field('hfVisible', document.hidden ? '0' : '1'); }
  function serializeDrafts() { field('hfDraftText', JSON.stringify(drafts)); }
  function saveDraft() {
    var box = root && replyBox();
    if (box && active !== '0') drafts[active] = box.value;
    serializeDrafts();
  }
  function restoreDraft() {
    var box = replyBox();
    if (!box) return;
    if (active !== '0' && Object.prototype.hasOwnProperty.call(drafts, active)) box.value = drafts[active];
    box.readOnly = false;
  }
  function notice(text, error) {
    var host = byId('correspondence-client-notice');
    if (!host) {
      host = document.createElement('div');
      host.id = 'correspondence-client-notice';
      host.setAttribute('role', 'status');
      host.setAttribute('aria-live', 'polite');
      root.insertBefore(host, root.firstChild);
    }
    host.className = 'correspondence-client-notice alert alert-' + (error ? 'danger' : 'info');
    host.textContent = text;
    host.hidden = !text;
  }
  function uploadControls() {
    return Array.prototype.map.call(root.querySelectorAll('.ajax__fileupload'), function (node) {
      // Toolkit renders the CSS class on an unnumbered child of its component span.
      var host = node.closest('[id]');
      return window.$find ? window.$find(node.id || (host && host.id) || 'AttachmentUpload') : null;
    }).filter(Boolean);
  }
  // These queue fields are from the bundled AjaxControlToolkit 17.1.1 control.
  // Checking the queue also covers the time before its uploadStart callback arrives.
  function pendingUpload() {
    return uploadActive || uploadControls().some(function (control) {
      return control._isUploading || (control._filesInQueue || []).some(function (file) { return !file._isUploaded; });
    });
  }
  function uploading() { return uploadActive || uploadControls().some(function (control) { return !!control._isUploading; }); }
  function busy() { return !!request || (manager && manager.get_isInAsyncPostBack()); }
  function isBottom(area) { return area.scrollHeight - area.clientHeight - area.scrollTop < 65; }
  function messageTop(node, area) { return node.getBoundingClientRect().top - area.getBoundingClientRect().top + area.scrollTop; }
  function messages() { return Array.prototype.slice.call(root.querySelectorAll('.correspondence-message[data-message-id]')); }
  function snapshotScroll() {
    var area = byId('correspondence-messages');
    if (!area || active === '0') return null;
    var nodes = messages(), firstVisible = nodes.find(function (node) { return messageTop(node, area) + node.offsetHeight >= area.scrollTop; });
    var snapshot = {
      top: area.scrollTop, bottom: isBottom(area),
      ids: nodes.map(function (node) { return node.dataset.messageId; }),
      anchor: firstVisible ? firstVisible.dataset.messageId : '',
      offset: firstVisible ? messageTop(firstVisible, area) - area.scrollTop : 0
    };
    scrolls[active] = snapshot;
    return snapshot;
  }
  function hideNewMessages() { delete unseen[active]; var button = byId('correspondence-new-messages'); if (button) button.hidden = true; }
  function bottom() {
    var area = byId('correspondence-messages');
    if (area) area.scrollTop = area.scrollHeight;
    stickyBottom = true;
    hideNewMessages();
  }
  function restoreScroll(snapshot, forceBottom) {
    var area = byId('correspondence-messages');
    if (!area) return;
    if (forceBottom || !snapshot || snapshot.bottom) { bottom(); return; }
    var anchor = messages().find(function (node) { return node.dataset.messageId === snapshot.anchor; });
    area.scrollTop = anchor ? messageTop(anchor, area) - snapshot.offset : snapshot.top;
    stickyBottom = false;
    var incoming = messages().filter(function (node) { return !snapshot.ids.includes(node.dataset.messageId) && !node.classList.contains('is-own'); });
    var pending = unseen[active] || new Set();
    incoming.forEach(function (node) { pending.add(node.dataset.messageId); });
    if (pending.size) unseen[active] = pending;
    var button = byId('correspondence-new-messages');
    if (button && pending.size) {
      button.hidden = false;
      button.textContent = 'رسائل جديدة (' + pending.size + ') — عرض';
    }
  }
  function loading(value) {
    root.classList.toggle('is-loading', value);
    var main = root.querySelector('.correspondence-main');
    if (main) {
      main.setAttribute('aria-busy', value ? 'true' : 'false');
      if (!main.querySelector('.correspondence-loading')) {
        var overlay = document.createElement('div');
        overlay.className = 'correspondence-loading';
        overlay.setAttribute('role', 'status');
        overlay.textContent = 'جارٍ تحميل المحادثة…';
        main.appendChild(overlay);
      }
    }
  }
  function updateLayout() {
    var sync = byId('correspondence-sync');
    active = threadId(sync ? sync.dataset.thread : root.dataset.thread);
    root.dataset.thread = active;
    field('hfThread', active);
    root.classList.toggle('has-thread', active !== '0');
    var layout = root.querySelector('.correspondence-layout');
    if (layout) layout.classList.toggle('has-thread', active !== '0');
    root.querySelectorAll('[data-thread-id]').forEach(function (link) {
      var selected = active !== '0' && threadId(link.dataset.threadId) === active;
      link.classList.toggle('is-active', selected);
      if (selected) link.setAttribute('aria-current', 'true'); else link.removeAttribute('aria-current');
    });
    var compose = byId('pnlCompose'), close = byId('btnCloseStart'), note = byId('correspondence-live-note'), empty = byId('correspondence-empty');
    if (compose) compose.hidden = active === '0' || !sync || sync.dataset.reply !== '1';
    var composerHost = byId('correspondence-compose');
    // Read-only states already render their notice in the refreshed conversation region.
    if (composerHost) composerHost.hidden = active === '0' || !sync || sync.dataset.reply !== '1';
    if (close) close.hidden = active === '0' || !sync || sync.dataset.close !== '1';
    if (note) { note.hidden = active === '0' || !sync || sync.dataset.reply === '1' || !sync.dataset.note; note.textContent = sync ? sync.dataset.note || '' : ''; }
    if (empty) empty.hidden = active !== '0';
    if (sync && sync.dataset.queued !== undefined) uploadCount = Number(sync.dataset.queued) || 0;
    resize();
  }
  function route(id, sourceUrl) {
    var url = new URL(sourceUrl || currentUrl, window.location.href);
    url.searchParams.delete('ID');
    url.searchParams.delete('id');
    if (id !== '0') url.searchParams.set('ID', id);
    if (root.dataset.scope === 'all') url.searchParams.set('scope', 'all'); else url.searchParams.delete('scope');
    if (root.dataset.draft) url.searchParams.set('draft', root.dataset.draft);
    return url;
  }
  function select(id, sourceUrl, fromHistory) {
    id = threadId(id);
    if (busy() || pendingUpload()) {
      notice(pendingUpload() ? 'ارفع الملفات المحددة أو امسحها قبل تبديل المحادثة.' : 'جارٍ إكمال العملية الحالية، يرجى الانتظار.', false);
      if (fromHistory) window.history.replaceState({ correspondence: active }, '', currentUrl);
      return;
    }
    if (id === active) { if (id !== '0') bottom(); return; }
    if (!manager || !window.__doPostBack || !root.dataset.selectTarget) { window.location.href = route(id, sourceUrl).href; return; }
    saveDraft();
    snapshotScroll();
    navigation = { id: id, url: route(id, sourceUrl).href, history: !!fromHistory, previousUrl: currentUrl };
    field('hfThread', id);
    field('hfNavigation', '1');
    notice('', false);
    window.__doPostBack(root.dataset.selectTarget, '');
    // An initializeRequest cancellation must not leave a stale requested thread.
    if (!request) { navigation = null; field('hfThread', active); field('hfNavigation', '0'); }
  }
  function resize() {
    if (!root) return;
    var layout = root.querySelector('.correspondence-layout');
    if (!layout) return;
    var top = layout.getBoundingClientRect().top;
    var available = Math.max(280, (window.visualViewport ? window.visualViewport.height : window.innerHeight) - Math.max(0, top) - 8);
    root.style.setProperty('--correspondence-height', available + 'px');
  }
  function initializeMessages() {
    var area = byId('correspondence-messages');
    if (!area) return;
    if (!area.dataset.chatBound) {
      area.dataset.chatBound = '1';
      area.setAttribute('tabindex', '0');
      area.addEventListener('scroll', function () { stickyBottom = isBottom(area); if (stickyBottom) hideNewMessages(); snapshotScroll(); }, { passive: true });
    }
    area.querySelectorAll('img').forEach(function (image) {
      if (image.dataset.chatBound) return;
      image.dataset.chatBound = '1';
      image.addEventListener('load', function () { if (stickyBottom) bottom(); else restoreScroll(scrolls[active], false); }, { once: true });
    });
  }
  function editingDetails() {
    var close = root.querySelector('[id$="pnlClose"]');
    return !!document.querySelector('#correspondence-preview.show') ||
      !!document.querySelector('#correspondence-create.show') ||
      !!root.querySelector('details[open], .correspondence-main .dropdown-menu.show, #correspondence-details.show, #correspondence-archive.show') ||
      !!(close && close.getClientRects().length);
  }
  function normalizeSearch(value) {
    return String(value || '').toLocaleLowerCase().replace(/[\u064b-\u065f\u0670\u0640]/g, '')
      .replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/[٠-٩]/g, function (digit) { return String(digit.charCodeAt(0) - 1632); })
      .replace(/[۰-۹]/g, function (digit) { return String(digit.charCodeAt(0) - 1776); }).replace(/\s+/g, ' ').trim();
  }
  function matchesSearch(node) {
    var input = byId('txtTitleSearch'), person = byId('txtPerson');
    var tokens = normalizeSearch(input && input.value).split(' ').filter(Boolean);
    var text = normalizeSearch(node.dataset.searchText || node.textContent), party = normalizeSearch(node.dataset.person || node.textContent);
    return tokens.every(function (token) { return text.indexOf(token) !== -1; }) && party.indexOf(normalizeSearch(person && person.value)) !== -1;
  }
  function tableApi(table) {
    return table && window.jQuery && jQuery.fn.dataTable && jQuery.fn.dataTable.isDataTable(table) ? jQuery(table).DataTable() : null;
  }
  function searchCount(count, total) {
    var label = byId('correspondence-search-count');
    if (label) label.textContent = count === total ? total + ' مراسلة' : count + ' من ' + total + ' مراسلة';
  }
  function applySearch() {
    var table = byId('ERPTable'), api = tableApi(table);
    if (api) { api.draw(); return; }
    var nodes = root.querySelectorAll('.correspondence-thread[data-thread-id], #ERPTable tbody tr[data-search-text]'), count = 0;
    nodes.forEach(function (node) { node.hidden = !matchesSearch(node); if (!node.hidden) count++; });
    var empty = byId('correspondence-search-empty');
    if (empty) empty.hidden = !nodes.length || count > 0;
    searchCount(count, nodes.length);
  }
  function saveTable() {
    var table = byId('ERPTable'), api = tableApi(table);
    if (!api) return;
    tableState = { table: table, search: api.search(), length: api.page.len(), page: api.page() };
  }
  function refreshTable() {
    var table = byId('ERPTable');
    if (!table || !window.CRMList || !CRMList.initializeTable) { applySearch(); return; }
    if (!localFilterBound && window.jQuery && jQuery.fn.dataTable) {
      localFilterBound = true;
      jQuery.fn.dataTable.ext.search.push(function (settings, data, index) {
        if (settings.nTable.id !== 'ERPTable') return true;
        var row = settings.aoData[index] && settings.aoData[index].nTr;
        return !row || !row.dataset.searchText || matchesSearch(row);
      });
    }
    if (tableState && tableState.table !== table) {
      var previous = tableApi(tableState.table);
      if (previous) previous.destroy();
    }
    CRMList.initializeTable();
    var api = tableApi(table);
    if (!api) { applySearch(); return; }
    jQuery(table).off('draw.dt.correspondence').on('draw.dt.correspondence', function () { searchCount(api.rows({ search: 'applied' }).count(), api.rows().count()); });
    if (tableState && tableState.table !== table) {
      api.page.len(tableState.length).search(tableState.search).draw();
      api.page(Math.min(tableState.page, Math.max(0, api.page.info().pages - 1))).draw('page');
      tableState = null;
    } else api.draw(false);
    var empty = byId('correspondence-search-empty');
    if (empty) empty.hidden = true;
  }
  function bindRequests() {
    if (hooksBound || !window.Sys || !Sys.WebForms) return;
    hooksBound = true;
    manager = Sys.WebForms.PageRequestManager.getInstance();
    manager.add_initializeRequest(function (sender, args) {
      visible();
      var source = args.get_postBackElement(), sourceId = source ? source.id : '';
      var timer = /tmCorrespondenceCount$/i.test(sourceId), clear = /btnClearUploads$/i.test(sourceId);
      if (request || manager.get_isInAsyncPostBack() || (pendingUpload() && (!clear || uploading())) || (timer && (document.hidden || editingDetails()))) {
        args.set_cancel(true);
        if (!timer) notice(pendingUpload() ? 'انتظر اكتمال رفع الملفات أو امسح الملفات التي لم تُرفع.' : 'جارٍ إكمال العملية الحالية، يرجى الانتظار.', false);
        return;
      }
      saveDraft();
      saveTable();
      request = { id: active, scroll: snapshotScroll(), send: /btnSend$/i.test(sourceId), clear: clear, navigation: navigation, box: replyBox() };
      if (request.send || navigation) {
        var box = replyBox();
        if (box) box.readOnly = true;
        loading(!!navigation);
      }
    });
    manager.add_endRequest(function (sender, args) {
      var previous = request, error = args.get_error();
      request = null;
      // Keep edits made during a refresh or clear, including when its composer was replaced.
      if (previous && !previous.send && !previous.navigation && previous.box && previous.id !== '0') {
        drafts[previous.id] = previous.box.value;
        serializeDrafts();
      }
      updateLayout();
      if (error) {
        notice('تعذر إكمال العملية. احتُفظ بمسودة الرد؛ أعد المحاولة، وتحقق من سجل المحادثة قبل إعادة إرسال الرد.', true);
        args.set_errorHandled(true);
      } else if (previous && previous.navigation && active !== previous.navigation.id) {
        notice('تعذر فتح المحادثة المطلوبة. احتُفظ بمسودة الرد.', true);
      }
      var sent = field('hfSendSucceeded');
      var sendSucceeded = !error && sent && sent.value === '1';
      if (sendSucceeded && previous) { delete drafts[previous.id]; serializeDrafts(); }
      if (!error && previous && (sendSucceeded || previous.clear)) notice('', false);
      if (sent) sent.value = '0';
      if (previous && previous.navigation) {
        if (!error && active === previous.navigation.id) {
          currentUrl = previous.navigation.url;
          if (previous.navigation.history) window.history.replaceState({ correspondence: active }, '', currentUrl);
          else window.history.pushState({ correspondence: active }, '', currentUrl);
        } else window.history.replaceState({ correspondence: active }, '', currentUrl);
      }
      navigation = null;
      field('hfNavigation', '0');
      restoreDraft();
      refreshTable();
      initializeMessages();
      loading(false);
      var switched = previous && previous.id !== active;
      restoreScroll(switched ? null : previous ? previous.scroll : scrolls[active], switched || sendSucceeded);
      if (previous && previous.send && !sendSucceeded && !error && !root.querySelector('.alert-danger')) notice('لم يتم تأكيد إرسال الرد. احتُفظ بالمسودة؛ راجع التنبيه ثم أعد المحاولة.', true);
      if (createdThread && active === createdThread && !error) { notice('تم إرسال المراسلة وتحديث القائمة.', false); createdThread = null; }
      visible();
    });
  }
  function preview(link, event) {
    var url;
    try { url = new URL(link.href, window.location.href); } catch (ignore) { return; }
    if (url.origin !== window.location.origin || !/\.(pdf|png|jpe?g|gif)$/i.test(url.pathname)) return;
    var modal = byId('correspondence-preview'), frame = byId('correspondence-preview-frame');
    if (!modal || !frame || !window.bootstrap) return;
    event.preventDefault();
    frame.src = url.href;
    bootstrap.Modal.getOrCreateInstance(modal).show();
  }
  function pendingEditorUpload(doc, child) {
    return Array.prototype.some.call(doc.querySelectorAll('.ajax__fileupload'), function (node) {
      var host = node.closest('[id]'), control = child.$find && child.$find(node.id || (host && host.id) || '');
      return control && (control._isUploading || (control._filesInQueue || []).some(function (file) { return !file._isUploaded; }));
    });
  }
  function initializeEditor() {
    var token = new URL(window.location.href).searchParams.get('editor');
    if (!/^[a-f0-9]{32}$/i.test(token || '') || window.parent === window) return;
    var editorBusy = false, frozenEditorControls = [], editorManager;
    function editorStatus(text) {
      var status = document.getElementById('correspondence-editor-status');
      if (!status) { status = document.createElement('div'); status.id = 'correspondence-editor-status'; status.className = 'alert alert-warning'; status.setAttribute('role', 'status'); document.querySelector('.correspondence-new-page').prepend(status); }
      status.textContent = text;
    }
    function freezeEditor() {
      frozenEditorControls = Array.prototype.map.call(document.querySelectorAll('[id$="btnSave"], [data-correspondence-cancel], .correspondence-new-heading a'), function (node) {
        var state = { node: node, disabled: node.disabled, aria: node.getAttribute('aria-disabled') };
        if ('disabled' in node) node.disabled = true;
        node.setAttribute('aria-disabled', 'true');
        return state;
      });
    }
    function releaseEditor() {
      editorBusy = false;
      frozenEditorControls.forEach(function (state) {
        // A refreshed control owns its server-rendered disabled state, including a completed save.
        if (!state.node.isConnected) return;
        if ('disabled' in state.node) state.node.disabled = state.disabled;
        if (state.aria === null) state.node.removeAttribute('aria-disabled'); else state.node.setAttribute('aria-disabled', state.aria);
      });
      frozenEditorControls = [];
    }
    function initializeFields() {
      if (window.jQuery && jQuery.fn.select2) jQuery(function () {
        document.querySelectorAll('.correspondence-new-page select.select2').forEach(function (node) {
          if (!jQuery(node).data('select2')) jQuery(node).select2({ dir: 'rtl', width: '100%', dropdownParent: jQuery(node).parent(), language: { noResults: function () { return 'لا توجد نتائج'; } } });
        });
      });
      window.parent.postMessage({ type: 'correspondence-editor-ready', token: token }, window.location.origin);
    }
    initializeFields();
    if (window.Sys && Sys.Application) Sys.Application.add_load(initializeFields);
    document.addEventListener('click', function (event) {
      var cancel = event.target.closest('[data-correspondence-cancel], .correspondence-new-heading a');
      if (!cancel) return;
      event.preventDefault();
      if (editorBusy || (editorManager && editorManager.get_isInAsyncPostBack())) { event.stopImmediatePropagation(); editorStatus('جارٍ إكمال العملية الحالية، يرجى الانتظار.'); return; }
      window.parent.postMessage({ type: 'correspondence-editor-cancel', token: token }, window.location.origin);
    }, true);
    if (window.Sys && Sys.WebForms) {
      editorManager = Sys.WebForms.PageRequestManager.getInstance();
      editorManager.add_initializeRequest(function (sender, args) {
        var source = args.get_postBackElement();
        if (editorBusy || editorManager.get_isInAsyncPostBack()) {
          args.set_cancel(true);
          editorStatus('جارٍ إكمال العملية الحالية، يرجى الانتظار.');
          return;
        }
        if (source && /btnSave$/.test(source.id) && pendingEditorUpload(document, window)) {
          args.set_cancel(true);
          editorStatus('انتظر اكتمال رفع المرفقات أو أزل الملفات التي تعذر رفعها قبل الإرسال.');
        }
      });
      // Freeze after Web Forms serializes the accepted request, preserving the submit/validator contract.
      editorManager.add_beginRequest(function () { editorBusy = true; freezeEditor(); });
      editorManager.add_endRequest(function (sender, args) {
        releaseEditor();
        if (args.get_error()) { editorStatus('تعذر تأكيد العملية. راجع قائمة المراسلات قبل إعادة الإرسال.'); args.set_errorHandled(true); }
      });
    }
  }
  function openCreate(link, event) {
    if (!window.bootstrap) return;
    if (busy() || pendingUpload()) { event.preventDefault(); notice(pendingUpload() ? 'انتظر اكتمال رفع المرفقات أو امسح الملفات المحددة قبل فتح نموذج جديد.' : 'جارٍ إكمال العملية الحالية، يرجى الانتظار.', false); return; }
    var url = new URL(link.href, window.location.href);
    if (url.origin !== location.origin || !/\/Modules\/Correspondence\/AddCorrespondence\.aspx$/i.test(url.pathname)) return;
    event.preventDefault();
    var bytes = new Uint8Array(16); window.crypto.getRandomValues(bytes);
    editorToken = Array.from(bytes).map(function (value) { return value.toString(16).padStart(2, '0'); }).join('');
    editorCompleted = false;
    url.searchParams.set('editor', editorToken);
    var frame = byId('correspondence-create-frame'), loading = byId('correspondence-create-loading');
    frame.hidden = true; loading.hidden = false; frame.src = url.href;
    bootstrap.Offcanvas.getOrCreateInstance(byId('correspondence-create')).show();
  }
  function bindCreate() {
    var host = byId('correspondence-create'), frame = byId('correspondence-create-frame');
    if (!host || !frame) return;
    frame.addEventListener('load', function () { if (editorToken) { frame.hidden = false; byId('correspondence-create-loading').hidden = true; } });
    host.addEventListener('hide.bs.offcanvas', function (event) {
      if (editorCompleted) return;
      try {
        var child = frame.contentWindow;
        if (child && ((child.Sys && child.Sys.WebForms && child.Sys.WebForms.PageRequestManager.getInstance().get_isInAsyncPostBack()) || pendingEditorUpload(frame.contentDocument, child))) {
          event.preventDefault(); notice('انتظر اكتمال العملية أو رفع المرفقات قبل إغلاق النموذج.', false);
        }
      } catch (ignore) { event.preventDefault(); }
    });
    window.addEventListener('message', function (event) {
      if (event.origin !== location.origin || event.source !== frame.contentWindow || !editorToken || !event.data || event.data.token !== editorToken) return;
      if (event.data.type === 'correspondence-editor-ready') { frame.hidden = false; byId('correspondence-create-loading').hidden = true; return; }
      if (event.data.type === 'correspondence-editor-cancel') { bootstrap.Offcanvas.getOrCreateInstance(host).hide(); return; }
      if (event.data.type !== 'correspondence-created' || !Array.isArray(event.data.ids) || !event.data.ids.length) return;
      var id = threadId(event.data.ids[0]); if (id === '0') return;
      editorCompleted = true;
      bootstrap.Offcanvas.getOrCreateInstance(host).hide();
      ['txtTitleSearch', 'txtPerson'].forEach(function (key) { var input = byId(key); if (input) input.value = ''; });
      root.querySelectorAll('[id$="ddlFilter"]').forEach(function (node) { node.value = 'all'; });
      root.querySelectorAll('[id$="ddlKind"], [id$="ddlPriority"], [id$="ddlBrand"], [id$="ddlBranch"]').forEach(function (node) { node.value = '0'; });
      root.querySelectorAll('[id$="txtFrom"], [id$="txtTo"], [id$="txtSender"], [id$="txtReceiver"]').forEach(function (node) { node.value = ''; });
      var api = tableApi(byId('ERPTable')); if (api) api.search('').draw();
      createdThread = id; editorToken = null;
      select(id, route(id).href, false);
    });
  }
  function start() {
    root = byId('correspondence-workspace');
    if (!root) { initializeEditor(); return; }
    bindCreate();
    var stored = field('hfDraftText');
    try {
      var parsed = JSON.parse(stored && stored.value || '{}');
      Object.keys(parsed).forEach(function (key) { if (threadId(key) !== '0' && typeof parsed[key] === 'string') drafts[threadId(key)] = parsed[key].slice(0, 4000); });
    } catch (ignore) { notice('تعذرت استعادة مسودة الرد السابقة. تحقق من النص قبل الإرسال.', true); }
    updateLayout();
    restoreDraft();
    initializeMessages();
    bottom();
    currentUrl = route(active).href;
    window.history.replaceState({ correspondence: active }, '', currentUrl);
    visible();
    bindRequests();
    refreshTable();
    if (window.Sys && Sys.Application) Sys.Application.add_load(bindRequests);
    document.addEventListener('visibilitychange', visible);
    if (window.visualViewport) window.visualViewport.addEventListener('resize', resize);
    document.addEventListener('input', function (event) {
      if (event.target === replyBox()) saveDraft();
      if (event.target.id === 'txtTitleSearch' || event.target.id === 'txtPerson') applySearch();
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Enter' && (event.target.id === 'txtTitleSearch' || event.target.id === 'txtPerson')) { event.preventDefault(); applySearch(); }
    }, true);
    document.addEventListener('click', function (event) {
      var target = event.target.closest('a,button,input[type="submit"]');
      if (!target) return;
      if (target.matches('[data-correspondence-file]')) { preview(target, event); return; }
      if (target.matches('[data-correspondence-create]')) { openCreate(target, event); return; }
      if (!root.contains(target)) return;
      if (target.matches('[data-thread-id], [data-correspondence-back]')) {
        if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        select(target.matches('[data-correspondence-back]') ? '0' : target.dataset.threadId, target.href, false);
        return;
      }
      if (target.id === 'correspondence-new-messages') { event.preventDefault(); bottom(); return; }
      if (target.closest('.ajax__fileupload')) return;
      if (target.matches('input[type="submit"],button[type="submit"],a[href^="javascript:__doPostBack"]')) {
        if (busy() || (pendingUpload() && (!/btnClearUploads$/i.test(target.id) || uploading()))) {
          event.preventDefault();
          event.stopImmediatePropagation();
          notice(pendingUpload() ? 'ارفع الملفات المحددة أو امسحها قبل إكمال العملية.' : 'جارٍ إكمال العملية الحالية، يرجى الانتظار.', false);
          return;
        }
        saveDraft();
      }
    }, true);
    window.addEventListener('popstate', function () { var url = new URL(window.location.href); select(url.searchParams.get('ID') || url.searchParams.get('id') || '0', url.href, true); });
    window.addEventListener('resize', function () { if (resizeFrame) window.cancelAnimationFrame(resizeFrame); resizeFrame = window.requestAnimationFrame(function () { resizeFrame = 0; resize(); }); });
    var modal = byId('correspondence-preview');
    if (modal) modal.addEventListener('hidden.bs.modal', function () { var frame = byId('correspondence-preview-frame'); if (frame) frame.removeAttribute('src'); });
  }

  window.CorrespondenceChat = {
    uploadStarted: function () { uploadActive = true; notice('جارٍ رفع المرفقات. يرجى الانتظار قبل إرسال الرد أو تبديل المحادثة.', false); },
    uploadCompleted: function (sender, args) {
      uploadActive = false;
      uploadCount += args && args.get_filesUploaded ? Number(args.get_filesUploaded()) || 0 : 0;
      var queued = byId('lblQueued') || (root && root.querySelector('[id$="lblQueued"]'));
      if (queued) queued.textContent = uploadCount ? 'المرفقات المحفوظة: ' + uploadCount : '';
      notice('اكتمل رفع المرفقات. اضغط إرسال لإضافتها إلى المحادثة.', false);
    },
    uploadFailed: function () { uploadActive = false; notice('تعذر رفع أحد الملفات. راجع حالة المرفقات، وأعد رفع الملف أو امسحه قبل المتابعة.', true); },
    select: select
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
}());
