(function () {
 'use strict';
 function options(select, nodes, name) {
  if (select.dataset.authorizedBrands === '1') { select.setAttribute('aria-label', name); return; }
  var brands = new Map();
  nodes.forEach(function (node) { if (node.dataset.brandId) brands.set(node.dataset.brandId, node.dataset.brandName || 'علامة تجارية'); });
  select.replaceChildren(new Option('جميع العلامات التجارية', ''));
  brands.forEach(function (title, id) { select.add(new Option(title, id)); });
  select.setAttribute('aria-label', name);
 }
 function initializeNews() {
  var root = document.getElementById('brandNewsSection'); if (!root || root.dataset.brandFilterReady) return;
  root.dataset.brandFilterReady = '1';
  var select = root.querySelector('[data-news-brand-filter]'), carousel = root.querySelector('.carousel'), empty = root.querySelector('[data-news-filter-empty]');
  if (!select || !carousel) return;
  var body = carousel.querySelector('.carousel-inner'), entries = Array.from(body.children), indicatorBox = carousel.querySelector('.carousel-indicators'), indicators = indicatorBox ? Array.from(indicatorBox.children) : [];
  options(select, entries, 'العلامة التجارية للأخبار');
  function applyFilter() {
   var instance = bootstrap.Carousel.getInstance(carousel); if (instance) instance.dispose();
   var visible = entries.filter(function (entry) { return !select.value || entry.dataset.brandId === select.value; });
   entries.forEach(function (entry) { entry.classList.remove('active', 'carousel-item-next', 'carousel-item-prev', 'carousel-item-start', 'carousel-item-end'); });
   if (visible.length) visible[0].classList.add('active');
   body.replaceChildren.apply(body, visible);
   if (indicatorBox) {
    indicatorBox.replaceChildren();
    visible.forEach(function (entry, index) {
     var button = indicators[entries.indexOf(entry)]; if (!button) return;
     button.dataset.bsSlideTo = String(index); button.classList.toggle('active', index === 0);
     if (index === 0) button.setAttribute('aria-current', 'true'); else button.removeAttribute('aria-current');
     indicatorBox.appendChild(button);
    });
    indicatorBox.hidden = visible.length < 2;
   }
   carousel.hidden = !visible.length; if (empty) empty.hidden = !!visible.length;
   if (visible.length) bootstrap.Carousel.getOrCreateInstance(carousel, { interval: false, ride: false });
  }
  var waiting = false;
  select.addEventListener('change', function () {
   if (carousel.querySelector('.carousel-item-next,.carousel-item-prev')) {
    if (!waiting) { waiting = true; carousel.addEventListener('slid.bs.carousel', function () { waiting = false; applyFilter(); }, { once: true }); }
    return;
   }
   applyFilter();
  });
 }
 function initializeCirculars() {
  var select = document.querySelector('[data-customer-circular-brand]'), search = document.querySelector('[data-customer-circular-search]');
  if (!select || !search || select.dataset.filterReady) return;
  select.dataset.filterReady = '1';
  var cards = Array.from(document.querySelectorAll('[data-circular-card]')), empty = document.querySelector('[data-circular-empty]');
  options(select, cards, 'العلامة التجارية للتعاميم');
  function filter() {
   var text = search.value.trim().toLowerCase(), count = 0;
   cards.forEach(function (card) { card.hidden = !((!select.value || select.value === card.dataset.brandId) && card.textContent.toLowerCase().includes(text)); if (!card.hidden) count++; });
   if (empty) empty.hidden = count > 0;
  }
  select.addEventListener('change', filter); search.addEventListener('input', filter);
 }
 document.addEventListener('DOMContentLoaded', function () { initializeNews(); initializeCirculars(); });
}());
