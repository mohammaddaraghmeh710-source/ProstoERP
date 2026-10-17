<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuideCategories.aspx.vb" Inherits="CRM.ManageWorkGuideCategories" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">إدارة تصنيفات دليل العمل</h5>

                <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="btn btn-primary" OnClick="btnAddNewItem_Click">
                    <i class="bx bx-plus me-sm-2"></i>
                    <span>إضافة تصنيف جديد</span>
                </asp:LinkButton>
            </div>

            <div class="card-body">

                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label">العلامة التجارية</label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged">
                        </asp:DropDownList>
                    </div>
                </div>

                <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                    <thead>
                        <tr>
                            <th>العلامة التجارية</th>
                            <th>التصنيف الأب</th>
                            <th>العنوان بالعربية</th>
                            <th>العنوان بالإنجليزية</th>
                            <th>الترتيب</th>
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
                                    <td data-title="العلامة التجارية"><%# Eval("Brand_Title_Ar")%></td>
                                    <td data-title="التصنيف الأب"><%# If(Eval("Parent_Title_Ar") Is Nothing, "-", Eval("Parent_Title_Ar"))%></td>
                                    <td data-title="العنوان بالعربية"><%# Eval("Title_Ar")%></td>
                                    <td data-title="العنوان بالإنجليزية"><%# Eval("Title_En")%></td>
                                    <td data-title="الترتيب"><%# Eval("Item_Order")%></td>
                                    <td data-title="الحالة"><%# If(Convert.ToBoolean(Eval("IsActive")), "فعال", "غير فعال")%></td>
                                    <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate")%></td>

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

                                    <td data-title="حذف">
                                        <asp:LinkButton CssClass="btn btn-icon btn-label-danger"
                                            ID="btnDelete"
                                            CommandName="DeleteItem"
                                            CommandArgument='<%# Eval("ID")%>'
                                            runat="server"
                                            ToolTip="حذف"
                                            CausesValidation="false"
                                            OnClientClick="return confirm('هل أنت متأكد من حذف هذا التصنيف؟');">
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