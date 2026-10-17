<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageBranches.aspx.vb" Inherits="CRM.ManageBranches" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- Branches table -->
                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">الفروع</h5>
                        </div>
                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server" CssClass="dt-button create-new btn btn-primary">
                                    <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">اضافة فرع جديد</span></span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>العلامة التجارية</th>
                                    <th>اسم الفرع بالعربية</th>
                                    <th>اسم الفرع بالانجليزية</th>
                                    <th>تاريخ الإنشاء</th>
                                     <th>QRCode</th>
                                  <%--  <th>تفعيل</th>--%>
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
                                              <td data-title="العلامة التجارية"><%# Eval("BrandTitle_Ar")%></td>
                                            <td data-title="اسم الفرع بالعربية"><%# Eval("Title_Ar")%></td>
                                            <td data-title="اسم الفرع بالانجليزية"><%# Eval("Title_En")%></td>
                                            <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate")%></td>
                                           <%-- <td data-title="تفعيل">
                                                <%# If(Eval("IsActive"), "مفعل", "غير مفعل") %>
                                            </td>--%>
                                             <td data-title="QRCode">
                                                    <asp:LinkButton CssClass="btn btn-icon btn-label-success" ID="lnkQRCode" CommandName="QRCode" CommandArgument='<%# Eval("ID")%>' runat="server" ToolTip="طباعة QRCode">    <i class="bx bx-qr"></i> </asp:LinkButton>
                                                </td>
                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit"
                                                    CommandName="Edit" CommandArgument='<%# Eval("ID")%>' runat="server" ToolTip="تعديل">
                                                    <i class="bx bx-edit-alt"></i>
                                                </asp:LinkButton>
                                            </td>
                                            <td data-title="حذف">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
    CommandName="DeleteItem"
    CommandArgument='<%# Eval("ID")%>'
    runat="server"
    ToolTip="حذف"
    CausesValidation="false"
    OnClientClick="return confirm('هل أنت متأكد من حذف هذا الفرع؟');">
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
                <!-- /Branches table -->
            </div>
        </div>
    </div>

</asp:Content>
