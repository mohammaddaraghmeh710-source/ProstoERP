<%@ Page Title="تقييم القسم" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Department_Dashboard.aspx.vb"
    Inherits="CRM.Department_Dashboard" %>
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

        /* ===== Job titles - Activity style ===== */
        .job-activity-card {
            padding-top: .25rem;
        }

        .job-activity-item {
            padding: .35rem .1rem .7rem;
        }

        .job-activity-label {
            font-size: .85rem;
            color: #6b7280;
        }

        .job-activity-value {
            font-size: .9rem;
            font-weight: 600;
        }

        .job-activity-meta {
            font-size: .75rem;
            color: #9ca3af;
            margin-top: .35rem;
        }

        .job-activity-bar {
            position: relative;
            width: 100%;
            height: 6px;
            border-radius: 999px;
            background-color: #e5e7eb;
            overflow: hidden;
            margin-top: .25rem;
        }

        .job-activity-bar-fill {
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

        .job-bar-green {
            background-color: #4ade80 !important;
        }

        .job-bar-yellow {
            background-color: #fde047 !important;
        }

        .job-bar-red {
            background-color: #f97373 !important;
        }

        .eval-close-btn i {
            font-size: 1.1rem;
        }

        .eval-close-btn:hover {
            background-color: #fee2e2;
            border-color: #fecaca;
            color: #dc2626;
        }

        /* Gauge header menu (info icon) */
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
            .attachment-img {
                max-height: 260px;
            }

            .user-profile-header {
                flex-direction: column !important;
                text-align: center;
            }
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

        /* ===== Policies & Video Modals ===== */
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

        /* ===== Job titles evaluation - مثل تقييم الأقسام في الفرع ===== */

        .jobtitle-eval-card {
            border-radius: 0.3125rem;
            padding: 12px 16px;
            margin-bottom: 12px;
            color: #ffffff;
            box-shadow: 0 10px 22px rgba(15, 23, 42, 0.18);
            position: relative;
            overflow: hidden;
        }

        /* نسبة التقييم */
        .jobtitle-score {
            font-weight: 700;
            font-size: 1rem;
        }

        /* اسم المحطة التعريفية */
        .jobtitle-name {
            font-weight: 600;
            font-size: .95rem;
        }

        /* شريط التقدم الأبيض */
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

        /* عدد الموظفين */
        .jobtitle-meta {
            font-size: .8rem;
            opacity: .9;
        }

        /* ألوان الكروت (نفس روح تصميم تقييم الأقسام في الفرع) */
        .dept-eval-color-1 {
            background-color: #6c757d; /* رمادي */
            color: #fff;
        }

        .dept-eval-color-2 {
            background-color: #ea5455; /* أحمر */
            color: #fff;
        }

        .dept-eval-color-3 {
            background-color: #5f8bff; /* أزرق */
            color: #fff;
        }

        .dept-eval-color-4 {
            background-color: #00cfe8; /* سماوي */
            color: #fff;
        }

        .dept-eval-color-5 {
            background-color: #28c76f; /* أخضر */
            color: #fff;
        }

        .dept-eval-color-6 {
            background-color: #ff9f43; /* برتقالي */
            color: #fff;
        }


        /* موبايل */
        @media (max-width: 576px) {
            .jobtitle-eval-card {
                padding-inline: 12px;
            }

            .jobtitle-score, .jobtitle-name {
                font-size: .9rem;
            }


            .badge-chip {
                font-size: 3.1rem;
            }
        }

        /* تابلت  */
        @media (max-width: 1024px) {
            .badge-chip {
                font-size: 3.1rem;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

        <!-- Header: بيانات القسم (مخفية حالياً) -->
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
                    <!-- /user-profile-header -->
                </div>
            </div>
        </div>

        <div class="row">
   
                <!-- Right: Violations & Complaints accordions -->
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
                                                data-bs-target='<%# "#collapseViolation_" & Eval("EvaluationID")%>'
                                                aria-expanded="false"
                                                aria-controls='<%# "collapseViolation_" & Eval("EvaluationID")%>'>
                                                <div class="w-100">


                                                    <div class="d-flex flex-wrap violation-badges mb-2">
                                                        <asp:Repeater ID="rptViolationChips" runat="server"
                                                            DataSource='<%# Eval("Violations")%>'>
                                                            <ItemTemplate>
                                                                <span class='<%# Eval("CssClass")%>'>
                                                                    <%# Eval("Title")%>
                                                                </span>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                    </div>
                                                </div>
                                            </button>


                                        </div>

                                        <div id='<%# "collapseViolation_" & Eval("EvaluationID")%>'
                                            class="accordion-collapse collapse"
                                            data-bs-parent="#accordionViolations">


                                            <div class="d-flex align-items-center gap-2 m-2">
                                                <img src='<%# Eval("BrandLogoUrl")%>' alt="Brand" class="brand-logo ms-1" />
                                                <div>
                                                    <div class="task-title">
                                                        <%# Eval("JobTitleName")%>
                                                    </div>
                                                    <div class="task-sub">
                                                        <i class="bx bx-time-five ms-1"></i>
                                                        <%# Eval("ShiftName")%>
                                                        <span class="mx-1">•</span>
                                                        <i class="bx bx-calendar ms-1"></i>
                                                        <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate"))%>
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="accordion-body pt-2">
                                                <div class="mb-3">
                                                    <span class="fw-semibold d-block mb-1">ملاحظات المفتش:</span>
                                                    <p class="mb-0">
                                                        <%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes"))%>
                                                    </p>
                                                </div>

                                                <div>
                                                    <asp:Button ID="btnShowAttachmentsViolation" runat="server"
                                                        CssClass="btn btn-sm btn-outline-secondary"
                                                        Text="المرفقات"
                                                        CommandName="ShowAttachments"
                                                        CommandArgument='<%# Eval("EvaluationID")%>' />

                                                    <asp:LinkButton ID="lnkCloseViolation" runat="server"
                                                        CssClass="btn btn-sm btn-outline-success ms-2"
                                                        Text="إغلاق"
                                                        CommandName="CloseOneViolation"
                                                        CommandArgument='<%# Eval("EvaluationID")%>'
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
                                                data-bs-target='<%# "#collapseComplaint_" & Eval("EvaluationID")%>'
                                                aria-expanded="false"
                                                aria-controls='<%# "collapseComplaint_" & Eval("EvaluationID")%>'>
                                                <div class="w-100">
                                                    <div class="d-flex align-items-center gap-2 mb-2">
                                                        <img src='<%# Eval("BrandLogoUrl")%>' alt="Brand" class="brand-logo ms-1" />
                                                        <div>
                                                            <div class="task-title">
                                                                <%# Eval("JobTitleName")%>
                                                            </div>
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
                                                        <asp:Repeater ID="rptViolationChipsComplaint" runat="server"
                                                            DataSource='<%# Eval("Violations")%>'>
                                                            <ItemTemplate>
                                                                <span class='<%# Eval("CssClass")%>'>
                                                                    <%# Eval("Title")%>
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
                                                CommandArgument='<%# Eval("EvaluationID")%>'
                                                OnClientClick="showPageLoader();" />
                                        </div>

                                        <div id='<%# "collapseComplaint_" & Eval("EvaluationID")%>'
                                            class="accordion-collapse collapse"
                                            data-bs-parent="#accordionComplaints">
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
            

                 <!-- Left: Gauge + summary -->
            <div class="col-lg-3 col-md-12 mb-4">
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تقييم القسم</h5>

                        <!-- أيقونة المعلومات مع القائمة -->
                        <div class="dropdown">
                            <button class="btn btn-sm card-header-menu-btn"
                                type="button"
                                data-bs-toggle="dropdown"
                                aria-expanded="false">
                                <i class="bx bx-info-circle fs-4"></i>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li>
                                    <a class="dropdown-item" href="javascript:void(0);" onclick="showDeptPoliciesModal();">سياسات القسم
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="javascript:void(0);" onclick="openWorkingMethodVideo();">طريقة العمل
                                    </a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="javascript:void(0);" onclick="openEvaluationMethodVideo();">طريقة التقييم
                                    </a>
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
                                    <small class="text-muted">النتيجة الإجمالية </small>
                                </div>
                            </div>
                        </div>

                        <!-- Summary -->
                        <div class="metric-pill">
                            <span>عدد المخالفات غير المنجزة</span>
                            <strong>
                                <asp:Literal ID="litViolationsCount" runat="server" Text="0" /></strong>
                        </div>
                        <div class="metric-pill">
                            <span>عدد الشكاوي غير المنجزة</span>
                            <strong>
                                <asp:Literal ID="litComplaintsCount" runat="server" Text="0" /></strong>
                        </div>
                        <div class="metric-pill">
                            <span>عدد جميع التقييمات (مرتبطة بالقسم)</span>
                            <strong>
                                <asp:Literal ID="litTotalEvals" runat="server" Text="0" /></strong>
                        </div>

                        <small class="text-muted d-block mt-2">* في حال عدم وجود مخالفات أو شكاوي، يكون تقييم القسم 100%.
                        </small>
                    </div>
                </div>

                <!-- Job titles evaluation - نفس تصميم تقييم الأقسام في الفرع -->
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
                                <div class="jobtitle-eval-card dept-eval-color-<%# (Container.ItemIndex Mod 6) + 1%>">
                                    <!-- الصف العلوي: النسبة + اسم المسمى -->
                                    <div class="d-flex justify-content-between align-items-center mb-2" style="direction: ltr;">
                                        <span class="jobtitle-score">
                                            <%# String.Format("{0:0.0}%", Eval("Score"))%>
                                        </span>
                                        <span class="jobtitle-name">
                                            <%# Eval("JobTitleName")%>
                                        </span>
                                    </div>

                                    <!-- شريط النسبة الأبيض -->
                                    <div class="jobtitle-progress">
                                        <div class="jobtitle-progress-bar"
                                            style='width: <%# Convert.ToDecimal(Eval("Score")).ToString("0.##", CultureInfo.InvariantCulture)%>%'>
                                        </div>
                                    </div>

                                    <!-- عدد الموظفين -->
                                    <div class="jobtitle-meta text-start mt-2">
                                        الموظفون: <%# Eval("EmployeesCount")%>
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
                                            <div class='carousel-item <%# IIf(Container.ItemIndex = 0, "active", "")%>'>
                                                <img src='<%# Eval("FilePath")%>' class="attachment-img d-block w-100" alt='<%# Eval("Title")%>' />
                                                <div class="carousel-caption d-none d-md-block">
                                                    <small class="bg-dark px-2 py-1 rounded-2">
                                                        <%# Eval("Title")%>
                                                    </small>
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

    <!-- Video Modal (طريقة العمل / طريقة التقييم) -->
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
                    <small class="d-block mt-2 text-center text-muted">هذا الفيديو مخصص للاستخدام الداخلي لموظفي بروستو فقط.
                    </small>
                </div>
            </div>
        </div>
    </div>

    <!-- Hidden fields لحفظ روابط الفيديو المشفرة -->
    <asp:HiddenField ID="hidWorkingMethodUrl" runat="server" />
    <asp:HiddenField ID="hidEvaluationMethodUrl" runat="server" />

    <!-- Loader عام للصفحة -->
    <div id="pageLoader" class="page-loader-backdrop d-none">
        <div class="page-loader-box text-center">
            <div class="spinner-border" role="status">
                <span class="visually-hidden">جاري التحميل...</span>
            </div>
            <div class="page-loader-text">
                جاري معالجة طلبك، الرجاء الانتظار...
            </div>
        </div>
    </div>

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

            // Job titles Activity style
            initJobActivityBars();

            // إيقاف الفيديو عند إغلاق المودال
            var videoModal = document.getElementById('deptVideoModal');
            if (videoModal) {
                videoModal.addEventListener('hidden.bs.modal', function () {
                    var video = document.getElementById('deptTrainingVideo');
                    if (video) {
                        video.pause();
                        video.currentTime = 0;
                    }
                });
            }
        });

        function initJobActivityBars() {
            var items = document.querySelectorAll('.job-activity-item');
            items.forEach(function (item) {
                var score = parseFloat(item.getAttribute('data-score')) || 0;
                score = Math.max(0, Math.min(100, score));

                var valueEl = item.querySelector('.job-activity-value');
                var barFill = item.querySelector('.job-activity-bar-fill');

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

                if (valueEl && colorClassValue) {
                    valueEl.classList.add(colorClassValue);
                }
                if (barFill && colorClassBar) {
                    barFill.classList.add(colorClassBar);
                }
            });
        }

        function showLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) {
                loader.classList.remove('d-none');
            }
        }

        function hideLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) {
                loader.classList.add('d-none');
            }
        }

        // ربط اللودر مع الـ UpdatePanel
        Sys.Application.add_load(function () {
            var prm = Sys.WebForms.PageRequestManager.getInstance();

            prm.add_initializeRequest(function (sender, args) {
                showLoader();
            });

            prm.add_endRequest(function (sender, args) {
                hideLoader();
                initJobActivityBars();
            });
        });

        // ======= مودالات القسم (سياسات / فيديوهات) =======

        function showDeptPoliciesModal() {
            var modalEl = document.getElementById('deptPoliciesModal');
            if (!modalEl) return;
            var modal = new bootstrap.Modal(modalEl);
            modal.show();
        }

        function openWorkingMethodVideo() {
            var hf = document.getElementById('<%=hidWorkingMethodUrl.ClientID%>');
            if (!hf || !hf.value) {
                alert('لم يتم تعريف فيديو طريقة العمل لهذا القسم.');
                return;
            }
            openDeptVideoModal('طريقة العمل', hf.value);
        }

        function openEvaluationMethodVideo() {
            var hf = document.getElementById('<%=hidEvaluationMethodUrl.ClientID%>');
            if (!hf || !hf.value) {
                alert('لم يتم تعريف فيديو طريقة التقييم لهذا القسم.');
                return;
            }
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

            // لو في مودال مفتوح (مرفقات/سياسات/فيديو) ما نعمل ريفرش
            function isAnyModalOpen() {
                return !!document.querySelector('.modal.show');
            }

            setInterval(function () {
                try {
                    if (isAnyModalOpen()) return;

                    // لو اللودر ظاهر (في Async PostBack شغال) ما نعمل ريفرش
                    var loader = document.getElementById('pageLoader');
                    if (loader && !loader.classList.contains('d-none')) return;

                    window.location.reload();
                } catch (e) { /* ignore */ }
            }, REFRESH_MS);
        })();
    </script>

</asp:Content>
