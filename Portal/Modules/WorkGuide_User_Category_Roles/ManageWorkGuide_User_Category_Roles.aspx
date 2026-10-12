<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuide_User_Category_Roles.aspx.vb" Inherits="CRM.ManageWorkGuide_User_Category_Roles" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="mb-0">إدارة صلاحيات دليل العمل</h5>
                    <small class="text-muted">إدارة صلاحيات العملاء على تصنيفات دليل العمل حسب العميل والدور</small>
                </div>

                <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="btn btn-primary" OnClick="btnAddNewItem_Click">
                    <i class="bx bx-plus me-sm-2"></i>
                    <span>إضافة صلاحية جديدة</span>
                </asp:LinkButton>
            </div>

            <div class="card-body">

                <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block" Visible="false"></asp:Label>

                <div class="row g-3 mb-4">

                    <div class="col-md-4">
                        <label class="form-label">العلامة التجارية</label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged">
                        </asp:DropDownList>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">العميل</label>
                        <asp:DropDownList ID="ddlUser" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlUser_SelectedIndexChanged">
                        </asp:DropDownList>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">الدور / الصلاحية</label>
                        <asp:DropDownList ID="ddlRole" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlRole_SelectedIndexChanged">
                        </asp:DropDownList>
                    </div>

                </div>

                <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                    <thead>
                        <tr>
                            <th>العميل</th>
                            <th>العلامة التجارية</th>
                            <th>الدور / الصلاحية</th>
                            <th>عدد التصنيفات</th>
                            <th>الحالة</th>
                            <th>تاريخ آخر إضافة</th>
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
                                    <td data-title="العميل"><%#: Eval("User_FullName_Ar") %></td>
                                    <td data-title="العلامة التجارية"><%# Eval("Brand_Title_Ar") %></td>
                                    <td data-title="الدور / الصلاحية"><%# Eval("Role_Title_Ar") %></td>

                                    <td data-title="عدد التصنيفات">
                                        <span class="badge bg-label-primary">
                                            <%# Eval("Categories_Count") %> تصنيفات
                                        </span>
                                    </td>

                                    <td data-title="الحالة">
                                        <%# If(Convert.ToBoolean(Eval("IsActive")), "فعال", "غير فعال") %>
                                    </td>

                                    <td data-title="تاريخ آخر إضافة">
                                        <%# Eval("AddedDate") %>
                                    </td>

                                    <td data-title="تعديل">
                                        <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                                            ID="btnEdit"
                                            CommandName="Edit"
                                            CommandArgument='<%# Eval("User_ID") & "|" & Eval("Brand_ID") & "|" & Eval("Role_ID") %>'
                                            runat="server"
                                            CausesValidation="false"
                                            ToolTip="تعديل">
                                            <i class="bx bx-edit-alt"></i>
                                        </asp:LinkButton>
                                    </td>

                                    <td data-title="حذف">
                                        <asp:LinkButton CssClass="btn btn-icon btn-label-danger"
                                            ID="btnDelete"
                                            CommandName="DeleteGroup"
                                            CommandArgument='<%# Eval("User_ID") & "|" & Eval("Brand_ID") & "|" & Eval("Role_ID") %>'
                                            runat="server"
                                            CausesValidation="false"
                                            ToolTip="حذف"
                                            OnClientClick="return confirm('هل أنت متأكد من حذف جميع صلاحيات هذا العميل على هذا الدور؟');">
                                            <i class="bx bx-trash-alt"></i>
                                        </asp:LinkButton>
                                    </td>
                                </tr>
                            </ItemTemplate>

                            <EmptyDataTemplate>
                                <span class="no-data-title">لا يوجد صلاحيات لعرضها</span>
                            </EmptyDataTemplate>
                        </asp:ListView>
                    </tbody>
                </table>

            </div>
        </div>

    </div>

</asp:Content>
