<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageWorkGuide_Documents.aspx.vb" Inherits="CRM.ManageWorkGuide_Documents" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0">إدارة ملفات دليل العمل</h5>

                <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="btn btn-primary" OnClick="btnAddNewItem_Click">
                    <i class="bx bx-plus me-sm-2"></i>
                    <span>إضافة ملف جديد</span>
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
                        <label class="form-label">التصنيف</label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlCategory_SelectedIndexChanged">
                        </asp:DropDownList>
                    </div>
                </div>

                <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                    <thead>
                        <tr>
                            <th>العلامة التجارية</th>
                            <th>التصنيف</th>
                            <th>العنوان بالعربية</th>
                            <th>الحجم</th>
                            <th>الإصدار</th>
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
                                    <td data-title="العلامة التجارية"><%# Eval("Brand_Title_Ar") %></td>
                                    <td data-title="التصنيف"><%# Eval("Category_Title_Ar") %></td>
                                    <td data-title="العنوان بالعربية"><%# Eval("Title_Ar") %></td>
                                    <td data-title="الحجم"><%# FormatFileSize(Eval("File_Size")) %></td>

                                    <td data-title="الإصدار">
                                        <asp:LinkButton ID="btnVersions"
                                            runat="server"
                                            CssClass="btn btn-sm btn-label-info"
                                            CommandName="Versions"
                                            CommandArgument='<%# Eval("ID") %>'
                                            CausesValidation="false">
                                            <%# "V" & Eval("Version_No").ToString() %>
                                        </asp:LinkButton>
                                    </td>

                                    <td data-title="الحالة"><%# If(Convert.ToBoolean(Eval("IsActive")), "فعال", "غير فعال") %></td>
                                    <td data-title="تاريخ الإنشاء"><%# Eval("AddedDate") %></td>

                                    <td data-title="تعديل">
                                        <asp:LinkButton CssClass="btn btn-icon btn-label-secondary"
                                            ID="btnEdit"
                                            CommandName="Edit"
                                            CommandArgument='<%# Eval("ID") %>'
                                            runat="server"
                                            CausesValidation="false"
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
                                            OnClientClick="return confirm('هل أنت متأكد من حذف هذا الملف؟');">
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

                <asp:HiddenField ID="hfSelectedDocumentID" runat="server" />

            </div>
        </div>

    </div>


    <!-- Versions Modal -->
    <div class="modal fade" id="versionsModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-centered" role="document">
            <div class="modal-content">

                <div class="modal-header">
                    <h5 class="modal-title">النسخ القديمة للملف</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body">

                    <asp:ListView ID="lstVersions" runat="server">
                        <LayoutTemplate>
                            <table class="table table-bordered table-striped">
                                <thead>
                                    <tr>
                                        <th>رقم النسخة</th>
                                        <th>تاريخ الحفظ</th>
                                      
                                        <th>ملاحظات</th>
                                        <th>مشاهدة</th>
                                        <th>استرجاع</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <asp:PlaceHolder runat="server" ID="ItemPlaceHolder"></asp:PlaceHolder>
                                </tbody>
                            </table>
                        </LayoutTemplate>

                        <ItemTemplate>
                            <tr>
                                <td><%# "V" & Eval("Version_No").ToString() %></td>
                                <td><%# Eval("AddedDate") %></td>
                               
                                <td><%# If(Eval("Change_Notes") Is Nothing, "-", Eval("Change_Notes")) %></td>

                                <td>
                                    <a class="btn btn-sm btn-label-primary"
                                        target="_blank"
                                        href='<%# "/Modules/WorkGuide_Documents/ViewWorkGuideFile.aspx?type=version&id=" & Eval("ID").ToString() %>'>
                                        مشاهدة الملف
                                    </a>
                                </td>

                                <td>
                                    <asp:LinkButton ID="btnRestoreVersion"
                                        runat="server"
                                        CssClass="btn btn-sm btn-label-warning"
                                        CommandName="RestoreVersion"
                                        CommandArgument='<%# Eval("ID") %>'
                                        CausesValidation="false"
                                        OnClientClick="return confirm('هل أنت متأكد من استرجاع هذه النسخة؟ سيتم حفظ النسخة الحالية ضمن النسخ القديمة.');">
                                        استرجاع
                                    </asp:LinkButton>
                                </td>
                            </tr>
                        </ItemTemplate>

                        <EmptyDataTemplate>
                            <div class="alert alert-warning mb-0">
                                لا توجد نسخ قديمة لهذا الملف.
                            </div>
                        </EmptyDataTemplate>
                    </asp:ListView>

                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إغلاق</button>
                </div>

            </div>
        </div>
    </div>

</asp:Content>