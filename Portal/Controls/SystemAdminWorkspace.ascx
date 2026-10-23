<%@ Control Language="VB" AutoEventWireup="false" CodeBehind="SystemAdminWorkspace.ascx.vb" Inherits="CRM.SystemAdminWorkspace" %>
<script id="systemAdminConfiguration" type="application/json"><%= ConfigurationJson %></script>
<div id="systemAdminWorkspace" class="crm-types">
 <asp:Button ID="reloadAdmin" runat="server" ClientIDMode="Static" Text="تحديث البيانات" CausesValidation="false" UseSubmitBehavior="false" style="display:none" OnClick="Reload_Click" />
 <div data-admin-notice role="status" aria-live="polite"></div>
 <div class="offcanvas offcanvas-end type-editor crm-editor-wide" id="systemAdminEditor" tabindex="-1" aria-labelledby="systemAdminEditorTitle">
  <div class="offcanvas-header border-bottom"><h2 id="systemAdminEditorTitle" class="offcanvas-title h5">إضافة / تعديل</h2><button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="إغلاق"></button></div>
  <div class="offcanvas-body p-0"><div class="p-4 text-muted" data-editor-loading role="status">جارٍ تحميل البيانات…</div><iframe title="نموذج الإضافة والتعديل" class="system-admin-frame" hidden></iframe></div>
 </div>
 <div class="modal fade" id="systemAdminConfirm" tabindex="-1" aria-labelledby="systemAdminConfirmTitle"><div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-header"><h2 class="modal-title h5" id="systemAdminConfirmTitle">تأكيد العملية</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button></div><div class="modal-body"><p data-confirm-message class="mb-0"></p></div><div class="modal-footer"><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إلغاء</button><button type="button" class="btn btn-danger" data-confirm-action>تأكيد</button></div></div></div></div>
</div>
<script src="/assets/js/crm-list.js?v=20261021suppliers"></script>
<script src="/assets/js/system-administration.js?v=20261018j"></script>
