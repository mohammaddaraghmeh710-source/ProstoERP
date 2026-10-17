<%@ Page Title="" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Manage_News.aspx.vb"
    Inherits="CRM.Manage_News" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12">

                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">الأخبار</h5>
                        </div>

                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <asp:LinkButton ID="btnAddNew" OnClick="btnAddNew_Click" runat="server"
                                    CssClass="dt-button create-new btn btn-primary">
                                    <span>
                                        <i class="bx bx-plus me-sm-2"></i>
                                        <span class="d-none d-sm-inline-block">إضافة خبر جديد</span>
                                    </span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <!-- Search -->
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="ddlBrand" Text="العلامة التجارية" CssClass="form-label" /><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select" /></div>
                        <div class="row g-2 mb-3">
                            <div class="col-lg-6 col-md-6 col-12">
                                <asp:TextBox ID="txtKeyword" runat="server" CssClass="form-control"
                                    placeholder="بحث بالعنوان/النبذة (عربي/إنجليزي)..." />
                            </div>

                            <div class="col-lg-3 col-md-3 col-12">
                                <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select">
                                    <asp:ListItem Text="الكل" Value="-1" />
                                    <asp:ListItem Text="نشط" Value="1" />
                                    <asp:ListItem Text="غير نشط" Value="0" />
                                </asp:DropDownList>
                            </div>

                            <div class="col-lg-3 col-md-3 col-12 d-flex gap-2">
                                <asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-secondary w-50"
                                    OnClick="btnSearch_Click" ToolTip="البحث">
                                    <i class="bx bx-search"></i>
                                </asp:LinkButton>

                                <asp:LinkButton ID="btnClear" runat="server"
                                    CssClass="btn btn-outline-secondary w-50"
                                    OnClick="btnClear_Click"
                                    ToolTip="إعادة تعيين">
                                    <i class="bx bx-refresh"></i>
                                </asp:LinkButton>
                            </div>
                        </div>

                        <!-- Table -->
                        <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>العنوان</th>
                                    <th>العلامة التجارية</th>
                                    <th>التاريخ</th>
                                    <th>الحالة</th>
                                    <th>الترتيب</th>
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
                                            <td data-title="العنوان">
                                                <div class="fw-bold"><%# Eval("Title_AR") %></div>
                                                <small class="text-muted"><%# Eval("Title_En") %></small>
                                            </td>

                                            <td data-title="العلامة التجارية"><%#: If(Convert.IsDBNull(Eval("BrandName")), "غير محددة", Eval("BrandName")) %></td>
                                            <td data-title="التاريخ">
                                                <%# If(Eval("Date") Is Nothing, String.Format("{0:dd/MM/yyyy HH:mm}", Eval("AddedDate")), String.Format("{0:dd/MM/yyyy HH:mm}", Eval("Date"))) %>
                                            </td>

                                            <td data-title="الحالة">
                                                <%# If(Convert.ToBoolean(Eval("IsActive")), "نشط", "غير نشط") %>
                                            </td>

                                            <td data-title="الترتيب">
                                                <%# If(Eval("Item_Order") Is Nothing, "-", Eval("Item_Order")) %>
                                            </td>

                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                                                    ID="btnEdit" CommandName="Edit" CommandArgument='<%# Eval("PID") %>'
                                                    runat="server" ToolTip="تعديل \ مشاهدة">
                                                    <i class="bx bx-edit-alt"></i>
                                                </asp:LinkButton>
                                            </td>

                                            <td data-title="حذف">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
                                                    CommandName="DeleteItem"
                                                    CommandArgument='<%# Eval("PID") %>'
                                                    runat="server"
                                                    ToolTip="حذف"
                                                    CausesValidation="false"
                                                    OnClientClick="return confirm('هل أنت متأكد من حذف هذا الخبر؟');">
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