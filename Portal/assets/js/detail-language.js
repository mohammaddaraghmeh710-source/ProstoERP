(function () {
  'use strict';
  function sync(root) {
    var language = root.getAttribute('data-detail-language') === 'en' ? 'en' : 'ar';
    root.querySelectorAll('[data-detail-header]').forEach(function (header) { header.setAttribute('dir', language === 'en' ? 'ltr' : 'rtl'); });
    var button = root.querySelector('[data-detail-language-toggle]');
    var state = root.querySelector('[data-detail-language-value]');
    var title = root.querySelector('[data-detail-title][data-detail-lang="' + language + '"]');
    if (button) {
      button.textContent = language === 'en' ? 'العربية' : 'English';
      button.setAttribute('lang', language === 'en' ? 'ar' : 'en');
      button.setAttribute('aria-label', language === 'en' ? 'عرض المحتوى بالعربية' : 'عرض المحتوى بالإنجليزية');
    }
    if (state) state.value = language;
    if (title) document.title = title.textContent.trim();
  }
  function initialize() {
    document.querySelectorAll('[data-detail-language]').forEach(sync);
  }
  document.addEventListener('click', function (event) {
    var button = event.target.closest('[data-detail-language-toggle]');
    if (!button) return;
    var root = button.closest('[data-detail-language]');
    if (!root) return;
    root.setAttribute('data-detail-language', root.getAttribute('data-detail-language') === 'en' ? 'ar' : 'en');
    sync(root);
  });
  document.addEventListener('DOMContentLoaded', function () {
    initialize();
    if (window.Sys && Sys.Application) Sys.Application.add_load(initialize);
  });
}());
