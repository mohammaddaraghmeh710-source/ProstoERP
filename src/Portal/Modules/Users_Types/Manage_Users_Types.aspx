<%@ Page Title="أنواع الموظفين" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Manage_Users_Types.aspx.vb" Inherits="CRM.Manage_Users_Types" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server" />
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y" dir="rtl">
        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <h5 class="card-title mb-0">أنواع الموظفين</h5>
                <a class="btn btn-primary" href="Add_Users_Types.aspx"><i class="bx bx-plus me-2"></i>إضافة نوع جديد</a>
            </div>
            <div class="card-body">
                <asp:Literal ID="litMessage" runat="server" />
                <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="row g-2 mb-3">
                    <div class="col-md-6">
                        <asp:Label runat="server" AssociatedControlID="txtKeyword" CssClass="form-label" Text="البحث بالاسم" />
                        <asp:TextBox ID="txtKeyword" runat="server" CssClass="form-control" MaxLength="200" placeholder="الاسم بالعربية أو الإنجليزية" />
                    </div>
                    <div class="col-md-3">
                        <asp:Label runat="server" AssociatedControlID="ddlStatus" CssClass="form-label" Text="الحالة" />
                        <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select">
                            <asp:ListItem Text="الكل" Value="-1" />
                            <asp:ListItem Text="فعال" Value="1" />
                            <asp:ListItem Text="موقوف" Value="0" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-md-3 d-flex gap-2 align-items-end">
                        <asp:LinkButton ID="btnSearch" runat="server" CssClass="btn btn-secondary" OnClick="btnSearch_Click" Text="بحث" />
                        <asp:LinkButton ID="btnClear" runat="server" CssClass="btn btn-outline-secondary" OnClick="btnClear_Click" Text="إعادة تعيين" />
                    </div>
                </asp:Panel>
                <div class="table-responsive">
                    <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                        <thead><tr><th>الرقم</th><th>الاسم بالعربية</th><th>الاسم بالإنجليزية</th><th>الترتيب</th><th>الحالة</th><th>تاريخ الإنشاء</th><th>الإجراءات</th></tr></thead>
                        <tbody>
                            <asp:ListView ID="lstData" runat="server" OnItemCommand="lstData_ItemCommand">
                                <LayoutTemplate><asp:PlaceHolder ID="ItemPlaceHolder" runat="server" /></LayoutTemplate>
                                <ItemTemplate>
                                    <tr>
                                        <td data-title="الرقم"><%#: Eval("ID")%></td>
                                        <td data-title="الاسم بالعربية"><%#: Eval("Title_Ar")%></td>
                                        <td data-title="الاسم بالإنجليزية"><%#: Eval("Title_En")%></td>
                                        <td data-title="الترتيب"><%#: Eval("Item_Order")%></td>
                                        <td data-title="الحالة"><%#: If(IsActiveValue(Eval("IsActive")), "فعال", "موقوف")%></td>
                                        <td data-title="تاريخ الإنشاء"><%#: Eval("AddedDate", "{0:dd/MM/yyyy HH:mm}")%></td>
                                        <td data-title="الإجراءات">
                                            <asp:HyperLink runat="server" CssClass="btn btn-sm btn-label-secondary" Text="تعديل" NavigateUrl='<%# "Edit_Users_Types.aspx?ID=" & Eval("ID")%>' />
                                            <asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-warning" CommandName="Deactivate" CommandArgument='<%# Eval("ID")%>' Visible='<%# IsActiveValue(Eval("IsActive"))%>' Text="إيقاف" CausesValidation="false" />
                                            <asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-success" CommandName="Activate" CommandArgument='<%# Eval("ID")%>' Visible='<%# Not IsActiveValue(Eval("IsActive"))%>' Text="تفعيل" CausesValidation="false" />
                                            <asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-danger" CommandName="DeleteItem" CommandArgument='<%# Eval("ID")%>' Text="حذف" CausesValidation="false" OnClientClick="return confirm('هل تريد حذف هذا النوع؟');" />
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:ListView>
                        </tbody>
                    </table>
                </div>
                <asp:Label ID="lblEmpty" runat="server" CssClass="d-block text-center text-muted py-3" Text="لا توجد عناصر مطابقة للبحث." Visible="false" />
            </div>
        </div>
    </div>
</asp:Content>