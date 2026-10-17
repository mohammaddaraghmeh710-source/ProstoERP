<%@ Page Title="تقييم القسم - عرض" Language="vb" AutoEventWireup="false"
    CodeBehind="Department_Dashboard_View.aspx.vb"
    Inherits="CRM.Department_Dashboard_View" %>

<!DOCTYPE html>
<html lang="ar" dir="rtl" class="light-style" data-theme="theme-default" data-assets-path="/assets/">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>تقييم القسم - عرض</title>

    <!-- ===== نفس مكتبات الستايل الموجودة بالـ Master ===== -->
    <link rel="icon" type="image/x-icon" href="/assets/img/favicon/favicon.ico" />

    <link rel="stylesheet" href="/assets/vendor/fonts/boxicons.css" />
    <link rel="stylesheet" href="/assets/vendor/fonts/fontawesome.css" />
    <link rel="stylesheet" href="/assets/vendor/fonts/flag-icons.css" />

    <link rel="stylesheet" href="/assets/vendor/css/rtl/core.css" class="template-customizer-core-css" />
    <link rel="stylesheet" href="/assets/vendor/css/rtl/theme-default.css" class="template-customizer-theme-css" />
    <link rel="stylesheet" href="/assets/css/demo.css" />

    <link rel="stylesheet" href="/assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/typeahead-js/typeahead.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/apex-charts/apex-charts.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/swiper/swiper.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/datatables-checkboxes-jquery/datatables.checkboxes.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/datatables-buttons-bs5/buttons.bootstrap5.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/flatpickr/flatpickr.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/select2/select2.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/quill/editor.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/quill/typography.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/pickr/pickr-themes.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/jquery-timepicker/jquery-timepicker.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/bootstrap-datepicker/bootstrap-datepicker.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/bootstrap-daterangepicker/bootstrap-daterangepicker.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/formvalidation/dist/css/formValidation.min.css" />
    <link rel="stylesheet" href="/assets/vendor/css/pages/ui-carousel.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/datatables-rowgroup-bs5/rowgroup.bootstrap5.css" />
    <link rel="stylesheet" href="/assets/vendor/css/pages/page-profile.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/sweetalert2/sweetalert2.css" />
    <link rel="stylesheet" href="/assets/vendor/libs/animate-css/animate.css" />
    <link href="/assets/css/table-style.css" rel="stylesheet" />

    <!-- Helpers -->
    <script src="/assets/vendor/js/helpers.js"></script>
    <script src="/assets/vendor/js/template-customizer.js"></script>
    <script src="/assets/js/config.js"></script>

    <!-- ====== نفس CSS صفحة Department_Dashboard.aspx ====== -->
    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .task-note-card { border-radius: .75rem; }

        .brand-logo {
            width: 40px;
            height: 40px;
            object-fit: cover;
            border-radius: 8px;
        }

        .task-title { font-weight: 600; color: #32475c; }
        .task-sub { font-size: .85rem; color: #6c757d; }

        .violation-badges { gap: .4rem; }

        .badge-chip {
            padding: .4rem .6rem;
            border-radius: 5px;
            font-weight: 500;
            font-size: .8rem;
        }

        .badge-danger-soft { background: #ffe4e6; color: #d2242a; }
        .badge-warning-soft { background: #fff4d6; color: #9a6b00; }
        .badge-primary-soft { background: #e6ecff; color: #3056ff; }
        .badge-info-soft { background: #e7f6ff; color: #117ea6; }

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

        .branch-gauge-inner small { font-size: .8rem; }

        .branch-gauge.gauge-green { background: conic-gradient(#28c76f calc(var(--value)*3.6deg), #e9ecef 0); }
        .branch-gauge.gauge-yellow { background: conic-gradient(#ffcc00 calc(var(--value)*3.6deg), #e9ecef 0); }
        .branch-gauge.gauge-red { background: conic-gradient(#ff4d4f calc(var(--value)*3.6deg), #e9ecef 0); }

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

        .metric-pill strong { font-size: .9rem; }

        /* Gauge header menu */
        .card-header-menu-btn {
            width: 32px;
            height: 32px;
            padding: 0;
            border-radius: 999px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        /* Modal attachments */
        .attachment-img {
            max-height: 420px;
            object-fit: contain;
            width: 100%;
        }

        @media (max-width: 576px) {
            .attachment-img { max-height: 260px; }
            .user-profile-header { flex-direction: column !important; text-align: center; }
        }

        /* Carousel controls */
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
        .page-loader-backdrop.d-none { display: none !important; }

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

        .page-loader-text { font-size: .9rem; color: #4b5563; }

        /* ===== Policies & Video Modals ===== */
        .dept-policies-content {
            max-height: 420px;
            overflow-y: auto;
            font-size: .9rem;
            line-height: 1.7;
        }

        .secure-video-wrapper video {
            display: block;
            width: 100%;
            border-radius: .5rem;
        }

        /* ===== Job titles evaluation cards ===== */
        .jobtitle-eval-card {
            border-radius: 0.3125rem;
            padding: 12px 16px;
            margin-bottom: 12px;
            color: #ffffff;
            box-shadow: 0 10px 22px rgba(15, 23, 42, 0.18);
            position: relative;
            overflow: hidden;
        }

        .jobtitle-score { font-weight: 700; font-size: 1rem; }
        .jobtitle-name { font-weight: 600; font-size: .95rem; }

        .jobtitle-progress {
            width: 100%;
            height: 4px;
            border-radius: 999px;
            background-color: rgba(255, 255, 255, 0.4);
            overflow: hidden;
            margin-top: 4px;
        }

        .jobtitle-progress-bar {
            height: 100%;
            border-radius: inherit;
            background-color: #ffffff;
            transition: width .3s ease;
        }

        .jobtitle-meta { font-size: .8rem; opacity: .9; }

        .dept-eval-color-1 { background-color: #6c757d; }
        .dept-eval-color-2 { background-color: #ea5455; }
        .dept-eval-color-3 { background-color: #5f8bff; }
        .dept-eval-color-4 { background-color: #00cfe8; }
        .dept-eval-color-5 { background-color: #28c76f; }
        .dept-eval-color-6 { background-color: #ff9f43; }
    </style>
    <link rel="stylesheet" href="/assets/css/erp-theme.css?v=20260906" />
</head>

<body style="background:#f5f5f9;" class="erp-ui">
    <form id="form1" runat="server">
        <!-- لازم ScriptManager عشان UpdatePanel + Sys.Application -->
        <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />

        <!-- محتوى الصفحة فقط (بدون Header/Footer) -->
        <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

            <!-- Header: بيانات القسم (مخفي كما كان) -->
            <div class="row" style="display: none">
                <div class="col-12">
                    <div class="card mb-4">
                        <div class="user-profile-header d-flex flex-column flex-sm-row text-sm-start text-center mb-4">
                            <div class="flex-shrink-0 mt-3 mx-sm-4 mx-auto">
                                <div class="avatar avatar-xl bg-label-primary d-inline-flex align-items-center justify-content-center rounded-3" style="width: 64px; height: 64px;">
                                    <i class="bx bx-grid-alt fs-1"></i>
                                </div>
                            </div>
                            <div class="flex-grow-1 mt-3 mt-sm-4">
                                <div class="d-flex align-items-md-end align-items-sm-start align-items-center justify-content-md-between justify-content-center mx-4 flex-md-row flex-column gap-3">
                                    <div>
                                        <h4 class="mb-1">
                                            <asp:Label ID="lblDeptName" runat="server" Text="اسم القسم"></asp:Label>
                                        </h4>
                                        <ul class="list-inline mb-0 d-flex align-items-center flex-wrap justify-content-sm-start justify-content-center gap-2">
                                            <li class="list-inline-item fw-semibold">
                                                <i class="bx bx-store-alt me-1"></i>
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
                                        <strong>
                                            <asp:Literal ID="litLastEvalDate" runat="server" Text="-"></asp:Literal>
                                        </strong>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <!-- Right -->
                <div class="col-lg-9 col-md-12">

                    <!-- Violations -->
                    <div class="card mb-4">
                        <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                            <h5 class="card-title mb-0">مخالفات غير منجزة
                                <small class="text-muted">- عدد المخالفات
                                    <asp:Literal ID="litViolationsHeaderCount" runat="server" Text="0" />
                                </small>
                            </h5>
                            <div class="d-flex align-items-center gap-2">
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
                                    لا توجد مخالفات غير منجزة في هذا القسم.
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
                                                    data-bs-target='<%# "#collapseViolation_" & Eval("EvaluationID") %>'
                                                    aria-expanded="false"
                                                    aria-controls='<%# "collapseViolation_" & Eval("EvaluationID") %>'>
                                                    <div class="w-100">
                                                        <div class="d-flex flex-wrap violation-badges mb-2">
                                                            <asp:Repeater ID="rptViolationChips" runat="server"
                                                                DataSource='<%# Eval("Violations") %>'>
                                                                <ItemTemplate>
                                                                    <span class='<%# Eval("CssClass") %>'>
                                                                        <%# Eval("Title") %>
                                                                    </span>
                                                                </ItemTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </button>
                                            </div>

                                            <div id='<%# "collapseViolation_" & Eval("EvaluationID") %>'
                                                class="accordion-collapse collapse"
                                                data-bs-parent="#accordionViolations">

                                                <div class="d-flex align-items-center gap-2 m-2">
                                                    <img src='<%# Eval("BrandLogoUrl") %>' alt="Brand" class="brand-logo ms-1" />
                                                    <div>
                                                        <div class="task-title"><%# Eval("JobTitleName") %></div>
                                                        <div class="task-sub">
                                                            <i class="bx bx-time-five ms-1"></i>
                                                            <%# Eval("ShiftName") %>
                                                            <span class="mx-1">•</span>
                                                            <i class="bx bx-calendar ms-1"></i>
                                                            <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate")) %>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div class="accordion-body pt-2">
                                                    <div class="mb-3">
                                                        <span class="fw-semibold d-block mb-1">ملاحظات المفتش:</span>
                                                        <p class="mb-0">
                                                            <%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes")) %>
                                                        </p>
                                                    </div>

                                                    <div>
                                                        <asp:Button ID="btnShowAttachmentsViolation" runat="server"
                                                            CssClass="btn btn-sm btn-outline-secondary"
                                                            Text="المرفقات"
                                                            CommandName="ShowAttachments"
                                                            CommandArgument='<%# Eval("EvaluationID") %>' />

                                                        <asp:LinkButton ID="lnkCloseViolation" runat="server"
                                                            CssClass="btn btn-sm btn-outline-success ms-2"
                                                            Text="إغلاق"
                                                            CommandName="CloseOneViolation"
                                                            CommandArgument='<%# Eval("EvaluationID") %>'
                                                            OnClientClick="showPageLoader();" />
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
                    <div class="card mb-4">
                        <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                            <h5 class="card-title mb-0">شكاوي غير منجزة
                                <small class="text-muted">- عدد الشكاوي
                                    <asp:Literal ID="litComplaintsHeaderCount" runat="server" Text="0" />
                                </small>
                            </h5>
                            <div class="d-flex align-items-center gap-2">
                                <asp:Button ID="btnCloseAllComplaints" runat="server"
                                    CssClass="btn btn-sm btn-outline-success"
                                    Text="إغلاق جميع الشكاوي"
                                    OnClick="btnCloseAllComplaints_Click"
                                    OnClientClick="showPageLoader();" />
                            </div>
                        </div>

                        <div class="card-body">
                            <asp:Panel ID="pnlNoComplaints" runat="server" Visible="False">
                                <div class="alert alert-success mb-2" role="alert">
                                    لا توجد شكاوي غير منجزة في هذا القسم.
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
                                                    data-bs-target='<%# "#collapseComplaint_" & Eval("EvaluationID") %>'
                                                    aria-expanded="false"
                                                    aria-controls='<%# "collapseComplaint_" & Eval("EvaluationID") %>'>
                                                    <div class="w-100">
                                                        <div class="d-flex align-items-center gap-2 mb-2">
                                                            <img src='<%# Eval("BrandLogoUrl") %>' alt="Brand" class="brand-logo ms-1" />
                                                            <div>
                                                                <div class="task-title"><%# Eval("JobTitleName") %></div>
                                                                <div class="task-sub">
                                                                    <i class="bx bx-time-five ms-1"></i>
                                                                    <%# Eval("ShiftName") %>
                                                                    <span class="mx-1">•</span>
                                                                    <i class="bx bx-calendar ms-1"></i>
                                                                    <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate")) %>
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div class="d-flex flex-wrap violation-badges mb-2">
                                                            <asp:Repeater ID="rptViolationChipsComplaint" runat="server"
                                                                DataSource='<%# Eval("Violations") %>'>
                                                                <ItemTemplate>
                                                                    <span class='<%# Eval("CssClass") %>'>
                                                                        <%# Eval("Title") %>
                                                                    </span>
                                                                </ItemTemplate>
                                                            </asp:Repeater>
                                                        </div>
                                                    </div>
                                                </button>

                                                <asp:LinkButton ID="lnkCloseComplaint" runat="server"
                                                    CssClass="btn btn-sm btn-outline-success ms-2"
                                                    Text="إغلاق"
                                                    CommandName="CloseOneComplaint"
                                                    CommandArgument='<%# Eval("EvaluationID") %>'
                                                    OnClientClick="showPageLoader();" />
                                            </div>

                                            <div id='<%# "collapseComplaint_" & Eval("EvaluationID") %>'
                                                class="accordion-collapse collapse"
                                                data-bs-parent="#accordionComplaints">
                                                <div class="accordion-body pt-2">
                                                    <div class="mb-3">
                                                        <span class="fw-semibold d-block mb-1">تفاصيل الشكوى / الملاحظات:</span>
                                                        <p class="mb-0"><%# Eval("Notes") %></p>
                                                    </div>

                                                    <div>
                                                        <asp:Button ID="btnShowAttachmentsComplaint" runat="server"
                                                            CssClass="btn btn-sm btn-outline-secondary"
                                                            Text="المرفقات"
                                                            CommandName="ShowAttachments"
                                                            CommandArgument='<%# Eval("EvaluationID") %>' />
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

                <!-- Left -->
                <div class="col-lg-3 col-md-12 mb-4">

                    <div class="card mb-4">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h5 class="card-title mb-0">تقييم القسم</h5>

                            <div class="dropdown">
                                <button class="btn btn-sm card-header-menu-btn"
                                    type="button"
                                    data-bs-toggle="dropdown"
                                    aria-expanded="false">
                                    <i class="bx bx-info-circle fs-4"></i>
                                </button>
                                <ul class="dropdown-menu dropdown-menu-end">
                                    <li>
                                        <a class="dropdown-item" href="javascript:void(0);" onclick="showDeptPoliciesModal();">سياسات القسم</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item" href="javascript:void(0);" onclick="openWorkingMethodVideo();">طريقة العمل</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item" href="javascript:void(0);" onclick="openEvaluationMethodVideo();">طريقة التقييم</a>
                                    </li>
                                </ul>
                            </div>
                        </div>

                        <div class="card-body">
                            <div class="text-center mb-3">
                                <div id="divDeptGauge" runat="server" class="branch-gauge" data-value="0">
                                    <div class="branch-gauge-inner">
                                        <span class="percentage">
                                            <asp:Literal ID="litDeptScore" runat="server" Text="100%"></asp:Literal>
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
                                <span>عدد جميع التقييمات (مرتبطة بالقسم)</span>
                                <strong><asp:Literal ID="litTotalEvals" runat="server" Text="0" /></strong>
                            </div>

                            <small class="text-muted d-block mt-2">* في حال عدم وجود مخالفات أو شكاوي، يكون تقييم القسم 100%.</small>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header text-center">
                            <h5 class="card-title mb-0">تقييم المحطات التعريفية في القسم</h5>
                        </div>
                        <div class="card-body">
                            <asp:Panel ID="pnlNoJobTitles" runat="server" Visible="False">
                                <div class="alert alert-info mb-0" role="alert">
                                    لا يوجد مسميات وظيفية مرتبطة بهذا القسم.
                                </div>
                            </asp:Panel>

                            <asp:Repeater ID="rptJobTitles" runat="server">
                                <ItemTemplate>
                                    <div class='jobtitle-eval-card dept-eval-color-<%# (Container.ItemIndex Mod 6) + 1 %>'>
                                        <div class="d-flex justify-content-between align-items-center mb-2" style="direction:ltr;">
                                            <span class="jobtitle-score"><%# String.Format("{0:0.0}%", Eval("Score")) %></span>
                                            <span class="jobtitle-name"><%# Eval("JobTitleName") %></span>
                                        </div>

                                        <div class="jobtitle-progress">
                                            <div class="jobtitle-progress-bar"
                                                style='width: <%# Convert.ToDecimal(Eval("Score")).ToString("0.##", System.Globalization.CultureInfo.InvariantCulture) %>%'>
                                            </div>
                                        </div>

                                        <div class="jobtitle-meta text-start mt-2">
                                            الموظفون: <%# Eval("EmployeesCount") %>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
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
                                                <div class='carousel-item <%# IIf(Container.ItemIndex = 0, "active", "") %>'>
                                                    <img src='<%# Eval("FilePath") %>' class="attachment-img d-block w-100" alt='<%# Eval("Title") %>' />
                                                    <div class="carousel-caption d-none d-md-block">
                                                        <small class="bg-dark px-2 py-1 rounded-2"><%# Eval("Title") %></small>
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
        <div class="modal fade" id="deptPoliciesModal" tabindex="-1" aria-labelledby="deptPoliciesModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 id="deptPoliciesModalLabel" class="modal-title">سياسات القسم</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                    </div>
                    <div class="modal-body">
                        <div class="dept-policies-content">
                            <asp:Literal ID="litDeptPolicies" runat="server" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Video Modal -->
        <div class="modal fade" id="deptVideoModal" tabindex="-1" aria-labelledby="deptVideoModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 id="deptVideoModalLabel" class="modal-title">فيديو توضيحي</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
                    </div>
                    <div class="modal-body">
                        <div class="secure-video-wrapper" oncontextmenu="return false;">
                            <video id="deptTrainingVideo"
                                controls
                                controlslist="nodownload noplaybackrate"
                                preload="metadata">
                                <source id="deptTrainingSource" src="" type="video/mp4" />
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

        <!-- ===== نفس مكتبات JS الأساسية (بدون master) ===== -->
        <script src="/assets/vendor/libs/jquery/jquery.js"></script>
        <script src="/assets/vendor/libs/popper/popper.js"></script>
        <script src="/assets/vendor/js/bootstrap.js"></script>
        <script src="/assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.js"></script>
        <script src="/assets/vendor/libs/hammer/hammer.js"></script>
        <script src="/assets/vendor/libs/i18n/i18n.js"></script>
        <script src="/assets/vendor/libs/typeahead-js/typeahead.js"></script>
        <script src="/assets/vendor/js/menu.js"></script>

        <script src="/assets/vendor/libs/sweetalert2/sweetalert2.js"></script>
        <script src="/assets/js/extended-ui-sweetalert2.js"></script>
        <script src="/assets/js/main.js"></script>

        <script>
            document.addEventListener('DOMContentLoaded', function () {
                // Gauge
                document.querySelectorAll('.branch-gauge').forEach(function (el) {
                    var val = parseFloat(el.getAttribute('data-value')) || 0;
                    val = Math.max(0, Math.min(100, val));
                    el.style.setProperty('--value', val);
                    var text = el.querySelector('.percentage');
                    if (text) text.textContent = val.toFixed(1) + '%';
                });

                // stop video on modal close
                var videoModal = document.getElementById('deptVideoModal');
                if (videoModal) {
                    videoModal.addEventListener('hidden.bs.modal', function () {
                        var video = document.getElementById('deptTrainingVideo');
                        if (video) { video.pause(); video.currentTime = 0; }
                    });
                }
            });

            function showLoader() {
                var loader = document.getElementById('pageLoader');
                if (loader) loader.classList.remove('d-none');
            }
            function hideLoader() {
                var loader = document.getElementById('pageLoader');
                if (loader) loader.classList.add('d-none');
            }

            // alias لتوافق OnClientClick الموجود بالصفحة الأصلية
            function showPageLoader() { showLoader(); }

            // ربط اللودر مع الـ UpdatePanel
            Sys.Application.add_load(function () {
                var prm = Sys.WebForms.PageRequestManager.getInstance();

                prm.add_initializeRequest(function () { showLoader(); });
                prm.add_endRequest(function () { hideLoader(); });
            });

            function showDeptPoliciesModal() {
                var modalEl = document.getElementById('deptPoliciesModal');
                if (!modalEl) return;
                var modal = new bootstrap.Modal(modalEl);
                modal.show();
            }

            function openWorkingMethodVideo() {
                var hf = document.getElementById('<%= hidWorkingMethodUrl.ClientID %>');
                if (!hf || !hf.value) { alert('لم يتم تعريف فيديو طريقة العمل لهذا القسم.'); return; }
                openDeptVideoModal('طريقة العمل', hf.value);
            }

            function openEvaluationMethodVideo() {
                var hf = document.getElementById('<%= hidEvaluationMethodUrl.ClientID %>');
                if (!hf || !hf.value) { alert('لم يتم تعريف فيديو طريقة التقييم لهذا القسم.'); return; }
                openDeptVideoModal('طريقة التقييم', hf.value);
            }

            function openDeptVideoModal(title, url) {
                var modalEl = document.getElementById('deptVideoModal');
                if (!modalEl) return;

                var titleEl = document.getElementById('deptVideoModalLabel');
                if (titleEl) titleEl.textContent = title;

                var video = document.getElementById('deptTrainingVideo');
                var source = document.getElementById('deptTrainingSource');

                if (video && source) {
                    video.pause();
                    source.src = url;
                    video.load();
                }

                var modal = new bootstrap.Modal(modalEl);
                modal.show();
            }
        </script>

        <script>
            // Auto refresh كل 5 دقائق (300000 ms)
            (function () {
                var REFRESH_MS = 1 * 60 * 1000;

                function isAnyModalOpen() {
                    return !!document.querySelector('.modal.show');
                }

                setInterval(function () {
                    try {
                        if (isAnyModalOpen()) return;

                        var loader = document.getElementById('pageLoader');
                        if (loader && !loader.classList.contains('d-none')) return;

                        window.location.reload();
                    } catch (e) { }
                }, REFRESH_MS);
            })();
        </script>

    </form>
</body>
</html>
