(function () {
 'use strict';
 function initialize() {
  var workspace = document.querySelector('[data-customer-feedback-workspace]');
  if (!workspace || workspace.dataset.customerFeedbackReady) return;
  workspace.dataset.customerFeedbackReady = '1';
  var wizard = workspace.querySelector('[data-feedback-wizard]'), drawer = document.getElementById('customerFeedbackWizard');
  var brand = wizard.querySelector('[data-customer-feedback-brand]'), branch = wizard.querySelector('[data-customer-feedback-branch]');
  var type = wizard.querySelector('[data-customer-feedback-type]'), topic = wizard.querySelector('[data-customer-feedback-topic]');
  var branchOptions = Array.from(branch.options).map(function (option) { return option.cloneNode(true); });
  var topicOptions = Array.from(topic.options).map(function (option) { return option.cloneNode(true); });
  var files = wizard.querySelector('[data-customer-feedback-files]'), submit = wizard.querySelector('[data-customer-feedback-submit]');
  var busy = false, fileError = '', frozenControls = [];
  function freezeWizard() {
   frozenControls = Array.from(drawer.querySelectorAll('input,select,textarea,button')).map(function (control) { return { control: control, disabled: control.disabled }; });
   frozenControls.forEach(function (entry) {
    entry.control.disabled = true;
    if (entry.control.tagName === 'SELECT' && window.jQuery && window.jQuery(entry.control).hasClass('select2-hidden-accessible')) { window.jQuery(entry.control).select2('close'); window.jQuery(entry.control).trigger('change.select2'); }
   });
   wizard.setAttribute('aria-busy', 'true');
  }
  function unlockWizard() {
   frozenControls.forEach(function (entry) {
    entry.control.disabled = entry.disabled;
    if (entry.control.tagName === 'SELECT' && window.jQuery && window.jQuery(entry.control).hasClass('select2-hidden-accessible')) window.jQuery(entry.control).trigger('change.select2');
   });
   frozenControls = []; wizard.removeAttribute('aria-busy');
  }
  drawer.addEventListener('hide.bs.offcanvas', function (event) { if (busy) event.preventDefault(); });
  function syncSelect(select, all, matches) {
   var selected = select.value;
   if (window.jQuery && window.jQuery(select).hasClass('select2-hidden-accessible')) window.jQuery(select).select2('destroy');
   select.replaceChildren.apply(select, all.filter(function (option) { return option.value === '0' || matches(option); }).map(function (option) { return option.cloneNode(true); }));
   select.value = Array.from(select.options).some(function (option) { return option.value === selected; }) ? selected : '0';
   if (window.jQuery && window.jQuery.fn.select2) window.jQuery(select).select2({ width: '100%', dropdownParent: window.jQuery(drawer), dir: 'rtl' });
  }
  function summary() {
   function label(select) { return select.selectedIndex >= 0 && select.value !== '0' ? select.options[select.selectedIndex].text : '—'; }
   wizard.querySelector('[data-customer-feedback-summary]').textContent = label(brand) + ' / ' + label(branch) + ' · ' + label(type) + ' · ' + label(topic);
  }
  function cascade() {
   syncSelect(branch, branchOptions, function (option) { return option.dataset.brandId === brand.value; });
   syncSelect(topic, topicOptions, function (option) { return option.dataset.brandId === brand.value && option.dataset.typeId === type.value; });
   wizard.querySelector('[data-customer-feedback-no-branch]').hidden = brand.value === '0' || branch.options.length > 1;
   summary();
  }
  [brand, type].forEach(function (select) { select.addEventListener('change', cascade); });
  [branch, topic].forEach(function (select) { select.addEventListener('change', summary); });
  if (window.jQuery) window.jQuery([brand, type]).on('change.customerFeedback', cascade);
  if (window.jQuery) window.jQuery([branch, topic]).on('change.customerFeedback', summary);
  if (window.jQuery && window.jQuery.fn.select2) window.jQuery([brand, type]).each(function () { if (window.jQuery(this).hasClass('select2-hidden-accessible')) window.jQuery(this).select2('destroy'); window.jQuery(this).select2({ width: '100%', dropdownParent: window.jQuery(drawer), dir: 'rtl' }); });
  cascade();
  var tableApi = null, tableSearchRegistered = false;
  function matches(row) {
   if (!row || !row.hasAttribute('data-customer-feedback-row')) return true;
   var list = workspace.querySelector('[data-customer-feedback-list]');
   var search = list.querySelector('[data-customer-feedback-search]').value.trim().toLocaleLowerCase();
   var brandID = list.querySelector('[data-customer-feedback-brand-filter]').value, state = list.querySelector('[data-customer-feedback-status]').value;
   var title = row.querySelector('[data-customer-feedback-title]');
   return (!search || row.dataset.feedbackId === search || (title && title.textContent.toLocaleLowerCase().indexOf(search) >= 0)) && (!brandID || row.dataset.brandId === brandID) && (!state || row.dataset.status === state);
  }
  function count() {
   var list = workspace.querySelector('[data-customer-feedback-list]'), total, visible;
   if (tableApi) { total = tableApi.rows().count(); visible = tableApi.rows({ search: 'applied' }).count(); }
   else { var rows = Array.from(list.querySelectorAll('[data-customer-feedback-row]')); total = rows.length; visible = rows.filter(function (row) { return !row.hidden; }).length; }
   list.querySelector('[data-customer-feedback-empty]').hidden = !!tableApi || visible > 0;
   list.querySelector('[data-customer-feedback-count]').textContent = 'الطلبات المعروضة: ' + visible + ' من ' + total;
  }
  function prepareTable() {
   var table = workspace.querySelector('#ERPTable');
   if (!table || !window.jQuery || !window.jQuery.fn.DataTable) return;
   if (!tableSearchRegistered) {
    window.jQuery.fn.dataTable.ext.search.push(function (settings, data, index) { return settings.nTable !== workspace.querySelector('#ERPTable') || matches(settings.aoData[index].nTr); });
    tableSearchRegistered = true;
   }
   if (window.CRMList) window.CRMList.initializeTable();
   if (!window.jQuery.fn.dataTable.isDataTable(table)) return;
   tableApi = window.jQuery(table).DataTable();
   var quick = workspace.querySelector('#ERPTable_wrapper .dataTables_filter input');
   if (quick) quick.setAttribute('data-customer-feedback-quick-search', '1');
   if (!table.dataset.customerFeedbackTableBound) { table.dataset.customerFeedbackTableBound = '1'; window.jQuery(table).on('draw.dt.customerFeedback', count); }
  }
  function allRows() { return tableApi ? tableApi.rows().nodes().toArray() : Array.from(workspace.querySelectorAll('[data-customer-feedback-row]')); }
  function destroyTable() {
   var table = workspace.querySelector('#ERPTable');
   if (window.bootstrap) allRows().forEach(function (row) { row.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (element) { var instance = window.bootstrap.Tooltip.getInstance(element); if (instance) instance.dispose(); }); });
   if (table && window.jQuery && window.jQuery.fn.DataTable && window.jQuery.fn.dataTable.isDataTable(table)) window.jQuery(table).DataTable().destroy();
   tableApi = null;
  }
  function filter() {
   prepareTable();
   if (tableApi) tableApi.draw();
   else allRows().forEach(function (row) { row.hidden = !matches(row); });
   count();
  }
  workspace.addEventListener('input', function (event) { if (event.target.matches('[data-customer-feedback-search]')) filter(); });
  workspace.addEventListener('change', function (event) { if (event.target.matches('[data-customer-feedback-brand-filter], [data-customer-feedback-status]')) filter(); });
  workspace.addEventListener('keydown', function (event) { if (event.key === 'Enter' && event.target.matches('[data-customer-feedback-search]')) event.preventDefault(); });
  workspace.addEventListener('click', function (event) {
   if (!event.target.closest('[data-customer-feedback-reset]')) return;
   ['[data-customer-feedback-search]', '[data-customer-feedback-brand-filter]', '[data-customer-feedback-status]'].forEach(function (selector) { workspace.querySelector(selector).value = ''; });
   if (tableApi) tableApi.search(''); filter();
  });
  files.addEventListener('change', function () {
   var list = wizard.querySelector('[data-customer-feedback-file-list]'), problem = '', chosen = Array.from(files.files || []);
   list.replaceChildren();
   if (chosen.length > 5) problem = 'الحد الأقصى خمسة مرفقات.';
   chosen.forEach(function (file) {
    if (file.size > 10 * 1024 * 1024) problem = 'حجم الملف يتجاوز 10 ميجابايت.';
    if (!/\.(pdf|docx?|xlsx?|jpe?g|png|gif)$/i.test(file.name)) problem = 'نوع الملف غير مسموح.';
    var item = document.createElement('li'); item.className = 'list-group-item px-0 small text-break'; item.textContent = file.name + ' · ' + (file.size / 1024 / 1024).toFixed(2) + ' MB'; list.appendChild(item);
   });
   fileError = problem; files.setCustomValidity(problem);
   var status = wizard.querySelector('[data-feedback-upload-status]'); status.textContent = problem || (chosen.length ? 'عدد المرفقات المحددة: ' + chosen.length : ''); status.classList.toggle('text-danger', !!problem);
  });
  function updateHidden(response) {
   var form = workspace.closest('form'), returnedForm = response.querySelector('form');
   if (!returnedForm) throw new Error('Invalid response');
   Array.from(form.querySelectorAll('input[type="hidden"]')).filter(function (input) { return /^__(VIEWSTATE|EVENTVALIDATION|EVENTTARGET|EVENTARGUMENT|LASTFOCUS|VIEWSTATEGENERATOR)/.test(input.name); }).forEach(function (input) { input.remove(); });
   Array.from(returnedForm.querySelectorAll('input[type="hidden"]')).filter(function (input) { return /^__(VIEWSTATE|EVENTVALIDATION|EVENTTARGET|EVENTARGUMENT|LASTFOCUS|VIEWSTATEGENERATOR)/.test(input.name); }).forEach(function (input) { form.appendChild(document.importNode(input, true)); });
  }
  function message(text) { var target = wizard.querySelector('[data-customer-feedback-wizard-message]'); target.replaceChildren(); var alert = document.createElement('div'); alert.className = 'alert alert-danger'; alert.setAttribute('role', 'alert'); alert.textContent = text; target.appendChild(alert); }
  wizard.addEventListener('invalid', function (event) {
   var label = event.target.id && wizard.querySelector('label[for="' + event.target.id + '"]');
   message(fileError && event.target === files ? fileError : 'يرجى مراجعة حقل ' + (label ? label.textContent : 'البيانات المطلوبة') + ' قبل المتابعة.');
  }, true);
  workspace.addEventListener('click', function (event) {
   var button = event.target.closest('[data-feedback-next],[data-feedback-jump],[data-feedback-submit]');
   if (!button || !fileError) return;
   var current = Number(wizard.dataset.feedbackCurrent || 0), target = button.dataset.feedbackJump;
   if (button.hasAttribute('data-feedback-submit') || current === 2 || (target && Number(target) > 2)) { event.preventDefault(); event.stopImmediatePropagation(); if (window.FeedbackWizard) window.FeedbackWizard.goTo(wizard, 2); files.setCustomValidity(fileError); files.reportValidity(); }
  }, true);
  workspace.closest('form').addEventListener('submit', async function (event) {
   if (!event.submitter || event.submitter !== submit) return;
   event.preventDefault();
   if (busy) return;
   if (fileError) { if (window.FeedbackWizard) window.FeedbackWizard.goTo(wizard, 2); files.setCustomValidity(fileError); files.reportValidity(); return; }
   var payload = new FormData(event.target); payload.set(submit.name, submit.value);
   busy = true; freezeWizard();
   try {
    var response = await fetch(event.target.action || window.location.href, { method: 'POST', body: payload, credentials: 'same-origin', cache: 'no-store' });
    if (response.redirected && new URL(response.url).pathname.toLowerCase().endsWith('/login.aspx')) { window.location.assign(response.url); return; }
    if (!response.ok) throw new Error('Request failed');
    var documentResult = new DOMParser().parseFromString(await response.text(), 'text/html'), returned = documentResult.querySelector('[data-customer-feedback-workspace]');
    if (!returned) throw new Error('Invalid response');
    updateHidden(documentResult);
    if (returned.dataset.feedbackSaved !== '1') {
     wizard.querySelector('[data-customer-feedback-wizard-message]').innerHTML = returned.querySelector('[data-customer-feedback-wizard-message]').innerHTML;
     return;
    }
    var oldList = workspace.querySelector('[data-customer-feedback-list]'), returnedList = returned.querySelector('[data-customer-feedback-list]');
    destroyTable();
    oldList.replaceWith(document.importNode(returnedList, true));
    ['[data-customer-feedback-search]', '[data-customer-feedback-brand-filter]', '[data-customer-feedback-status]'].forEach(function (selector) { workspace.querySelector(selector).value = ''; });
    ['[data-customer-feedback-message]', '[data-customer-feedback-statistics]'].forEach(function (selector) { workspace.querySelector(selector).innerHTML = returned.querySelector(selector).innerHTML; });
    wizard.querySelector('[data-customer-feedback-wizard-message]').replaceChildren();
    wizard.querySelectorAll('textarea,input[type="text"]').forEach(function (input) { input.value = ''; });
    files.value = ''; files.dispatchEvent(new Event('change'));
    if (window.FeedbackWizard) window.FeedbackWizard.goTo(wizard, 0);
    filter();
    var savedID = returned.dataset.feedbackSavedId, newRow = /^[1-9][0-9]*$/.test(savedID || '') ? allRows().find(function (row) { return row.dataset.feedbackId === savedID; }) : null;
    if (newRow) {
     newRow.classList.add('feedback-new-request', 'table-success'); newRow.tabIndex = -1; var added = document.createElement('span'); added.className = 'badge bg-label-success ms-2'; added.textContent = 'تمت الإضافة'; (newRow.querySelector('.type-record-name') || newRow.querySelector('td')).appendChild(added);
     if (tableApi) { var index = tableApi.rows({ search: 'applied', order: 'applied' }).nodes().toArray().indexOf(newRow), length = tableApi.page.len(); if (index >= 0 && length > 0) tableApi.page(Math.floor(index / length)).draw('page'); }
    }
    function revealSavedRow() { if (newRow) { newRow.scrollIntoView({ block: 'center', behavior: window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' }); newRow.focus({ preventScroll: true }); } }
    busy = false; unlockWizard();
    if (window.bootstrap && drawer.classList.contains('show')) { drawer.addEventListener('hidden.bs.offcanvas', revealSavedRow, { once: true }); window.bootstrap.Offcanvas.getOrCreateInstance(drawer).hide(); } else revealSavedRow();
    document.dispatchEvent(new CustomEvent('feedback-updated'));
   } catch (error) { message('تعذر تأكيد الإرسال. بقيت بياناتك ومرفقاتك، ويمكن إعادة المحاولة بأمان.'); }
   finally { busy = false; unlockWizard(); }
  });
  filter();
  if (drawer.dataset.feedbackReopen === '1' && window.bootstrap) window.bootstrap.Offcanvas.getOrCreateInstance(drawer).show();
 }
 document.addEventListener('DOMContentLoaded', initialize);
}());
