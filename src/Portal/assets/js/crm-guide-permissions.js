(function () {
 'use strict';
 window.addEventListener('load',function () {
  var source=document.getElementById('guideGrantTreeData'),element=document.getElementById('guidePermissionsTree'),input=document.getElementById('grantTreeSearch');
  if(!source||!element||!window.jQuery||!jQuery.fn.jstree)return;
  var tree=jQuery(element),nodes=JSON.parse(source.textContent||'[]');
  tree.on('ready.jstree',function () {
   tree.jstree(true).open_all();
   document.querySelectorAll('#guideGrantControls [data-category]').forEach(function (controls) {
    var node=document.getElementById('grant-category-'+controls.dataset.category);
    if(!node)return;
    var anchor=node.querySelector(':scope > .jstree-anchor');
    if(anchor)anchor.insertAdjacentElement('afterend',controls);
   });
   CRMGuideTreeSearch.refresh('grantTreeSearch',tree);
  }).jstree({core:{data:nodes,multiple:false,force_text:true,themes:{name:'default'}},search:{show_only_matches:false,close_opened_onclear:false},plugins:['search']});
  CRMGuideTreeSearch.bind('grantTreeSearch',tree);
 });
}());
