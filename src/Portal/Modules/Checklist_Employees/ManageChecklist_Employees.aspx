<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageChecklist_Employees.aspx.vb" Inherits="CRM.ManageChecklist_Employees" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <!-- نفترض أن ScriptManager موجود في Site.Master -->

    <!-- UpdatePanel لتجنّب الـ Full Refresh -->
    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div class="container-xxl flex-grow-1 container-p-y">

                <div class="row gy-4">
                    <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                        <div class="card cvv-code-mask mb-4">

                            <!-- Header + زر إضافة -->
                            <div class="card-header flex-column flex-md-row">
                                <div class="head-label">
                                    <h5 class="card-title mb-0">إدارة قائمة التقييم</h5>
                                </div>
                                <div class="dt-action-buttons text-end pt-3 pt-md-0">
                                    <div class="dt-buttons">
                                        <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="dt-button create-new btn btn-primary" OnClick="btnAddNewItem_Click">
                                            <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">إضافة بند جديد</span></span>
                                        </asp:LinkButton>
                                    </div>
                                </div>
                            </div>

                            <div class="card-body">

                                <!-- فلاتر البحث -->
                                <div class="row g-3 mb-4">

                                    <div class="col-md-3">
                                        <label class="form-label">العلامة التجارية</label>
                                        <asp:DropDownList ID="ddlBrands" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlBrands_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                    <div class="col-md-3">
                                        <label class="form-label">الفرع</label>
                                        <asp:DropDownList ID="ddlBranch" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlBranch_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                    <div class="col-md-3">
                                        <label class="form-label">القسم</label>
                                        <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlDepartment_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                    <div class="col-md-3">
                                        <label class="form-label">المحطة التعريفية</label>
                                        <asp:DropDownList ID="ddlJobTitle" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlJobTitle_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                                                         <!-- فلتر البند الوظيفي (اختياري) -->
                                     <div class="col-md-3" runat="server" visible="false">
                                       <label class="form-label">البند الوظيفي (اختياري)</label>
                                        <asp:DropDownList ID="ddlJobTitleItem" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlJobTitleItem_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                    
                                     <div class="col-md-3" runat="server" visible="false">
                                        <label class="form-label">فترة العمل</label>
                                        <asp:DropDownList ID="ddlShift" runat="server" CssClass="form-select"></asp:DropDownList>
                                    </div>
                               
                                </div>

                                <div class="row g-3 mb-4" >
                                   

                                     <div class="col-md-4">
                                       <label class="form-label">نوع الموظف</label>
                                        <asp:DropDownList ID="ddlUsersType" runat="server" CssClass="form-select"
                                            AutoPostBack="true"
                                            OnSelectedIndexChanged="ddlUsersType_SelectedIndexChanged">
                                        </asp:DropDownList>
                                    </div>

                                    <div class="col-md-8">
                                        <label class="form-label">بحث بالعنوان / الوصف</label>
                                        <div class="input-group">
                                            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="اكتب جزء من العنوان أو الوصف"></asp:TextBox>
                                            <button type="button" class="btn btn-secondary"
                                                onclick="__doPostBack('<%= btnSearch.UniqueID %>','')">
                                                بحث
                                            </button>
                                        </div>
                                    </div>
                                </div>

                               

                                <!-- الجدول -->
                                <table id="ERPTable" class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                                    <thead>
                                        <tr>
                                            <th>العنوان</th>
                                            <th>الهيكل التنظيمي</th>
                                            <th>نوع الموظف</th>
                                            <th>الوزن</th>
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
                                                    <!-- العنوان: عربي + إنجليزي -->
                                                    <td data-title="العنوان">
                                                        <div><%# Eval("Title_Ar") %></div>
                                                        <small class="text-muted d-block"><%# Eval("Title_En") %></small>
                                                    </td>

                                                    <!-- الهيكل التنظيمي: بروستو / الفرع / القسم / المحطة التعريفية / الوردية -->
                                                    <td data-title="الهيكل التنظيمي">
                                                        بروستو /
                                                        <%# Eval("BranchTitle") %> /
                                                        <%# Eval("DepartmentTitle") %> /
                                                        <%# Eval("JobTitleTitle") %> /
                                                        <%# Eval("ShiftTitle") %>
                                                    </td>

                                                    <!-- نوع الموظف -->
                                                    <td data-title="نوع الموظف">
                                                        <%# Eval("UsersTypesTitle") %>
                                                    </td>

                                                    <!-- الوزن -->
                                                    <td data-title="الوزن">
                                                        <%# String.Format("{0:0.##}", Eval("Weight")) %>
                                                    </td>

                                                    <!-- تعديل -->
                                                    <td data-title="تعديل">
                                                        <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit"
                                                            CommandName="Edit" CommandArgument='<%# Eval("ID") %>' runat="server" ToolTip="تعديل">
                                                            <i class="bx bx-edit-alt"></i>
                                                        </asp:LinkButton>
                                                    </td>

                                                    <!-- حذف -->
                                                    <td data-title="حذف">
                                                        <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
                                                            CommandName="DeleteItem"
                                                            CommandArgument='<%# Eval("ID") %>'
                                                            runat="server"
                                                            ToolTip="حذف"
                                                            CausesValidation="false"
                                                            OnClientClick="return confirm('هل أنت متأكد من حذف هذا البند؟');">
                                                            <i class="bx bx-trash-alt"></i>
                                                        </asp:LinkButton>
                                                    </td>
                                                </tr>
                                            </ItemTemplate>

                                            <EmptyDataTemplate>
                                                <tr>
                                                    <td colspan="6" class="text-center text-muted py-3">
                                                        لا يوجد محتوى لعرضه حالياً
                                                    </td>
                                                </tr>
                                            </EmptyDataTemplate>
                                        </asp:ListView>
                                    </tbody>
                                </table>

                                <!-- زر البحث المخفي -->
                                <asp:Button ID="btnSearch" runat="server" Text="بحث" CssClass="d-none" OnClick="btnSearch_Click" />

                            </div>

                        </div>
                    </div>
                </div>
            </div>

        </ContentTemplate>
    </asp:UpdatePanel>

    <!-- UpdateProgress لعرض الـ Loading Spinner أثناء أي Async PostBack -->
    <asp:UpdateProgress ID="updProg" runat="server" AssociatedUpdatePanelID="upMain" DisplayAfter="100">
        <ProgressTemplate>
            <div class="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center bg-dark bg-opacity-25" style="z-index: 1050;">
                <div class="spinner-border" role="status">
                    <span class="visually-hidden">جار التحميل...</span>
                </div>
            </div>
        </ProgressTemplate>
    </asp:UpdateProgress>

</asp:Content>
