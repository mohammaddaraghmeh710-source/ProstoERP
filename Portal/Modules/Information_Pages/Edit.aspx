<%@ Page Title="إدارة صفحة معلوماتية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Edit.aspx.vb" Inherits="CRM.EditInformationPage" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <script src="/ckeditor/ckeditor.js"></script>
    <style>.information-roles input{margin-inline-end:.4rem}.information-roles label{margin-inline-end:1.5rem;margin-bottom:.7rem}</style>
</asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
<div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
    <asp:Literal ID="litMessage" runat="server" />
    <section class="card"><div class="card-header"><h4 class="mb-0">إدارة صفحة معلوماتية</h4></div><div class="card-body">
    <asp:Label ID="lblVersion" runat="server" CssClass="badge bg-label-primary mb-3" />
    <fieldset class="border rounded p-3 mb-4">
        <legend class="float-none w-auto px-2 fs-6">صلاحيات الاطلاع</legend>
        <div class="mb-3">
            <asp:Label runat="server" AssociatedControlID="lstBrands" CssClass="form-label" Text="العلامات التجارية" />
            <asp:ListBox ID="lstBrands" runat="server" SelectionMode="Multiple" CssClass="form-select information-audience-select" data-placeholder="اختر علامة تجارية واحدة أو أكثر" />
            <small class="text-muted d-block mt-2">تظهر الصفحة لمستخدمي العلامات المحددة فقط، بشرط سماح الجمهور المحدد والنشر. يجب اختيار علامة فعالة واحدة على الأقل.</small>
        </div>
        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="ddlAudience" CssClass="form-label" Text="جمهور الصفحة"/><asp:DropDownList ID="ddlAudience" runat="server" CssClass="form-select" onchange="informationAccess()"><asp:ListItem Value="employees">الموظفون</asp:ListItem><asp:ListItem Value="customers">العملاء</asp:ListItem><asp:ListItem Value="all">الجميع — الموظفون والعملاء</asp:ListItem></asp:DropDownList></div>
        <div id="informationEmployees"><asp:Label runat="server" AssociatedControlID="ddlAccess" CssClass="form-label" Text="من يستطيع الاطلاع على الصفحة؟" />
        <asp:DropDownList ID="ddlAccess" runat="server" CssClass="form-select" onchange="informationAccess()">
            <asp:ListItem Value="all">كل أنواع الموظفين ضمن العلامات المحددة</asp:ListItem><asp:ListItem Value="roles">أنواع موظفين محددة</asp:ListItem>
        </asp:DropDownList>
        <div id="informationRoles" class="mt-3"><asp:CheckBoxList ID="cblRoles" runat="server" RepeatLayout="Flow" CssClass="information-roles" /></div></div>
        <div id="informationCustomers"><asp:Label runat="server" AssociatedControlID="ddlCustomersAccess" CssClass="form-label" Text="العملاء المسموح لهم بالاطلاع"/><asp:DropDownList ID="ddlCustomersAccess" runat="server" CssClass="form-select" onchange="informationAccess()"><asp:ListItem Value="all">كل العملاء ضمن العلامات المحددة</asp:ListItem><asp:ListItem Value="selected">عملاء محددون بالاسم</asp:ListItem></asp:DropDownList><div id="informationCustomerSelection" class="mt-3"><asp:Label runat="server" AssociatedControlID="lstCustomers" CssClass="form-label" Text="اختر العملاء"/><asp:ListBox ID="lstCustomers" runat="server" SelectionMode="Multiple" CssClass="form-select information-audience-select" data-placeholder="ابحث عن اسم العميل واختر عميلًا أو أكثر"/><small id="informationCustomerStatus" class="text-muted d-block mt-2" role="status" aria-live="polite">تظهر فقط أسماء العملاء التابعين للعلامات التجارية المختارة.</small></div></div>
        <div id="informationEveryone" class="alert alert-primary mb-0">تظهر الصفحة لكل أنواع الموظفين ولكل العملاء ضمن العلامات التجارية المحددة، بعد النشر وخلال فترة العرض.</div>
        <small class="text-muted d-block mt-2">مدير النظام يستطيع الإدارة والمعاينة دائمًا. تغيير العلامات أو الجمهور أو المستفيدين يُسجّل دون إنشاء إصدار للمحتوى، ولا يغيّر استرجاع إصدار سابق صلاحيات الاطلاع الحالية.</small>
    </fieldset>
    <div class="row g-3">
        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtTitleAr" CssClass="form-label" Text="العنوان بالعربية" /><asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="250" /></div>
        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtTitleEn" CssClass="form-label" Text="العنوان بالإنجليزية" /><asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="250" dir="ltr" /></div>
        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtSummaryAr" CssClass="form-label" Text="الملخص بالعربية" /><asp:TextBox ID="txtSummaryAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" /></div>
        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtSummaryEn" CssClass="form-label" Text="الملخص بالإنجليزية" /><asp:TextBox ID="txtSummaryEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" dir="ltr" /></div>
        <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtDetailsAr" CssClass="form-label" Text="التفاصيل بالعربية" /><asp:TextBox ID="txtDetailsAr" runat="server" TextMode="MultiLine" Rows="10" ValidateRequestMode="Disabled" CssClass="form-control" /></div>
        <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtDetailsEn" CssClass="form-label" Text="التفاصيل بالإنجليزية" /><asp:TextBox ID="txtDetailsEn" runat="server" TextMode="MultiLine" Rows="10" ValidateRequestMode="Disabled" CssClass="form-control" dir="ltr" /></div>
        <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="ddlStatus" CssClass="form-label" Text="الحالة" /><asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select"><asp:ListItem Value="0">مسودة</asp:ListItem><asp:ListItem Value="1">منشورة</asp:ListItem></asp:DropDownList></div>
        <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="ddlMode" CssClass="form-label" Text="طريقة النشر" /><asp:DropDownList ID="ddlMode" runat="server" CssClass="form-select" onchange="informationSchedule()"><asp:ListItem Value="immediate">نشر فوري</asp:ListItem><asp:ListItem Value="scheduled">نشر مجدول</asp:ListItem></asp:DropDownList></div>
        <div class="col-md-4"><asp:Label runat="server" AssociatedControlID="txtOrder" CssClass="form-label" Text="ترتيب العرض" /><asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number" Text="0" min="0" /></div>
        <div id="informationSchedule" class="col-12"><div class="row g-3">
            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtStart" CssClass="form-label" Text="بداية العرض" /><asp:TextBox ID="txtStart" runat="server" CssClass="form-control" TextMode="DateTimeLocal" /></div>
            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtEnd" CssClass="form-label" Text="نهاية العرض" /><asp:TextBox ID="txtEnd" runat="server" CssClass="form-control" TextMode="DateTimeLocal" /></div>
        </div><p class="text-muted mt-2">التاريخان إلزاميان للنشر المجدول، بتوقيت عمّان. تختفي الصفحة عند حلول وقت النهاية.</p></div>
    </div>
    <p class="text-muted mt-3">المسودة لا تظهر للمستخدمين. تعديل المحتوى أو إعدادات النشر والترتيب ينشئ إصدارًا جديدًا، أما صلاحيات الاطلاع فمستقلة عن الإصدارات.</p>
    <asp:Button ID="btnSave" runat="server" Text="حفظ الصفحة" CssClass="btn btn-primary" OnClick="Save_Click" OnClientClick="informationUpdateEditors();" />
    <a href="Manage.aspx" class="btn btn-outline-secondary">العودة للإدارة</a>
    </div></section>
</div>
<script>
function informationAccess() {
    var audience=document.getElementById('<%= ddlAudience.ClientID %>').value;
    document.getElementById('informationEmployees').hidden=audience!=='employees';
    document.getElementById('informationCustomers').hidden=audience!=='customers';
    document.getElementById('informationEveryone').hidden=audience!=='all';
    document.getElementById('informationCustomerSelection').hidden=document.getElementById('<%= ddlCustomersAccess.ClientID %>').value!=='selected';
    document.getElementById('informationRoles').hidden = document.getElementById('<%= ddlAccess.ClientID %>').value !== 'roles';
}
function informationSchedule() {
    var scheduled = document.getElementById('<%= ddlMode.ClientID %>').value === 'scheduled';
    document.getElementById('informationSchedule').hidden = !scheduled;
    ['<%= txtStart.ClientID %>', '<%= txtEnd.ClientID %>'].forEach(function(id) {
        var field = document.getElementById(id); field.required = scheduled; field.disabled = !scheduled;
    });
}
function informationUpdateEditors() { if (window.CKEDITOR) Object.keys(CKEDITOR.instances).forEach(function(key) { CKEDITOR.instances[key].updateElement(); }); }
function initializeInformationCustomers(){
    var brands=document.getElementById('<%= lstBrands.ClientID %>'),customers=document.getElementById('<%= lstCustomers.ClientID %>');
    var customerOptions=Array.from(customers.options).map(function(option){return option.cloneNode(true);});
    var customerStatus=document.getElementById('informationCustomerStatus');
    function filterCustomers(){
        var selectedBrands=new Set(Array.from(brands.selectedOptions).map(function(option){return option.value;}));
        var selectedCustomers=new Set(Array.from(customers.selectedOptions).map(function(option){return option.value;}));
        if(window.jQuery && jQuery(customers).data('select2')) jQuery(customers).select2('close');
        customers.replaceChildren();
        customerOptions.forEach(function(option){
            if(!(option.getAttribute('data-brand-ids')||'').split(',').some(function(id){return selectedBrands.has(id);} ))return;
            var item=option.cloneNode(true);item.selected=selectedCustomers.has(item.value);customers.appendChild(item);
        });
        var retained=Array.from(customers.selectedOptions).length,removed=selectedCustomers.size-retained;
        customers.disabled=customers.options.length===0;
        customerStatus.textContent=(!selectedBrands.size?'اختر علامة تجارية أولًا لعرض عملائها.':!customers.options.length?'لا يوجد عملاء متاحون للعلامات التجارية المختارة.':'يمكنك البحث باسم العميل ضمن العلامات المختارة.')+(removed?' أُزيلت اختيارات العملاء الذين لا يتبعون العلامات المحددة.':'');
        if(window.jQuery && jQuery(customers).data('select2')) jQuery(customers).trigger('change.select2');
    }
    if(window.jQuery && jQuery.fn.select2){
        var settings={dir:'rtl',width:'100%',language:{noResults:function(){return 'لا توجد أسماء عملاء مطابقة';}}};
        jQuery(brands).select2({dir:'rtl',width:'100%'});
        settings.matcher=function(params,data){
            if(!params.term)return data;
            var name=data.element?data.element.getAttribute('data-customer-name'):data.text;
            return jQuery.fn.select2.defaults.defaults.matcher(params,{id:data.id,text:name||''})?data:null;
        };
        jQuery(customers).select2(settings);
        var search=jQuery(customers).next('.select2').find('.select2-search__field');
        search.attr('aria-label','البحث باسم العميل').on('keydown',function(event){if(event.key==='Enter')event.preventDefault();});
        jQuery(brands).on('change.informationCustomers',filterCustomers);
    }else brands.addEventListener('change',filterCustomers);
    filterCustomers();
}
document.addEventListener('DOMContentLoaded', function() {
    if(window.jQuery)jQuery(initializeInformationCustomers);else initializeInformationCustomers();
    informationAccess();
    informationSchedule();
    if (!window.CKEDITOR) return;
    [['<%= txtDetailsAr.ClientID %>', 'rtl', 'ar'], ['<%= txtDetailsEn.ClientID %>', 'ltr', 'en']].forEach(function(item) {
        CKEDITOR.replace(item[0], {language:item[2], contentsLangDirection:item[1], height:280,
            toolbar:[['Format','Bold','Italic','Underline','Strike','RemoveFormat'],['NumberedList','BulletedList','Blockquote'],['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],['Link','Unlink','Table','HorizontalRule'],['Undo','Redo','Maximize']],
            removePlugins:'elementspath', resize_enabled:false,
            allowedContent:'p div span{text-align,direction}[dir]; h1 h2 h3 h4 h5 h6; br hr strong b em i u s sub sup; ul ol li blockquote pre code; a[href,title]; table thead tbody tfoot tr caption; td th[colspan,rowspan]'
        });
    });
});
</script>
</asp:Content>
