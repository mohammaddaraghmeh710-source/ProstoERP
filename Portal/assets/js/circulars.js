(function () {
 'use strict';
 function ready(){
  if(window.jQuery){
   if(jQuery.fn.DataTable) jQuery('.circular-table').each(function(){if(!jQuery.fn.DataTable.isDataTable(this))jQuery(this).DataTable({paging:false,searching:false,info:false,ordering:false,responsive:true,columnDefs:[{targets:0,responsivePriority:1},{targets:-1,responsivePriority:2}],language:{emptyTable:'لا توجد تعاميم'}});});
   if(jQuery.fn.select2)jQuery('.circular-select').each(function(){jQuery(this).select2({dir:'rtl',width:'100%',placeholder:'اختر القيم المطلوبة',closeOnSelect:false,dropdownParent:jQuery(this).closest('.modal')});});
  }
  var audience=document.querySelector('[data-circular-audience]');
  function targetPanels(){document.querySelectorAll('[data-audience-panel]').forEach(function(p){p.hidden=p.dataset.audiencePanel!==audience.value;});}
  if(audience){audience.addEventListener('change',targetPanels);targetPanels();}
  var workspace=document.getElementById('circularWorkspace');
  if(workspace){
   var notice=document.querySelector('.circulars>.alert');if(notice)workspace.querySelector('.modal-body').prepend(notice);
   var tabId=workspace.dataset.initialTab;
   if(tabId && document.getElementById(tabId))bootstrap.Tab.getOrCreateInstance(document.getElementById(tabId)).show();
   bootstrap.Modal.getOrCreateInstance(workspace).show();
   workspace.addEventListener('hidden.bs.modal',function(){
    var url=new URL(location.href);['ID','action','new','saved'].forEach(function(key){url.searchParams.delete(key);});history.replaceState(null,'',url);workspace.closest('form').action=url.pathname+url.search;
   });
  }
  var viewer=document.getElementById('circularViewer');if(!viewer)return;
  var status=document.getElementById('circularPdfStatus'),open=document.getElementById('circularOpen'),download=document.getElementById('circularDownload'),
      canvas=document.getElementById('circularPdfCanvas'),prev=document.getElementById('pdfPrevious'),next=document.getElementById('pdfNext'),doc=null,page=1,busy=false;
  function uuid(){if(crypto.randomUUID)return crypto.randomUUID();var b=crypto.getRandomValues(new Uint8Array(16));b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;var s=Array.from(b,function(x){return x.toString(16).padStart(2,'0');}).join('');return s.slice(0,8)+'-'+s.slice(8,12)+'-'+s.slice(12,16)+'-'+s.slice(16,20)+'-'+s.slice(20);}
  function markRead(){document.dispatchEvent(new Event('circular-read'));if(viewer.dataset.admin!=='1'){
   var state=document.getElementById('circularReadState');if(state){state.textContent='مقروء';state.className='badge bg-label-success';}
   var id=new URL(viewer.dataset.fileUrl,location.href).searchParams.get('ID');
   var card=Array.from(document.querySelectorAll('[data-circular-id]')).find(function(c){return c.dataset.circularId===id;});
   var badge=card && card.querySelector('[data-read-badge]');
   if(badge && badge.textContent==='غير مقروء'){badge.textContent='مقروء';badge.className='badge bg-label-success';var count=document.querySelector('.circulars>.row>.col-md-4:nth-child(2) h4');if(count)count.textContent=Math.max(0,Number(count.textContent)-1);}
  }}
  function message(text,error){status.textContent=text;status.className='p-3 small '+(error?'text-danger':'text-muted');}
  async function bytes(action){
   var response=await fetch(viewer.dataset.fileUrl+'&action='+action+'&event='+uuid(),{method:'POST',credentials:'same-origin',cache:'no-store',headers:{'X-Circular-CSRF':viewer.dataset.csrf}});
   if(!response.ok)throw new Error(await response.text());
   if(!(response.headers.get('Content-Type')||'').includes('application/pdf'))throw new Error('انتهت جلسة الدخول. أعد تسجيل الدخول.');
   var result=await response.arrayBuffer();markRead();return result;
  }
  async function render(){
   var pdfPage=await doc.getPage(page),base=pdfPage.getViewport({scale:1});
   var scale=Math.min((viewer.clientWidth-8)/base.width,2,Math.sqrt(5000000/(base.width*base.height)));
   var viewport=pdfPage.getViewport({scale:Math.max(.05,scale)});
   canvas.width=viewport.width;canvas.height=viewport.height;canvas.classList.remove('d-none');
   await pdfPage.render({canvasContext:canvas.getContext('2d'),viewport:viewport}).promise;
   document.getElementById('pdfPageLabel').textContent=page+' / '+doc.numPages;
   prev.disabled=page<=1;next.disabled=page>=doc.numPages;
  }
  async function operation(action){
   if(busy)return;busy=true;open.disabled=true;if(download)download.disabled=true;
   message(action==='view'?'جارٍ تحميل الملف للعرض…':'جارٍ تجهيز التنزيل…',false);
   try{
    var data=await bytes(action);
    if(action==='download'){
     var url=URL.createObjectURL(new Blob([data],{type:'application/pdf'})),link=document.createElement('a');
     link.href=url;link.download='circular.pdf';link.click();setTimeout(function(){URL.revokeObjectURL(url);},60000);message('تم تجهيز الملف للتنزيل وتسجيل العملية.',false);
    }else{
     if(typeof pdfjsLib==='undefined')throw new Error('تعذر تحميل عارض PDF.');
     if(doc)await doc.destroy();
     pdfjsLib.GlobalWorkerOptions.workerSrc='/assets/js/pdf.worker.min.js';
     doc=await pdfjsLib.getDocument({data:new Uint8Array(data),isEvalSupported:false,enableScripting:false,disableFontFace:true,useSystemFonts:false,standardFontDataUrl:"/assets/vendor/libs/pdfjs/standard_fonts/"}).promise;page=1;
     await render();var controls=document.getElementById('circularPdfControls');controls.classList.remove('d-none');controls.classList.add('d-flex');
     message('تم فتح الملف وتسجيل العملية.',false);
    }
   }catch(e){message(e.message||'تعذر فتح الملف. أعد المحاولة.',true);}
   finally{busy=false;open.disabled=false;if(download)download.disabled=false;}
  }
  open.addEventListener('click',function(){operation('view');});
  if(download)download.addEventListener('click',function(){operation('download');});
  if(workspace && viewer.dataset.initialAction){workspace.addEventListener('shown.bs.modal',function(){operation(viewer.dataset.initialAction);},{once:true});}
  async function move(delta){if(busy||!doc||page+delta<1||page+delta>doc.numPages)return;busy=true;try{page+=delta;await render();}catch(e){message('تعذر عرض الصفحة.',true);}finally{busy=false;}}
  prev.addEventListener('click',function(){move(-1);});next.addEventListener('click',function(){move(1);});
 }
 if(document.readyState==='complete')ready();else window.addEventListener('load',ready);
})();
