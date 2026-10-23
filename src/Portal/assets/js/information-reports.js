(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () { jQuery(function () {
    var root = document.querySelector('[data-information-report]');
    if (!root) return;
    var table = jQuery.fn.dataTable.isDataTable('#ERPTable') ? jQuery('#ERPTable').DataTable() : null;
    var name = root.querySelector('[data-history-name]'), action = root.querySelector('[data-history-action]');
    if (table && name && action) {
      jQuery.fn.dataTable.ext.search.push(function (settings, row) {
        if (settings.nTable.id !== 'ERPTable') return true;
        return (!name.value.trim() || (row[1] + ' ' + row[3]).toLowerCase().includes(name.value.trim().toLowerCase())) &&
          (!action.value || row[2].includes(action.value));
      });
      name.addEventListener('input', function () { table.draw(); });
      action.addEventListener('change', function () { table.draw(); });
      name.addEventListener('keydown', function (event) { if (event.key === 'Enter') event.preventDefault(); });
      root.querySelector('[data-history-reset]').addEventListener('click', function () {
        name.value = ''; action.value = ''; table.search('').draw();
      });
    }
    var pending, modalElement = root.querySelector('#restoreVersionModal');
    if (!modalElement) return;
    var modal = bootstrap.Modal.getOrCreateInstance(modalElement);
    root.addEventListener('click', function (event) {
      var button = event.target.closest('[data-restore-version]');
      if (!button) return;
      if (button.dataset.confirmed === '1') { delete button.dataset.confirmed; return; }
      event.preventDefault(); pending = button;
      root.querySelector('[data-restore-number]').textContent = button.dataset.restoreVersion;
      modal.show();
    });
    root.querySelector('[data-restore-confirm]').addEventListener('click', function () {
      if (!pending) return;
      this.disabled = true;
      pending.dataset.confirmed = '1'; pending.click();
    });
    modalElement.addEventListener('hidden.bs.modal', function () { pending = null; });
  }); });
}());
