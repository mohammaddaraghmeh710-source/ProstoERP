<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="ManageJobTitles.aspx.vb" Inherits="CRM.ManageJobTitles" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">

    <style>
        .form-label-sm { font-size: .8rem; margin-bottom: .15rem; }
        .dataTables_filter { float: left; padding-bottom: 8px; }
        .pagination { padding-top: 8px !important; }
        .dataTables_info { padding-top: 8px !important; }
    </style>



</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- JobTitles table -->
                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">المحطات التعريفية</h5>
                        </div>

                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server"
                                    CssClass="dt-button create-new btn btn-primary">
                                    <span>
                                        <i class="bx bx-plus me-sm-2"></i>
                                        <span class="d-none d-sm-inline-block">اضافة محطة تعريفية جديدة</span>
                                    </span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <!-- ====== FILTERS (Same style as ManageDepartments) ====== -->
                        <div class="row g-2 mb-3">

                            <div class="col-12 col-md-3">
                                <label class="form-label form-label-sm">العلامة التجارية</label>
                                <asp:DropDownList ID="ddlBrandFilter" runat="server"
                                    CssClass="form-select form-select-sm"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlBrandFilter_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>

                            <div class="col-12 col-md-3">
                                <div runat="server" id="divBranch" visible="false">
                                    <label class="form-label form-label-sm">الفرع</label>
                                    <asp:DropDownList ID="ddlBranchFilter" runat="server"
                                        CssClass="form-select form-select-sm"
                                        AutoPostBack="true"
                                        OnSelectedIndexChanged="ddlBranchFilter_SelectedIndexChanged">
                                    </asp:DropDownList>
                                </div>
                            </div>

                            <div class="col-12 col-md-3">
                                <div runat="server" id="divDepartment" visible="false">
                                    <label class="form-label form-label-sm">القسم</label>
                                    <asp:DropDownList ID="ddlDepartmentFilter" runat="server"
                                        CssClass="form-select form-select-sm">
                                    </asp:DropDownList>
                                </div>
                            </div>

                            <!-- Buttons (Search + Reset side-by-side) -->
                            <div class="col-12 col-md-3 d-flex align-items-end gap-2">
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

                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <small class="text-muted">
                                يمكنك البحث حسب العلامة التجارية ثم الفرع ثم القسم، ثم الضغط على زر "بحث".
                            </small>
                        </div>
                        <!-- ====== /FILTERS ====== -->

                        <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>العلامة التجارية</th>
                                    <th>الفرع</th>
                                    <th>القسم</th>
                                    <th>المحطة بالعربية</th>
                                    <th>المحطة بالانجليزية</th>
                                    <th>تاريخ الإنشاء</th>
                                    <th>QRCode</th>
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
                                        <tr>
                                            <td data-title="العلامة التجارية"><%# Eval("BrandTitle_Ar") %></td>
                                            <td data-title="الفرع"><%# Eval("BranchTitle_Ar") %></td>
                                            <td data-title="القسم"><%# Eval("DepartmentTitle_Ar") %></td>

                                            <td data-title="المحطة بالعربية"><%# Eval("Title_Ar") %></td>
                                            <td data-title="المحطة بالانجليزية"><%# Eval("Title_En") %></td>

                                            <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate") %></td>

                                            <td data-title="QRCode">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-success" ID="lnkQRCode"
                                                    CommandName="QRCode" CommandArgument='<%# Eval("ID") %>'
                                                    runat="server" ToolTip="طباعة QRCode">
                                                    <i class="bx bx-qr"></i>
                                                </asp:LinkButton>
                                            </td>

                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit"
                                                    CommandName="Edit" CommandArgument='<%# Eval("ID") %>'
                                                    runat="server" ToolTip="تعديل">
                                                    <i class="bx bx-edit-alt"></i>
                                                </asp:LinkButton>
                                            </td>

                                            <td data-title="حذف">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
                                                    CommandName="DeleteItem"
                                                    CommandArgument='<%# Eval("ID") %>'
                                                    runat="server"
                                                    ToolTip="حذف"
                                                    CausesValidation="false"
                                                    OnClientClick="return confirm('هل أنت متأكد من حذف هذا العنصر؟');"  >
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
                <!-- /JobTitles table -->

            </div>
        </div>
    </div>

</asp:Content>
