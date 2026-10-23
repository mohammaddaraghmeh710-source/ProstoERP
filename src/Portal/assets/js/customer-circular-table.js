(function () {
  'use strict';
  function normalize(value) {
    return String(value || '').normalize('NFKD').toLocaleLowerCase()
      .replace(/[\u064b-\u065f\u0670]/g, '').replace(/[أإآ]/g, 'ا').replace(/ى/g, 'ي');
  }
  function setup() {
    var root = document.getElementById('customerCirculars');
    var table = document.getElementById('customerCircularTable');
    if (!root || !table || table.dataset.circularInitialized === '1') return;
    table.dataset.circularInitialized = '1';
    var name = root.querySelector('[data-circular-name-filter]');
    var brand = root.querySelector('[data-circular-brand-filter]');
    var read = root.querySelector('[data-circular-read-filter]');
    var count = root.querySelector('[data-circular-count]');
    var empty = root.querySelector('[data-circular-filter-empty]');
    var rows = Array.from(table.querySelectorAll('tbody tr[data-circular-row]'));
    var api = null;
    function matches(row) {
      return (!name.value || normalize(row.dataset.circularName).indexOf(normalize(name.value.trim())) >= 0) &&
        (!brand.value || row.dataset.brandId === brand.value) && (!read.value || row.dataset.read === read.value);
    }
    function tooltips() {
      if (!window.bootstrap) return;
      root.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (button) {
        bootstrap.Tooltip.getOrCreateInstance(button, { trigger: 'hover focus', container: 'body' });
      });
    }
    function updateCount() {
      var matched = rows.filter(matches).length;
      if (count) count.textContent = matched.toLocaleString('ar') + ' تعميم';
      if (empty) empty.hidden = !!api || matched > 0;
    }
    function redraw(keepPage) {
      if (api) {
        api.draw(keepPage ? false : true);
        var page = api.page.info();
        if (page.pages && page.page >= page.pages) api.page(page.pages - 1).draw('page');
      } else rows.forEach(function (row) { row.hidden = !matches(row); });
      updateCount();
    }
    if (window.jQuery && jQuery.fn.DataTable) {
      // Scope this predicate and instance to the dashboard's own table.
      jQuery.fn.dataTable.ext.search.push(function (settings, data, index) {
        return settings.nTable !== table || matches(settings.aoData[index].nTr);
      });
      api = jQuery(table).DataTable({
        responsive: false, autoWidth: false, searching: true, order: [], pageLength: 10,
        lengthMenu: [[10, 25, 50, -1], [10, 25, 50, 'الكل']],
        columnDefs: [{ targets: -1, orderable: false }],
        dom: '<"row mx-2 align-items-center type-table-toolbar"<"col-12"l>>t<"type-table-pagination"ip>',
        language: {
          lengthMenu: '_MENU_', info: 'عرض _START_ إلى _END_ من أصل _TOTAL_ تعميم', infoFiltered: '(من إجمالي _MAX_)',
          infoEmpty: 'لا توجد تعاميم', emptyTable: 'لا توجد تعاميم متاحة لحسابك حاليًا.', zeroRecords: 'لا توجد تعاميم مطابقة للفلاتر المحددة.',
          paginate: { first: 'الأول', last: 'الأخير', next: 'التالي', previous: 'السابق' }
        }
      });
      jQuery(table).on('preDraw.dt', function () {
        if (!window.bootstrap) return;
        root.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (button) {
          var instance = bootstrap.Tooltip.getInstance(button); if (instance) instance.dispose();
        });
      }).on('draw.dt', function () { updateCount(); tooltips(); });
      var length = root.querySelector('.dataTables_length select');
      if (length) length.setAttribute('aria-label', 'عدد التعاميم المعروضة');
    }
    name.addEventListener('input', function () { redraw(false); });
    name.addEventListener('keydown', function (event) { if (event.key === 'Enter') event.preventDefault(); });
    brand.addEventListener('change', function () { redraw(false); });
    read.addEventListener('change', function () { redraw(false); });
    document.addEventListener('circular-read', function (event) {
      var detail = event.detail || {};
      var changed = false;
      rows.forEach(function (row) {
        if (row.dataset.circularId !== String(detail.id) || row.dataset.circularVersion !== String(detail.version)) return;
        row.dataset.read = '1';
        var badge = row.querySelector('[data-read-badge]');
        if (badge) { badge.textContent = 'مقروء'; badge.classList.remove('bg-label-warning'); badge.classList.add('bg-label-success'); }
        if (api) api.row(row).invalidate('dom');
        changed = true;
      });
      if (changed) redraw(true);
    });
    document.addEventListener('circular-reader-updated', function () { redraw(true); });
    redraw(true); tooltips();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', setup);
  else setup();
}());
