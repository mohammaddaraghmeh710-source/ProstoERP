(function () {
 'use strict';
 function ready(){
  var root=document.getElementById('circularReader');if(!root||root.dataset.readerBound)return;root.dataset.readerBound='1';
  var metadata=document.getElementById('readerMetadata'),title=document.getElementById('readerDocumentTitle'),date=document.getElementById('readerDate'),brand=document.getElementById('readerBrand'),summary=document.getElementById('readerSummary'),language=document.getElementById('readerLanguage');
  var status=document.getElementById('readerStatus'),state=document.getElementById('readerReadState'),download=document.getElementById('readerDownload'),retry=document.getElementById('readerRetry'),controls=document.getElementById('readerPdfControls'),wrap=document.getElementById('readerCanvasWrap'),canvas=document.getElementById('readerPdfCanvas');
  var previous=document.getElementById('readerPrevious'),next=document.getElementById('readerNext'),pageLabel=document.getElementById('readerPageLabel'),zoomIn=document.getElementById('readerZoomIn'),zoomOut=document.getElementById('readerZoomOut'),zoomLabel=document.getElementById('readerZoomLabel');
  var generation=0,controller=null,pdf=null,loadingTask=null,renderTask=null,current=null,openingID=0,page=1,zoom=1,busy=false,lang='ar',marked=new Set(),resizeTimer;
  function uuid(){if(crypto.randomUUID)return crypto.randomUUID();var b=crypto.getRandomValues(new Uint8Array(16));b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;var s=Array.from(b,function(x){return x.toString(16).padStart(2,'0');}).join('');return s.slice(0,8)+'-'+s.slice(8,12)+'-'+s.slice(12,16)+'-'+s.slice(16,20)+'-'+s.slice(20);}
  function message(text,failed){status.textContent=text;status.className=(failed?'alert alert-danger my-3':'text-muted small py-3');status.setAttribute('role',failed?'alert':'status');}
  function buttons(){previous.disabled=busy||!pdf||page<=1;next.disabled=busy||!pdf||page>=pdf.numPages;zoomIn.disabled=busy||!pdf||zoom>=3;zoomOut.disabled=busy||!pdf||zoom<=.5;download.disabled=busy||!current||!current.allowDownload;}
  function resetUi(){metadata.hidden=true;controls.hidden=true;wrap.hidden=true;retry.hidden=true;download.hidden=true;download.disabled=true;pageLabel.textContent='—';zoomLabel.textContent='100%';buttons();}
  async function release(){
   var oldRender=renderTask,oldLoading=loadingTask,oldPdf=pdf;renderTask=loadingTask=pdf=null;
   var jobs=[];if(oldRender){oldRender.cancel();jobs.push(oldRender.promise.catch(function(){}));}
   if(oldLoading)jobs.push(Promise.resolve(oldLoading.destroy()).catch(function(){}));
   else if(oldPdf)jobs.push(Promise.resolve(oldPdf.destroy()).catch(function(){}));
   await Promise.all(jobs);
  }
  async function errorText(response){
   if(response.status===409)return 'تغير إصدار التعميم. أعد المحاولة لعرض النسخة الحالية.';
   var type=response.headers.get('Content-Type')||'',text;
   if(type.indexOf('application/json')!==-1){var body=await response.json();text=body.error||body.message;}
   else if(type.indexOf('text/plain')!==-1)text=await response.text();
   return typeof text==='string'&&text.length<700?text:'تعذر عرض التعميم. تحقق من صلاحية الجلسة وأعد المحاولة.';
  }
  function localizedMetadata(){
   if(!current)return;var english=lang==='en';metadata.dir=english?'ltr':'rtl';metadata.lang=english?'en':'ar';
   title.textContent=(english?current.titleEn:current.title)||(english?'English title is unavailable.':'عنوان التعميم غير متاح.');
   summary.textContent=(english?current.summaryEn:current.summary)||(english?'English summary is unavailable.':'لا يوجد ملخص.');
   date.textContent=current.date||'';date.dateTime=current.date||'';brand.textContent=current.brand||'';brand.hidden=!current.brand;
   document.getElementById('readerVersion').textContent=(english?'Version ':'الإصدار ')+current.version;
   language.textContent=english?'العربية':'English';language.setAttribute('aria-label',english?'عرض التعميم باللغة العربية':'View circular in English');
  }
  function dialog(ticket){
   if(root.classList.contains('show'))return Promise.resolve();
   return new Promise(function(resolve){function finish(){root.removeEventListener('shown.bs.modal',finish);root.removeEventListener('hide.bs.modal',finish);root.removeEventListener('hidden.bs.modal',reopen);resolve();}function reopen(){if(ticket!==generation)finish();else bootstrap.Modal.getOrCreateInstance(root).show();}root.addEventListener('shown.bs.modal',finish);root.addEventListener('hide.bs.modal',finish);root.addEventListener('hidden.bs.modal',reopen);bootstrap.Modal.getOrCreateInstance(root).show();});
  }
  function readState(meta){state.textContent=meta.admin?'معاينة إدارية':(meta.isRead?'مقروء':'غير مقروء');state.className='badge '+(meta.admin?'bg-label-secondary':(meta.isRead?'bg-label-success':'bg-label-warning'));}
  function markRead(meta){
   if(meta.admin)return;var changed=false;
   document.querySelectorAll('[data-circular-row][data-circular-id][data-circular-version]').forEach(function(row){
    if(Number(row.dataset.circularId)!==meta.id||Number(row.dataset.circularVersion)!==meta.version)return;
    if(row.dataset.read!=='1')changed=true;row.dataset.read='1';
    row.querySelectorAll('[data-read-badge]').forEach(function(badge){badge.textContent='مقروء';badge.className='badge bg-label-success';});
   });
   if(changed)document.querySelectorAll('[data-circular-unread-count]').forEach(function(count){var value=Number(count.dataset.count);if(Number.isFinite(value)){value=Math.max(0,value-1);count.dataset.count=String(value);count.textContent=value.toLocaleString();}});
   meta.isRead=true;if(current===meta)readState(meta);
   var detail={id:meta.id,version:meta.version},key=meta.id+':'+meta.version;
   if(!marked.has(key)){marked.add(key);document.dispatchEvent(new CustomEvent('circular-read',{detail:detail}));}
   document.dispatchEvent(new CustomEvent('circular-reader-updated',{detail:detail}));
  }
  async function render(ticket){
   if(!pdf||ticket!==generation)return;var documentPdf=pdf,pdfPage=await documentPdf.getPage(page);if(ticket!==generation)return;
   var base=pdfPage.getViewport({scale:1}),width=Math.max(40,wrap.clientWidth-2),scale=Math.max(.05,Math.min(width/base.width*zoom,4,Math.sqrt(5000000/(base.width*base.height)))),viewport=pdfPage.getViewport({scale:scale});
   canvas.width=viewport.width;canvas.height=viewport.height;renderTask=pdfPage.render({canvasContext:canvas.getContext('2d'),viewport:viewport});var task=renderTask;
   try{await task.promise;}finally{if(renderTask===task)renderTask=null;}
   if(ticket!==generation)return;pageLabel.textContent=page+' / '+documentPdf.numPages;zoomLabel.textContent=Math.round(zoom*100)+'%';
  }
  async function bytes(meta,action){
   var url=new URL(meta.fileUrl,location.href);if(url.origin!==location.origin)throw new Error('رابط الملف غير صالح.');
   url.searchParams.set('action',action);url.searchParams.set('event',uuid());url.searchParams.set('version',meta.version);
   if(meta.admin)url.searchParams.set('admin','1');else url.searchParams.delete('admin');
   controller=new AbortController();
   var response=await fetch(url.href,{method:'POST',credentials:'same-origin',cache:'no-store',signal:controller.signal,headers:{'X-Circular-CSRF':root.dataset.csrf}});
   if(!response.ok)throw new Error(await errorText(response));
   if(!(response.headers.get('Content-Type')||'').includes('application/pdf'))throw new Error('انتهت جلسة الدخول. أعد تسجيل الدخول.');
   var deliveredVersion=response.headers.get('X-Circular-Version');if(deliveredVersion&&Number(deliveredVersion)!==meta.version)throw new Error('تغير إصدار التعميم. أعد المحاولة لعرض النسخة الحالية.');
   var data=await response.arrayBuffer();if(!data.byteLength)throw new Error('الملف فارغ أو لم يكتمل تحميله.');markRead(meta);return data;
  }
  async function view(meta,ticket){
   busy=true;buttons();message('جارٍ تحميل ملف التعميم للعرض…',false);
   try{
    var data=await bytes(meta,'view');if(ticket!==generation)return;
    if(typeof pdfjsLib==='undefined')throw new Error('تعذر تحميل عارض PDF. أعد تحميل الصفحة.');
    pdfjsLib.GlobalWorkerOptions.workerSrc='/assets/js/pdf.worker.min.js';
    loadingTask=pdfjsLib.getDocument({data:new Uint8Array(data),isEvalSupported:false,enableScripting:false,disableFontFace:true,useSystemFonts:false,standardFontDataUrl:'/assets/vendor/libs/pdfjs/standard_fonts/'});
    var task=loadingTask,loaded=await task.promise;if(ticket!==generation){await loaded.destroy();return;}pdf=loaded;loadingTask=null;page=1;zoom=1;wrap.hidden=false;controls.hidden=false;
    await render(ticket);if(ticket===generation)message(meta.staleList?'تم عرض الإصدار الأحدث. حدّث القائمة لإظهار حالته الجديدة.':'',false);
   }catch(error){if(ticket===generation&&error.name!=='AbortError'&&error.name!=='RenderingCancelledException'){wrap.hidden=true;controls.hidden=true;retry.hidden=false;message(error.message||'تعذر عرض الملف.',true);}}
   finally{if(ticket===generation){busy=false;controller=null;buttons();}}
  }
  async function open(id){
   id=Number(id);if(!Number.isSafeInteger(id)||id<1)return;
   var ticket=++generation;openingID=id;if(controller)controller.abort();controller=null;current=null;busy=true;resetUi();message('جارٍ تحميل بيانات التعميم…',false);
   if(!window.bootstrap){message('تعذر تحميل نافذة العرض. أعد تحميل الصفحة.',true);return;}
   var shown=dialog(ticket);
   try{
    await release();if(ticket!==generation)return;canvas.width=canvas.height=0;
    var url=new URL(root.dataset.endpoint,location.href);url.searchParams.set('kind',root.dataset.kind);url.searchParams.set('id',id);controller=new AbortController();
    var response=await fetch(url.href,{method:'POST',credentials:'same-origin',cache:'no-store',signal:controller.signal,headers:{'X-Circular-CSRF':root.dataset.csrf}});
    if(!response.ok)throw new Error(await errorText(response));
    if(!(response.headers.get('Content-Type')||'').includes('application/json'))throw new Error('انتهت جلسة الدخول. أعد تسجيل الدخول.');
    var meta=await response.json();if(ticket!==generation)return;
    if(Number(meta.id)!==id||!Number.isSafeInteger(Number(meta.version))||Number(meta.version)<1||typeof meta.fileUrl!=='string')throw new Error('بيانات التعميم غير مكتملة.');
    if(root.dataset.kind==='admin'&&meta.admin!==true)throw new Error('تعذر التحقق من صلاحية المعاينة الإدارية.');
    meta.id=id;meta.version=Number(meta.version);meta.admin=root.dataset.kind==='admin';meta.allowDownload=meta.allowDownload===true;meta.isRead=meta.isRead===true;
    meta.staleList=Array.from(document.querySelectorAll('[data-circular-row][data-circular-id][data-circular-version]')).some(function(row){return Number(row.dataset.circularId)===meta.id&&Number(row.dataset.circularVersion)!==meta.version;});
    current=meta;lang='ar';localizedMetadata();readState(meta);document.getElementById('readerFileName').textContent=meta.fileName||'PDF';metadata.hidden=false;download.hidden=!meta.allowDownload;
    await shown;if(ticket!==generation)return;await view(meta,ticket);
   }catch(error){if(ticket===generation&&error.name!=='AbortError'){message(error.message||'تعذر تحميل التعميم.',true);retry.hidden=false;}}
   finally{if(ticket===generation){busy=false;controller=null;buttons();}}
  }
  root.addEventListener('hide.bs.modal',function(){generation++;if(controller)controller.abort();controller=null;current=null;busy=false;resetUi();release().catch(function(){});});
  language.addEventListener('click',function(){lang=lang==='ar'?'en':'ar';localizedMetadata();});
  retry.addEventListener('click',function(){if(openingID)open(openingID);});
  download.addEventListener('click',async function(){
   if(busy||!current||!current.allowDownload)return;var meta=current,ticket=generation;busy=true;buttons();message('جارٍ تجهيز التحميل…',false);
   try{var data=await bytes(meta,'download');if(ticket!==generation)return;var url=URL.createObjectURL(new Blob([data],{type:'application/pdf'})),link=document.createElement('a');link.href=url;link.download=meta.fileName||'circular-'+meta.id+'.pdf';document.body.appendChild(link);link.click();link.remove();setTimeout(function(){URL.revokeObjectURL(url);},60000);message('تم تجهيز الملف للتحميل.',false);}
   catch(error){if(ticket===generation&&error.name!=='AbortError')message(error.message||'تعذر تحميل الملف.',true);}
   finally{if(ticket===generation){busy=false;controller=null;buttons();}}
  });
  async function changePage(delta,zoomDelta){
   if(busy||!pdf||page+delta<1||page+delta>pdf.numPages)return;var ticket=generation;page+=delta;zoom=Math.max(.5,Math.min(3,zoom+(zoomDelta||0)));busy=true;buttons();
   try{await render(ticket);}catch(error){if(ticket===generation&&error.name!=='RenderingCancelledException')message('تعذر عرض الصفحة.',true);}finally{if(ticket===generation){busy=false;buttons();}}
  }
  previous.addEventListener('click',function(){changePage(-1,0);});next.addEventListener('click',function(){changePage(1,0);});zoomOut.addEventListener('click',function(){changePage(0,-.25);});zoomIn.addEventListener('click',function(){changePage(0,.25);});
  window.addEventListener('resize',function(){clearTimeout(resizeTimer);resizeTimer=setTimeout(function(){if(pdf&&!busy)changePage(0,0);},150);});
  document.addEventListener('click',function(event){var button=event.target.closest('[data-circular-open][data-circular-id]');if(!button)return;event.preventDefault();open(button.dataset.circularId);});
  window.CircularReader={open:open};
  var employeeTable=document.querySelector('[data-circular-employee-table]');
  if(employeeTable&&window.jQuery&&jQuery.fn.DataTable){
   var unread=document.querySelector('[data-circular-unread-filter]');if(unread&&unread.tagName!=='INPUT')unread=unread.querySelector('input[type=checkbox]');
   jQuery.fn.dataTable.ext.search.push(function(settings,data,index){return settings.nTable!==employeeTable||!unread||!unread.checked||settings.aoData[index].nTr.dataset.read!=='1';});
   var employeeApi=jQuery(employeeTable).DataTable({paging:false,info:false,autoWidth:false,order:[],searching:true,dom:'<"type-table-toolbar d-flex justify-content-end px-3 py-3"f>t',language:{search:'',searchPlaceholder:'بحث سريع في الجدول...',emptyTable:'لا توجد تعاميم مطابقة.',zeroRecords:'لا توجد نتائج مطابقة.'},columnDefs:[{targets:-1,orderable:false}]});
   var quick=document.querySelector('#employeeCircularTable_wrapper .dataTables_filter input');if(quick){quick.setAttribute('aria-label','بحث سريع في التعاميم');quick.addEventListener('keydown',function(event){if(event.key==='Enter')event.preventDefault();});}
   document.addEventListener('circular-reader-updated',function(){employeeApi.rows().invalidate('dom').draw();});
  }
  if(window.bootstrap)document.querySelectorAll('[data-circular-open][data-bs-toggle="tooltip"]').forEach(function(button){bootstrap.Tooltip.getOrCreateInstance(button,{trigger:'hover focus',container:'body'});});
  if(Number(root.dataset.initialId)>0)open(root.dataset.initialId);
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',ready);else ready();
}());
