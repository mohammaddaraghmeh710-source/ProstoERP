window.crmGuideUpdateEditors=function(){if(window.CKEDITOR)['guideDetailsAr','guideDetailsEn'].forEach(function(id){if(CKEDITOR.instances[id])CKEDITOR.instances[id].updateElement();});};
(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () {
    if (window.CKEDITOR) {
      [['guideDetailsAr','rtl','ar'],['guideDetailsEn','ltr','en']].forEach(function (item) {
        if (!document.getElementById(item[0])) return;
        CKEDITOR.replace(item[0],{language:item[2],contentsLangDirection:item[1],height:240,resize_enabled:false,
          toolbar:[['Format','Bold','Italic','Underline','Strike','RemoveFormat'],['NumberedList','BulletedList','Blockquote'],['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],['Link','Unlink','Table','HorizontalRule'],['Undo','Redo','Maximize']],
          removePlugins:'elementspath',allowedContent:'p div span{text-align,direction}[dir]; h1 h2 h3 h4 h5 h6; br hr strong b em i u s sub sup; ul ol li blockquote pre code; a[href,title]; table thead tbody tfoot tr caption; td th[colspan,rowspan]'});
      });
    }
    var source = document.getElementById('crmGuideTreeData');
    if (!source || !window.jQuery || !jQuery.fn.jstree) return;
    var nodes = JSON.parse(source.textContent || '[]');
    var theme = document.documentElement.classList.contains('light-style') ? 'default' : 'default-dark';
    var selected = document.getElementById('categorySelected');
    var checked = document.getElementById('guideCategoryIDs');
    var manager = jQuery('#categoryManageTree');
    var choices = jQuery('#guideCategoryTree');
    var categoryBrand = document.getElementById('categoryBrand'), guideBrand = document.getElementById('guideBrand');
    function search(inputID, tree) { CRMGuideTreeSearch.bind(inputID, tree); }
    function enableActions(value) {
      document.querySelectorAll('[data-crm-category-action]').forEach(function (button) {
        button.classList.toggle('disabled', !value);
        button.setAttribute('aria-disabled', value ? 'false' : 'true');
      });
    }
    enableActions(selected && selected.value);
    function treeNodes(prefix, brand) {
      var result = JSON.parse(JSON.stringify(nodes.filter(function (node) { return brand && String(node.brandId) === brand; })));
      result.forEach(function (node) {
        node.state = node.state || {};
        node.state.opened = true;
        node.data = {categoryId:node.id,brandId:node.brandId};
        node.id = prefix + node.id;
        if (node.parent !== '#') node.parent = prefix + node.parent;
      });
      return result;
    }
    function emptyMessage(tree, count, brand) {
      if (count) return;
      tree.one('ready.jstree', function () {
        var message = document.createElement('p');
        message.className = 'small text-muted mb-0';
        message.textContent = brand ? 'لا توجد تصنيفات لهذه العلامة التجارية. أضف تصنيفًا رئيسيًا للبدء.' : 'اختر العلامة التجارية أولًا لعرض تصنيفاتها.';
        tree[0].appendChild(message);
      });
    }
    if (manager.length) {
      var managementBrand = categoryBrand ? categoryBrand.value : '', managementNodes = treeNodes('category-', managementBrand);
      manager.jstree({core:{data:managementNodes,multiple:false,force_text:true,themes:{name:theme}},search:{show_only_matches:false,close_opened_onclear:false},plugins:['search']})
        .on('ready.jstree', function () {
          manager.jstree(true).open_all();
          CRMGuideTreeSearch.refresh('categoryTreeSearch',manager);
          if (selected && selected.value && manager.jstree(true).get_node('category-' + selected.value)) manager.jstree(true).select_node('category-' + selected.value);
        }).on('select_node.jstree', function (event, data) {
          if (selected) selected.value = data.node.data.categoryId;
          enableActions(data.node.data.categoryId);
        });
      search('categoryTreeSearch', manager);
      emptyMessage(manager, managementNodes.length, managementBrand);
    }
    if (choices.length && checked) {
      function renderChoices(preserve) {
        if (choices.data('jstree')) choices.jstree('destroy');
        choices.off('.crmGuideChoices').empty();
        if (!preserve) checked.value = '';
        var ids = checked.value.split(',').filter(Boolean), brand = guideBrand ? guideBrand.value : '';
        var choiceNodes = treeNodes('guide-category-', brand);
        choiceNodes.forEach(function (node) { node.state.checked = ids.indexOf(node.data.categoryId) !== -1; });
        choices.jstree({core:{data:choiceNodes,force_text:true,themes:{name:theme}},checkbox:{three_state:false,cascade:'',tie_selection:false,whole_node:true},search:{show_only_matches:false,close_opened_onclear:false},plugins:['checkbox','search']})
        .on('ready.jstree.crmGuideChoices', function () {
          choices.jstree(true).open_all();
          CRMGuideTreeSearch.refresh('guideCategorySearch',choices);
        }).on('check_node.jstree.crmGuideChoices uncheck_node.jstree.crmGuideChoices', function () {
          checked.value = choices.jstree(true).get_checked().map(function (id) { return choices.jstree(true).get_node(id).data.categoryId; }).join(',');
        });
        emptyMessage(choices, choiceNodes.length, brand);
      }
      renderChoices(true);
      if (guideBrand) guideBrand.addEventListener('change', function () { renderChoices(false); });
      search('guideCategorySearch', choices);
    }
  });
}());
