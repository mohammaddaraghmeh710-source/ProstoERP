<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageMaintenance_Companies.aspx.vb" Inherits="CRM.ManageMaintenance_Companies" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">شركات الصيانة</h5>
                        </div>

                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server"
                                    CssClass="dt-button create-new btn btn-primary">
                                    <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">إضافة شركة صيانة</span></span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">
                        <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>العنوان بالعربية</th>
                                    <th>العنوان بالإنجليزية</th>
                                    <th>تاريخ الإنشاء</th>
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
                                            <td data-title="العنوان بالعربية"><%# Eval("Title_Ar")%></td>
                                            <td data-title="العنوان بالإنجليزية"><%# Eval("Title_En")%></td>
                                            <td data-title="تاريخ الإنشاء">
                                                <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("AddedDate"))%>
                                            </td>

                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                                                    ID="btnEdit" CommandName="Edit" CommandArgument='<%# Eval("ID")%>'
                                                    runat="server" ToolTip="تعديل \ مشاهدة">
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
                                                    OnClientClick="return confirm('هل أنت متأكد من حذف شركة الصيانة؟');">
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
        </div>

    </div>

</asp:Content>
