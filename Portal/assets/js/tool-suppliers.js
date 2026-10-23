(function () {
    'use strict';
    if (window.ToolSuppliers) return;

    function normalize(value) {
        return String(value || '').toLowerCase().normalize('NFKD')
            .replace(/[\u064b-\u065f\u0670]/g, '').replace(/[أإآ]/g, 'ا').replace(/ى/g, 'ي');
    }

    function initialize() {
        var brand = document.querySelector('select[data-tool-brand]');
        var supplier = document.querySelector('select[data-tool-suppliers]');
        if (!brand || !supplier) return;
        // Keep all server-rendered options registered for ASP.NET event validation.
        if (!supplier._toolSupplierOptions) {
            supplier._toolSupplierOptions = Array.from(supplier.options).map(function (option) { return option.cloneNode(true); });
        }
        if (window.jQuery && !brand._toolSupplierChangeBound) {
            brand._toolSupplierChangeBound = true;
            jQuery(brand).on('change.toolSupplier', function (event) {
                // Select2 emits a jQuery change rather than a native DOM event.
                var current = document.querySelector('select[data-tool-suppliers]');
                if (!event.originalEvent && current) filter(brand, current);
            });
        }
        filter(brand, supplier);
    }

    function filter(brand, supplier) {
        var selected = supplier.value;
        var brandId = brand.value;
        var allowAll = supplier.dataset.allowAllBrands === 'true';
        var includeUnavailable = supplier.dataset.includeUnavailable === 'true';
        var oldAccount = supplier.dataset.currentAccount || '';
        var oldBrand = supplier.dataset.currentBrand || '';
        var source = supplier._toolSupplierOptions || [];
        if (window.jQuery && jQuery(supplier).data('select2')) jQuery(supplier).select2('destroy');
        supplier.replaceChildren();
        source.forEach(function (option) {
            if (!option.value) {
                supplier.appendChild(option.cloneNode(true));
                return;
            }
            var brands = (option.dataset.brandIds || '').split(',').map(function (id) { return id.trim(); });
            var historical = selected === oldAccount && option.value === oldAccount && brandId === oldBrand;
            var available = includeUnavailable || option.dataset.available === '1' || historical;
            if (available && ((allowAll && !brandId) || (brandId && brands.indexOf(brandId) >= 0))) {
                supplier.appendChild(option.cloneNode(true));
            }
        });
        supplier.value = Array.from(supplier.options).some(function (option) { return option.value === selected; }) ? selected : '';
        supplier.disabled = !allowAll && !brandId;
        if (window.jQuery && jQuery.fn.select2) {
            jQuery(supplier).select2({
                width: '100%', dir: 'rtl', dropdownParent: jQuery(supplier).parent(), minimumResultsForSearch: 0,
                matcher: function (params, data) {
                    if (!params.term || normalize(data.text).indexOf(normalize(params.term)) >= 0) return data;
                    return null;
                },
                language: { noResults: function () { return 'لا يوجد مورد مطابق للعلامة التجارية'; } }
            });
        }
    }

    // Capture before the existing organization cascade's asynchronous postback.
    document.addEventListener('change', function (event) {
        if (!event.target.matches('select[data-tool-brand]')) return;
        var supplier = document.querySelector('select[data-tool-suppliers]');
        if (supplier) filter(event.target, supplier);
    }, true);

    function setup() {
        // Template scans .select2 containers on ready; initialize after that scan.
        if (window.jQuery) jQuery(initialize);
        else initialize();
        if (window.Sys && Sys.WebForms && !window.ToolSuppliers.ajaxBound) {
            window.ToolSuppliers.ajaxBound = true;
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(initialize);
        }
    }
    window.ToolSuppliers = { initialize: initialize, ajaxBound: false };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', setup);
    else setup();
}());
