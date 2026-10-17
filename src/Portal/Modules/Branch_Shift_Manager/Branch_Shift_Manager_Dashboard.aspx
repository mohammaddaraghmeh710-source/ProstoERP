<%@ Page Title="تقييم الفرع" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Branch_Shift_Manager_Dashboard.aspx.vb"
    Inherits="CRM.Branch_Shift_Manager_Dashboard" %>
<%@ Import Namespace="System.Globalization" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .task-note-card {
            border-radius: .75rem;
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

        /* Summary pills */
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

        /* ===== Branch Departments - Activity style ===== */
        .branch-activity-card {
            padding-top: .25rem;
        }

        .branch-activity-item {
            padding: .35rem .1rem .7rem;
            cursor: pointer;
        }

        .branch-activity-label {
            font-size: .85rem;
            color: #6b7280;
        }

        .branch-activity-value {
            font-size: .9rem;
            font-weight: 600;
        }

        .branch-activity-meta {
            font-size: .75rem;
            color: #9ca3af;
            margin-top: .35rem;
        }

        .branch-activity-bar {
            position: relative;
            width: 100%;
            height: 6px;
            border-radius: 999px;
            background-color: #e5e7eb;
            overflow: hidden;
            margin-top: .25rem;
        }

        .branch-activity-bar-fill {
            height: 100%;
            border-radius: inherit;
            transition: width .3s ease;
        }

        .job-score-green {
            color: #16a34a !important;
        }

        .job-score-yellow {
            color: #eab308 !important;
        }

        .job-score-red {
            color: #ef4444 !important;
        }

        .eval-close-btn i {
            font-size: 1.1rem;
        }

        .eval-close-btn:hover {
            background-color: #fee2e2;
            border-color: #fecaca;
            color: #dc2626;
        }

        .card-header-menu-btn {
            width: 32px;
            height: 32px;
            padding: 0;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
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

        #attachmentsCarousel .carousel-control-prev,
        #attachmentsCarousel .carousel-control-next {
            display: flex !important;
            align-items: center;
            justify-content: center;
            opacity: 1 !important;
            width: 3rem;
        }

        #attachmentsCarousel .carousel-control-prev-icon,
        #attachmentsCarousel .carousel-control-next-icon {
            background-color: rgba(0, 0, 0, 0.45);
            border-radius: 50%;
            width: 2.4rem;
            height: 2.4rem;
            background-size: 1.3rem 1.3rem;
        }

        /* ===== Loader عام للصفحة ===== */
        .page-loader-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(255, 255, 255, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }

        .page-loader-backdrop.d-none {
            display: none !important;
        }

        .page-loader-box {
            padding: 1.5rem 2rem;
            border-radius: .75rem;
            background: #ffffff;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .18);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: .75rem;
        }

        .page-loader-text {
            font-size: .9rem;
            color: #4b5563;
        }

        .page-loader.d-none {
            display: none !important;
        }

        .dept-policies-content {
            max-height: 420px;
            overflow-y: auto;
            font-size: .9rem;
            line-height: 1.7;
        }

        .secure-video-wrapper {
            position: relative;
        }

        .secure-video-wrapper video {
            display: block;
            width: 100%;
            border-radius: .5rem;
        }

        /* ===== Colored department cards (like screenshot) ===== */
        .dept-bg-success { background-color: #28c76f; color: #fff; }
        .dept-bg-secondary { background-color: #6c757d; color: #fff; }
        .dept-bg-primary { background-color: #5f8bff; color: #fff; }
        .dept-bg-info { background-color: #00cfe8; color: #fff; }
        .dept-bg-warning { background-color: #ff9f43; color: #fff; }
        .dept-bg-danger { background-color: #ea5455; color: #fff; }

        .branch-activity-item[class*="dept-bg-"] .branch-activity-label,
        .branch-activity-item[class*="dept-bg-"] .branch-activity-meta,
        .branch-activity-item[class*="dept-bg-"] .branch-activity-value {
            color: #fff !important;
        }

        .branch-activity-item[class*="dept-bg-"] .branch-activity-bar {
            background-color: rgba(255, 255, 255, 0.3);
        }

        /* خلفية العداد رمادي دائم */
        .branch-activity-card .branch-activity-bar {
            background: #cccccc !important;
        }

        /* لون العداد نفسه (الفل) أبيض دائم */
        .branch-activity-card .branch-activity-bar-fill {
            background: #ffffff !important;
        }

        .branch-activity-card .branch-activity-bar-fill.job-bar-green,
        .branch-activity-card .branch-activity-bar-fill.job-bar-yellow,
        .branch-activity-card .branch-activity-bar-fill.job-bar-red {
            background: #ffffff !important;
        }

        /* ===== Branch shift header ===== */
        .branch-header-card {
            direction: rtl;
        }

        .branch-header-card .avatar-wrapper {
            flex-shrink: 0;
        }

        .branch-header-card .avatar-md {
            width: 48px;
            height: 48px;
            object-fit: cover;
            border-radius: 12px;
        }

        .branch-header-main h5 {
            font-size: 1rem;
            font-weight: 600;
            margin-bottom: .1rem;
        }

        .branch-header-stats {
            justify-content: flex-start;
        }

        .branch-header-stats .stat-pill {
            min-width: 110px;
            padding: .35rem .6rem;
            border-radius: .6rem;
            background-color: #f5f5f9;
            text-align: center;
            font-size: .75rem;
        }

        .branch-header-stats .stat-pill span {
            display: block;
            color: #6c757d;
            margin-bottom: .15rem;
        }

        .branch-header-stats .stat-pill strong {
            font-size: .9rem;
        }

        @media (max-width: 576px) {
            .branch-header-card .card-body {
                align-items: flex-start;
            }

            .branch-header-stats {
                width: 100%;
                justify-content: space-between;
            }

            .branch-header-stats .stat-pill {
                flex: 1 1 calc(50% - .4rem);
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

        <!-- Branch Shift Header -->
        <div class="card mb-3 branch-header-card">
            <div class="card-body d-flex flex-wrap align-items-center justify-content-between gap-3">
                <div class="d-flex align-items-center gap-3 flex-grow-1">
                    <div class="avatar-wrapper">
                        <asp:Image ID="imgCurrentUser" runat="server"
                            CssClass="avatar avatar-md rounded-3"
                            ImageUrl="~/assets/img/avatars/1.png"
                            AlternateText="المستخدم" />
                    </div>
                    <div class="branch-header-main">
                        <h5 class="mb-1">
                            <asp:Literal ID="litCurrentUserName" runat="server" />
                        </h5>
                        <div class="text-muted small mb-1">
                            <i class="bx bx-store-alt ms-1"></i>
                            <asp:Literal ID="litBrandBranchHeader" runat="server" />
                            &nbsp;
                            <i class="bx bx-calendar ms-1"></i>
                            <asp:Literal ID="litTodayDate" runat="server" />
                        </div>
                    </div>
                </div>

                <div class="branch-header-stats d-flex flex-wrap gap-2">
                    <asp:LinkButton ID="lnkEmpTotal" runat="server" CssClass="stat-pill text-primary" OnClick="lnkEmpTotal_Click">
                        <span>عدد الموظفين</span>
                        <strong><asp:Literal ID="litEmpTotal" runat="server" Text="0" /></strong>
                    </asp:LinkButton>

                    <asp:LinkButton ID="lnkEmpActual" runat="server" CssClass="stat-pill text-success" OnClick="lnkEmpActual_Click">
                        <span>العدد الحالي</span>
                        <strong><asp:Literal ID="litEmpActual" runat="server" Text="0" /></strong>
                    </asp:LinkButton>

                    <asp:LinkButton ID="lnkEmpOnLeave" runat="server" CssClass="stat-pill text-warning" OnClick="lnkEmpOnLeave_Click">
                        <span>عدد المجازين</span>
                        <strong><asp:Literal ID="litEmpOnLeave" runat="server" Text="0" /></strong>
                    </asp:LinkButton>

                    <asp:LinkButton ID="lnkEmpAbsent" runat="server" CssClass="stat-pill text-danger" OnClick="lnkEmpAbsent_Click">
                        <span>غياب بدون عذر</span>
                        <strong><asp:Literal ID="litEmpAbsent" runat="server" Text="0" /></strong>
                    </asp:LinkButton>
                </div>
            </div>
        </div>

        <!-- Header: بيانات الفرع (مخفي كما كان) -->
        <div class="row" style="display: none">
            <div class="col-12">
                <div class="card mb-4">
                    <div class="user-profile-header d-flex flex-column flex-sm-row text-sm-start text-center mb-4">
                        <div class="flex-shrink-0 mt-3 mx-sm-4 mx-auto">
                            <div class="avatar avatar-xl bg-label-primary d-inline-flex align-items-center justify-content-center rounded-3" style="width: 64px; height: 64px;">
                                <i class="bx bx-store-alt fs-1"></i>
                            </div>
                        </div>
                        <div class="flex-grow-1 mt-3 mt-sm-4">
                            <div class="d-flex align-items-md-end align-items-sm-start align-items-center justify-content-md-between justify-content-center mx-4 flex-md-row flex-column gap-3">
                                <div>
                                    <h4 class="mb-1">
                                        <asp:Label ID="lblBranchName" runat="server" Text="اسم الفرع"></asp:Label>
                                    </h4>
                                    <ul class="list-inline mb-0 d-flex align-items-center flex-wrap justify-content-sm-start justify-content-center gap-2">
                                        <li class="list-inline-item fw-semibold">
                                            <i class="bx bx-grid-alt me-1"></i>
                                            <asp:Literal ID="litBrandBranch" runat="server" />
                                        </li>
                                        <li class="list-inline-item fw-semibold">
                                            <i class="bx bx-time-five me-1"></i>
                                            <asp:Literal ID="litShiftName" runat="server" />
                                        </li>
                                    </ul>
                                </div>
                                <div class="text-sm-end text-center">
                                    <span class="d-block text-muted mb-1">آخر تقييم</span>
                                    <strong><asp:Literal ID="litLastEvalDate" runat="server" Text="-"></asp:Literal></strong>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- /user-profile-header -->
                </div>
            </div>
        </div>

        <div class="row">

            <!-- Left: Gauge + summary -->
            <div class="col-lg-4 col-md-12 mb-4">
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تقييم الفرع</h5>

                        <div class="dropdown">
                            <button class="btn btn-sm card-header-menu-btn" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="bx bx-info-circle fs-4"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><a class="dropdown-item" href="javascript:void(0);" onclick="showBranchPoliciesModal();">سياسات الفرع</a></li>
                                <li><a class="dropdown-item" href="javascript:void(0);" onclick="openWorkingMethodVideo();">طريقة العمل</a></li>
                                <li><a class="dropdown-item" href="javascript:void(0);" onclick="openEvaluationMethodVideo();">طريقة التقييم</a></li>
                            </ul>
                        </div>
                    </div>

                    <div class="card-body">
                        <div class="text-center mb-3">
                            <div id="divBranchGauge" runat="server" class="branch-gauge" data-value="0">
                                <div class="branch-gauge-inner">
                                    <span class="percentage">
                                        <asp:Literal ID="litBranchScore" runat="server" Text="100%"></asp:Literal>
                                    </span>
                                    <small class="text-muted">النتيجة الإجمالية</small>
                                </div>
                            </div>
                        </div>

                        <div class="metric-pill">
                            <span>عدد المخالفات غير المنجزة</span>
                            <strong><asp:Literal ID="litViolationsCount" runat="server" Text="0" /></strong>
                        </div>
                        <div class="metric-pill">
                            <span>عدد الشكاوي غير المنجزة</span>
                            <strong><asp:Literal ID="litComplaintsCount" runat="server" Text="0" /></strong>
                        </div>
                        <div class="metric-pill">
                            <span>عدد جميع التقييمات (مرتبطة بالفرع)</span>
                            <strong><asp:Literal ID="litTotalEvals" runat="server" Text="0" /></strong>
                        </div>

                        <small class="text-muted d-block mt-2">
                            * في حال عدم وجود مخالفات أو شكاوي، يكون تقييم الفرع 100%.
                        </small>
                    </div>
                </div>

                <!-- Branch Departments evaluation - Activity style -->
                <div class="card">
                    <div class="card-header d-flex align-items-center justify-content-between gap-2">
                        <h5 class="card-title mb-0">تقييم الأقسام في الفرع</h5>

                        <a href="/modules/QRCode/QRCode_Reader.aspx"
                           class="btn btn-outline-primary btn-sm d-flex align-items-center"
                           onclick="showLoader()">
                            <i class="bx bx-qr-scan me-1"></i>
                            قراءة QRCode
                        </a>
                    </div>

                    <div class="card-body branch-activity-card">
                        <asp:Repeater ID="rptDepartments" runat="server">
                            <ItemTemplate>
                                <div class='card mb-3 branch-activity-item <%# Eval("BgClass")%>'
                                     data-score='<%# Convert.ToDecimal(Eval("Score")).ToString("0.##", CultureInfo.InvariantCulture)%>'
                                     onclick="openTypeModal('<%# Eval("DepartmentID")%>');"
                                     style="padding: 10px;">
                                    <div class="d-flex justify-content-between align-items-center p-2">
                                        <span class="branch-activity-label"><%# Eval("DepartmentName")%></span>
                                        <span class="branch-activity-value"><%# String.Format("{0:0.0}%", Eval("Score"))%></span>
                                    </div>
                                    <div class="branch-activity-bar">
                                        <div class="branch-activity-bar-fill"></div>
                                    </div>
                                    <div class="branch-activity-meta p-2">
                                        الموظفون: <%# Eval("EmployeesCount")%>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlNoDepartments" runat="server" Visible="False">
                            <div class="alert alert-info mb-0" role="alert">
                                لا توجد أقسام مرتبطة بهذا الفرع.
                            </div>
                        </asp:Panel>
                    </div>
                </div>

            </div>

            <!-- Right: Violations & Complaints accordions -->
            <div class="col-lg-8 col-md-12">

                <!-- Violations -->
                <div class="card mb-4">
                    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                        <h5 class="card-title mb-0">
                            مخالفات غير منجزة
                            <small class="text-muted">- عدد المخالفات <asp:Literal ID="litViolationsHeaderCount" runat="server" Text="0" /></small>
                        </h5>

                        <div class="d-flex align-items-center gap-2" runat="server" visible="false">
                            <asp:Button ID="btnCloseAllViolations" runat="server"
                                CssClass="btn btn-sm btn-outline-success"
                                Text="إغلاق جميع المخالفات"
                                OnClick="btnCloseAllViolations_Click"
                                OnClientClick="showPageLoader();" />
                        </div>
                    </div>

                    <div class="card-body">
                        <asp:Panel ID="pnlNoViolations" runat="server" Visible="False">
                            <div class="alert alert-success mb-2" role="alert">
                                لا توجد مخالفات غير منجزة في هذا الفرع.
                            </div>
                        </asp:Panel>

                        <div class="accordion" id="accordionViolations">
                            <asp:Repeater ID="rptViolations" runat="server">
                                <ItemTemplate>
                                    <div class="accordion-item card mb-3 shadow-none border task-note-card">
                                        <div class="d-flex align-items-center justify-content-between px-3 pt-3">
                                            <button class="accordion-button px-0 py-0 bg-transparent shadow-0 flex-grow-1 collapsed"
                                                type="button"
                                                data-bs-toggle="collapse"
                                                data-bs-target='<%# "#collapseViolation_" & Eval("EvaluationID")%>'
                                                aria-expanded="false"
                                                aria-controls='<%# "collapseViolation_" & Eval("EvaluationID")%>'>
                                                <div class="w-100">
                                                    <div class="d-flex align-items-center gap-2 mb-2">
                                                        <img src='<%# Eval("BrandLogoUrl")%>' alt="Brand" class="brand-logo ms-1" />
                                                        <div>
                                                            <div class="task-title"><%# Eval("JobTitleName")%></div>
                                                            <div class="task-sub">
                                                                <i class="bx bx-time-five ms-1"></i> <%# Eval("ShiftName")%>
                                                                <span class="mx-1">•</span>
                                                                <i class="bx bx-calendar ms-1"></i> <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <div class="d-flex flex-wrap violation-badges mb-2">
                                                        <asp:Repeater ID="rptViolationChips" runat="server" DataSource='<%# Eval("Violations")%>'>
                                                            <ItemTemplate>
                                                                <span class='<%# Eval("CssClass")%>'><%# Eval("Title")%></span>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                    </div>
                                                </div>
                                            </button>

                                            <asp:LinkButton ID="lnkCloseViolation" runat="server" Visible="false"
                                                CssClass="btn btn-sm btn-outline-success ms-2"
                                                Text="إغلاق"
                                                CommandName="CloseOneViolation"
                                                CommandArgument='<%# Eval("EvaluationID")%>'
                                                OnClientClick="showPageLoader();" />
                                        </div>

                                        <div id='<%# "collapseViolation_" & Eval("EvaluationID")%>' class="accordion-collapse collapse" data-bs-parent="#accordionViolations">
                                            <div class="accordion-body pt-2">
                                                <div class="mb-3">
                                                    <span class="fw-semibold d-block mb-1">ملاحظات المفتش:</span>
                                                    <p class="mb-0"><%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes"))%></p>
                                                </div>

                                                <div>
                                                    <asp:Button ID="btnShowAttachmentsViolation" runat="server"
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

                <!-- Complaints -->
                <div class="card">
                    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                        <h5 class="card-title mb-0">
                            شكاوي غير منجزة
                            <small class="text-muted">- عدد الشكاوي <asp:Literal ID="litComplaintsHeaderCount" runat="server" Text="0" /></small>
                        </h5>
                        <div class="d-flex align-items-center gap-2">
                            <asp:Button ID="btnCloseAllComplaints" runat="server" Visible="false"
                                CssClass="btn btn-sm btn-outline-success"
                                Text="إغلاق جميع الشكاوي"
                                OnClick="btnCloseAllComplaints_Click"
                                OnClientClick="showPageLoader();" />
                        </div>
                    </div>

                    <div class="card-body">
                        <asp:Panel ID="pnlNoComplaints" runat="server" Visible="False">
                            <div class="alert alert-success mb-2" role="alert">
                                لا توجد شكاوي غير منجزة في هذا الفرع.
                            </div>
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
                                                            <div class="task-title"><%# Eval("JobTitleName")%></div>
                                                            <div class="task-sub">
                                                                <i class="bx bx-time-five ms-1"></i> <%# Eval("ShiftName")%>
                                                                <span class="mx-1">•</span>
                                                                <i class="bx bx-calendar ms-1"></i> <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
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

                                            <asp:LinkButton ID="lnkCloseComplaint" runat="server" Visible="false"
                                                CssClass="btn btn-sm btn-outline-success ms-2"
                                                Text="إغلاق"
                                                CommandName="CloseOneComplaint"
                                                CommandArgument='<%# Eval("EvaluationID")%>'
                                                OnClientClick="showPageLoader();" />
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

    <!-- ✅ Hidden: Selected Department -->
    <asp:HiddenField ID="hidSelectedDepartmentId" runat="server" />

    <!-- ✅ Evaluation Type Modal -->
    <div class="modal fade" id="evaluationTypeModal" tabindex="-1" aria-labelledby="evaluationTypeModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-md modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 id="evaluationTypeModalLabel" class="modal-title">اختيار نوع التقييم</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                </div>

                <div class="modal-body">
                    <asp:Panel ID="pnlNoChecklistTypes" runat="server" Visible="false">
                        <div class="alert alert-info mb-0">لا توجد أنواع تقييم مفعّلة.</div>
                    </asp:Panel>

                    <asp:Repeater ID="rptChecklistTypes" runat="server">
                        <HeaderTemplate>
                            <div class="list-group">
                        </HeaderTemplate>

                        <ItemTemplate>
                            <button type="button"
                                    class="list-group-item list-group-item-action d-flex justify-content-between align-items-center"
                                    onclick="selectEvalType('<%# Eval("ID")%>');">
                                <span><%# Eval("Title_Ar")%></span>
                                <i class="bx bx-chevron-left"></i>
                            </button>
                        </ItemTemplate>

                        <FooterTemplate>
                            </div>
                        </FooterTemplate>
                    </asp:Repeater>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">إلغاء</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Attachments Modal -->
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
            <asp:AsyncPostBackTrigger ControlID="rptViolations" EventName="ItemCommand" />
            <asp:AsyncPostBackTrigger ControlID="rptComplaints" EventName="ItemCommand" />
        </Triggers>
    </asp:UpdatePanel>

    <!-- Policies Modal -->
    <div class="modal fade" id="branchPoliciesModal" tabindex="-1" aria-labelledby="branchPoliciesModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 id="branchPoliciesModalLabel" class="modal-title">سياسات الفرع</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                </div>
                <div class="modal-body">
                    <div class="dept-policies-content">
                        <asp:Literal ID="litBranchPolicies" runat="server" />
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Employees UpdatePanel (كما كان) -->
    <asp:UpdatePanel ID="updEmployees" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
        <ContentTemplate>

            <!-- Employees List Modal -->
            <div class="modal fade" id="employeesModal" tabindex="-1" aria-labelledby="employeesModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 id="employeesModalLabel" class="modal-title">
                                <asp:Literal ID="litEmployeesFilterTitle" runat="server" Text="الموظفون"></asp:Literal>
                            </h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                        </div>
                        <div class="modal-body">
                            <asp:Repeater ID="rptEmployeesByDept" runat="server">
                                <ItemTemplate>
                                    <div class="mb-3">
                                        <h6 class="mb-2"><%# Eval("DepartmentName")%></h6>

                                        <asp:Repeater ID="rptEmployeesInner" runat="server"
                                            DataSource='<%# Eval("Employees")%>'
                                            OnItemCommand="rptEmployeesInner_ItemCommand">
                                            <ItemTemplate>
                                                <div class="d-flex flex-wrap align-items-center justify-content-between branch-emp-row mb-2 p-2 rounded-3 bg-light">
                                                    <div>
                                                        <div class="fw-semibold"><%# Eval("FullName")%></div>
                                                        <div class="text-muted small"><%# Eval("JobTitleName")%></div>
                                                    </div>
                                                    <div class="d-flex gap-2 mt-2 mt-sm-0">
                                                        <asp:LinkButton ID="lnkViewProfile" runat="server"
                                                            CssClass="btn btn-sm btn-outline-primary"
                                                            CommandName="ViewProfile"
                                                            CommandArgument='<%# Eval("ID")%>'
                                                            Text="ملف الموظف" />

                                                        <asp:LinkButton ID="lnkEditEmp" runat="server"
                                                            CssClass="btn btn-sm btn-outline-secondary"
                                                            CommandName="EditEmp"
                                                            CommandArgument='<%# Eval("ID")%>'
                                                            Text="تعديل" />
                                                    </div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Edit Employee Modal -->
            <div class="modal fade" id="editEmployeeModal" tabindex="-1" aria-labelledby="editEmployeeModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-md modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 id="editEmployeeModalLabel" class="modal-title">تعديل بيانات الموظف</h5>
                            <asp:Button ID="btnCloseEditHeader" runat="server" CssClass="btn-close" OnClick="btnCloseEditHeader_Click" />
                        </div>
                        <div class="modal-body">
                            <asp:HiddenField ID="hidEditEmployeeID" runat="server" />

                            <div class="mb-3">
                                <label class="form-label">القسم</label>
                                <asp:DropDownList ID="ddlEditDepartment" runat="server"
                                    CssClass="form-select"
                                    AutoPostBack="True"
                                    OnSelectedIndexChanged="ddlEditDepartment_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>

                            <div class="mb-3">
                                <label class="form-label">المحطة التعريفية</label>
                                <asp:DropDownList ID="ddlEditJobTitle" runat="server" CssClass="form-select"></asp:DropDownList>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <asp:Button ID="btnSaveEmployeeDeptJob" runat="server"
                                CssClass="btn btn-primary"
                                Text="حفظ"
                                OnClick="btnSaveEmployeeDeptJob_Click" />

                            <asp:Button ID="btnCloseEdit" runat="server"
                                CssClass="btn btn-outline-secondary"
                                Text="إلغاء"
                                OnClick="btnCloseEdit_Click" />
                        </div>
                    </div>
                </div>
            </div>

        </ContentTemplate>
        <Triggers>
            <asp:AsyncPostBackTrigger ControlID="lnkEmpTotal" EventName="Click" />
            <asp:AsyncPostBackTrigger ControlID="lnkEmpActual" EventName="Click" />
            <asp:AsyncPostBackTrigger ControlID="lnkEmpOnLeave" EventName="Click" />
            <asp:AsyncPostBackTrigger ControlID="lnkEmpAbsent" EventName="Click" />
        </Triggers>
    </asp:UpdatePanel>

    <!-- Video Modal -->
    <div class="modal fade" id="branchVideoModal" tabindex="-1" aria-labelledby="branchVideoModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 id="branchVideoModalLabel" class="modal-title">فيديو توضيحي</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                </div>
                <div class="modal-body">
                    <div class="secure-video-wrapper" oncontextmenu="return false;">
                        <video id="branchTrainingVideo" controls controlslist="nodownload noplaybackrate" preload="metadata">
                            <source id="branchTrainingSource" src="" type="video/mp4" />
                            المتصفح لا يدعم تشغيل الفيديو.
                        </video>
                    </div>
                    <small class="d-block mt-2 text-center text-muted">هذا الفيديو مخصص للاستخدام الداخلي لموظفي بروستو فقط.</small>
                </div>
            </div>
        </div>
    </div>

    <asp:HiddenField ID="hidWorkingMethodUrl" runat="server" />
    <asp:HiddenField ID="hidEvaluationMethodUrl" runat="server" />

    <!-- Loader -->
    <div id="pageLoader" class="page-loader-backdrop d-none">
        <div class="page-loader-box text-center">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">جاري التحميل...</span>
            </div>
            <div class="page-loader-text">جاري معالجة طلبك، الرجاء الانتظار...</div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            hideLoader();
        });

        document.addEventListener('DOMContentLoaded', function () {
            document.querySelectorAll('.branch-gauge').forEach(function (el) {
                var val = parseFloat(el.getAttribute('data-value')) || 0;
                val = Math.max(0, Math.min(100, val));
                el.style.setProperty('--value', val);
                var text = el.querySelector('.percentage');
                if (text) text.textContent = val.toFixed(1) + '%';
            });

            initBranchActivityBars();

            var videoModal = document.getElementById('branchVideoModal');
            if (videoModal) {
                videoModal.addEventListener('hidden.bs.modal', function () {
                    var video = document.getElementById('branchTrainingVideo');
                    if (video) {
                        video.pause();
                        video.currentTime = 0;
                    }
                });
            }
        });

        window.addEventListener('pageshow', function () {
            hideLoader();
        });

        function initBranchActivityBars() {
            var items = document.querySelectorAll('.branch-activity-item');
            items.forEach(function (item) {
                var score = parseFloat(item.getAttribute('data-score')) || 0;
                score = Math.max(0, Math.min(100, score));

                var valueEl = item.querySelector('.branch-activity-value');
                var barFill = item.querySelector('.branch-activity-bar-fill');

                if (valueEl) {
                    valueEl.textContent = score.toFixed(1) + '%';
                    valueEl.classList.remove('job-score-green', 'job-score-yellow', 'job-score-red');
                }
                if (barFill) {
                    barFill.style.width = score + '%';
                    barFill.classList.remove('job-bar-green', 'job-bar-yellow', 'job-bar-red');
                }

                var colorClassValue = '';
                var colorClassBar = '';

                if (score >= 90) {
                    colorClassValue = 'job-score-green';
                    colorClassBar = 'job-bar-green';
                } else if (score >= 60) {
                    colorClassValue = 'job-score-yellow';
                    colorClassBar = 'job-bar-yellow';
                } else {
                    colorClassValue = 'job-score-red';
                    colorClassBar = 'job-bar-red';
                }

                if (valueEl && colorClassValue) valueEl.classList.add(colorClassValue);
                if (barFill && colorClassBar) barFill.classList.add(colorClassBar);
            });
        }

        function showLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.remove('d-none');
        }

        function hideLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.add('d-none');
        }

        Sys.Application.add_load(function () {
            var prm = Sys.WebForms.PageRequestManager.getInstance();

            prm.add_initializeRequest(function () {
                showLoader();
            });

            prm.add_endRequest(function () {
                hideLoader();
                initBranchActivityBars();
            });
        });

        function showBranchPoliciesModal() {
            var modalEl = document.getElementById('branchPoliciesModal');
            if (!modalEl) return;
            new bootstrap.Modal(modalEl).show();
        }

        function openWorkingMethodVideo() {
            var hf = document.getElementById('<%=hidWorkingMethodUrl.ClientID%>');
            if (!hf || !hf.value) { alert('لم يتم تعريف فيديو طريقة العمل لهذا الفرع.'); return; }
            openBranchVideoModal('طريقة العمل', hf.value);
        }

        function openEvaluationMethodVideo() {
            var hf = document.getElementById('<%=hidEvaluationMethodUrl.ClientID%>');
            if (!hf || !hf.value) { alert('لم يتم تعريف فيديو طريقة التقييم لهذا الفرع.'); return; }
            openBranchVideoModal('طريقة التقييم', hf.value);
        }

        function openBranchVideoModal(title, url) {
            var modalEl = document.getElementById('branchVideoModal');
            if (!modalEl) return;

            var titleEl = document.getElementById('branchVideoModalLabel');
            if (titleEl) titleEl.textContent = title;

            var video = document.getElementById('branchTrainingVideo');
            var source = document.getElementById('branchTrainingSource');

            if (video && source) {
                video.pause();
                source.src = url;
                video.load();
            }

            new bootstrap.Modal(modalEl).show();
        }

        function showPageLoader() {
            showLoader();
        }

        // ✅ فتح مودال أنواع التقييم وتخزين القسم
        function openTypeModal(deptId) {
            var hfDept = document.getElementById('<%=hidSelectedDepartmentId.ClientID%>');
            if (hfDept) hfDept.value = deptId;

            var modalEl = document.getElementById('evaluationTypeModal');
            if (!modalEl) return;

            new bootstrap.Modal(modalEl).show();
        }

        // ✅ اختيار نوع التقييم ثم توجيه لنفس الصفحة مع Type
        function selectEvalType(typeId) {
            var hfDept = document.getElementById('<%=hidSelectedDepartmentId.ClientID%>');
            var deptId = hfDept ? hfDept.value : '';

            if (!deptId) {
                alert('حدث خطأ: لم يتم تحديد القسم.');
                return;
            }

            var shiftId = '<%=If(ShiftID.HasValue, ShiftID.Value.ToString(), "")%>';

            showLoader();

            var url = '/Modules/Evaluations/JobTitles_Evaluation.aspx?Departmentid=' + encodeURIComponent(deptId);
            if (shiftId) url += '&shiftID=' + encodeURIComponent(shiftId);

            url += '&Type=' + encodeURIComponent(typeId);

            window.location.href = url;
        }

    </script>

</asp:Content>
