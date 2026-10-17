<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Manage_JobTitle_Items.aspx.vb" Inherits="CRM.Manage_JobTitle_Items" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .form-label-sm { font-size: .8rem; margin-bottom: .15rem; }
        .dataTables_filter{
                float: left;
    padding-bottom: 8px;
        }
        .pagination
        {
              padding-top: 8px !important;
        }
        .dataTables_info
        {
              padding-top: 8px !important;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- JobTitle Items table -->
                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">عناصر المحطات التعريفية</h5>
                        </div>
                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server"
                                    CssClass="dt-button create-new btn btn-primary">
                                    <span>
                                        <i class="bx bx-plus me-sm-2"></i>
                                        <span class="d-none d-sm-inline-block">إضافة عنصر جديد</span>
                                    </span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <!-- ✅ UpdatePanel لمنع الـ Refresh والحفاظ على فتح البحث المتقدم -->
                        <asp:UpdatePanel ID="updFiltersAndGrid" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>

                                <!-- Hidden field لحفظ حالة فتح البحث المتقدم -->
                                <asp:HiddenField ID="hfAdvancedOpen" runat="server" Value="0" />

                                <!-- ====== البحث الأساسي (بنفس ستايل المرفق) ====== -->
                                <div class="row g-2 mb-3">
                                    <div class="col-12 col-md-3">
                                        <label class="form-label form-label-sm">رقم الأداة</label>
                                        <asp:TextBox ID="txtToolNumber" runat="server"
                                            CssClass="form-control form-control-sm" placeholder="رقم الأداة"></asp:TextBox>
                                    </div>

                                    <div class="col-12 col-md-3">
                                        <label class="form-label form-label-sm">نوع الأداة</label>
                                        <asp:DropDownList ID="ddlItemTypeBasic" runat="server"
                                            CssClass="form-select form-select-sm"></asp:DropDownList>
                                    </div>

                                    <div class="col-12 col-md-4">
                                        <label class="form-label form-label-sm">اسم الأداة</label>
                                        <asp:TextBox ID="txtToolName" runat="server"
                                            CssClass="form-control form-control-sm" placeholder="اسم الأداة (عربي/إنجليزي)"></asp:TextBox>
                                    </div>

                                    <!-- أزرار البحث + إعادة التعيين بجانب بعض -->
                                    <div class="col-12 col-md-2 d-flex align-items-end gap-2">
                                        <asp:LinkButton ID="btnSearch" runat="server"
                                            CssClass="btn btn-sm btn-primary flex-grow-1"
                                            OnClick="btnSearch_Click">
                                            <i class="bx bx-search me-1"></i> بحث
                                        </asp:LinkButton>

                                        <asp:LinkButton ID="btnReset" runat="server"
                                            CssClass="btn btn-sm btn-label-secondary"
                                            OnClick="btnReset_Click"
                                            ToolTip="إعادة تعيين">
                                            <i class="bx bx-refresh"></i>
                                        </asp:LinkButton>
                                    </div>
                                </div>

                                <!-- Toggle البحث المتقدم (بنفس فكرة المرفق) -->
                                <div class="d-flex justify-content-between align-items-center mb-2">
                                    <small class="text-muted">
                                        البحث العام يعتمد على رقم الأداة ونوع الأداة واسم الأداة، يمكنك استخدام باقي الخيارات في البحث المتقدم.
                                    </small>

                                    <button type="button" class="btn btn-sm btn-link px-0" onclick="toggleAdvancedSearchProsto()">
                                        <i class="bx bx-filter-alt ms-1"></i> بحث متقدم
                                    </button>
                                </div>

                                <!-- ====== البحث المتقدم (Hidden by default) ====== -->
                                <asp:Panel ID="pnlAdvancedSearch" runat="server" CssClass="mb-3 d-none">

                                    <div class="row g-2 mb-2">
                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">العلامة التجارية</label>
                                            <asp:DropDownList ID="ddlBrand" runat="server"
                                                CssClass="form-select form-select-sm"
                                                AutoPostBack="true"
                                                OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged"></asp:DropDownList>
                                        </div>

                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">الفرع</label>
                                            <asp:DropDownList ID="ddlBranch" runat="server"
                                                CssClass="form-select form-select-sm"
                                                AutoPostBack="true"
                                                OnSelectedIndexChanged="ddlBranch_SelectedIndexChanged"></asp:DropDownList>
                                        </div>

                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">القسم</label>
                                            <asp:DropDownList ID="ddlDepartment" runat="server"
                                                CssClass="form-select form-select-sm"
                                                AutoPostBack="true"
                                                OnSelectedIndexChanged="ddlDepartment_SelectedIndexChanged"></asp:DropDownList>
                                        </div>
                                    </div>

                                    <div class="row g-2 mb-2">
                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">المحطة التعريفية</label>
                                            <asp:DropDownList ID="ddlJobTitleAdvanced" runat="server"
                                                CssClass="form-select form-select-sm"></asp:DropDownList>
                                        </div>

                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">الشركة الموردة</label>
                                            <asp:DropDownList ID="ddlSupplier" runat="server"
                                                CssClass="form-select form-select-sm"></asp:DropDownList>
                                        </div>

                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">شركة الصيانة</label>
                                            <asp:DropDownList ID="ddlMaintenanceCompany" runat="server"
                                                CssClass="form-select form-select-sm"></asp:DropDownList>
                                        </div>
                                    </div>

                                    <div class="row g-2">
                                        <div class="col-12 col-md-6">
                                            <label class="form-label form-label-sm">نوع الأداة</label>
                                            <asp:DropDownList ID="ddlItemTypeAdvanced" runat="server"
                                                CssClass="form-select form-select-sm"></asp:DropDownList>
                                        </div>

                                        <div class="col-12 col-md-6 d-flex align-items-end">
                                            <asp:LinkButton ID="btnAdvancedSearch" runat="server"
                                                CssClass="btn btn-sm btn-primary w-100"
                                                OnClick="btnAdvancedSearch_Click">
                                                <i class="bx bx-filter-alt me-1"></i> تطبيق
                                            </asp:LinkButton>
                                        </div>
                                    </div>

                                </asp:Panel>

                                <!-- الجدول -->
                                <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                                    <thead>
                                        <tr>
                                            <th>الهيكل التنظيمي</th>
                                            <th>اسم الأداة</th>
                                            <th>رقم الأداة</th>
                                            <th>نوع الأداة</th>
                                            <th>تاريخ الإنشاء</th>
                                             <th>QR Code</th>
                                            <th>تعديل</th>
                                            <th>حذف</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <asp:ListView runat="server" ID="lstData" OnItemCommand="lstData_ItemCommand">
                                            <LayoutTemplate>
                                                <asp:PlaceHolder runat="server" ID="ItemPlaceHolder"></asp:PlaceHolder>
                                            </LayoutTemplate>

                                            <ItemTemplate>
    <tr>
        <td data-title="الهيكل التنظيمي"><%# Eval("OrgStructure_Ar")%></td>
        <td data-title="اسم الأداة"><%# Eval("Title_Ar")%></td>
        <td data-title="رقم الأداة"><%# Eval("Tool_Number")%></td>
        <td data-title="نوع الأداة"><%# Eval("ItemType_Title_Ar")%></td>
        <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate")%></td>

        <!-- QR Code -->
        <td data-title="QR Code">
            <asp:LinkButton CssClass="btn btn-icon btn-label-success"
                ID="lnkPrintQrCode"
                CommandName="PrintQrCode"
                CommandArgument='<%# Eval("ID")%>'
                runat="server"
                ToolTip="عرض / طباعة QR Code">
                 <i class="bx bx-qr"></i>
            </asp:LinkButton>
        </td>



        <!-- Edit -->
        <td data-title="تعديل">
            <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                ID="btnEdit"
                CommandName="Edit"
                CommandArgument='<%# Eval("ID")%>'
                runat="server"
                ToolTip="تعديل">
                <i class="bx bx-edit-alt"></i>
            </asp:LinkButton>
        </td>

        <!-- Delete -->
        <td data-title="حذف">
            <asp:LinkButton CssClass="btn btn-icon btn-label-danger"
                ID="btnDelete"
                CommandName="DeleteItem"
                CommandArgument='<%# Eval("ID")%>'
                runat="server"
                ToolTip="حذف"
                CausesValidation="false"
                OnClientClick="return confirm('هل أنت متأكد من حذف هذا العنصر؟');">
                <i class="bx bx-trash-alt"></i>
            </asp:LinkButton>
        </td>
    </tr>
</ItemTemplate>


                                            <EmptyDataTemplate>
                                                <span class="no-data-title">لا يوجد محتوى لعرضه</span>
                                            </EmptyDataTemplate>
                                        </asp:ListView>
                                    </tbody>
                                </table>

                            </ContentTemplate>

<%-- Triggers لضمان AsyncPostBack بدل refresh --%>
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="ddlBrand" EventName="SelectedIndexChanged" />
                                <asp:AsyncPostBackTrigger ControlID="ddlBranch" EventName="SelectedIndexChanged" />
                                <asp:AsyncPostBackTrigger ControlID="ddlDepartment" EventName="SelectedIndexChanged" />

                                <asp:AsyncPostBackTrigger ControlID="btnSearch" EventName="Click" />
                                <asp:AsyncPostBackTrigger ControlID="btnAdvancedSearch" EventName="Click" />
                                <asp:AsyncPostBackTrigger ControlID="btnReset" EventName="Click" />
                            </Triggers>

                        </asp:UpdatePanel>

                    </div>
                </div>
                <!-- /JobTitle Items table -->

            </div>
        </div>

    </div>

 <script type="text/javascript">
     // ===================== Advanced Search Toggle =====================
     function toggleAdvancedSearchProsto() {
         var pnl = document.getElementById('<%=pnlAdvancedSearch.ClientID%>');
        var hf = document.getElementById('<%=hfAdvancedOpen.ClientID%>');
        if (!pnl || !hf) return;

        pnl.classList.toggle('d-none');
        hf.value = pnl.classList.contains('d-none') ? "0" : "1";
    }

    function applyAdvancedStateProsto() {
        var pnl = document.getElementById('<%=pnlAdvancedSearch.ClientID%>');
        var hf = document.getElementById('<%=hfAdvancedOpen.ClientID%>');
         if (!pnl || !hf) return;

         if (hf.value === "1") pnl.classList.remove('d-none');
         else pnl.classList.add('d-none');
     }

     // ===================== DataTable Helpers =====================
     function initERPDataTable() {
         try {
             if (typeof $ === "undefined" || !$.fn || !$.fn.DataTable) return;

             var selector = "#ERPTable";

             // إذا تم تهيئته مسبقاً لا تعيد تهيئته
             if ($.fn.DataTable.isDataTable(selector)) return;

             $(selector).DataTable({
                 responsive: true,
                 autoWidth: false,
                 language: {
                     search: "بحث:",
                     lengthMenu: "عرض _MENU_",
                     info: "عرض _START_ إلى _END_ من أصل _TOTAL_",
                     infoEmpty: "لا توجد بيانات",
                     zeroRecords: "لا توجد نتائج",
                     paginate: { first: "الأول", last: "الأخير", next: "التالي", previous: "السابق" }
                 }
             });

         } catch (e) { }
     }

     function destroyERPDataTable() {
         try {
             if (typeof $ === "undefined" || !$.fn || !$.fn.DataTable) return;

             var selector = "#ERPTable";
             if ($.fn.DataTable.isDataTable(selector)) {
                 // destroy(true) يزيل Wrappers قبل ما UpdatePanel يعيد رسم الجدول
                 $(selector).DataTable().destroy(true);
             }
         } catch (e) { }
     }

     // ===================== Hook UpdatePanel Once =====================
     (function () {
         // منع تكرار ربط الأحداث لو السكربت اتنفذ أكثر من مرة
         if (window.__ERP_DT_PRM_HOOKED) return;
         window.__ERP_DT_PRM_HOOKED = true;

         document.addEventListener("DOMContentLoaded", function () {
             applyAdvancedStateProsto();

             // IMPORTANT:
             // لا تعمل initERPDataTable هنا حتى لا تتكرر (لأن القالب غالباً يعمل init تلقائياً)

             if (typeof (Sys) !== "undefined"
                 && Sys.WebForms
                 && Sys.WebForms.PageRequestManager) {

                 var prm = Sys.WebForms.PageRequestManager.getInstance();

                 prm.add_beginRequest(function () {
                     destroyERPDataTable();
                 });

                 prm.add_endRequest(function () {
                     // رجّع حالة البحث المتقدم
                     applyAdvancedStateProsto();

                     // بعد تحديث UpdatePanel: أعد تهيئة الـ DataTable (لأن سكربت القالب لا يعيد تهيئتها)
                     initERPDataTable();
                 });
             }
         });
     })();
 </script>



</asp:Content>
