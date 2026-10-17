<%@ Page Title="تقييم الموظف" Language="vb" AutoEventWireup="false" Async="true" AsyncTimeout="150" MasterPageFile="~/Site.Master" CodeBehind="MyProfile.aspx.vb" Inherits="CRM.MyProfile" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .employee-hover-banner {
            display: none !important;
        }

        .task-note-card {
            border-radius: .75rem;
        }

        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .note-meta-small {
            font-size: .8rem;
        }

        .erp-profile-spacing {
            margin-right: 0.5rem !important;
            margin-left: 0.5rem !important;
        }

        .employee-header-card {
            background: linear-gradient(135deg, #f4f5fb 0%, #ffffff 40%, #fef9f5 100%);
            border-radius: 1rem;
            border: 1px solid #e5e7eb;
        }

        .employee-avatar {
            width: 84px;
            height: 84px;
            object-fit: cover;
            border-radius: 1rem;
            border: 3px solid #ffffff;
            box-shadow: 0 6px 18px rgba(15, 23, 42, 0.15);
        }

        .employee-main h4 {
            font-size: 1.15rem;
            font-weight: 700;
            color: #111827;
            margin-bottom: .35rem;
        }

        .employee-meta {
            display: flex;
            flex-wrap: wrap;
            gap: .35rem .75rem;
            font-size: .85rem;
            color: #4b5563;
        }

            .employee-meta .meta-item i {
                color: #9ca3af;
                margin-left: .25rem;
            }

        .employee-last-eval {
            min-width: 160px;
        }

            .employee-last-eval span {
                font-size: .8rem;
            }

            .employee-last-eval .last-eval-date {
                font-size: .95rem;
                font-weight: 600;
                color: #111827;
            }

        @media (max-width: 576px) {
            .employee-header-card .card-body {
                text-align: center;
            }

            .employee-meta {
                justify-content: center;
            }

            .employee-last-eval {
                text-align: center !important;
            }
        }

        /* Gauge */
        .branch-gauge {
            --value: 0;
            width: 160px;
            height: 160px;
            border-radius: 50%;
            background: conic-gradient(#5f8bff calc(var(--value)*3.6deg), #ff5b5c 0, #e9ecef 0);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto .75rem;
        }

        .branch-gauge-inner {
            width: 75%;
            height: 75%;
            border-radius: 50%;
            background: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            gap: .15rem;
        }

            .branch-gauge-inner .percentage {
                font-size: 1.8rem;
                font-weight: 600;
                color: #32475c;
            }

            .branch-gauge-inner small {
                font-size: .8rem;
            }

        .branch-gauge.gauge-green {
            background: conic-gradient(#28c76f calc(var(--value)*3.6deg), #e9ecef 0);
        }

        .branch-gauge.gauge-yellow {
            background: conic-gradient(#ffcc00 calc(var(--value)*3.6deg), #e9ecef 0);
        }

        .branch-gauge.gauge-red {
            background: conic-gradient(#ff4d4f calc(var(--value)*3.6deg), #e9ecef 0);
        }

        .brand-logo {
            width: 40px;
            height: 40px;
            object-fit: cover;
            border-radius: 8px;
        }

        .task-title {
            font-weight: 600;
            color: #32475c;
        }

        .task-sub {
            font-size: .85rem;
            color: #6c757d;
        }

        .violation-badges {
            gap: .4rem;
        }

        .badge-chip {
            padding: .4rem .6rem;
            border-radius: 5px;
            font-weight: 500;
            font-size: .8rem;
        }

        .badge-danger-soft {
            background: #ffe4e6;
            color: #d2242a;
        }

        .badge-warning-soft {
            background: #fff4d6;
            color: #9a6b00;
        }

        .badge-primary-soft {
            background: #e6ecff;
            color: #3056ff;
        }

        .badge-info-soft {
            background: #e7f6ff;
            color: #117ea6;
        }

        .metric-pill {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: .5rem .75rem;
            border-radius: .5rem;
            background-color: #f5f5f9;
            font-size: .85rem;
            margin-bottom: .4rem;
        }

            .metric-pill strong {
                font-size: .9rem;
            }

        .checklist-summary-item {
            border-radius: .5rem;
            background-color: #f9fafb;
        }

        .summary-danger {
            background-color: #ffe4e6;
            border: 1px solid #fecaca;
        }

        .summary-warning {
            background-color: #fff4d6;
            border: 1px solid #fde68a;
        }

        .summary-normal {
            background-color: #e6ffed;
            border: 1px solid #bbf7d0;
        }

        .checklist-summary-item .badge {
            background-color: #ffffff;
            color: #111827;
            border: 1px dashed rgba(148, 163, 184, 0.6);
        }

        .attachment-img {
            max-height: 420px;
            object-fit: contain;
            width: 100%;
        }

        @media (max-width: 576px) {
            .attachment-img {
                max-height: 260px;
            }

            .user-profile-header {
                flex-direction: column !important;
                text-align: center;
            }
        }

        #attachmentsCarousel .carousel-control-prev, #attachmentsCarousel .carousel-control-next {
            display: flex !important;
            align-items: center;
            justify-content: center;
            opacity: 1 !important;
            width: 3rem;
        }

        #attachmentsCarousel .carousel-control-prev-icon, #attachmentsCarousel .carousel-control-next-icon {
            background-color: rgba(0, 0, 0, 0.45);
            border-radius: 50%;
            width: 2.4rem;
            height: 2.4rem;
            background-size: 1.3rem 1.3rem;
        }

        .form-label-sm {
            font-size: .8rem;
            margin-bottom: .15rem;
        }

        .status-badge {
            font-size: .75rem;
            border-radius: 3px;
            padding: .15rem .6rem;
            border-width: 1px;
            border-style: solid;
        }

        .status-open {
            background-color: #fee2e2;
            color: #b91c1c;
            border-color: #fecaca;
        }

        .status-closed {
            background-color: #dcfce7;
            color: #166534;
            border-color: #bbf7d0;
        }

        /* ========== Modal checklist rows ========== */
        .ce-row {
            border: 1px solid #eef2f7;
            border-radius: .6rem;
            padding: .65rem .75rem;
        }

            .ce-row:hover {
                background: #fbfcfe;
            }

        .ce-title {
            font-weight: 700;
            color: #1f2937;
        }

        .ce-brief {
            font-size: .85rem;
            color: #6b7280;
        }

        .ce-right {
            display: flex;
            align-items: center;
            gap: .6rem;
        }

        .ce-cat {
            font-size: .75rem;
            padding: .25rem .5rem;
            border-radius: 6px;
            border: 1px solid #e5e7eb;
            background: #f9fafb;
            color: #374151;
        }

        .ce-weight {
            font-size: .75rem;
            padding: .25rem .5rem;
            border-radius: 6px;
            border: 1px dashed rgba(148,163,184,.6);
            background: #fff;
        }

        .ce-check {
            transform: scale(1.15);
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

        <!-- Header -->
        <div class="row">
            <div class="col-12">
                <div class="card mb-4 employee-header-card">
                    <div class="card-body d-flex flex-column flex-md-row align-items-center justify-content-between gap-3">
                        <div class="d-flex align-items-center gap-3 flex-grow-1 flex-wrap justify-content-center justify-content-md-start">
                            <div class="avatar-wrapper">
                                <img id="imgEmployee" runat="server" src="/assets/img/avatars/13.png" class="employee-avatar" alt="صورة الموظف" />
                            </div>
                            <div class="employee-main">
                                <h4 class="mb-0">
                                    <asp:Label ID="lblEmployeeName" runat="server" Text="اسم الموظف"></asp:Label></h4>
                                <div class="employee-meta mt-2">
                                    <div class="meta-item"><i class="bx bx-id-card"></i>رقم الموظف:
                                        <asp:Literal ID="litEmployeeCode" runat="server" /></div>
                                    <div class="meta-item"><i class="bx bx-briefcase-alt"></i>
                                        <asp:Literal ID="litDeptJob" runat="server" /></div>
                                    <div class="meta-item"><i class="bx bx-store-alt"></i>
                                        <asp:Literal ID="litBrandBranch" runat="server" /></div>
                                </div>
                            </div>
                        </div>

                        <div class="text-center text-md-end">
                            <div class="employee-last-eval mb-2">
                                <span class="text-muted d-block mb-1">آخر تقييم</span>
                                <span class="last-eval-date d-block">
                                    <asp:Literal ID="litLastEvalDate" runat="server" Text="-"></asp:Literal></span>
                            </div>

                            <!-- ✅ زر تقييم الموظف -->
                            <asp:Button ID="btnOpenEmployeeEvaluation" runat="server"
                                CssClass="btn btn-sm btn-primary"
                                Text="تقييم الموظف"
                                OnClick="btnOpenEmployeeEvaluation_Click" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <asp:Panel ID="pnlAttendance" runat="server" Visible="false" CssClass="card mb-4">
            <div class="card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                <h5 class="card-title mb-0">حركات الدوام اليوم</h5>
                <asp:HyperLink ID="lnkAttendance" runat="server" CssClass="btn btn-outline-primary" Text="عرض سجل الدوام" />
            </div>
            <div class="card-body">
                <asp:Literal ID="litAttendanceMessage" runat="server" />
                <div class="table-responsive"><table class="table table-bordered card-list-table mb-0">
                    <thead><tr><th>وقت الحركة</th><th>الحركة</th><th>الجهاز</th></tr></thead><tbody>
                    <asp:Repeater ID="rptTodayAttendance" runat="server"><ItemTemplate><tr>
                        <td data-title="وقت الحركة"><%#: Eval("PunchTime")%></td><td data-title="الحركة"><%#: Eval("PunchState")%></td><td data-title="الجهاز"><%#: Eval("Terminal")%></td>
                    </tr></ItemTemplate></asp:Repeater></tbody>
                </table></div>
                <asp:Label ID="lblNoAttendance" runat="server" CssClass="d-block text-center text-muted py-3" Text="لا توجد حركات دوام لهذا اليوم." Visible="false" />
            </div>
        </asp:Panel>

        <!-- Main -->
        <div class="row">
            <!-- Left -->
            <div class="col-lg-4 col-md-12 mb-4">

                <!-- تقييم الموظف -->
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تقييم الموظف</h5>
                    </div>
                    <div class="card-body">

                        <div class="text-center mb-3">
                            <div id="divEmployeeGauge" runat="server" class="branch-gauge" data-value="0">
                                <div class="branch-gauge-inner">
                                    <span class="percentage">
                                        <asp:Literal ID="litEmployeeScore" runat="server" Text="100%"></asp:Literal></span>
                                    <small class="text-muted">النتيجة الإجمالية</small>
                                </div>
                            </div>
                        </div>

                        <!-- ✅ تعديل العنوان -->
                        <div class="metric-pill">
                            <span>عدد المهام غير المنجزة</span>
                            <strong>
                                <asp:Literal ID="litOpenTasksCount" runat="server" Text="0" /></strong>
                        </div>

                        <!-- ✅ عنصر جديد: عدد المخالفات (من Evaluations_Employees) -->
                        <div class="metric-pill">
                            <span>عدد المخالفات</span>
                            <strong>
                                <asp:Literal ID="litEmployeeViolationsCount" runat="server" Text="0" /></strong>
                        </div>

                        <div class="metric-pill">
                            <span>عدد الشكاوي غير المنجزة</span>
                            <strong>
                                <asp:Literal ID="litComplaintsCount" runat="server" Text="0" /></strong>
                        </div>

                        <div class="metric-pill">
                            <span>عدد جميع التقييمات (مرتبطة بالموظف)</span>
                            <strong>
                                <asp:Literal ID="litTotalEvals" runat="server" Text="0" /></strong>
                        </div>
                    </div>
                </div>

                <!-- ملخص المهام المتكررة (قديم كما هو) -->
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h6 class="card-title mb-0">ملخص المهام المتكررة</h6>
                    </div>
                    <div class="card-body">
                        <asp:Panel ID="pnlNoChecklistSummary" runat="server" Visible="False">
                            <div class="alert alert-light mb-0" role="alert">لا توجد مهام مكررة لهذا الموظف.</div>
                        </asp:Panel>

                        <asp:Repeater ID="rptChecklistSummary" runat="server">
                            <ItemTemplate>
                                <div class='d-flex align-items-center justify-content-between checklist-summary-item mb-2 p-2 <%# Eval("CssClass")%>'>
                                    <div class="me-2">
                                        <div class="fw-semibold small"><%# Eval("Title")%></div>
                                        <div class="text-muted small">
                                            <i class="bx bx-category-alt ms-1"></i>
                                            <%# Eval("CategoryTitle")%>
                                        </div>
                                    </div>
                                    <span class="badge fs-6"><%# Eval("Count")%>×</span>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <!-- ✅ ملخص المخالفات (جديد) -->
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h6 class="card-title mb-0">ملخص المخالفات</h6>
                    </div>
                    <div class="card-body">
                        <asp:Panel ID="pnlNoViolationsSummary" runat="server" Visible="False">
                            <div class="alert alert-light mb-0" role="alert">لا توجد مخالفات لهذا الموظف.</div>
                        </asp:Panel>

                        <asp:Repeater ID="rptViolationsSummary" runat="server">
                            <ItemTemplate>
                                <div class='d-flex align-items-center justify-content-between checklist-summary-item mb-2 p-2 <%# Eval("CssClass")%>'>
                                    <div class="me-2">
                                        <div class="fw-semibold small"><%# Eval("Title")%></div>
                                        <div class="text-muted small">
                                            <i class="bx bx-category-alt ms-1"></i>
                                            <%# Eval("CategoryTitle")%>
                                        </div>
                                    </div>
                                    <span class="badge fs-6"><%# Eval("Count")%>×</span>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>
            </div>

            <!-- Right -->
            <div class="col-lg-8 col-md-12">

                <!-- ✅ تغيير عنوان سجل المخالفات القديم إلى سجل المهام غير المنجزة -->
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">سجل المهام غير المنجزة</h5>
                    </div>
                    <div class="card-body">

                        <!-- فلاتر البحث (قديم) -->
                        <div class="row g-2 mb-3">
                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">من تاريخ</label>
                                <asp:TextBox ID="txtFromDate" runat="server" CssClass="form-control form-control-sm" placeholder="مثال: 01/01/2025"></asp:TextBox>
                            </div>

                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">إلى تاريخ</label>
                                <asp:TextBox ID="txtToDate" runat="server" CssClass="form-control form-control-sm" placeholder="مثال: 31/12/2025"></asp:TextBox>
                            </div>

                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">حالة المهمة</label>
                                <asp:DropDownList ID="ddlStatusFilter" runat="server" CssClass="form-select form-select-sm">
                                    <asp:ListItem Text="الكل" Value=""></asp:ListItem>
                                    <asp:ListItem Text="غير منجزة" Value="open"></asp:ListItem>
                                    <asp:ListItem Text="منجزة" Value="closed"></asp:ListItem>
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-12 col-md-6">
                                <label class="form-label form-label-sm">تصنيف عناصر التقييم</label>
                                <asp:DropDownList ID="ddlChecklistCategoryFilter" runat="server" CssClass="form-select form-select-sm"></asp:DropDownList>
                            </div>
                            <div class="col-12 col-md-6">
                                <label class="form-label form-label-sm">عنصر التقييم</label>
                                <asp:DropDownList ID="ddlChecklistFilter" runat="server" CssClass="form-select form-select-sm"></asp:DropDownList>
                            </div>
                        </div>

                        <div class="d-flex justify-content-end mb-3">
                            <asp:Button ID="btnSearchHistory" runat="server" CssClass="btn btn-sm btn-primary" Text="بحث" OnClick="btnSearchHistory_Click" />
                        </div>

                        <asp:Panel ID="pnlNoViolationsHistory" runat="server" Visible="False">
                            <div class="alert alert-info mb-2" role="alert">لا توجد مهام مطابقة لمعايير البحث.</div>
                        </asp:Panel>

                        <asp:Repeater ID="rptViolationsHistory" runat="server">
                            <ItemTemplate>
                                <div class="card mb-2 shadow-none border checklist-history-item">
                                    <div class="card-body py-2 px-3">
                                        <div class="d-flex align-items-center justify-content-between mb-1">
                                            <div class="me-2">
                                                <div class="fw-semibold small">
                                                    <%# Eval("DepartmentName")%> – <%# Eval("JobTitleName")%>
                                                </div>
                                                <div class="text-muted note-meta-small">
                                                    <i class="bx bx-time-five ms-1"></i>
                                                    <%# Eval("ShiftName")%>
                                                    <span class="mx-1">•</span>
                                                    <i class="bx bx-calendar ms-1"></i>
                                                    <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
                                                </div>
                                            </div>
                                            <span class='<%# Eval("StatusCss")%>'><%# Eval("StatusText")%></span>
                                        </div>

                                        <div class="d-flex flex-wrap violation-badges mt-2">
                                            <asp:Repeater ID="rptHistoryChips" runat="server" DataSource='<%# Eval("Violations")%>'>
                                                <ItemTemplate>
                                                    <span class='<%# Eval("CssClass")%>'><%# Eval("Title")%></span>
                                                </ItemTemplate>
                                            </asp:Repeater>
                                        </div>

                                        <div class="mt-2">
                                            <span class="fw-semibold d-block mb-1 small">ملاحظات المفتش:</span>
                                            <p class="mb-1 small"><%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes"))%></p>
                                        </div>

                                        <div class="mt-2 d-flex justify-content-end">
                                            <asp:Button ID="btnShowAttachmentsHistory" runat="server"
                                                CssClass="btn btn-sm btn-outline-secondary"
                                                Text="المرفقات"
                                                CommandName="ShowAttachments"
                                                CommandArgument='<%# Eval("EvaluationID")%>' />
                                        </div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                    </div>
                </div>

                <!-- ✅ سجل المخالفات (جديد من Evaluations_Employees) -->
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">سجل المخالفات</h5>
                    </div>
                    <div class="card-body">

                        <!-- فلاتر المخالفات -->
                        <div class="row g-2 mb-3">
                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">من تاريخ</label>
                                <asp:TextBox ID="txtVFrom" runat="server" CssClass="form-control form-control-sm" placeholder="مثال: 01/01/2025"></asp:TextBox>
                            </div>

                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">إلى تاريخ</label>
                                <asp:TextBox ID="txtVTo" runat="server" CssClass="form-control form-control-sm" placeholder="مثال: 31/12/2025"></asp:TextBox>
                            </div>

                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">الحالة</label>
                                <asp:DropDownList ID="ddlVStatus" runat="server" CssClass="form-select form-select-sm">
                                    <asp:ListItem Text="الكل" Value=""></asp:ListItem>
                                    <asp:ListItem Text="غير منجزة" Value="open"></asp:ListItem>
                                    <asp:ListItem Text="منجزة" Value="closed"></asp:ListItem>
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-12 col-md-6">
                                <label class="form-label form-label-sm">تصنيف المخالفة</label>
                                <asp:DropDownList ID="ddlVCategory" runat="server" CssClass="form-select form-select-sm"></asp:DropDownList>
                            </div>
                            <div class="col-12 col-md-6">
                                <label class="form-label form-label-sm">عنصر المخالفة</label>
                                <asp:DropDownList ID="ddlVChecklist" runat="server" CssClass="form-select form-select-sm"></asp:DropDownList>
                            </div>
                        </div>

                        <div class="d-flex justify-content-end mb-3">
                            <asp:Button ID="btnSearchViolations" runat="server" CssClass="btn btn-sm btn-primary" Text="بحث" OnClick="btnSearchViolations_Click" />
                        </div>

                        <asp:Panel ID="pnlNoViolations" runat="server" Visible="False">
                            <div class="alert alert-info mb-2" role="alert">لا توجد مخالفات مطابقة لمعايير البحث.</div>
                        </asp:Panel>

                        <asp:Repeater ID="rptEmployeeViolations" runat="server">
                            <ItemTemplate>
                                <div class="card mb-2 shadow-none border">
                                    <div class="card-body py-2 px-3">
                                        <div class="d-flex align-items-center justify-content-between mb-1">
                                            <div class="me-2">
                                                <div class="fw-semibold small">
                                                    <%# Eval("DepartmentName")%> – <%# Eval("JobTitleName")%>
                                                </div>
                                                <div class="text-muted note-meta-small">
                                                    <i class="bx bx-time-five ms-1"></i>
                                                    <%# Eval("ShiftName")%>
                                                    <span class="mx-1">•</span>
                                                    <i class="bx bx-calendar ms-1"></i>
                                                    <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
                                                </div>
                                            </div>
                                            <span class='<%# Eval("StatusCss")%>'><%# Eval("StatusText")%></span>
                                        </div>

                                        <div class="d-flex flex-wrap violation-badges mt-2">
                                            <asp:Repeater ID="rptVChips" runat="server" DataSource='<%# Eval("Violations")%>'>
                                                <ItemTemplate>
                                                    <span class='<%# Eval("CssClass")%>'><%# Eval("Title")%></span>
                                                </ItemTemplate>
                                            </asp:Repeater>
                                        </div>

                                        <div class="mt-2">
                                            <span class="fw-semibold d-block mb-1 small">ملاحظات:</span>
                                            <p class="mb-1 small"><%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes"))%></p>
                                        </div>

                                        <div class="mt-2 d-flex justify-content-end">
                                            <asp:Button ID="btnShowVAttachments" runat="server"
                                                CssClass="btn btn-sm btn-outline-secondary"
                                                Text="المرفقات"
                                                CommandName="ShowVAttachments"
                                                CommandArgument='<%# Eval("EvaluationID")%>' />
                                        </div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                    </div>
                </div>

                <!-- شكاوي غير منجزة (قديم كما هو) -->
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">شكاوي غير منجزة</h5>
                        <span class="badge bg-warning text-dark rounded-pill">
                            <asp:Literal ID="litComplaintsBadge" runat="server" Text="0" />
                        </span>
                    </div>
                    <div class="card-body">
                        <asp:Panel ID="pnlNoComplaints" runat="server" Visible="False">
                            <div class="alert alert-success mb-2" role="alert">لا توجد شكاوي غير منجزة لهذا الموظف.</div>
                        </asp:Panel>

                        <div class="accordion" id="accordionComplaints">
                            <asp:Repeater ID="rptComplaints" runat="server">
                                <ItemTemplate>
                                    <div class="accordion-item card mb-3 shadow-none border task-note-card">
                                        <div class="d-flex align-items-center justify-content-between px-3 pt-3">
                                            <button class="accordion-button px-0 py-0 bg-transparent shadow-0 flex-grow-1 collapsed"
                                                type="button"
                                                data-bs-toggle="collapse"
                                                data-bs-target='<%# "#collapseComplaint_" & Eval("EvaluationID")%>'
                                                aria-expanded="false"
                                                aria-controls='<%# "collapseComplaint_" & Eval("EvaluationID")%>'>
                                                <div class="w-100">
                                                    <div class="d-flex align-items-center gap-2 mb-2">
                                                        <img src='<%# Eval("BrandLogoUrl")%>' alt="Brand" class="brand-logo ms-1" />
                                                        <div>
                                                            <div class="task-title"><%# Eval("DepartmentName")%> – <%# Eval("JobTitleName")%></div>
                                                            <div class="task-sub">
                                                                <i class="bx bx-time-five ms-1"></i>
                                                                <%# Eval("ShiftName")%>
                                                                <span class="mx-1">•</span>
                                                                <i class="bx bx-calendar ms-1"></i>
                                                                <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <div class="d-flex flex-wrap violation-badges mb-2">
                                                        <asp:Repeater ID="rptViolationChipsComplaint" runat="server" DataSource='<%# Eval("Violations")%>'>
                                                            <ItemTemplate>
                                                                <span class='<%# Eval("CssClass")%>'><%# Eval("Title")%></span>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                    </div>
                                                </div>
                                            </button>
                                        </div>

                                        <div id='<%# "collapseComplaint_" & Eval("EvaluationID")%>' class="accordion-collapse collapse" data-bs-parent="#accordionComplaints">
                                            <div class="accordion-body pt-2">
                                                <div class="mb-3">
                                                    <span class="fw-semibold d-block mb-1">تفاصيل الشكوى / الملاحظات:</span>
                                                    <p class="mb-0"><%# Eval("Notes")%></p>
                                                </div>

                                                <div>
                                                    <asp:Button ID="btnShowAttachmentsComplaint" runat="server"
                                                        CssClass="btn btn-sm btn-outline-secondary"
                                                        Text="المرفقات"
                                                        CommandName="ShowAttachments"
                                                        CommandArgument='<%# Eval("EvaluationID")%>' />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>



    <!-- Attachments Modal (قديم - مستخدم للمهام والشكاوي) -->
    <asp:UpdatePanel ID="updAttachments" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
            <div class="modal fade" id="attachmentsModal" tabindex="-1" aria-labelledby="attachmentsModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 id="attachmentsModalLabel" class="modal-title">مرفقات التقييم</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                        </div>
                        <div class="modal-body">
                            <div id="attachmentsCarousel" class="carousel slide" data-bs-touch="true">
                                <div class="carousel-inner">
                                    <asp:Repeater ID="rptAttachmentsCarousel" runat="server">
                                        <ItemTemplate>
                                            <div class='carousel-item <%# IIf(Container.ItemIndex = 0, "active", "")%>'>
                                                <img src='<%# Eval("FilePath")%>' class="attachment-img d-block w-100" alt='<%# Eval("Title")%>' />
                                                <div class="carousel-caption d-none d-md-block">
                                                    <small class="bg-dark px-2 py-1 rounded-2"><%# Eval("Title")%></small>
                                                </div>
                                            </div>
                                        </ItemTemplate>
                                    </asp:Repeater>
                                </div>
                                <button class="carousel-control-prev" type="button" data-bs-target="#attachmentsCarousel" data-bs-slide="prev">
                                    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                    <span class="visually-hidden">السابق</span>
                                </button>
                                <button class="carousel-control-next" type="button" data-bs-target="#attachmentsCarousel" data-bs-slide="next">
                                    <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                    <span class="visually-hidden">التالي</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </ContentTemplate>
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="rptViolationsHistory" EventName="ItemCommand" />
            <asp:AsyncPostBackTrigger ControlID="rptComplaints" EventName="ItemCommand" />
            <asp:AsyncPostBackTrigger ControlID="rptEmployeeViolations" EventName="ItemCommand" />
        </Triggers>
    </asp:UpdatePanel>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            document.querySelectorAll('.branch-gauge').forEach(function (el) {
                var val = parseFloat(el.getAttribute('data-value')) || 0;
                val = Math.max(0, Math.min(100, val));
                el.style.setProperty('--value', val);
                var text = el.querySelector('.percentage');
                if (text) text.textContent = val.toFixed(1) + '%';
            });
        });
    </script>
</asp:Content>
