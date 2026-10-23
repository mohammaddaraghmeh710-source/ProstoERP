<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ManageDepartments.aspx.vb" Inherits="CRM.ManageDepartments" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">

    <style>
        .form-label-sm { font-size: .8rem; margin-bottom: .15rem; }
        .dataTables_filter { float: left; padding-bottom: 8px; }
        .pagination { padding-top: 8px !important; }
        .dataTables_info { padding-top: 8px !important; }
    </style>

    <script>
        // Department link popup (copy)
        function showDepartmentLinkPopup(deptId) {
            try {
                var base = window.location.origin;
                var url = base + '/Modules/Departments_Dashboards/Department_Dashboard_View.aspx?DepartmentID=' + encodeURIComponent(deptId);

                Swal.fire({
                    title: 'رابط صفحة القسم',
                    html:
                        '<div style="text-align:right; direction:rtl;">' +
                        '  <input id="deptLinkInput" class="swal2-input" style="width:100%; font-size:13px;" readonly value="' + url + '">' +
                        '</div>',
                    icon: 'info',
                    showCancelButton: true,
                    confirmButtonText: 'Copy',
                    cancelButtonText: 'إغلاق',
                    reverseButtons: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#6c757d',
                    didOpen: () => {
                        const inp = document.getElementById('deptLinkInput');
                        if (inp) { inp.focus(); inp.select(); }
                    }
                }).then(async (result) => {
                    if (result.isConfirmed) {
                        var textToCopy = url;

                        if (navigator.clipboard && window.isSecureContext) {
                            await navigator.clipboard.writeText(textToCopy);
                        } else {
                            var inp = document.getElementById('deptLinkInput');
                            if (inp) {
                                inp.focus();
                                inp.select();
                                document.execCommand('copy');
                            }
                        }

                        Swal.fire({
                            toast: true,
                            position: 'top',
                            icon: 'success',
                            title: 'تم نسخ الرابط',
                            showConfirmButton: false,
                            timer: 1800
                        });
                    }
                });

            } catch (e) {
                console.log(e);
            }
            return false;
        }
    </script>


</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- Departments table -->
                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">الأقسام</h5>
                        </div>
                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server"
                                    CssClass="dt-button create-new btn btn-primary">
                                    <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">اضافة قسم جديد</span></span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <!-- ====== FILTERS (Same style as Manage_JobTitle_Items) ====== -->
                        <div class="row g-2 mb-3">

                            <div class="col-12 col-md-5">
                                <label class="form-label form-label-sm">العلامة التجارية</label>
                                <asp:DropDownList ID="ddlBrandFilter" runat="server"
                                    CssClass="form-select form-select-sm"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlBrandFilter_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>

                            <div class="col-12 col-md-5">
                                <div runat="server" id="divBranch" visible="false">
                                    <label class="form-label form-label-sm">الفرع</label>
                                    <asp:DropDownList ID="ddlBranchFilter" runat="server"
                                        CssClass="form-select form-select-sm">
                                    </asp:DropDownList>
                                </div>
                            </div>

                            <!-- Buttons (Search + Reset side-by-side) -->
                            <div class="col-12 col-md-2 d-flex align-items-end gap-2">
                                <asp:LinkButton ID="btnSearch" runat="server"
                                    CssClass="btn btn-sm btn-primary flex-grow-1"
                                    OnClick="btnSearch_Click">
                                    <i class="bx bx-search me-1"></i> بحث
                                </asp:LinkButton>

                                <asp:LinkButton ID="btnClear" runat="server"
                                    CssClass="btn btn-sm btn-label-secondary"
                                    OnClick="btnClear_Click"
                                    ToolTip="إعادة تعيين">
                                    <i class="bx bx-refresh"></i>
                                </asp:LinkButton>
                            </div>

                        </div>

                        <!-- Info line + (optional) advanced toggle look -->
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <small class="text-muted">
                                يمكنك البحث حسب العلامة التجارية والفرع، ثم الضغط على زر "بحث".
                            </small>
                        
                        </div>
                        <!-- ====== /FILTERS ====== -->

                        <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>العلامة التجارية</th>
                                    <th>الفرع</th>
                                    <th>اسم القسم بالعربية</th>
                                    <th>اسم القسم بالانجليزية</th>
                                    <th>تاريخ الإنشاء</th>
                                    <th>QRCode</th>
                                    <th>رابط صفحة القسم</th>
                                    <th>تعديل</th>
                                    <th>حذف</th>
                                </tr>
                            </thead>

                            <tbody>
                                <asp:ListView runat="server" ID="lstData">
                                    <LayoutTemplate>
                                        <asp:PlaceHolder runat="server" ID="ItemPlaceHolder"></asp:PlaceHolder>
                                    </LayoutTemplate>

                                    <ItemTemplate>
                                        <tr data-admin-name='<%#: CRM.SystemAdministrationUI.SearchName(Container.DataItem) %>' data-admin-id='<%#: Eval("ID") %>' data-admin-active='<%# CRM.SystemAdministrationUI.State(Container.DataItem) %>'>
                                            <td data-title="العلامة التجارية"><%#: Eval("BrandTitle_Ar") %></td>
                                            <td data-title="الفرع"><%#: Eval("BranchTitle_Ar") %></td>
                                            <td data-title="اسم القسم بالعربية"><%#: Eval("Title_Ar") %></td>
                                            <td data-title="اسم القسم بالانجليزية"><%#: Eval("Title_En") %></td>
                                            <td data-title="تاريخ الإنشاء"><%#: Eval("AddedDate", "{0:yyyy/MM/dd HH:mm}") %></td>

                                            <td data-title="QRCode">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-success" ID="lnkQRCode"
                                                    CommandName="QRCode" CommandArgument='<%#: Eval("ID") %>'
                                                    runat="server" ToolTip="طباعة QRCode">
                                                    <i class="bx bx-qr"></i>
                                                </asp:LinkButton>
                                            </td>

                                            <td data-title="رابط صفحة القسم">
                                                <a href="javascript:void(0);"
                                                   class="btn btn-icon btn-label-info"
                                                   onclick="return showDepartmentLinkPopup('<%#: Eval("ID") %>');"
                                                   title="عرض رابط صفحة القسم">
                                                    <i class="bx bx-link"></i>
                                                </a>
                                            </td>

                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit"
                                                    CommandName="Edit" CommandArgument='<%#: Eval("ID") %>'
                                                    runat="server" ToolTip="تعديل">
                                                    <i class="bx bx-edit-alt"></i>
                                                </asp:LinkButton>
                                            </td>

                                        <td data-title="حذف">
                                               <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
    CommandName="DeleteItem"
    CommandArgument='<%#: Eval("ID") %>'
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

                    </div>
                </div>
                <!-- /Departments table -->

            </div>
        </div>
    </div>

</ContentTemplate></asp:UpdatePanel></asp:Content>
