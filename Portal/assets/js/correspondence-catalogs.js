(function () {
  'use strict';
  var pendingDelete, allowDelete = false, savedSearch = '', savedPage = 0, filterName = '', filterState = '', busy = false, revealID = 0;
  function editor() { return document.getElementById('correspondenceCatalogEditor'); }
  function freeze(value) {
    busy = value;
    var panel = editor();
    if (panel) {
      panel.setAttribute('aria-busy', String(value));
      panel.querySelectorAll('button,input[type="submit"]').forEach(function (button) { button.disabled = value; });
    }
  }
  window.CorrespondenceCatalogUI = {
    open: function () { freeze(false); if (window.bootstrap) bootstrap.Offcanvas.getOrCreateInstance(editor()).show(); },
    close: function (recordID) {
      if (recordID > 0) { revealID = recordID; filterName = ''; filterState = ''; savedSearch = ''; savedPage = 0; }
      freeze(false); if (window.bootstrap) bootstrap.Offcanvas.getOrCreateInstance(editor()).hide();
    },
    confirmDelete: function (button) {
      if (allowDelete) { allowDelete = false; return true; }
      if (busy || !window.bootstrap) return false;
      pendingDelete = button;
      bootstrap.Modal.getOrCreateInstance(document.getElementById('catalogDeleteModal')).show();
      return false;
    }
  };
  function table() {
    if (!window.jQuery || !jQuery.fn.DataTable || !jQuery.fn.dataTable.isDataTable('#ERPTable')) return null;
    return jQuery('#ERPTable').DataTable();
  }
  function initialize() {
    if (window.CRMList) CRMList.initializeTable();
    var api = table(), name = document.getElementById('catalogName'), state = document.getElementById('catalogState');
    if (name) {
      name.value = filterName;
      if (!name.dataset.catalogBound) {
        name.dataset.catalogBound = '1';
        name.addEventListener('input', function () { filterName = this.value; var current = table(); if (current) current.draw(); });
        name.addEventListener('keydown', function (event) { if (event.key === 'Enter') event.preventDefault(); });
      }
    }
    if (state) {
      state.value = filterState;
      if (!state.dataset.catalogBound) {
        state.dataset.catalogBound = '1';
        state.addEventListener('change', function () { filterState = this.value; var current = table(); if (current) current.draw(); });
      }
    }
    if (api) {
      api.search(savedSearch).draw();
      api.page(Math.min(savedPage, Math.max(0, api.page.info().pages - 1))).draw('page');
      if (revealID) {
        var matches = api.rows().indexes().toArray().filter(function (index) { return api.row(index).node().getAttribute('data-catalog-id') === String(revealID); });
        if (matches.length) {
          var index = matches[0], order = api.rows({ order: 'applied', search: 'applied' }).indexes().toArray();
          api.page(Math.floor(order.indexOf(index) / api.page.len())).draw('page');
          var row = api.row(index).node(); row.classList.add('table-success');
          var link = row.querySelector('[id$="btnEditOption"]'); if (link) link.focus({ preventScroll: true });
        }
        revealID = 0;
      }
    }
  }
  document.addEventListener('DOMContentLoaded', function () {
    if (window.jQuery && jQuery.fn.dataTable) {
      jQuery.fn.dataTable.ext.search.push(function (settings, data, index) {
        if (settings.nTable.id !== 'ERPTable' || !document.getElementById('correspondenceCatalogs')) return true;
        var row = settings.aoData[index].nTr;
        return (!filterName || (row.getAttribute('data-catalog-name') || '').toLocaleLowerCase().indexOf(filterName.trim().toLocaleLowerCase()) !== -1) &&
          (!filterState || row.getAttribute('data-catalog-active') === filterState);
      });
    }
    initialize();
    editor().addEventListener('hide.bs.offcanvas', function (event) { if (busy) event.preventDefault(); });
    document.getElementById('catalogDeleteConfirm').addEventListener('click', function () {
      if (!pendingDelete) return;
      var modal = document.getElementById('catalogDeleteModal'), button = pendingDelete;
      pendingDelete = null;
      modal.addEventListener('hidden.bs.modal', function () { allowDelete = true; button.click(); }, { once: true });
      bootstrap.Modal.getOrCreateInstance(modal).hide();
    });
    if (window.Sys && Sys.WebForms) {
      var manager = Sys.WebForms.PageRequestManager.getInstance();
      manager.add_initializeRequest(function (sender, args) { if (busy) args.set_cancel(true); });
      manager.add_beginRequest(function () {
        var api = table();
        if (api) {
          savedSearch = api.search(); savedPage = api.page();
          var controls = document.getElementById('pnlTableActions'), wrapper = document.getElementById('ERPTable_wrapper');
          if (controls && wrapper) wrapper.parentNode.insertBefore(controls, wrapper);
          document.querySelectorAll('#ERPTable [data-bs-toggle="tooltip"]').forEach(function (item) {
            var instance = window.bootstrap && bootstrap.Tooltip.getInstance(item); if (instance) instance.dispose();
          });
          api.destroy();
        }
        freeze(true);
      });
      manager.add_endRequest(function () { freeze(false); initialize(); });
    }
  });
}());
