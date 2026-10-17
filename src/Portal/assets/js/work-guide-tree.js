(function () {
    'use strict';

    function enhance(select) {
        if (select.dataset.wgReady) return;
        select.dataset.wgReady = 'true';
        var multiple = select.multiple;
        var wrapper = document.createElement('div');
        wrapper.className = 'wg-category-tree';
        var searchLabel = document.createElement('label');
        searchLabel.textContent = 'البحث في التصنيفات';
        searchLabel.className = 'form-label';
        var search = document.createElement('input');
        search.type = 'search';
        search.className = 'form-control mb-2';
        search.placeholder = 'اسم التصنيف';
        search.id = select.id + '-search';
        searchLabel.htmlFor = search.id;
        var tree = document.createElement('div');
        var summary = document.createElement('div');
        summary.className = 'text-muted small mt-2';
        summary.setAttribute('aria-live', 'polite');
        var nodes = [], lookup = new Map();
        Array.from(select.options).forEach(function (option) {
            var node = {option: option, id: option.value, parent: option.dataset.parent || '', children: []};
            nodes.push(node);
            lookup.set(node.id, node);
        });
        nodes.forEach(function (node) {
            var parent = lookup.get(node.parent);
            if (parent && parent !== node) parent.children.push(node);
        });

        function descendants(node, seen) {
            seen = seen || new Set();
            if (seen.has(node.id)) return [];
            seen.add(node.id);
            return [node].concat(node.children.flatMap(function (child) {
                return descendants(child, seen);
            }));
        }

        function update() {
            nodes.forEach(function (node) {
                node.input.checked = node.option.selected;
                node.row.classList.toggle('wg-selected', node.option.selected);
                if (node.groupInput) {
                    var eligible = descendants(node).filter(function (child) {
                        return !child.option.disabled && child.id !== '0';
                    });
                    var count = eligible.filter(function (child) {
                        return child.option.selected;
                    }).length;
                    node.groupInput.disabled = eligible.length === 0;
                    node.groupInput.checked = eligible.length > 0 && count === eligible.length;
                    node.groupInput.indeterminate = count > 0 && count < eligible.length;
                }
            });
            var chosen = nodes.filter(function (node) {
                return node.option.selected && node.id !== '0';
            });
            summary.textContent = multiple ? chosen.length + ' تصنيفات محددة — تحديد كل المجموعة يشمل التصنيفات المتاحة للاختيار داخلها.' : (chosen[0] ? chosen[0].option.dataset.path || chosen[0].option.text : 'جميع التصنيفات المتاحة');
        }

        function render(node, visiting) {
            if (visiting.has(node.id)) return null;
            visiting = new Set(visiting);
            visiting.add(node.id);
            var container = document.createElement('div');
            container.className = 'wg-tree-node';
            node.container = container;
            var row = document.createElement('div');
            row.className = 'wg-tree-row';
            node.row = row;
            var label = document.createElement('label');
            label.className = 'wg-node-label';
            var input = document.createElement('input');
            input.type = multiple ? 'checkbox' : 'radio';
            input.name = select.id + '-visual';
            input.disabled = node.option.disabled;
            node.input = input;
            var text = document.createElement('span');
            text.textContent = node.option.dataset.name || node.option.text;
            label.append(input, text);
            row.append(label);
            if (node.option.dataset.state) {
                var state = document.createElement('small');
                state.className = 'text-muted';
                state.textContent = node.option.dataset.state;
                row.append(state);
            }
            input.addEventListener('change', function () {
                if (!multiple) nodes.forEach(function (other) {
                    other.option.selected = false;
                });
                node.option.selected = input.checked;
                update();
                select.dispatchEvent(new Event('change', {bubbles: true}));
            });
            container.append(row);
            if (node.children.length) {
                var details = document.createElement('details');
                details.open = true;
                node.details = details;
                var heading = document.createElement('summary');
                heading.textContent = 'التصنيفات الفرعية';
                details.append(heading);
                if (multiple) {
                    var groupLabel = document.createElement('label');
                    groupLabel.className = 'wg-group-label';
                    var groupInput = document.createElement('input');
                    groupInput.type = 'checkbox';
                    node.groupInput = groupInput;
                    groupLabel.append(groupInput, document.createTextNode('تحديد كل المجموعة'));
                    groupInput.addEventListener('change', function () {
                        descendants(node).forEach(function (child) {
                            if (!child.option.disabled && child.id !== '0') child.option.selected = groupInput.checked;
                        });
                        update();
                    });
                    details.append(groupLabel);
                }
                node.children.forEach(function (child) {
                    var childElement = render(child, visiting);
                    if (childElement) details.append(childElement);
                });
                container.append(details);
            }
            return container;
        }

        nodes.filter(function (node) {
            return !lookup.has(node.parent) || node.parent === node.id;
        }).forEach(function (node) {
            var element = render(node, new Set());
            if (element) tree.append(element);
        });
        // Malformed hierarchies remain selectable rather than silently disappearing.
        nodes.filter(function (node) {
            return !node.input;
        }).forEach(function (node) {
            node.children = [];
            tree.append(render(node, new Set()));
        });
        search.addEventListener('input', function () {
            var term = search.value.trim().toLocaleLowerCase();
            nodes.forEach(function (node) {
                node.container.hidden = false;
            });
            nodes.forEach(function (node) {
                var matches = descendants(node).some(function (child) {
                    return (child.option.dataset.path || child.option.text).toLocaleLowerCase().includes(term);
                });
                node.container.hidden = !matches;
                if (term && matches && node.details) node.details.open = true;
            });
        });
        select.addEventListener('change', update);
        wrapper.append(searchLabel, search, tree, summary);
        select.after(wrapper);
        select.classList.add('wg-tree-source');
        update();
    }

    function init() {
        document.querySelectorAll('select[data-wg-tree]').forEach(enhance);
        document.querySelectorAll('[data-wg-category-modal]').forEach(function (modal) {
            if (modal.dataset.wgModalReady) return;
            modal.dataset.wgModalReady = 'true';
            var select = modal.querySelector('select[data-wg-tree]'), previousValue;
            modal.addEventListener('show.bs.modal', function () {
                previousValue = select.value;
            });
            modal.addEventListener('shown.bs.modal', function () {
                var search = modal.querySelector('input[type="search"]');
                if (search) search.focus();
            });
            modal.addEventListener('hidden.bs.modal', function () {
                select.value = previousValue;
                select.dispatchEvent(new Event('change', {bubbles: true}));
            });
        });
        document.querySelectorAll('select[data-wg-role]').forEach(function (select) {
            if (select.dataset.wgRoleReady) return;
            select.dataset.wgRoleReady = 'true';
            var preview = document.createElement('div');
            preview.className = 'wg-role-preview text-muted';
            preview.setAttribute('aria-live', 'polite');
            select.after(preview);

            function updateRole() {
                var option = select.options[select.selectedIndex];
                preview.textContent = option ? option.dataset.permissions || '' : '';
            }

            select.addEventListener('change', updateRole);
            updateRole();
        });
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
    window.WorkGuideTree = {init: init};
}());
