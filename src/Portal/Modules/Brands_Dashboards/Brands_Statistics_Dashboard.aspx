<%@ Page Title="لوحة تحكم العلامة التجارية" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Brands_Statistics_Dashboard.aspx.vb" Inherits="CRM.Brands_Statistics_Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>

        .brand-logo {
            width: 40px;
            height: 40px;
            object-fit: cover;
            border-radius: 8px;
        }

        /* أيقونة الفرع داخل دائرة */
        .branch-activity-icon {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 14px;
        }

        /* ربط الألوان بالأيقونات */
        .icon-success { background: #22c55e; }
        .icon-warning { background: #f59e0b; }
        .icon-danger { background: #ef4444; }
        .icon-primary { background: #3b82f6; }
        .icon-info { background: #0ea5e9; }

        /* بطاقة تقييم الفروع على شكل Activity */
        .branches-activity-card {
            padding-top: .5rem;
        }

        .branch-activity-row {
            margin-bottom: 1.1rem;
        }

            .branch-activity-row:last-child {
                margin-bottom: 0;
            }

        .branch-activity-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: .85rem;
            margin-bottom: .25rem;
        }

        .branch-activity-name {
            font-weight: 500;
            color: #4b5563;
        }

        .branch-activity-value {
            font-weight: 600;
            color: #111827;
        }

        /* شريط التقدم */
        .branch-activity-bar-track {
            width: 100%;
            height: 6px;
            border-radius: 999px;
            background-color: #e5e7eb; /* الرمادي الفاتح مثل الصورة */
            overflow: hidden;
        }

        .branch-activity-bar-fill {
            height: 100%;
            border-radius: 999px;
            width: 0;
        }

        /* ألوان حسب ColorKey (نفس الفكرة من الكارت القديم) */
        .branch-bar-success {
            background: #22c55e;
        }

        .branch-bar-warning {
            background: #f59e0b;
        }

        .branch-bar-danger {
            background: #ef4444;
        }

        .branch-bar-primary {
            background: #3b82f6;
        }

        .branch-bar-info {
            background: #0ea5e9;
        }

        .branches-mini-wrapper {
            direction: rtl;
            text-align: right;
        }

        .mini-branch-box {
            min-width: 180px;
        }

            .mini-branch-box .metric-value {
                font-weight: 600;
                font-size: 1.3rem;
            }

        /* كروت الملاحظات / الشكاوي */
        .task-note-card {
            border-radius: .75rem;
        }

        .note-meta-small {
            font-size: .8rem;
        }

        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
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

        .form-label-sm {
            font-size: .8rem;
            margin-bottom: .15rem;
        }

        /* Badges حالة المهمة */
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

        /* مرفقات - صور داخل المودال */
        .attachment-img {
            max-height: 420px;
            object-fit: contain;
            width: 100%;
        }

        @media (max-width: 576px) {
            .attachment-img {
                max-height: 260px;
            }
        }

        /* أسهم الكاروسيل داخل المودال */
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

        /* إخفاء الـ Charts القديمة من قالب Sneat */
        #growthRadialChart,
        #impressionRadialChart,
        #impressionDonutChart {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
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
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y branches-mini-wrapper">

        <!-- ========== الصف الأول: تقييم الفروع + تقييم العلامة التجارية ========== -->
        <div class="row">

            <!-- تقييم الفروع (كروت صغيرة لكل فرع) + سجل المهام + الشكاوي -->
            <div class="col-lg-9 col-md-12 mb-4">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">سجل المخالفات للعلامة التجارية</h5>
                    </div>
                    <div class="card-body">

                        <!-- UpdatePanel لسجل المخالفات + الفلاتر + الباجينغ -->
                        <asp:UpdatePanel ID="updHistory" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>

                                <!-- فلاتر البحث (بحث عام + بحث متقدم) -->
                                <div class="row g-2 mb-3">
                                    <div class="col-12 col-md-4">
                                        <label class="form-label form-label-sm">من تاريخ</label>
                                        <asp:TextBox ID="txtFromDate" runat="server"
                                            CssClass="form-control form-control-sm"
                                            placeholder="مثال: 01/01/2025"></asp:TextBox>
                                    </div>

                                    <div class="col-12 col-md-4">
                                        <label class="form-label form-label-sm">إلى تاريخ</label>
                                        <asp:TextBox ID="txtToDate" runat="server"
                                            CssClass="form-control form-control-sm"
                                            placeholder="مثال: 31/12/2025"></asp:TextBox>
                                    </div>

                                    <div class="col-12 col-md-4">
                                        <label class="form-label form-label-sm">حالة المهمة</label>
                                        <asp:DropDownList ID="ddlStatusFilter" runat="server"
                                            CssClass="form-select form-select-sm">
                                            <asp:ListItem Text="الكل" Value=""></asp:ListItem>
                                            <asp:ListItem Text="غير منجزة" Value="open"></asp:ListItem>
                                            <asp:ListItem Text="منجزة" Value="closed"></asp:ListItem>
                                        </asp:DropDownList>
                                    </div>
                                </div>

                                <div class="d-flex justify-content-between align-items-center mb-2">
                                    <small class="text-muted">
                                        البحث العام يعتمد على التاريخ وحالة المهمة،  يمكنك استخدام باقي الخيارات في البحث المتقدم.
                                    </small>
                                    <button type="button" class="btn btn-sm btn-link px-0" onclick="toggleAdvancedFilters()">
                                        <i class="bx bx-filter-alt ms-1"></i> بحث متقدم
                                    </button>
                                </div>

                                <!-- فلاتر البحث المتقدم -->
                                <div id="advancedFilters" class="mb-3 d-none">
                                    <div class="row g-2 mb-2">
                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">اسم الفرع</label>
                                            <asp:DropDownList ID="ddlBranchFilter" runat="server"
                                                CssClass="form-select form-select-sm">
                                            </asp:DropDownList>
                                        </div>
                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">اسم القسم</label>
                                            <asp:DropDownList ID="ddlDepartmentFilter" runat="server"
                                                CssClass="form-select form-select-sm">
                                            </asp:DropDownList>
                                        </div>
                                        <div class="col-12 col-md-4">
                                            <label class="form-label form-label-sm">المحطة التعريفية</label>
                                            <asp:DropDownList ID="ddlJobTitleFilter" runat="server"
                                                CssClass="form-select form-select-sm">
                                            </asp:DropDownList>
                                        </div>
                                    </div>

                                    <div class="row g-2 mb-2">
                                        <div class="col-12 col-md-6">
                                            <label class="form-label form-label-sm">تصنيف عنصر التقييم</label>
                                            <asp:DropDownList ID="ddlChecklistCategoryFilter" runat="server"
                                                CssClass="form-select form-select-sm">
                                            </asp:DropDownList>
                                        </div>
                                        <div class="col-12 col-md-6">
                                            <label class="form-label form-label-sm">عنصر التقييم</label>
                                            <asp:DropDownList ID="ddlChecklistFilter" runat="server"
                                                CssClass="form-select form-select-sm">
                                            </asp:DropDownList>
                                        </div>
                                    </div>
                                </div>

                                <div class="d-flex justify-content-end mb-3">
                                    <asp:Button ID="btnSearchHistory" runat="server"
                                        CssClass="btn btn-sm btn-primary"
                                        Text="بحث"
                                        OnClick="btnSearchHistory_Click" />
                                </div>

                                <!-- لا توجد نتائج -->
                                <asp:Panel ID="pnlNoViolationsHistory" runat="server" Visible="False">
                                    <div class="alert alert-info mb-2" role="alert">
                                        لا توجد مخالفات مطابقة لمعايير البحث.
                                    </div>
                                </asp:Panel>

                                <!-- نتائج البحث / السجل -->
                                <asp:Repeater ID="rptViolationsHistory" runat="server">
                                    <ItemTemplate>
                                        <div class="card mb-2 shadow-none border checklist-history-item">
                                            <div class="card-body py-2 px-3">
                                                <div class="d-flex align-items-center justify-content-between mb-1">
                                                    <div class="me-2">
                                                        <div class="fw-semibold small">
                                                            <%# Eval("BranchName") %> – <%# Eval("DepartmentName") %> – <%# Eval("JobTitleName") %>
                                                        </div>
                                                        <div class="text-muted note-meta-small">
                                                            <i class="bx bx-time-five ms-1"></i>
                                                            <%# Eval("ShiftName") %>
                                                            <span class="mx-1">•</span>
                                                            <i class="bx bx-calendar ms-1"></i>
                                                            <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate")) %>
                                                        </div>
                                                    </div>
                                                    <span class='<%# Eval("StatusCss") %>'>
                                                        <%# Eval("StatusText") %>
                                                    </span>
                                                </div>

                                                <!-- Chips لعناصر الـ Checklist -->
                                                <div class="d-flex flex-wrap violation-badges mt-2">
                                                    <asp:Repeater ID="rptHistoryChips" runat="server"
                                                        DataSource='<%# Eval("Violations") %>'>
                                                        <ItemTemplate>
                                                            <span class='<%# Eval("CssClass") %>'>
                                                                <%# Eval("Title") %>
                                                            </span>
                                                        </ItemTemplate>
                                                    </asp:Repeater>
                                                </div>

                                                <!-- ملاحظات المفتش -->
                                                <div class="mt-2">
                                                    <span class="fw-semibold d-block mb-1 small">ملاحظات المفتش:</span>
                                                    <p class="mb-1 small">
                                                        <%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes")) %>
                                                    </p>
                                                </div>

                                                <!-- زر المرفقات -->
                                                <div class="mt-2 d-flex justify-content-end">
                                                    <asp:Button ID="btnShowAttachmentsHistory" runat="server"
                                                        CssClass="btn btn-sm btn-outline-secondary"
                                                        Text="المرفقات"
                                                        CommandName="ShowAttachments"
                                                        CommandArgument='<%# Eval("EvaluationID") %>' />
                                                </div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>

                                <!-- Paging لسجل المخالفات -->
                                <asp:Panel ID="pnlHistoryPager" runat="server" CssClass="d-flex justify-content-between align-items-center mt-2" Visible="False">
                                    <asp:LinkButton ID="btnHistoryPrev" runat="server"
                                        CssClass="btn btn-sm btn-outline-secondary"
                                        Text="السابق"
                                        CommandArgument="-1"
                                        OnClick="HistoryPager_Click" />
                                    <asp:Label ID="lblHistoryPageInfo" runat="server" CssClass="small text-muted"></asp:Label>
                                    <asp:LinkButton ID="btnHistoryNext" runat="server"
                                        CssClass="btn btn-sm btn-outline-secondary"
                                        Text="التالي"
                                        CommandArgument="1"
                                        OnClick="HistoryPager_Click" />
                                </asp:Panel>

                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>
                </div>

                <!-- شكاوي غير منجزة للعلامة التجارية -->
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">شكاوي غير منجزة للعلامة التجارية</h5>
                        <span class="badge bg-warning text-dark rounded-pill">
                            <asp:Literal ID="litComplaintsBadge" runat="server" Text="0" />
                        </span>
                    </div>
                    <div class="card-body">
                        <asp:Panel ID="pnlNoComplaints" runat="server" Visible="False">
                            <div class="alert alert-success mb-2" role="alert">
                                لا توجد شكاوي غير منجزة لهذه العلامة التجارية.
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
                                                            <div class="task-title">
                                                                <%# Eval("BranchName") %> – <%# Eval("DepartmentName") %> – <%# Eval("JobTitleName") %>
                                                            </div>
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

            <!-- تقييم العلامة التجارية + توزيع عناصر التقييم + ملخص المهام/الشكاوي -->
            <div class="col-lg-3 col-md-12 mb-4">

                <!-- تقييم العلامة التجارية (Growth) -->
                <div class="card mb-4">
                    <div class="card-header text-center">
                        <h6 class="mb-0">تقييم العلامة التجارية</h6>
                    </div>
                    <div class="card-body text-center">
                        <!-- div القديم مخفي بالـ CSS، نتركه للقالب -->
                        <div id="growthRadialChart"></div>

                        <!-- الـ Chart الجديد المعتمد -->
                        <div id="brandEvaluationChart"></div>

                        <h6 class="mb-0 mt-4">
                            <asp:Literal ID="litBrandScoreText" runat="server" />
                        </h6>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">تقييم الفروع</h5>
                    </div>
                    <div class="card-body">
                        <ul class="p-0 m-0">
                            <asp:Repeater ID="rptBranches" runat="server">
                                <ItemTemplate>
                                    <li class="d-flex mb-4 pb-2">
                                        <!-- الأيقونة -->
                                        <div class="avatar avatar-sm flex-shrink-0 me-3">
                                            <span class='avatar-initial rounded-circle bg-label-<%# Eval("ColorKey") %>'>
                                                <i class="bx bx-store"></i>
                                            </span>
                                        </div>

                                        <!-- النص + الـ Progress -->
                                        <div class="d-flex flex-column w-100">
                                            <div class="d-flex justify-content-between mb-1">
                                                <!-- اسم الفرع -->
                                                <span><%# Eval("Name") %></span>
                                                <!-- نسبة التقييم -->
                                                <span class="text-muted">
                                                    <%# Eval("ScoreStr") %>%
                                                </span>
                                            </div>

                                            <div class="progress" style="height: 6px">
                                                <div class='progress-bar bg-<%# Eval("ColorKey") %>'
                                                    style='<%# "width:" & Eval("ScoreStr") & "%;" %>'
                                                    role="progressbar"
                                                    aria-valuenow='<%# Eval("ScoreStr") %>'
                                                    aria-valuemin="0"
                                                    aria-valuemax="100">
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                </ItemTemplate>
                            </asp:Repeater>
                        </ul>
                    </div>
                </div>

                <!-- توزيع عناصر التقييم حسب التصنيف -->
                <div class="card mb-4">
                    <div class="card-header text-center pb-0">
                        <h6 class="mb-1">توزيع عناصر التقييم حسب التصنيف</h6>
                    </div>
                    <div class="card-body text-center">
                        <!-- الـ Donut الوحيد المعتمد -->
                        <div id="categoriesDonutChart"></div>
                    </div>
                </div>

                <!-- ملخص عدد المهام / الشكاوي (كل العلامة) -->
                <div class="col-sm-12 col-12 mb-4">
                    <div class="row">
                        <div class="col-12 mb-4">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex justify-content-between">
                                        <div class="d-flex align-items-center gap-3">
                                            <div class="avatar">
                                                <span class="avatar-initial bg-label-primary rounded-circle">
                                                    <i class="bx bx-task fs-4"></i>
                                                </span>
                                            </div>
                                            <div class="card-info">
                                                <h5 class="card-title mb-0 me-2">
                                                    <asp:Literal ID="litBrandTasksCount" runat="server"></asp:Literal>
                                                </h5>
                                                <small class="text-muted">عدد المهام</small>
                                            </div>
                                        </div>
                                        <div id="conversationChart"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 mb-4">
                            <div class="card">
                                <div class="card-body">
                                    <div class="d-flex justify-content-between">
                                        <div class="d-flex align-items-center gap-3">
                                            <div class="avatar">
                                                <span class="avatar-initial bg-label-warning rounded-circle">
                                                    <i class="bx bx-food-menu fs-4"></i>
                                                </span>
                                            </div>
                                            <div class="card-info">
                                                <h5 class="card-title mb-0 me-2">
                                                    <asp:Literal ID="litBrandComplaintsCount" runat="server"></asp:Literal>
                                                </h5>
                                                <small class="text-muted">عدد الشكاوي</small>
                                            </div>
                                        </div>
                                        <div id="incomeChart"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </div>

    </div>

    <!-- لنقل البيانات إلى JavaScript -->
    <asp:Literal ID="litBrandScore" runat="server" Visible="false" />
    <asp:Literal ID="litCategoriesData" runat="server" Visible="false" />

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

    <!-- Attachments Modal + UpdatePanel -->
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
                                                    <small class="bg-dark px-2 py-1 rounded-2">
                                                        <%# Eval("Title") %>
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
            <asp:AsyncPostBackTrigger ControlID="rptViolationsHistory" EventName="ItemCommand" />
            <asp:AsyncPostBackTrigger ControlID="rptComplaints" EventName="ItemCommand" />
        </Triggers>
    </asp:UpdatePanel>

    <script type="text/javascript">
        // دالة عامة لتبديل إظهار/إخفاء الفلاتر المتقدمة
        function toggleAdvancedFilters() {
            var adv = document.getElementById("advancedFilters");
            if (adv) {
                adv.classList.toggle("d-none");
            }
        }

        document.addEventListener("DOMContentLoaded", function () {

            // ===== دوال إظهار / إخفاء الـ Loader =====
            function showPageLoader() {
                var el = document.getElementById("pageLoader");
                if (el) el.classList.remove("d-none");
            }

            function hidePageLoader() {
                var el = document.getElementById("pageLoader");
                if (el) el.classList.add("d-none");
            }

            // ربط الـ Loader بأي Postback كامل (Submit للفورم)
            try {
                var theForm = document.forms[0];
                if (theForm) {
                    theForm.addEventListener("submit", function () {
                        showPageLoader();
                    });
                }
            } catch (e) { }

            // ربط الـ Loader بأي AsyncPostBack (UpdatePanel)
            if (typeof (Sys) !== "undefined"
                && Sys.WebForms
                && Sys.WebForms.PageRequestManager) {

                var prm = Sys.WebForms.PageRequestManager.getInstance();

                prm.add_beginRequest(function (sender, args) {
                    showPageLoader();
                });

                prm.add_endRequest(function (sender, args) {
                    hidePageLoader();
                });
            }

            // ====== قراءة بيانات الـ Charts من الـ Literals ======
            var brandScore = parseFloat('<%= litBrandScore.Text %>') || 0.0;
            var categoriesJson = '<%= litCategoriesData.Text %>';
            var categories = [];

            try {
                if (categoriesJson && categoriesJson.length > 0) {
                    categories = JSON.parse(categoriesJson);
                }
            } catch (e) {
                categories = [];
            }

            // ====== Growth Radial Chart - Brand Score ======
            if (typeof ApexCharts !== "undefined" && document.querySelector("#brandEvaluationChart")) {
                var radialOptions = {
                    series: [brandScore],
                    chart: {
                        height: 260,
                        type: 'radialBar'
                    },
                    labels: [''],
                    plotOptions: {
                        radialBar: {
                            hollow: { size: '55%' },
                            dataLabels: {
                                name: { fontSize: '13px' },
                                value: {
                                    fontSize: '20px',
                                    formatter: function (val) {
                                        return val.toFixed(2) + '%';
                                    }
                                }
                            }
                        }
                    }
                };
                var radialChart = new ApexCharts(document.querySelector("#brandEvaluationChart"), radialOptions);
                radialChart.render();
            }

            // ====== Donut Chart - Checklist Categories Distribution ======
            if (typeof ApexCharts !== "undefined" && document.querySelector("#categoriesDonutChart")) {

                var categoryNames = categories.map(function (c) { return c.Name; });
                var categoryCounts = categories.map(function (c) { return c.Count; });

                var donutOptions = {
                    series: categoryCounts,
                    chart: {
                        type: 'donut',
                        height: 260
                    },
                    labels: categoryNames,
                    dataLabels: { enabled: true },
                    legend: { position: 'bottom' }
                };

                var donutChart = new ApexCharts(document.querySelector("#categoriesDonutChart"), donutOptions);
                donutChart.render();
            }
        });
    </script>
</asp:Content>
