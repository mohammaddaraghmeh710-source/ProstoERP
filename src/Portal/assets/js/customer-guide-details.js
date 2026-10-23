(function () {
 'use strict';
 window.addEventListener('load',function () {
  var source=document.getElementById('customerCategoryTreeData'),category=document.getElementById('category'),search=document.getElementById('customerCategorySearch'),tree=jQuery('#customerCategoryTree');
  if(source&&category&&tree.length&&jQuery.fn.jstree){
   var initial=true,brand=document.getElementById('customerGuideBrand'),table=document.getElementById('ERPTable'),nodes=JSON.parse(source.textContent||'[]');
   function selectedBrand(){return brand?brand.value:'';}
   function belongsToBrand(node){return !selectedBrand()||(node.data&&node.data.brandId===selectedBrand());}
   function matchesRow(row){return (!selectedBrand()||row.dataset.guideBrand===selectedBrand())&&(!category.value||row.dataset.guideCategory===category.value);}
   if(table&&jQuery.fn.dataTable){
    jQuery.fn.dataTable.ext.search.push(function(settings,data,index){return settings.nTable!==table||matchesRow(settings.aoData[index].nTr);});
    jQuery(table).on('draw.dt',function(){
     var api=jQuery(table).DataTable(),ids=new Set();api.rows({search:'applied'}).nodes().each(function(row){ids.add(row.dataset.guideId);});
     document.getElementById('customerGuideItemCount').textContent=ids.size.toLocaleString('ar');
    });
   }
   function redraw(){
    if(table&&jQuery.fn.dataTable&&jQuery.fn.dataTable.isDataTable(table))jQuery(table).DataTable().draw();
    else if(table)table.querySelectorAll('tbody tr[data-guide-brand]').forEach(function(row){row.hidden=!matchesRow(row);});
    var count=nodes.filter(function(node){return node.data&&node.data.hasAccess&&(!selectedBrand()||node.data.brandId===selectedBrand());}).length;
    document.getElementById('customerGuideCategoryCount').textContent=count.toLocaleString('ar');
    var option=category.selectedOptions[0],rights='حسب التصنيف الموضح لكل دليل';
    if(option&&option.value)rights=option.dataset.view==='1'?(option.dataset.download==='1'?'اطلاع وتحميل':'اطلاع فقط'):'تحميل فقط';
    document.getElementById('customerGuideRights').textContent=rights;
   }
   function choose(value){
    if(category.value===value)return;category.value=value;
    if(!value)tree.jstree(true).deselect_all();
    redraw();
   }
   function filterBrand(){
    var instance=tree.jstree(true),selected=selectedBrand(),option=category.selectedOptions[0];
    if(option&&option.value&&selected&&option.dataset.brand!==selected){category.value='';instance.deselect_all();}
    Array.from(category.options).forEach(function(item){var available=!item.value||!selected||item.dataset.brand===selected;item.hidden=!available;item.disabled=!available;});
    nodes.filter(function(node){return node.data&&node.data.isBrand;}).forEach(function(node){if(!selected||node.data.brandId===selected)instance.show_node(node.id);else instance.hide_node(node.id);});
    CRMGuideTreeSearch.refresh('customerCategorySearch',tree,belongsToBrand);redraw();
   }
   tree.on('ready.jstree',function(){var instance=tree.jstree(true);instance.open_all();if(category.value)instance.select_node('customer-category-'+category.value);initial=false;filterBrand();})
    .on('select_node.jstree',function(event,data){if(!initial&&data.node.data&&data.node.data.categoryId)choose(data.node.data.categoryId);})
    .jstree({core:{data:nodes,force_text:true,multiple:false,themes:{name:'default'}},search:{show_only_matches:false,close_opened_onclear:false},plugins:['search']});
   CRMGuideTreeSearch.bind('customerCategorySearch',tree,belongsToBrand);
   document.getElementById('customerAllCategories').addEventListener('click',function(){choose('');});
   if(brand)brand.addEventListener('change',filterBrand);
   category.addEventListener('change',filterBrand);
  }
  var page=document.getElementById('guideDetailsPage');if(!page)return;
  var ar=document.getElementById('guideDetailsArabic'),en=document.getElementById('guideDetailsEnglish'),input=document.getElementById('guideDetailsSearch'),counter=document.getElementById('guideDetailsMatches'),next=document.getElementById('guideDetailsNext');
  var matches=[],active=-1,searchTimer,lastQuery='';
  function clearMarks(){[ar,en].forEach(function(root){root.querySelectorAll('mark[data-guide-match]').forEach(function(mark){mark.replaceWith(document.createTextNode(mark.textContent));});root.normalize();});matches=[];active=-1;}
  function highlight(){
   clearMarks();var query=input.value.trim().toLocaleLowerCase();lastQuery=query;
   if(!query){counter.textContent='';next.disabled=true;return;}
   [ar,en].forEach(function(root){
    var walker=document.createTreeWalker(root,NodeFilter.SHOW_TEXT),nodes=[],text='',node;
    while((node=walker.nextNode())){nodes.push({node:node,start:text.length,end:text.length+node.length});text+=node.data;}
    var lower=text.toLocaleLowerCase(),offset=0,index,ranges=[];
    while(matches.length+ranges.length<500&&(index=lower.indexOf(query,offset))!==-1){ranges.push({start:index,end:index+query.length,marks:[]});offset=index+query.length;}
    nodes.slice().reverse().forEach(function(item){
     ranges.slice().reverse().forEach(function(range){
      var start=Math.max(range.start,item.start)-item.start,end=Math.min(range.end,item.end)-item.start;
      if(start>=end)return;
      var part=item.node;if(end<part.length)part.splitText(end);if(start>0)part=part.splitText(start);
      var mark=document.createElement('mark');mark.dataset.guideMatch='1';part.replaceWith(mark);mark.appendChild(part);range.marks.unshift(mark);
     });
    });
    ranges.forEach(function(range){if(range.marks.length)matches.push(range.marks);});
   });
   counter.textContent=matches.length?(matches.length===500?'أول 500 نتيجة':'عدد النتائج: '+matches.length):'لا توجد نتائج مطابقة.';
   next.disabled=!matches.length;
   if(matches.length)goNext();
  }
  function goNext(){
   if(!matches.length)return;
   active=(active+1)%matches.length;
   var mark=matches[active][0],pane=mark.closest('.tab-pane'),tab=document.getElementById(pane.getAttribute('aria-labelledby'));
   function reveal(){if(mark.isConnected&&matches[active]&&matches[active][0]===mark&&pane.classList.contains('active'))mark.scrollIntoView({block:'center',behavior:'smooth'});}
   if(tab.classList.contains('active'))reveal();
   else {tab.addEventListener('shown.bs.tab',reveal,{once:true});bootstrap.Tab.getOrCreateInstance(tab).show();}
   counter.textContent='النتيجة '+(active+1)+' من '+matches.length+' — '+(pane.id==='guideDetailsArPane'?'العربية':'English');
  }
  function advanceSearch(){clearTimeout(searchTimer);if(input.value.trim().toLocaleLowerCase()!==lastQuery)highlight();else goNext();}
  input.addEventListener('input',function(){clearTimeout(searchTimer);searchTimer=setTimeout(highlight,150);});
  input.addEventListener('keydown',function(event){if(event.key==='Enter'){event.preventDefault();advanceSearch();}});
  next.addEventListener('click',advanceSearch);
  highlight();
 });
}());
