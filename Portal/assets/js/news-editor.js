window.crmNewsUpdateEditors=function(){if(window.CKEDITOR)['txtDetails','txtDetailsEn'].forEach(function(id){if(CKEDITOR.instances[id])CKEDITOR.instances[id].updateElement();});};
(function(){
 'use strict';
 document.addEventListener('DOMContentLoaded',function(){
  if(!window.CKEDITOR)return;
  [['txtDetails','rtl','ar'],['txtDetailsEn','ltr','en']].forEach(function(item){
   if(!document.getElementById(item[0]))return;
   CKEDITOR.replace(item[0],{language:item[2],contentsLangDirection:item[1],height:240,resize_enabled:false,
    toolbar:[['Format','Bold','Italic','Underline','Strike','RemoveFormat'],['NumberedList','BulletedList','Blockquote'],['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],['Link','Unlink','Table','HorizontalRule'],['Undo','Redo','Maximize']],
    removePlugins:'elementspath',allowedContent:'p div span{text-align,direction}[dir]; h1 h2 h3 h4 h5 h6; br hr strong b em i u s sub sup; ul ol li blockquote pre code; a[href,title]; table thead tbody tfoot tr caption; td th[colspan,rowspan]'});
  });
 });
}());
