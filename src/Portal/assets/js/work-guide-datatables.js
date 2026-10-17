(function () {
    'use strict';
    document.addEventListener('DOMContentLoaded', function () {
        if (!window.jQuery || !jQuery.fn.DataTable) return;
        jQuery('table[data-wg-datatable]').each(function () {
            if (jQuery.fn.dataTable.isDataTable(this)) return;
            jQuery(this).DataTable({
                // The shared ERPTable CSS displays the actual rows as employee-style cards.
                responsive: false,
                autoWidth: false,
                searching: true,
                order: [],
                pageLength: 10,
                lengthMenu: [[10, 25, 50, -1], [10, 25, 50, 'الكل']],
                dom: '<"table-toolbar"lf>t<"table-pagination flex-wrap"ip>',
                language: {
                    lengthMenu: 'إظهار _MENU_',
                    search: 'بحث:',
                    searchPlaceholder: 'ابحث في الجدول...',
                    infoFiltered: '(من إجمالي _MAX_ سجل)',
                    info: 'عرض _START_ إلى _END_ من أصل _TOTAL_ سجل',
                    infoEmpty: 'لا توجد سجلات مطابقة.',
                    emptyTable: 'لا توجد سجلات مطابقة للبحث.',
                    zeroRecords: 'لا توجد سجلات مطابقة للبحث.',
                    paginate: { first: 'الأول', last: 'الأخير', next: 'التالي', previous: 'السابق' },
                    aria: { sortAscending: ': ترتيب تصاعدي', sortDescending: ': ترتيب تنازلي' }
                }
            });
        });
    });
    window.prepareWorkGuideLogExport = function () {
        var field = document.getElementById('hfExportLogIDs');
        if (!field) return true;
        field.value = '';
        var table = document.getElementById('ERPTable');
        if (window.jQuery && jQuery.fn.dataTable && table && jQuery.fn.dataTable.isDataTable(table)) {
            var nodes = jQuery(table).DataTable().rows({ search: 'applied' }).nodes().toArray();
            field.value = JSON.stringify(nodes.map(function (row) { return Number(row.getAttribute('data-log-id')); }));
        }
        return true;
    };
}());
