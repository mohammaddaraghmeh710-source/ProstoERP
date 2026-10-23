(function () {
 'use strict';
 function normalize(value){return String(value||'').normalize('NFKD').replace(/[\u0300-\u036f\u064b-\u065f\u0670\u0640]/g,'').replace(/[أإآٱ]/g,'ا').replace(/ى/g,'ي').toLocaleLowerCase().trim();}
 function goTo(root,index){
  var steps=Array.from(root.querySelectorAll('[data-feedback-step]'));index=Math.max(0,Math.min(steps.length-1,Number(index)||0));root.dataset.feedbackCurrent=String(index);
  steps.forEach(function(step,i){step.hidden=i!==index;step.classList.toggle('active',i===index);});
  root.querySelectorAll('[data-feedback-indicator]').forEach(function(item){var step=Number(item.dataset.feedbackIndicator);item.classList.toggle('active',step===index);item.classList.toggle('done',step<index);if(step===index)item.setAttribute('aria-current','step');else item.removeAttribute('aria-current');});
  root.querySelectorAll('[data-feedback-prev]').forEach(function(button){button.hidden=index===0;});root.querySelectorAll('[data-feedback-next]').forEach(function(button){button.hidden=index===steps.length-1;});root.querySelectorAll('[data-feedback-submit]').forEach(function(button){button.hidden=index!==steps.length-1;});
  var progress=root.querySelector('[data-feedback-progress]');if(progress)progress.textContent='الخطوة '+(index+1)+' من '+steps.length;
  root.dispatchEvent(new CustomEvent('feedback-step-changed',{bubbles:true,detail:{step:index}}));
 }
 function invalidControl(step){
  return Array.from(step.querySelectorAll('[data-feedback-required],input[required],textarea[required],select[required]')).find(function(control){
   if(control.disabled)return false;var option=control.selectedOptions&&control.selectedOptions[0],validZero=option&&option.dataset.feedbackValidZero==='1';
   var unavailable=option&&(option.disabled||option.hidden||option.dataset.feedbackUnavailable==='1');
   var missing=control.dataset.feedbackRequired!==undefined&&(!String(control.value||'').trim()||(control.tagName==='SELECT'&&control.value==='0'&&!validZero));
   control.setCustomValidity(unavailable?'الاختيار المحدد غير متاح. اختر قيمة أخرى.':missing?'أكمل هذا الحقل قبل المتابعة.':'');return !control.checkValidity();
  });
 }
 function validate(root,from,to){
  var steps=Array.from(root.querySelectorAll('[data-feedback-step]'));
  for(var index=from;index<=to;index++){var control=invalidControl(steps[index]);if(control){goTo(root,index);control.focus();control.reportValidity();return false;}}return true;
 }
 function uploadsPending(root){return root.dataset.uploadBusy==='1'||Array.from(root.querySelectorAll('.ajax__fileupload')).some(function(upload){return /\((pending|uploading|error)\)/i.test(upload.textContent);});}
 function uploadState(root){var pending=uploadsPending(root),status=root.querySelector('[data-feedback-upload-status]'),text=pending?'انتظر اكتمال رفع الملفات أو أزل الملف الذي تعذر رفعه.':'';if(status&&status.textContent!==text)status.textContent=text;root.querySelectorAll('[data-feedback-submit]').forEach(function(button){button.disabled=pending||button.dataset.feedbackDisabled==='1';});return pending;}
 function topics(select){
  var target=document.getElementById(select.dataset.feedbackTopicTarget);if(!target)return;
  function filter(){var chosen=target.selectedOptions[0];if(chosen&&chosen.value!=='0'&&chosen.dataset.feedbackType!==select.value)target.value='0';Array.from(target.options).forEach(function(option){var visible=option.value==='0'||(option.dataset.feedbackType===select.value&&option.dataset.feedbackUnavailable!=='1');option.hidden=!visible;option.disabled=!visible;});}
  select.addEventListener('change',filter);filter();
 }
 function routing(select){Array.from(select.options).forEach(function(option){if(option.dataset.feedbackUnavailable==='1')option.disabled=true;});var target=document.getElementById(select.dataset.feedbackRoutingTarget);if(!target)return;function show(){var option=select.selectedOptions[0];target.textContent=option&&option.dataset.feedbackRouting||'';}select.addEventListener('change',show);show();}
 function initialize(scope){
  scope=scope||document;scope.querySelectorAll('.feedback-workspace .ajax__fileupload_selectFileButton').forEach(function(button){button.textContent='اختيار الملفات';});scope.querySelectorAll('.feedback-workspace .ajax__fileupload_dropzone').forEach(function(zone){zone.textContent='اسحب الملفات هنا أو اخترها من الجهاز';});scope.querySelectorAll('[data-feedback-type-select]').forEach(function(select){if(!select.dataset.feedbackTypeBound){select.dataset.feedbackTypeBound='1';topics(select);}});
  scope.querySelectorAll('[data-feedback-routing-select]').forEach(function(select){if(!select.dataset.feedbackRoutingBound){select.dataset.feedbackRoutingBound='1';routing(select);}});
  scope.querySelectorAll('[data-feedback-action-submit]').forEach(function(button){
   var root=button.closest('.feedback-workspace');if(!root||root.dataset.feedbackActionUploadBound)return;root.dataset.feedbackActionUploadBound='1';var upload=root.querySelector('.ajax__fileupload');
   function update(){var pending=uploadsPending(root),status=root.querySelector('[data-feedback-upload-status]'),text=pending?'انتظر اكتمال رفع الملفات أو أزل الملف الذي تعذر رفعه.':'';button.disabled=pending||button.dataset.feedbackDisabled==='1';if(status&&status.textContent!==text)status.textContent=text;}
   if(upload)new MutationObserver(update).observe(upload,{childList:true,subtree:true,characterData:true});update();
  });
  var roots=Array.from(scope.querySelectorAll('[data-feedback-wizard]'));if(scope.matches&&scope.matches('[data-feedback-wizard]'))roots.unshift(scope);
  roots.forEach(function(root){
   if(root.dataset.feedbackWizardBound)return;root.dataset.feedbackWizardBound='1';goTo(root,root.dataset.feedbackCurrent||0);
   root.addEventListener('click',function(event){var button=event.target.closest('[data-feedback-next],[data-feedback-prev],[data-feedback-jump],[data-feedback-submit]');if(!button)return;var steps=Array.from(root.querySelectorAll('[data-feedback-step]')),current=Number(root.dataset.feedbackCurrent)||0;
    if(button.matches('[data-feedback-submit]')){if(!validate(root,0,steps.length-1)||uploadState(root)){event.preventDefault();event.stopImmediatePropagation();if(uploadsPending(root))goTo(root,Math.min(2,steps.length-1));}return;}
    event.preventDefault();var next=button.matches('[data-feedback-next]')?current+1:button.matches('[data-feedback-prev]')?current-1:Number(button.dataset.feedbackJump);
    if(next>current&&(!validate(root,current,next-1)||(current===2&&uploadState(root))))return;goTo(root,next);
   },true);
   root.addEventListener('keydown',function(event){if(event.key==='Enter'&&event.target.matches('input:not([type=submit]):not([type=button]):not([type=file])')){event.preventDefault();var button=root.querySelector('[data-feedback-next]:not([hidden])');if(button)button.click();}});
   root.addEventListener('input',function(event){if(event.target.setCustomValidity)event.target.setCustomValidity('');});root.addEventListener('change',function(event){if(event.target.setCustomValidity)event.target.setCustomValidity('');});
   var uploader=root.querySelector('.ajax__fileupload');if(uploader)new MutationObserver(function(){uploadState(root);}).observe(uploader,{childList:true,subtree:true,characterData:true});uploadState(root);
  });
 }
 function table(){
  var element=document.querySelector('[data-feedback-table]'),filters=document.querySelector('[data-feedback-filters]');if(!element||!filters||element.dataset.feedbackFilterBound)return;element.dataset.feedbackFilterBound='1';
  var name=filters.querySelector('[data-feedback-filter-name]'),type=filters.querySelector('[data-feedback-filter-type]'),status=filters.querySelector('[data-feedback-filter-status]');
  function matches(row){if(!row.dataset.feedbackId)return true;var query=normalize(name&&name.value),state=status&&status.value||'0',kind=type&&type.value||'0';return(!query||row.dataset.feedbackId===query||normalize(row.dataset.feedbackTitle).includes(query))&&(kind==='0'||row.dataset.feedbackType===kind)&&(state==='0'||(state==='4'?row.dataset.feedbackStatus!=='3':row.dataset.feedbackStatus===state));}
  if(window.jQuery&&jQuery.fn.dataTable){jQuery.fn.dataTable.ext.search.push(function(settings,data,index){return settings.nTable!==element||matches(settings.aoData[index].nTr);});if(window.CRMList)CRMList.initializeTable();}
  function apply(){if(window.jQuery&&jQuery.fn.dataTable&&jQuery.fn.dataTable.isDataTable(element))jQuery(element).DataTable().draw();else element.querySelectorAll('[data-feedback-row]').forEach(function(row){row.hidden=!matches(row);});}
  if(name){name.addEventListener('input',apply);name.addEventListener('keydown',function(event){if(event.key==='Enter'){event.preventDefault();apply();}});}if(type)type.addEventListener('change',apply);if(status)status.addEventListener('change',apply);
  var reset=filters.querySelector('[data-feedback-reset-filters]');if(reset)reset.addEventListener('click',function(){if(name)name.value='';if(type)type.value='0';if(status)status.value='0';apply();});apply();
 }
 function ready(){initialize(document);table();if(window.Sys&&Sys.Application&&!window.feedbackWizardAjaxBound){window.feedbackWizardAjaxBound=true;Sys.Application.add_load(function(){initialize(document);});}}
 document.addEventListener('click',function(event){var button=event.target.closest('[data-feedback-action-submit]');if(button){var root=button.closest('.feedback-workspace');if(root&&uploadsPending(root)){event.preventDefault();event.stopImmediatePropagation();var status=root.querySelector('[data-feedback-upload-status]');if(!status){status=document.createElement('p');status.className='small text-danger mt-2';status.setAttribute('role','alert');var modal=button.closest('[role=dialog]');(modal?modal.querySelector('.modal-body'):root).appendChild(status);}status.textContent='انتظر اكتمال رفع الملفات أو أزل الملف الذي تعذر رفعه قبل تأكيد الإجراء.';}}},true);
 window.FeedbackWizard={initialize:initialize,goTo:goTo};if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',ready);else ready();
}());
