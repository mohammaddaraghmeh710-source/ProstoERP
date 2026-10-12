<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuideRoles.aspx.vb" Inherits="CRM.ManageWorkGuideRoles" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

<div class="container-xxl flex-grow-1 container-p-y">
    <div class="card mb-4">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">إدارة صلاحيات دليل العمل</h5>

            <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="btn btn-primary" OnClick="btnAddNewItem_Click">
                    <i class="bx bx-plus me-sm-2"></i>
                    <span>إضافة صلاحية جديدة</span>
            </asp:LinkButton>
        </div>

        <div class="card-body">
            <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                <thead>
                    <tr>
                        <th>الاسم بالعربية</th>
                        <th>الاسم بالإنجليزية</th>
                        <th>الكود</th>
                        <th>الحالة</th>
                        <th>تاريخ الإنشاء</th>
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
                                <td data-title="الاسم بالعربية"><%# Eval("Title_Ar") %></td>
                                <td data-title="الاسم بالإنجليزية"><%# Eval("Title_En") %></td>
                                <td data-title="الكود"><%# Eval("Code") %></td>
                                <td data-title="الحالة">
                                    <%# If(Convert.ToBoolean(Eval("IsActive")), "فعال", "غير فعال") %>
                                </td>
                                <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate") %></td>

                                <td data-title="تعديل">
                                    <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                                        ID="btnEdit"
                                        CommandName="Edit"
                                        CommandArgument='<%# Eval("ID") %>'
                                        runat="server"
                                        ToolTip="تعديل">
                                            <i class="bx bx-edit-alt"></i>
                                    </asp:LinkButton>
                                </td>

                                <td data-title="حذف">
                                    <asp:LinkButton CssClass="btn btn-icon btn-label-danger"
                                        ID="btnDelete"
                                        CommandName="DeleteItem"
                                        CommandArgument='<%# Eval("ID") %>'
                                        runat="server"
                                        ToolTip="حذف"
                                        CausesValidation="false"
                                        OnClientClick="return confirm('هل أنت متأكد من حذف هذه الصلاحية؟');">
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
</div>

</asp:Content>