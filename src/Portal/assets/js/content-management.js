(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () { jQuery(function () {
    var root=document.getElementById('contentManager');if(!root)return;
    var pages=root.dataset.kind==='pages',kind=root.dataset.kind,rows=[],customers=[],editing={},pendingDelete=null,opening=0,busy=false,imageUrl=null;
    var q=function(s){return root.querySelector(s);},all=function(s){return Array.from(root.querySelectorAll(s));},field=function(n){return q('[data-field="'+n+'"]');};
    var editor=bootstrap.Offcanvas.getOrCreateInstance(q('#contentEditor')),deleteModal=bootstrap.Modal.getOrCreateInstance(q('#contentDeleteModal')),linksModal=bootstrap.Modal.getOrCreateInstance(q('#contentLinksModal'));
    function message(target,text,error){target.replaceChildren();if(!text)return;var box=document.createElement('div');box.className='alert '+(error?'alert-danger':'alert-success');box.textContent=text;target.appendChild(box);}
    async function api(action,data,file){
      var body=new FormData();body.append('payload',JSON.stringify(data||{}));if(file)body.append('image',file);
      var response=await fetch('/Modules/ContentManagementAjax.aspx?kind='+kind+'&action='+action,{method:'POST',credentials:'same-origin',headers:{'X-Content-CSRF':root.dataset.token},body:body});
      var result;try{result=await response.json();}catch(e){throw new Error('تعذر الاتصال بالخادم؛ تحقق من الدخول وأعد المحاولة.');}
      if(!response.ok)throw new Error(result.message||'تعذر تنفيذ العملية.');return result;
    }
    function table(){return window.jQuery&&jQuery.fn.dataTable&&jQuery.fn.dataTable.isDataTable('#ERPTable')?jQuery('#ERPTable').DataTable():null;}
    function textCell(row,label,value){var td=document.createElement('td');td.dataset.title=label;td.textContent=value==null?'':value;row.appendChild(td);return td;}
    function action(container,name,icon,callback,url){var button=document.createElement(url?'a':'button');if(url)button.href=url;else button.type='button';button.className='btn btn-sm btn-icon type-row-action text-secondary';button.title=name;button.setAttribute('aria-label',name);button.setAttribute('data-bs-toggle','tooltip');var i=document.createElement('i');i.className='fa-solid '+icon;i.setAttribute('aria-hidden','true');button.appendChild(i);if(callback)button.addEventListener('click',callback);container.appendChild(button);}
    function matches(r){var search=q('[data-filter="name"]').value.trim().toLowerCase(),brand=q('[data-filter="brand"]').value,status=q('[data-filter="status"]').value,archive=q('[data-filter="archive"]').value;
      return (!pages||r.deleted===(archive==='1'))&&(!search||(r.nameAr+' '+r.nameEn+' '+r.summary).toLowerCase().includes(search))&&(!brand||r.brands.includes(Number(brand)))&&(!status||r.active===(status==='1'));
    }
    function render(focus){
      var dt=table(),visible=rows.filter(matches),nodes=visible.map(function(r){
        var tr=document.createElement('tr');tr.dataset.recordId=r.id;
        var title=textCell(tr,'العنوان',''),ar=document.createElement('div'),en=document.createElement('small');ar.className='fw-semibold type-record-name';ar.textContent=r.nameAr;en.className='text-muted d-block';en.dir='ltr';en.textContent=r.nameEn;title.append(ar,en);
        if(pages){var audience=document.createElement('small');audience.className='text-muted d-block';audience.textContent=r.audience;title.appendChild(audience);}
        textCell(tr,'العلامة التجارية',r.brandNames||'غير محددة');var state=textCell(tr,'الحالة',''),badge=document.createElement('span');badge.className='badge '+(r.active&&!r.deleted?'bg-label-success':'bg-label-secondary');badge.textContent=r.status;state.appendChild(badge);
        textCell(tr,pages?'فترة العرض':'التاريخ',r.dateText);textCell(tr,'الترتيب',r.order);
        var version=textCell(tr,pages?'الإصدار':'الصورة','');if(pages){var a=document.createElement('a');a.href='History.aspx?ID='+r.id;a.textContent=r.version;a.className='badge bg-label-primary';a.title='إصدارات الصفحة';version.appendChild(a);}else{var image=document.createElement('img');image.src=r.image;image.alt='صورة الخبر';image.width=40;image.height=32;image.className='rounded';image.style.objectFit='cover';version.appendChild(image);}
        var actions=textCell(tr,'الإجراءات',''),group=document.createElement('div');group.className='type-flex type-row-actions';actions.appendChild(group);
        if(pages){action(group,'معاينة','fa-eye',null,'View.aspx?preview=1&ID='+r.id);action(group,'رابط الصفحة','fa-link',function(){q('#employeePageUrl').value=new URL('/Modules/Information_Pages/View.aspx?ID='+r.id,location.origin).href;q('#customerPageUrl').value=new URL('/CustomerPortal/InformationPage.aspx?id='+r.id,location.origin).href;q('[data-copy-status]').textContent='';linksModal.show();});}
        if(!r.deleted){action(group,'تعديل','fa-pen-to-square',function(){openEditor(r.id);});action(group,'حذف','fa-trash-can',function(){pendingDelete=r;q('[data-delete-name]').textContent=r.nameAr;message(q('[data-delete-message]'),'');deleteModal.show();});}
        return tr;
      });
      all('#ERPTable [data-bs-toggle="tooltip"]').forEach(function(el){var instance=bootstrap.Tooltip.getInstance(el);if(instance)instance.dispose();});
      if(dt){dt.clear();dt.rows.add(nodes);dt.draw(false);}else{q('#ERPTable tbody').replaceChildren.apply(q('#ERPTable tbody'),nodes);}
      all('[data-bs-toggle="tooltip"]').forEach(function(el){bootstrap.Tooltip.getOrCreateInstance(el,{trigger:'hover focus',container:'body'});});
      if(focus){var index=visible.findIndex(function(r){return r.id===focus;});if(index>=0){if(dt){dt.search('');var indexes=dt.rows({order:'applied',search:'applied'}).indexes().toArray(),position=indexes.indexOf(index);if(dt.page.len()>0)dt.page(Math.floor(position/dt.page.len())).draw(false);}var node=q('tr[data-record-id="'+focus+'"]');if(node){node.classList.add('table-primary');node.scrollIntoView({block:'nearest',behavior:'smooth'});}}}
    }
    async function refresh(focus){
      var data=await api('list');rows=data.rows;var filter=q('[data-filter="brand"]'),previous=filter.value;filter.replaceChildren(new Option('جميع العلامات التجارية',''));
      data.brands.forEach(function(b){filter.add(new Option(b.Title_Ar,b.ID));});rows.forEach(function(r){r.brands.forEach(function(id){if(!Array.from(filter.options).some(function(o){return o.value===String(id);}))filter.add(new Option(r.brandNames+' (غير فعالة)',id));});});filter.value=previous;
      var current=rows.filter(function(r){return !r.deleted;});q('[data-stat="total"]').textContent=current.length;q('[data-stat="active"]').textContent=current.filter(function(r){return r.active;}).length;q('[data-stat="inactive"]').textContent=current.filter(function(r){return !r.active;}).length;
      var revealed=false,record=rows.find(function(r){return r.id===focus;});if(record&&!matches(record)){resetFilters(false);revealed=true;}var dt=table();if(focus&&dt)dt.search('');render(focus);return revealed;
    }
    function resetFilters(draw){all('[data-filter]').forEach(function(el){el.value=el.dataset.filter==='archive'?'0':'';});var dt=table();if(dt)dt.search('');if(draw!==false)render();}
    function access(){
      var audience=field('audience').value;q('[data-employee-scope]').hidden=audience!=='employees';q('[data-customer-scope]').hidden=audience!=='customers';q('[data-everyone]').hidden=audience!=='all';q('[data-role-options]').hidden=field('employeeScope').value!=='selected';q('[data-customer-selection]').hidden=field('customerScope').value!=='selected';q('[data-schedule]').hidden=!pages||field('mode').value!=='scheduled';if(pages&&!q('[data-customer-scope]').hidden&&!q('[data-customer-selection]').hidden&&jQuery(q('#contentCustomers')).data('select2'))jQuery(q('#contentCustomers')).trigger('change.select2');
    }
    function scopedCustomers(selected){
      var select=q('#contentCustomers'),brands=new Set(Array.from(field('brands').selectedOptions).map(function(o){return Number(o.value);})),chosen=selected||Array.from(select.selectedOptions).map(function(o){return Number(o.value);});
      if(jQuery(select).data('select2'))jQuery(select).select2('close');select.replaceChildren();customers.filter(function(c){return String(c.Brand_IDs||'').split(',').some(function(id){return brands.has(Number(id));});}).forEach(function(c){var option=new Option(c.Name_AR+' — '+(c.BrandName||'')+(c.IsAvailable?'':' (غير متاح)'),c.ID,false,chosen.includes(c.ID));option.dataset.customerName=c.Name_AR;select.add(option);});
      select.disabled=!select.options.length;var retained=Array.from(select.selectedOptions).length;q('[data-customer-status]').textContent=(!brands.size?'اختر علامة تجارية أولًا.':!select.options.length?'لا يوجد عملاء للعلامات المختارة.':'ابحث باسم العميل ضمن العلامات المختارة.')+(retained<chosen.length?' أُزيلت اختيارات العملاء الخارجين عن العلامات المحددة.':'');jQuery(select).trigger('change.select2');
    }
    function setValue(name,value){field(name).value=value==null?'':value;}
    function initRichEditors(){
      if(!window.CKEDITOR)return;
      [['contentDetailsAr','ar','rtl'],['contentDetailsEn','en','ltr']].forEach(function(item){if(!CKEDITOR.instances[item[0]])CKEDITOR.replace(item[0],{language:item[1],contentsLangDirection:item[2],height:220,toolbar:[['Format','Bold','Italic','Underline','Strike','RemoveFormat'],['NumberedList','BulletedList','Blockquote'],['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],['Link','Unlink','Table','HorizontalRule'],['Undo','Redo','Maximize']],removePlugins:'elementspath',resize_enabled:false,allowedContent:'p div span{text-align,direction}[dir]; h1 h2 h3 h4 h5 h6; br hr strong b em i u s sub sup; ul ol li blockquote pre code; a[href,title]; table thead tbody tfoot tr caption; td th[colspan,rowspan]'});});
    }
    function rich(name,value){var id=field(name).id,instance=window.CKEDITOR&&CKEDITOR.instances[id];if(arguments.length>1){field(name).value=value||'';if(instance)instance.setData(value||'');return;}return instance&&instance.status==='ready'?instance.getData():field(name).value;}
    async function openEditor(id){
      if(busy)return;var sequence=++opening;message(q('[data-manager-message]'),'');q('[data-manager-add]').disabled=true;
      try{var data=await api('editor',{id:id});if(sequence!==opening)return;var item=data.item||{};editing={id:id,version:item.VersionNumber||0,accessRevision:item.AccessRevision||0,revision:data.revision||''};customers=data.customers||[];message(q('[data-editor-message]'),'');
        all('[data-field]').forEach(function(el){if(!['brands'].includes(el.dataset.field))el.value='';});
        var brands=field('brands');if(jQuery(brands).data('select2'))jQuery(brands).select2('destroy');brands.multiple=pages;brands.replaceChildren();if(!pages)brands.add(new Option('اختر العلامة التجارية',''));
        data.brands.forEach(function(b){brands.add(new Option(b.Title_Ar+(b.IsAvailable?'':' (غير متاحة)'),b.ID,false,pages?b.IsSelected:b.ID===item.Brand_ID));});
        if(!pages&&item.Brand_ID&&!Array.from(brands.options).some(function(o){return o.value===String(item.Brand_ID);}))brands.add(new Option((item.BrandName||'علامة غير متاحة')+' (غير فعالة)',item.Brand_ID,false,true));
        if(pages){jQuery(brands).select2({dir:'rtl',width:'100%',dropdownParent:jQuery(q('#contentEditor'))});var roleContainer=q('[data-role-options]');roleContainer.replaceChildren();data.roles.forEach(function(role){var div=document.createElement('div'),label=document.createElement('label'),input=document.createElement('input');div.className='col-12 col-md-6';label.className='form-check-label';input.type='checkbox';input.value=role.ID;input.checked=role.IsSelected;input.className='form-check-input me-2';label.append(input,document.createTextNode(role.Title_Ar+(role.IsActive?'':' (غير فعال)')));div.appendChild(label);roleContainer.appendChild(div);});}
        setValue('titleAr',pages?item.Title_Ar:item.Title_AR);setValue('titleEn',item.Title_En);setValue('summaryAr',pages?item.Summary_Ar:item.Brief_Ar);setValue('summaryEn',pages?item.Summary_En:item.Brief_En);setValue('order',item.Item_Order||0);setValue('active',id?(pages?item.IsPublished:item.IsActive)?'1':'0':pages?'0':'1');
        setValue('audience',item.Audience||'employees');setValue('employeeScope',item.AllUserTypes===false?'selected':'all');setValue('customerScope',item.AllCustomers===false?'selected':'all');setValue('mode',item.PublishMode||'immediate');setValue('start',data.start||'');setValue('end',data.end||'');
        var local=new Date();local=new Date(local.getTime()-local.getTimezoneOffset()*60000);setValue('date',item.Date?item.Date.slice(0,16):local.toISOString().slice(0,16));
        if(pages)scopedCustomers(customers.filter(function(c){return c.IsSelected;}).map(function(c){return c.ID;}));
        q('#contentImage').value='';if(imageUrl){URL.revokeObjectURL(imageUrl);imageUrl=null;}var preview=q('#contentImagePreview');preview.hidden=!item.Image;preview.src=item.Image&&/^\/FileManager\/[a-zA-Z0-9_./-]+\.(png|jpe?g|gif|webp)$/i.test(item.Image)&&!item.Image.includes('..')?item.Image:'/assets/img/illustrations/customer-default.svg';
        q('#contentEditorTitle').textContent=(id?'تعديل ':'إضافة ')+(pages?'صفحة معلوماتية':'خبر');access();editor.show();initRichEditors();rich('detailsAr',pages?item.Details_Ar:item.Details);rich('detailsEn',item.Details_En||item.Details_EN);
      }catch(error){message(q('[data-manager-message]'),error.message,true);}finally{q('[data-manager-add]').disabled=false;}
    }
    var disabledBeforeSave=[];
    function lockEditor(locked){
      if(locked){disabledBeforeSave=Array.from(q('#contentEditor').querySelectorAll('input,select,textarea,button')).map(function(el){var previous=el.disabled;el.disabled=true;return [el,previous];});}
      else{disabledBeforeSave.forEach(function(pair){pair[0].disabled=pair[1];});disabledBeforeSave=[];}
      if(window.CKEDITOR)['contentDetailsAr','contentDetailsEn'].forEach(function(id){var instance=CKEDITOR.instances[id];if(instance&&instance.status==='ready')instance.setReadOnly(locked);});
    }
    async function save(){
      if(busy)return;var data=Object.assign({},editing);all('[data-field]').forEach(function(el){data[el.dataset.field]=el.value;});data.brands=Array.from(field('brands').selectedOptions).map(function(o){return o.value;}).join(',');data.brand=field('brands').value;data.roles=all('[data-role-options] input:checked').map(function(i){return i.value;}).join(',');data.customers=Array.from(q('#contentCustomers').selectedOptions).map(function(o){return o.value;}).join(',');data.detailsAr=rich('detailsAr');data.detailsEn=rich('detailsEn');
      var required=['titleAr','order'].concat(pages?['titleEn','summaryAr','summaryEn']:['date']);var invalid=required.map(field).find(function(el){return !el.value.trim()||!el.checkValidity();});
      if(invalid){message(q('[data-editor-message]'),'يرجى استكمال الحقول المطلوبة بقيم صحيحة.',true);invalid.focus();return;}if(!data.brands||(pages&&data.audience==='customers'&&data.customerScope==='selected'&&!data.customers)||(pages&&data.audience==='employees'&&data.employeeScope==='selected'&&!data.roles)){message(q('[data-editor-message]'),'راجع العلامات التجارية واختيار العملاء أو أنواع الموظفين.',true);return;}
      busy=true;lockEditor(true);q('[data-editor-save]').disabled=true;message(q('[data-editor-message]'),'');
      var written=false;
      try{var result=await api('save',data,pages?null:q('#contentImage').files[0]);written=true;editing.id=result.id;editor.hide();var revealed=await refresh(result.id);message(q('[data-manager-message]'),'تم حفظ التغييرات وتحديث الجدول والإحصائيات.'+(revealed?' أُعيد ضبط الفلاتر لإظهار السجل المحفوظ.':''));}
      catch(error){if(!written)message(q('[data-editor-message]'),error.message,true);if(written){message(q('[data-manager-message]'),'تم الحفظ، لكن تعذر عرض القائمة الجديدة. أعد فتح صفحة الإدارة قبل تكرار الحفظ.',true);q('[data-manager-add]').disabled=true;}}
      finally{busy=false;lockEditor(false);q('[data-editor-save]').disabled=false;}
    }
    q('[data-manager-add]').addEventListener('click',function(){openEditor(0);});q('[data-editor-save]').addEventListener('click',save);q('[data-filter-apply]').addEventListener('click',function(){render();});q('[data-filter-reset]').addEventListener('click',function(){resetFilters();});all('[data-filter]').forEach(function(el){el.addEventListener(el.tagName==='SELECT'?'change':'input',function(){render();});});
    ['audience','employeeScope','customerScope','mode'].forEach(function(name){field(name).addEventListener('change',access);});jQuery(field('brands')).on('change.contentCustomers',function(){if(pages)scopedCustomers();});
    jQuery(q('#contentCustomers')).select2({dir:'rtl',width:'100%',dropdownParent:jQuery(q('#contentEditor')),matcher:function(params,data){if(!params.term)return data;return jQuery.fn.select2.defaults.defaults.matcher(params,{text:data.element?data.element.dataset.customerName:data.text,id:data.id})?data:null;},language:{noResults:function(){return 'لا توجد أسماء عملاء مطابقة';}}});jQuery(q('#contentCustomers')).next('.select2').find('.select2-search__field').attr('aria-label','البحث باسم العميل');
    q('#contentEditor').addEventListener('shown.bs.offcanvas',function(){[field('brands'),q('#contentCustomers')].forEach(function(el){if(jQuery(el).data('select2'))jQuery(el).trigger('change.select2');});});
    q('#contentImage').addEventListener('change',function(){if(imageUrl)URL.revokeObjectURL(imageUrl);var file=this.files[0],preview=q('#contentImagePreview');preview.hidden=!file;if(file){if(!/^image\/(png|jpeg|gif|webp)$/.test(file.type)||file.size>10485760){this.value='';preview.hidden=true;message(q('[data-editor-message]'),'اختر صورة صحيحة حتى 10 ميجابايت.',true);return;}imageUrl=URL.createObjectURL(file);preview.src=imageUrl;}});
    q('[data-delete-confirm]').addEventListener('click',async function(){if(!pendingDelete||busy)return;busy=true;this.disabled=true;try{await api('delete',{id:pendingDelete.id,version:pendingDelete.version,revision:pendingDelete.revision});deleteModal.hide();pendingDelete=null;await refresh();message(q('[data-manager-message]'),'تم الحذف وتحديث البيانات.');}catch(error){message(q('[data-delete-message]'),error.message,true);}finally{busy=false;this.disabled=false;}});
    all('[data-copy-url]').forEach(function(button){button.addEventListener('click',async function(){var input=q('#'+button.dataset.copyUrl);try{if(navigator.clipboard&&window.isSecureContext)await navigator.clipboard.writeText(input.value);else{input.select();if(!document.execCommand('copy'))throw new Error();}q('[data-copy-status]').textContent='تم نسخ الرابط.';}catch(error){input.focus();input.select();q('[data-copy-status]').textContent='تعذر النسخ التلقائي؛ يمكنك نسخ الرابط المحدد يدويًا.';}});});
    root.addEventListener('keydown',function(event){if(event.key==='Enter'&&event.target.matches('input,select'))event.preventDefault();});
    all('[data-pages-only]').forEach(function(el){el.hidden=!pages;});all('[data-news-only]').forEach(function(el){el.hidden=pages;});all('[data-manager-title]').forEach(function(el){el.textContent=pages?'إدارة الصفحات المعلوماتية':'إدارة الأخبار';});q('[data-manager-add] span').textContent=pages?'إضافة صفحة':'إضافة خبر';q('[data-version-heading]').textContent=pages?'الإصدار':'الصورة';q('[data-date-heading]').textContent=pages?'فترة العرض':'التاريخ';if(pages){q('[data-active-label]').textContent='الصفحات المنشورة';q('[data-inactive-label]').textContent='المسودات';field('active').options[0].text='منشورة';field('active').options[1].text='مسودة';q('[data-filter="status"]').options[1].text='منشورة';q('[data-filter="status"]').options[2].text='مسودة';}
    access();refresh().catch(function(error){message(q('[data-manager-message]'),error.message,true);});
  }); });
}());
