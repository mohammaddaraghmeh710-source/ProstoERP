(function () {
 'use strict';
 window.addEventListener('load', function () {
  var config=document.getElementById('customerGuideConfig'),modal=document.getElementById('customerGuideViewer');
  if(!config||!modal)return;
  var status=document.getElementById('guidePdfStatus'),operation=document.getElementById('guideOperationStatus'),canvas=document.getElementById('guidePdfCanvas'),prev=document.getElementById('guidePrevious'),next=document.getElementById('guideNext'),label=document.getElementById('guidePageLabel');
  var zoomIn=document.getElementById('guideZoomIn'),zoomOut=document.getElementById('guideZoomOut'),zoomLabel=document.getElementById('guideZoomLabel');
  var pdf=null,page=1,zoom=1,busy=false,generation=0,controller=null;
  function message(target,text,failed){target.textContent=text;target.className=failed?'alert alert-danger mt-3':'text-muted small my-3';}
  function destroy(){generation++;if(controller)controller.abort();controller=null;if(pdf){pdf.destroy();pdf=null;}canvas.classList.add('d-none');canvas.width=canvas.height=0;label.textContent='—';zoom=1;zoomLabel.textContent='100%';prev.disabled=next.disabled=zoomIn.disabled=zoomOut.disabled=true;busy=false;}
  async function bytes(button,action){
   var response=await fetch('WorkGuideFile.aspx?id='+encodeURIComponent(button.dataset.id)+'&category='+encodeURIComponent(button.dataset.category)+'&action='+action,{method:'POST',credentials:'same-origin',cache:'no-store',signal:controller?controller.signal:undefined,headers:{'X-CRMGuide-CSRF':config.dataset.csrf}});
   if(!response.ok)throw new Error(await response.text());
   var type=response.headers.get('Content-Type')||'';
   var allowed=action==='view'?type.includes('application/pdf'):['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'].some(function(mime){return type.includes(mime);});
   if(!allowed)throw new Error('انتهت جلسة الدخول. أعد تسجيل الدخول.');
   var name='',match=(response.headers.get('Content-Disposition')||'').match(/filename\*=UTF-8''([^;]+)/i);
   if(match){try{name=decodeURIComponent(match[1]);}catch(error){}}
   return {data:await response.arrayBuffer(),name:name};
  }
  async function render(ticket){
   var pdfPage=await pdf.getPage(page);if(ticket!==generation)return;
   var body=modal.querySelector('.modal-body'),style=getComputedStyle(body);
   var base=pdfPage.getViewport({scale:1}),width=body.clientWidth-parseFloat(style.paddingLeft)-parseFloat(style.paddingRight)-2;
   var viewport=pdfPage.getViewport({scale:Math.max(.05,Math.min(width/base.width*zoom,4,Math.sqrt(5000000/(base.width*base.height))))});
   canvas.width=viewport.width;canvas.height=viewport.height;canvas.classList.remove('d-none');
   await pdfPage.render({canvasContext:canvas.getContext('2d'),viewport:viewport}).promise;
   if(ticket!==generation)return;label.textContent=page+' / '+pdf.numPages;prev.disabled=page<=1;next.disabled=page>=pdf.numPages;zoomLabel.textContent=Math.round(zoom*100)+'%';zoomIn.disabled=zoom>=3;zoomOut.disabled=zoom<=.5;
  }
  document.addEventListener('click',async function(event){
   var button=event.target.closest('[data-guide-action]');if(!button||busy)return;
   var action=button.dataset.guideAction;if(action!=='view'&&action!=='download')return;
   if(action==='view')destroy();busy=true;button.disabled=true;controller=new AbortController();var ticket=generation;
   var target=action==='view'?status:operation;
   if(action==='view'){
    document.getElementById('guideViewerTitle').textContent=button.dataset.title||'عارض دليل العمل';
    bootstrap.Modal.getOrCreateInstance(modal).show();
   }
   message(target,action==='view'?'جارٍ تجهيز الملف للعرض…':'جارٍ تجهيز التحميل…',false);
   try{
    var result=await bytes(button,action),data=result.data;if(ticket!==generation)return;
    if(action==='download'){
     var url=URL.createObjectURL(new Blob([data])),link=document.createElement('a');link.href=url;link.download=result.name||'work-guide-'+button.dataset.id+button.dataset.extension;document.body.appendChild(link);link.click();link.remove();setTimeout(function(){URL.revokeObjectURL(url);},60000);message(target,'تم تجهيز الملف للتحميل.',false);
    }else{
     pdfjsLib.GlobalWorkerOptions.workerSrc='/assets/js/pdf.worker.min.js';
     var loaded=await pdfjsLib.getDocument({data:new Uint8Array(data),isEvalSupported:false,enableScripting:false,disableFontFace:true}).promise;
     if(ticket!==generation){loaded.destroy();return;}pdf=loaded;page=1;await render(ticket);if(ticket===generation)message(target,'',false);
    }
   }catch(error){if(error.name!=='AbortError'&&ticket===generation)message(target,error.message||'تعذر تنفيذ العملية.',true);}
   finally{button.disabled=false;if(ticket===generation){busy=false;controller=null;}}
  });
  async function move(delta){if(busy||!pdf||page+delta<1||page+delta>pdf.numPages)return;busy=true;page+=delta;try{await render(generation);}catch(error){message(status,'تعذر عرض الصفحة.',true);}finally{busy=false;}}
  prev.addEventListener('click',function(){move(-1);});next.addEventListener('click',function(){move(1);});
  async function resize(delta){if(busy||!pdf)return;busy=true;zoom=Math.min(3,Math.max(.5,zoom+delta));try{await render(generation);}catch(error){message(status,'تعذر تغيير حجم الصفحة.',true);}finally{busy=false;}}
  zoomIn.addEventListener('click',function(){resize(.25);});zoomOut.addEventListener('click',function(){resize(-.25);});
  modal.addEventListener('hidden.bs.modal',destroy);
  window.addEventListener('resize',function(){if(pdf)resize(0);});
 });
}());
