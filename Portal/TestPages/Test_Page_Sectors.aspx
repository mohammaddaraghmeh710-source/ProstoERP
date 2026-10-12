<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Page_Sectors.aspx.vb" Inherits="CRM.Test_Page_Sectors" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* تحسين عرض قائمة الموظفين على الموبايل */
        .employee-item {
            border-bottom: 1px solid #f0f2f4;
            padding-bottom: 0.5rem;
            margin-bottom: 0.75rem;
        }

        .employee-item:last-child {
            border-bottom: none;
            margin-bottom: 0;
        }

        /* جعل الكروت خفيفة على الموبايل */
        @media (max-width: 767.98px) {
            .stats-card h4 {
                font-size: 1.1rem;
            }
            .stats-card span {
                font-size: 0.8rem;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <!-- ======= الكروت الإحصائية أعلى الصفحة ======= -->
        <div class="row g-4 mb-4">
            <!-- إجمالي الموظفين -->
            <div class="col-sm-4 col-xl-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <div class="d-flex align-items-start justify-content-between">
                            <div class="content-left">
                                <span>عدد الموظفين الكلي</span>
                                <div class="d-flex align-items-end mt-2">
                                    <h4 class="mb-0 me-2">
                                        <asp:Label ID="lblTotalEmployees" runat="server" Text="0"></asp:Label>
                                    </h4>
                                    <small class="text-success">
                                        (<asp:Label ID="lblTotalEmployeesSmall" runat="server" Text="0"></asp:Label>)
                                    </small>
                                </div>
                                <small>
                                    <asp:Label ID="lblBranchNameCard1" runat="server" Text=""></asp:Label>
                                </small>
                            </div>
                            <span class="badge bg-label-primary rounded p-2">
                                <i class="bx bx-group bx-sm"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- الموظفين الفعّالين -->
            <div class="col-sm-4 col-xl-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <div class="d-flex align-items-start justify-content-between">
                            <div class="content-left">
                                <span>عدد الموظفين الفعال</span>
                                <div class="d-flex align-items-end mt-2">
                                    <h4 class="mb-0 me-2">
                                        <asp:Label ID="lblActiveEmployees" runat="server" Text="0"></asp:Label>
                                    </h4>
                                    <small class="text-success">
                                        (<asp:Label ID="lblActiveEmployeesSmall" runat="server" Text="0"></asp:Label>)
                                    </small>
                                </div>
                                <small>
                                    <asp:Label ID="lblBranchNameCard2" runat="server" Text=""></asp:Label>
                                </small>
                            </div>
                            <span class="badge bg-label-success rounded p-2">
                                <i class="bx bx-user-check bx-sm"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- الموظفين المجازين -->
            <div class="col-sm-4 col-xl-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <div class="d-flex align-items-start justify-content-between">
                            <div class="content-left">
                                <span>عدد الموظفين المجازين</span>
                                <div class="d-flex align-items-end mt-2">
                                    <h4 class="mb-0 me-2">
                                        <asp:Label ID="lblOnLeaveEmployees" runat="server" Text="0"></asp:Label>
                                    </h4>
                                    <small class="text-danger">
                                        (<asp:Label ID="lblOnLeaveEmployeesSmall" runat="server" Text="0"></asp:Label>)
                                    </small>
                                </div>
                                <small>
                                    <asp:Label ID="lblBranchNameCard3" runat="server" Text=""></asp:Label>
                                </small>
                            </div>
                            <span class="badge bg-label-danger rounded p-2">
                                <i class="bx bx-user-minus bx-sm"></i>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ======= الكارد الرئيسي: تحديد الموظفين لكل قسم ======= -->

        <div class="card cvv-code-mask" style="padding: 15px;">
            <div class="card-header flex-column flex-md-row">
                <div class="d-flex align-items-md-end align-items-sm-start align-items-center justify-content-md-between justify-content-start  flex-md-row flex-column gap-4">
                    <div class="user-profile-info">
                        <h4>تحديد الموظفين لكل قسم</h4>

                        <ul class="list-inline mb-0 mt-2 d-flex align-items-center flex-wrap justify-content-sm-start justify-content-center gap-2">
                           <%-- <li class="list-inline-item fw-semibold badge bg-label-secondary rounded p-2">
                                <i class="bx bx-user"></i>
                                <span>اسم المدير:</span>
                                <asp:Label ID="lblManagerName" runat="server"></asp:Label>
                            </li>--%>
                            <li class="list-inline-item fw-semibold bg-label-secondary rounded p-2">
                                <i class="bx bx-map"></i>
                                <asp:Label ID="lblBranchNameHeader" runat="server"></asp:Label>
                            </li>
                            <li class="list-inline-item fw-semibold bg-label-secondary rounded p-2">
                                <i class="bx bx-calendar-alt"></i>
                                <asp:Label ID="lblTodayDate" runat="server"></asp:Label>
                            </li>
                        </ul>
                    </div>

                    <!-- رسالة نجاح/خطأ عامة -->
                    <asp:Panel ID="pnlPageMessage" runat="server" Visible="false"
                        CssClass="alert alert-success mb-0 py-2 px-3">
                        <asp:Label ID="lblPageMessage" runat="server"></asp:Label>
                    </asp:Panel>
                </div>
            </div>

            <div class="row">
                <!-- ======= القائمة الجانبية: الموظفون بدون قسم/مسمى ======= -->
                <div class="col-xl-4 col-lg-5 col-md-5 order-2 order-md-1">
                    <div class="row m-1">
                        <div class="card card-action mb-4">
                            <div class="card-header align-items-center">
                                <h5 class="card-action-title mb-0">الموظفون بدون قسم / مسمى وظيفي</h5>
                            </div>
                            <div class="card-body" style="max-height: 480px; overflow-y: auto;">
                                <asp:Panel ID="pnlNoUnassignedEmployees" runat="server" Visible="false"
                                    CssClass="alert alert-info mb-0">
                                    لا يوجد موظفين بدون قسم أو مسمى وظيفي في هذا الفرع.
                                </asp:Panel>

                                <asp:Repeater ID="rptUnassignedEmployees" runat="server" OnItemCommand="rptUnassignedEmployees_ItemCommand">
                                    <ItemTemplate>
                                        <div class="employee-item d-flex align-items-start">
                                            <div class="d-flex align-items-start">
                                                <div class="avatar me-3">
                                                    <img src='<%# If(String.IsNullOrEmpty(Eval("UserImage")), "../../assets/img/avatars/2.png", Eval("UserImage")) %>'
                                                         alt="Avatar" class="rounded-circle" style="width:40px;height:40px;object-fit:cover;">
                                                </div>
                                                <div class="mt-1">
                                                    <h6 class="mb-0"><%# Eval("FullName_Ar") %></h6>
                                                    <small class="text-muted">موظف جديد</small>
                                                </div>
                                            </div>
                                            <div class="ms-auto">
                                                <asp:LinkButton ID="btnEditEmployee" runat="server"
                                                    CssClass="btn btn-label-primary p-1 btn-sm"
                                                    CommandName="EditEmployee"
                                                    CommandArgument='<%# Eval("ID") %>'>
                                                    <i class="bx bx-edit-alt me-1"></i>تعديل
                                                </asp:LinkButton>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ======= الأقسام وكروت عدد الموظفين + الصور ======= -->
                <div class="col-xl-8 col-lg-7 col-md-7 order-1 order-md-2">
                    <div class="row g-4">
                        <asp:Repeater ID="rptDepartments" runat="server" OnItemDataBound="rptDepartments_ItemDataBound">
                            <ItemTemplate>
                                <div class="col-xl-6 col-lg-12 col-md-12">
                                    <div class="card">
                                        <div class="card-body">
                                            <div class="d-flex justify-content-between mb-2">
                                                <h6 class="fw-normal">
                                                    العدد
                                                    <%# Eval("EmployeesCount") %> موظف
                                                </h6>
                                                <ul class="list-unstyled d-flex align-items-center avatar-group mb-0">
                                                    <asp:Repeater ID="rptDeptEmployees" runat="server">
                                                        <ItemTemplate>
                                                            <li data-bs-toggle="tooltip" data-popup="tooltip-custom"
                                                                data-bs-placement="top"
                                                                class="avatar avatar-sm pull-up"
                                                                title='<%# Eval("FullName_Ar") %>'>
                                                                <img class="rounded-circle"
                                                                     src='<%# If(String.IsNullOrEmpty(Eval("UserImage")), "../../assets/img/avatars/2.png", Eval("UserImage")) %>'
                                                                     alt="Avatar"
                                                                     style="object-fit:cover;">
                                                            </li>
                                                        </ItemTemplate>
                                                    </asp:Repeater>
                                                </ul>
                                            </div>
                                            <div class="d-flex justify-content-between align-items-end">
                                                <div class="role-heading">
                                                    <h5 class="mb-1"><%# Eval("DeptName") %></h5>
                                                    <small class="text-muted">قسم تابع لفرعك</small>
                                                </div>
                                                <span class="text-muted">
                                                    <i class="bx bx-grid-alt"></i>
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlNoDepartments" runat="server" Visible="false"
                            CssClass="alert alert-warning mx-3 mb-3">
                            لا توجد أقسام مرتبطة بهذا الفرع حتى الآن.
                        </asp:Panel>
                    </div>
                </div>
            </div>
        </div>

        <!--/ Main Card -->
    </div>

    <!-- ====================== Popup: تعيين قسم/مسمى/شفت للموظف ====================== -->

    <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;">

        <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">
                        <asp:Literal runat="server" ID="lblPopupTitle2">تعيين الموظف إلى قسم</asp:Literal>
                    </h5>

                    <asp:Button ID="btnClosePopup" runat="server" CssClass="btn-close" OnClick="btnClosePopup_Click" />
                </div>
                <div class="modal-body">
                    <asp:Label ID="lblPopupError" runat="server" CssClass="text-danger d-block mb-2"></asp:Label>

                    <div class="row">
                        <div class="col-xl-12 col-lg-12 col-md-12 mb-3">
                            <label class="form-label">الاسم</label>
                            <asp:TextBox ID="txtPopupEmployeeName" runat="server"
                                CssClass="form-control" ReadOnly="true"></asp:TextBox>
                        </div>
                    </div>

                    <div class="row g-2">
                        <div class="col-xl-6 col-lg-6 col-md-12 mb-3">
                            <label class="form-label">الفرع</label>
                            <asp:TextBox ID="txtPopupBranchName" runat="server"
                                CssClass="form-control" ReadOnly="true"></asp:TextBox>
                        </div>
                        <div class="col-xl-6 col-lg-6 col-md-12 mb-3">
                            <label class="form-label">القسم</label>
                            <asp:DropDownList ID="ddlPopupDepartment" runat="server"
                                CssClass="select2 form-select"
                                AutoPostBack="True"
                                OnSelectedIndexChanged="ddlPopupDepartment_SelectedIndexChanged">
                            </asp:DropDownList>
                        </div>
                    </div>

                    <div class="row g-2">
                        <div class="col-xl-6 col-lg-6 col-md-12 mb-3">
                            <label class="form-label">المسمى الوظيفي</label>
                            <asp:DropDownList ID="ddlPopupJobTitle" runat="server"
                                CssClass="select2 form-select">
                            </asp:DropDownList>
                        </div>

                        <div class="col-xl-6 col-lg-6 col-md-12 mb-3">
                            <label class="form-label">فترة العمل (الشفت)</label>
                            <asp:DropDownList ID="ddlPopupShift" runat="server"
                                CssClass="select2 form-select">
                            </asp:DropDownList>
                        </div>
                    </div>

                    <asp:HiddenField ID="hdPopupEmployeeID" runat="server" />
                </div>

                <div class="modal-footer">
                    <asp:Button ID="btnSaveEmployeeSector" runat="server"
                        CssClass="btn btn-primary" Text="حفظ"
                        OnClick="btnSaveEmployeeSector_Click" />
                    <asp:Button ID="btnCancelPopup" runat="server"
                        CssClass="btn btn-label-secondary" Text="إغلاق"
                        OnClick="btnClosePopup_Click" CausesValidation="false" />
                </div>
            </div>
        </div>
    </asp:Panel>

    <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" PopupControlID="PanelPopUp"
        BackgroundCssClass="OpacityBG" runat="server" TargetControlID="LBLPOP">
    </cc11:ModalPopupExtender>
    <asp:Label ID="LBLPOP" runat="server" />

</asp:Content>
