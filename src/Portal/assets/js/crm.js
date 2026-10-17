(function () {
    'use strict';
    document.addEventListener('DOMContentLoaded', function () {
        if (window.jQuery && jQuery.fn.DataTable) {
            jQuery('.crm-table').each(function () {
                if (jQuery.fn.dataTable.isDataTable(this)) return;
                jQuery(this).DataTable({
                    responsive: false, autoWidth: false, searching: true, order: [], pageLength: 10,
                    lengthMenu: [[10, 25, 50, -1], [10, 25, 50, 'الكل']],
                    dom: '<"table-toolbar"lf>t<"table-pagination flex-wrap"ip>',
                    language: {
                        lengthMenu: 'إظهار _MENU_',
                        search: 'بحث:',
                        searchPlaceholder: 'ابحث في الجدول...',
                        info: 'عرض _START_ إلى _END_ من أصل _TOTAL_',
                        infoFiltered: '(من _MAX_ سجل)',
                        infoEmpty: 'لا توجد سجلات',
                        emptyTable: 'لا توجد سجلات مطابقة.',
                        zeroRecords: 'لا توجد نتائج مطابقة.',
                        paginate: {first: 'الأول', last: 'الأخير', next: 'التالي', previous: 'السابق'}
                    }
                });
            });
        }
    });
}());
