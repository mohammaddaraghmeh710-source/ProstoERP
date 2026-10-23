(function () {
  function initializeTable() {
    function tooltips() {
      if (!window.bootstrap) return;
      document.querySelectorAll('.crm-types [data-bs-toggle="tooltip"]').forEach(function (element) {
        bootstrap.Tooltip.getOrCreateInstance(element, {trigger:'hover focus',container:'body'});
      });
    }
    tooltips();
    if (!window.jQuery || !jQuery.fn.DataTable) return;
    var table = document.getElementById('ERPTable');
    if (!table || jQuery.fn.dataTable.isDataTable(table)) return;
    if (document.getElementById('systemAdminConfiguration') && table.dataset.adminPrepared !== '1') return;
    jQuery(table).DataTable({responsive:false, autoWidth:false, searching:true, order:[], pageLength:10,
      lengthMenu:[[10,25,50,-1],[10,25,50,'الكل']],
      dom:'<"row mx-2 align-items-center type-table-toolbar"<"col-md-2"<"me-3"l>><"col-md-10"<"dt-action-buttons type-toolbar-actions"f>>>t<"type-table-pagination"ip>',
      language:{search:'',searchPlaceholder:'بحث سريع...',lengthMenu:'_MENU_',info:'عرض _START_ إلى _END_ من أصل _TOTAL_ عنصر',infoFiltered:'(من إجمالي _MAX_ عنصر)',infoEmpty:'لا توجد عناصر',emptyTable:'لا توجد عناصر مطابقة. جرّب تغيير الفلاتر أو إضافة عنصر جديد.',zeroRecords:'لا توجد نتائج مطابقة.',paginate:{first:'الأول',last:'الأخير',next:'التالي',previous:'السابق'}},
      initComplete:function () {
        var controls=document.getElementById('pnlTableActions');
        var actions=document.querySelector('#ERPTable_wrapper .type-toolbar-actions');
        if (controls && actions) actions.appendChild(controls);
        var length=document.querySelector('#ERPTable_wrapper .dataTables_length select');
        if (length) length.setAttribute('aria-label','عدد العناصر المعروضة');
        var search=document.querySelector('#ERPTable_wrapper .dataTables_filter input');
        if(search){search.setAttribute('aria-label','بحث سريع في الجدول');search.addEventListener('keydown',function(event){if(event.key==='Enter')event.preventDefault();});}
        tooltips();
      }
    });
    jQuery(table).on('preDraw.dt',function () {
      if (!window.bootstrap) return;
      table.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function (element) {
        var instance=bootstrap.Tooltip.getInstance(element);if(instance)instance.dispose();
      });
    }).on('draw.dt',tooltips);
  }
  function initializeOrganization() {
    document.querySelectorAll('[data-crm-account-branches]').forEach(function (brands) {
      var branches = document.getElementById(brands.getAttribute('data-crm-account-branches'));
      if (!branches) return;
      if (!branches._crmOrganizationOptions) {
        branches._crmOrganizationOptions = Array.from(branches.options).map(function (option) { return option.cloneNode(true); });
      }
      function update() {
        var selectedBrands = Array.from(brands.selectedOptions).map(function (option) { return option.value; });
        var selectedBranches = Array.from(branches.selectedOptions).map(function (option) { return option.value; });
        branches.replaceChildren();
        branches._crmOrganizationOptions.forEach(function (option) {
          if (selectedBrands.indexOf(option.getAttribute('data-brand-id')) < 0) return;
          var copy = option.cloneNode(true);
          copy.selected = selectedBranches.indexOf(copy.value) >= 0;
          branches.appendChild(copy);
        });
        branches.disabled = !selectedBrands.length || !branches.options.length;
        var help = document.getElementById('accountBranchesHelp');
        if (help) help.textContent = !selectedBrands.length ? 'اختر العلامات التجارية أولاً لعرض الفروع التابعة لها.' :
          (!branches.options.length ? 'لا توجد فروع متاحة للعلامات التجارية المحددة. يمكن الحفظ دون تحديد فروع.' : 'يمكن اختيار عدة فروع لكل علامة تجارية، أو الحفظ دون تحديد فروع.');
        if (window.jQuery && jQuery(branches).data('select2')) jQuery(branches).trigger('change.select2');
      }
      if (!brands._crmOrganizationBound) {
        brands._crmOrganizationBound = true;
        // Resolve current controls again if an AJAX region has replaced the branch list.
        if (window.jQuery) jQuery(brands).on('change.crmOrganization', initializeOrganization);
        else brands.addEventListener('change', initializeOrganization);
      }
      update();
    });
  }
  window.CRMList=window.CRMList||{};
  window.CRMList.initializeTable=initializeTable;
  window.CRMList.initializeOrganization=initializeOrganization;
  document.addEventListener('DOMContentLoaded', function () {
    initializeOrganization();
    document.querySelectorAll('[data-crm-branch-target]').forEach(function (brand) {
      var branch = document.getElementById(brand.getAttribute('data-crm-branch-target'));
      if (!branch || !branch.options.length) return;
      var placeholder = branch.options[0].cloneNode(true);
      var options = Array.from(branch.options).slice(1).map(function (option) { return option.cloneNode(true); });
      function update(value) {
        branch.replaceChildren(placeholder.cloneNode(true));
        options.forEach(function (option) {
          if ((!brand.value && brand.getAttribute('data-crm-all-options') === 'true') || (brand.value && option.getAttribute('data-brand-id') === brand.value)) branch.appendChild(option.cloneNode(true));
        });
        branch.value = value || '';
        if (branch.selectedIndex < 0) branch.selectedIndex = 0;
        if (window.jQuery && jQuery(branch).data('select2')) jQuery(branch).trigger('change.select2');
      }
      update(branch.value);
      if (window.jQuery) jQuery(brand).on('change.crmBranches', function () { update(''); });
      else brand.addEventListener('change', function () { update(''); });
    });
    if (window.jQuery && jQuery.fn.select2) {
      // Run after the shared Template ready callbacks, which scan .select2 containers.
      jQuery(function () {
      document.querySelectorAll('[data-crm-search-select]').forEach(function (select) {
        var field = jQuery(select);
        if (field.data('select2')) return;
        field.wrap('<div class="position-relative crm-search-select"></div>');
        field.select2({width:'100%',dir:'rtl',minimumResultsForSearch:0,dropdownParent:field.parent(),
          placeholder:select.getAttribute('data-placeholder') || undefined,closeOnSelect:!select.multiple,
          matcher:function(params,data){if(!params.term)return data;return window.CRMGuideTreeSearch?(CRMGuideTreeSearch.matches(params.term,data.text)?data:null):jQuery.fn.select2.defaults.defaults.matcher(params,data);},
          language:{noResults:function () { return 'لا توجد نتائج مطابقة'; },searching:function () { return 'جارٍ البحث...'; }}});
        field.on('select2:open', function () {
          var input = field.parent()[0].querySelector('.select2-search__field');
          if (input) {
            input.placeholder = select.getAttribute('data-crm-search-select');
            input.setAttribute('aria-label', input.placeholder);
            input.addEventListener('keydown', function (event) { if (event.key === 'Enter') event.preventDefault(); });
            input.focus();
          }
        });
      });
      });
    }
    document.querySelectorAll('[data-crm-logo-preview]').forEach(function (input) {
      var preview = document.getElementById(input.getAttribute('data-crm-logo-preview'));
      if (!preview) return;
      var original = preview.src, objectUrl;
      var error = input.parentElement.querySelector('[data-crm-logo-error]');
      input.addEventListener('change', function () {
        if (objectUrl) URL.revokeObjectURL(objectUrl);
        preview.src = original;
        if (error) error.textContent = '';
        var file = input.files[0];
        if (!file) return;
        if (!/^image\/(png|jpeg|gif)$/.test(file.type) || !/\.(png|jpe?g|gif)$/i.test(file.name) || file.size > 2097152 || file.size === 0) {
          input.value = '';
          if (error) error.textContent = 'اختر صورة PNG أو JPG أو GIF بحجم لا يتجاوز 2 ميجابايت.';
          return;
        }
        objectUrl = URL.createObjectURL(file);
        preview.src = objectUrl;
      });
    });
    initializeTable();
  });
}());
