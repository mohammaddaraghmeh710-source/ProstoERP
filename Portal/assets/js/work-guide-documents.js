(function () {
    'use strict';
    document.addEventListener('DOMContentLoaded', function () {
        if (!window.jQuery || !jQuery.fn.select2) return;
        jQuery('[data-wg-multiselect]').select2({
            width: '100%', dir: 'rtl', closeOnSelect: false, allowClear: true,
            placeholder: 'اختر تصنيفًا أو أكثر',
            language: { noResults: function () { return 'لا توجد تصنيفات مطابقة'; }, searching: function () { return 'جارٍ البحث…'; } }
        });
    });
}());
