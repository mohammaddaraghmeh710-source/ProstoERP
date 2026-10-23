(function () {
    function addClickAndTouch(el, handler) {
        if (!el) return;
        el.addEventListener('click', handler, false);
        el.addEventListener('touchstart', function (e) {
            e.preventDefault();
            handler(e);
        }, { passive: false });
    }

    function initTableFeatures() {
        const table = document.getElementById('ERPTable');
        if (!table) return;
        if (table.dataset.enhanced === '1') return;

        const tbody = table.querySelector('tbody');
        const allRows = Array.from(tbody.querySelectorAll('tr'));

        // ===== toolbar (length + search) =====
        const toolbar = document.createElement('div');
        toolbar.className = 'table-toolbar';

        const filterBox = document.createElement('div');
        filterBox.className = 'dataTables_filter';
        filterBox.innerHTML = `
      <label>
        <span>بحث:</span>
        <input id="tbl-search" type="search" class="form-control form-control-sm" placeholder="ابحث..." />
      </label>
    `;

        const lengthBox = document.createElement('div');
        lengthBox.className = 'dataTables_length';
        lengthBox.innerHTML = `
      <label>
        <span>إظهار</span>
        <select id="tbl-length" class="form-select form-select-sm">
          <option value="10">10 </option>
          <option value="25">25 </option>
          <option value="50">50 </option>
          <option value="-1">الكل</option>
        </select>
      </label>
    `;

        // insert toolbar before table
        const wrapper = document.createElement('div');
        wrapper.className = 'table-wrapper';
        const parent = table.parentNode;
        parent.insertBefore(toolbar, table);
        parent.insertBefore(wrapper, table);
        wrapper.appendChild(table);

        toolbar.appendChild(lengthBox);
        toolbar.appendChild(filterBox);

        // ===== pagination container =====
        const paginationWrapper = document.createElement('div');
        paginationWrapper.className = 'table-pagination';

        const totalLabel = document.createElement('div');
        totalLabel.className = 'total-records';
        paginationWrapper.appendChild(totalLabel);

        const pagUl = document.createElement('ul');
        pagUl.className = 'pagination pagination-sm mb-0';
        paginationWrapper.appendChild(pagUl);

        parent.appendChild(paginationWrapper);

        // ===== state =====
        let pageSize = 10;
        let currentPage = 1;
        let filteredRows = [...allRows];

        function updateTotalLabel() {
            const total = filteredRows.length;
            const start = total === 0 ? 0 : (pageSize === -1 ? 1 : (currentPage - 1) * pageSize + 1);
            const end = pageSize === -1 ? total : Math.min(currentPage * pageSize, total);

            totalLabel.textContent =
                total === 0
                    ? 'لا توجد سجلات مطابقة.'
                    : `عرض ${start} إلى ${end} من أصل ${total} سجل`;
        }

        function totalPages() {
            if (pageSize === -1) return 1;
            return Math.max(1, Math.ceil(filteredRows.length / pageSize));
        }

        function renderRows() {
            allRows.forEach(tr => (tr.style.display = 'none'));

            if (pageSize === -1) {
                filteredRows.forEach(tr => (tr.style.display = ''));
                renderPager(1);
                return;
            }

            const pages = totalPages();
            if (currentPage > pages) currentPage = pages;

            const start = (currentPage - 1) * pageSize;
            const end = start + pageSize;

            filteredRows.slice(start, end).forEach(tr => (tr.style.display = ''));
            renderPager(pages);
        }

        function renderPager(pages) {
            pagUl.innerHTML = '';

            if (pages <= 1) return;

            function createPageItem(page, label, disabled, active) {
                const li = document.createElement('li');
                li.className = 'page-item';
                if (disabled) li.classList.add('disabled');
                if (active) li.classList.add('active');

                const a = document.createElement('a');
                a.href = 'javascript:void(0);';
                a.className = 'page-link';
                a.textContent = label;

                if (!disabled && !active) {
                    a.addEventListener('click', function () {
                        currentPage = page;
                        renderRows();
                        updateTotalLabel();
                    });
                }

                li.appendChild(a);
                return li;
            }

            const prevDisabled = currentPage === 1;
            const nextDisabled = currentPage === pages;

            const prevLi = document.createElement('li');
            prevLi.className = 'page-item' + (prevDisabled ? ' disabled' : '');
            const prevA = document.createElement('a');
            prevA.href = 'javascript:void(0);';
            prevA.className = 'page-link';
            prevA.innerHTML = '<i class="bx bx-chevron-right"></i>';
            if (!prevDisabled) {
                prevA.addEventListener('click', function () {
                    currentPage--;
                    renderRows();
                    updateTotalLabel();
                });
            }
            prevLi.appendChild(prevA);
            pagUl.appendChild(prevLi);

            for (let p = 1; p <= pages; p++) {
                pagUl.appendChild(createPageItem(p, String(p), false, p === currentPage));
            }

            const nextLi = document.createElement('li');
            nextLi.className = 'page-item' + (nextDisabled ? ' disabled' : '');
            const nextA = document.createElement('a');
            nextA.href = 'javascript:void(0);';
            nextA.className = 'page-link';
            nextA.innerHTML = '<i class="bx bx-chevron-left"></i>';
            if (!nextDisabled) {
                nextA.addEventListener('click', function () {
                    currentPage++;
                    renderRows();
                    updateTotalLabel();
                });
            }
            nextLi.appendChild(nextA);
            pagUl.appendChild(nextLi);
        }

        function applySearchFilter() {
            const searchInput = document.getElementById('tbl-search');
            const term = (searchInput.value || '').toLowerCase().trim();

            if (!term) {
                filteredRows = [...allRows];
            } else {
                filteredRows = allRows.filter(tr => {
                    const tds = Array.from(tr.querySelectorAll('td'));
                    return tds.some(td => (td.textContent || '').toLowerCase().includes(term));
                });
            }
            currentPage = 1;
            renderRows();
            updateTotalLabel();
        }

        const lengthSelect = document.getElementById('tbl-length');
        lengthSelect.addEventListener('change', function () {
            pageSize = parseInt(this.value, 10);
            currentPage = 1;
            renderRows();
            updateTotalLabel();
        });

        const searchInput = document.getElementById('tbl-search');
        let searchTimeout = null;
        searchInput.addEventListener('input', function () {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(applySearchFilter, 250);
        });

        renderRows();
        updateTotalLabel();

        table.dataset.enhanced = '1';
    }

    // Conditional Web Forms regions can replace the table after initial page load.
    window.ERPTableFeatures = { refresh: initTableFeatures };
    document.addEventListener('DOMContentLoaded', initTableFeatures);
})();
