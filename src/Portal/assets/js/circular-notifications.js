(function(){
 'use strict';
 document.addEventListener('DOMContentLoaded',function(){
  var button=document.querySelector('[data-circular-notifications]');if(!button)return;
  var list=document.querySelector('[data-notice-items]'),badge=document.querySelector('[data-notice-count]'),busy=false;
  var feedbackLabels={1:'تم تقديم الطلب',2:'تم تحويل الطلب',3:'تم إغلاق الطلب'};
  async function refresh(){
   if(busy)return;busy=true;
   try{
    var response=await fetch('/CircularNotifications.aspx',{credentials:'same-origin',cache:'no-store'});if(!response.ok)throw new Error();
    var data=await response.json(),entries=(data.rows||[]).map(function(row){return {row:row,kind:'circular',time:row.ModifiedUtc};}).concat((data.feedback||[]).map(function(row){return {row:row,kind:'feedback',time:row.SendDate};}));
    entries.sort(function(a,b){return String(b.time||'').localeCompare(String(a.time||''));});
    list.replaceChildren();badge.hidden=!entries.length;badge.textContent=entries.length;button.setAttribute('aria-label','الإشعارات'+(entries.length?'، '+entries.length+' إشعار غير مقروء':''));
    list.className=entries.length?'list-group list-group-flush':'p-4 text-center text-muted';if(!entries.length)list.textContent='لا توجد إشعارات حاليًا.';
    entries.forEach(function(entry){
     var row=entry.row,feedback=entry.kind==='feedback',link=document.createElement('a');link.className='list-group-item list-group-item-action py-3';link.dataset.noticeKind=entry.kind;
     link.href=(feedback?(data.customer?'/CustomerPortal/FeedbackDetail.aspx?id=':'/Modules/Employee_Feedback/ViewEmployeeFeedback.aspx?ID='):(data.customer?'/CustomerPortal/Circulars.aspx?ID=':'/Modules/Circulars/Index.aspx?ID='))+encodeURIComponent(row.ID);
     var title=document.createElement('strong');title.className='d-block';title.textContent=row.Title;
     var info=document.createElement('small');info.className='text-muted';info.textContent=feedback?(String(row.TypeName||'').trim()||'طلب')+' · '+(feedbackLabels[row.NotificationType]||'تحديث على الطلب'):'تعميم جديد · الإصدار '+row.Version;
     link.append(title,info);list.appendChild(link);
    });
   }catch(error){badge.hidden=true;list.className='p-4 text-center text-muted';list.textContent='تعذر تحميل الإشعارات حاليًا.';}finally{busy=false;}
  }
  button.addEventListener('click',refresh);document.addEventListener('circular-read',refresh);document.addEventListener('feedback-read',refresh);document.addEventListener('feedback-updated',refresh);document.addEventListener('visibilitychange',function(){if(!document.hidden)refresh();});setInterval(function(){if(!document.hidden)refresh();},30000);refresh();
 });
}());
