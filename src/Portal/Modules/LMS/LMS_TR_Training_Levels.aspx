<%@ Page Title="البرنامج التدريبي للموظفين" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="LMS_TR_Training_Levels.aspx.vb" Inherits="CRM.LMS_TR_Training_Levels" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .employee-hover-banner {
            display: none !important;
        }

        /* ===== Header card (same روح MyProfile) ===== */
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

        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* ===== Pills ===== */
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

        /* ===== Status badges (by LevelStatusID) ===== */
        .status-badge {
            font-size: .75rem;
            border-radius: 6px;
            padding: .2rem .6rem;
            border-width: 1px;
            border-style: solid;
            white-space: nowrap;
            display: inline-flex;
            align-items: center;
            gap: .35rem;
        }

        /* ✅ حسب المطلوب:
           1 = open (green), 2 = done (blue), 3 = locked (red) */
        .status-green {
            background-color: #dcfce7;
            color: #166534;
            border-color: #bbf7d0;
        }

        .status-blue {
            background-color: #dbeafe;
            color: #1d4ed8;
            border-color: #bfdbfe;
        }

        .status-red {
            background-color: #fee2e2;
            color: #b91c1c;
            border-color: #fecaca;
        }

        /* ===== Charts containers ===== */
        .chart-box {
            min-height: 320px;
        }

        .chart-box-lg {
            min-height: 380px;
        }

        /* ===== LEVEL REPORT CARD ===== */
        .level-report-card {
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            overflow: hidden;
            height: 100%;
        }

        .level-card-inner {
            padding: 18px 20px;
        }

        .level-report-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }

        .level-info {
            flex: 1;
            min-width: 260px;
        }

        .level-title {
            font-weight: 800;
            color: #111827;
            font-size: 1.05rem;
            margin: 0;
        }

        .level-subtitle {
            color: #6b7280;
            font-size: .9rem;
            line-height: 1.7;
            margin-top: 6px;
        }

        .level-meta-row {
            display: flex;
            gap: 22px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: flex-start;
        }

        .meta-block {
            text-align: center;
            min-width: 120px;
            padding: 2px 6px;
        }

        .meta-label {
            color: #6b7280;
            font-size: .83rem;
        }

        .meta-value {
            margin-top: 6px;
            font-weight: 800;
            color: #374151;
            font-size: .95rem;
        }

        .date-pill {
            font-size: .75rem;
            border-radius: 6px;
            padding: .25rem .6rem;
            border: 1px solid #e5e7eb;
            background: #f9fafb;
            color: #374151;
            display: inline-flex;
            align-items: center;
            gap: .35rem;
        }

            .date-pill.start {
                background: #ecfdf5;
                border-color: #bbf7d0;
                color: #166534;
            }

            .date-pill.end {
                background: #fff1f2;
                border-color: #fecdd3;
                color: #9f1239;
            }

        /* Progress line */
        .watch-progress-wrap {
            margin-top: 14px;
            padding-top: 8px;
        }

        .watch-progress-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            margin-bottom: 8px;
        }

            .watch-progress-head .label {
                color: #6b7280;
                font-size: .85rem;
                font-weight: 700;
            }

            .watch-progress-head .percent {
                color: #374151;
                font-size: .85rem;
                font-weight: 800;
            }

        .watch-progress {
            height: 10px;
            border-radius: 999px;
            background: #eef2f7;
            overflow: hidden;
        }

            .watch-progress > span {
                display: block;
                height: 100%;
                width: 0%;
                border-radius: 999px;
                background: #4f86ff;
                transition: width .35s ease;
            }

        .level-report-footer {
            border-top: 1px solid #eef2f7;
            padding: 12px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
        }

        .footer-left {
            display: flex;
            align-items: center;
            gap: 12px;
            color: #6b7280;
            font-size: .85rem;
        }

            .footer-left .mini {
                display: inline-flex;
                align-items: center;
                gap: .35rem;
            }

            .footer-left a.mini {
                color: #6b7280;
            }

                .footer-left a.mini:hover {
                    color: #374151;
                }

        .btn-soft {
            border: 1px solid #e5e7eb;
            background: #fff;
        }

            .btn-soft:hover {
                background: #f9fafb;
            }

        .btn-disabled {
            opacity: .6;
            cursor: not-allowed !important;
            pointer-events: none;
        }

        @media (max-width: 576px) {
            .employee-header-card .card-body {
                text-align: center;
            }

            .employee-meta {
                justify-content: center;
            }

            .chart-box-lg {
                min-height: 320px;
            }

            .level-meta-row {
                justify-content: center;
            }

            .level-report-footer {
                justify-content: center;
            }
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
                                <h4 class="mb-0">مرحبًا،
                                    <asp:Label ID="lblEmployeeName" runat="server" Text="اسم الموظف"></asp:Label>
                                </h4>

                                <div class="employee-meta mt-2">
                                    <div class="meta-item">
                                        <i class="bx bx-mortarboard"></i>
                                        <asp:Literal ID="litTr_TypeName" runat="server" Text="-" />
                                    </div>
                                    <div class="meta-item">
                                        <i class="bx bx-layer"></i>
                                        عدد المستويات: <strong><asp:Literal ID="litTotalLevels" runat="server" Text="0" /></strong>
                                    </div>
                                    <div class="meta-item">
                                        <i class="bx bx-lock-alt"></i>
                                        فتح تدريجي حسب الإكمال
                                    </div>
                                </div>

                                <div class="mt-2 text-muted" style="font-size: .9rem; line-height: 1.8;">
                                  <asp:Literal ID="litTrainingLevelNote" runat="server" ></asp:Literal>
                                </div>
                            </div>
                        </div>

                        <div class="text-center text-md-end">
                            <asp:LinkButton ID="btnContinue" runat="server" CssClass="btn btn-sm btn-success" OnClick="btnContinue_Click">
                                <i class="bx bx-rocket ms-1"></i> ابدأ رحلتك التعليمية
                            </asp:LinkButton>

                            <%--Start_Popup--%>
                            <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
                                <div class="modal-dialog modal-dialog-centered" role="document">
                                    <div class="modal-content">
                                        <div class="text-center m-4">
                                            <img src="/assets/img/Prosto/Success_Icon.png" />
                                        </div>
                                        <div class="modal-body">
                                            <h2 class="text-center">
                                                <asp:Literal runat="server" ID="Literal1">تم تفعيل المستوى الاول</asp:Literal>
                                            </h2>
                                            <div class="swal2-html-container" id="swal2-html-container" style="display: block;">
                                                <asp:Literal ID="lblMessage" runat="server"></asp:Literal>
                                            </div>
                                        </div>
                                        <div class="text-center m-4">
                                            <asp:Button ID="btnClosePopup" runat="server" Text="اغلاق" CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                                        </div>
                                    </div>
                                </div>
                            </asp:Panel>

                            <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" PopupControlID="PanelPopUp"
                                BackgroundCssClass="OpacityBG" runat="server" TargetControlID="LBLPOP">
                            </cc11:ModalPopupExtender>
                            <asp:Label ID="LBLPOP" runat="server" />
                            <%--End_Popup--%>
                        </div>

                    </div>
                </div>
            </div>
        </div>

        <!-- Main -->
        <div class="row">

            <!-- Right column -->
            <div class="col-lg-4 col-md-12 mb-4">

                <!-- Progress + Donut -->
                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تقدمك في البرنامج</h5>
                    </div>
                    <div class="card-body">

                        <div class="text-center mb-3">
                            <div id="chartOverall" class="chart-box"></div>
                        </div>

                        <!-- ✅ من الـ Stored Procedure -->
                        <div class="metric-pill">
                            <span>المستويات المتاحة حالياً</span>
                            <strong><asp:Literal ID="litOpenLevels" runat="server" Text="0" /></strong>
                        </div>

                        <div class="metric-pill">
                            <span>المستويات المكتملة</span>
                            <strong><asp:Literal ID="litDoneLevels" runat="server" Text="0" /></strong>
                        </div>

                        <div class="metric-pill">
                            <span>المستويات المغلقة</span>
                            <strong><asp:Literal ID="litLockedLevels" runat="server" Text="0" /></strong>
                        </div>

                        <div class="metric-pill">
                            <span>إجمالي ساعات الفيديوهات</span>
                            <strong>
                                <asp:Literal ID="litTotalHours" runat="server" Text="0" /> ساعة
                            </strong>
                        </div>

                        <!-- ✅ نسبة الإنجاز (مخفية للاستخدام في الرسم) -->
                        <asp:Literal ID="litCompletionPercent" runat="server" Text="0" Visible="false" />
                    </div>
                </div>
            </div>

            <!-- Left column -->
            <div class="col-lg-8 col-md-12">

                <!-- Filters -->
                <div class="card mb-4">
                    <div class="card-body">
                        <div class="row g-2 align-items-end">
                            <div class="col-12 col-md-6">
                                <label class="form-label form-label-sm">بحث</label>
                                <input id="txtSearch" type="text" class="form-control form-control-sm" placeholder="ابحث باسم المستوى..." />
                            </div>

                            <div class="col-12 col-md-4">
                                <label class="form-label form-label-sm">الحالة</label>
                                <select id="ddlStatus" class="form-select form-select-sm">
                                    <option value="all">الكل</option>
                                    <option value="open">متاح حاليا</option>
                                    <option value="done">مكتمل</option>
                                    <option value="locked">مغلق</option>
                                </select>
                            </div>

                            <div class="col-12 col-md-2 d-grid">
                                <button type="button" class="btn btn-sm btn-primary" onclick="applyFilters()">بحث</button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ===== Levels Grid ===== -->
                <div class="row g-3" id="levelsGrid">
                    <asp:Repeater ID="rptLevels" runat="server">
                        <ItemTemplate>
                            <div class="col-12 level-item"
                                data-status='<%# GetStatusKeyById(Eval("LevelStatusID"))%>'
                                data-title='<%# HtmlAttr(Eval("Title_Ar"))%>'>

                                <div class="level-report-card">
                                    <div class="level-card-inner">
                                        <div class="level-report-header">
                                            <div class="level-info">
                                                <h6 class="level-title">
                                                    <%# "المستوى " & Eval("Item_Order") & ": " & Eval("Title_Ar")%>
                                                </h6>

                                                <div class="level-subtitle text-truncate-2">
                                                    <%# Eval("Summary_Ar")%>
                                                </div>

                                                <div class="mt-3 d-flex flex-wrap gap-2">
                                                    <span class="date-pill start">
                                                        <i class="bx bx-calendar"></i>البداية: <%# FormatDate(Eval("StartDate"))%>
                                                    </span>
                                                    <span class="date-pill end">
                                                        <i class="bx bx-calendar-x"></i>النهاية: <%# FormatDate(Eval("EndDate"))%>
                                                    </span>
                                                </div>

                                                <%# GetLockedHintHtmlById(Eval("LevelStatusID"))%>
                                            </div>

                                            <div class="level-meta-row">
                                                <div class="meta-block">
                                                    <div class="meta-label">عدد الفيديوهات</div>
                                                    <div class="meta-value"><%# Eval("VideosCount")%></div>
                                                </div>

                                                <div class="meta-block">
                                                    <div class="meta-label">الساعات</div>
                                                    <div class="meta-value"><%# FormatHours(Eval("TotalDurationHours"))%></div>
                                                </div>

                                                <div class="meta-block">
                                                    <div class="meta-label">الحالة</div>
                                                    <div class="meta-value">
                                                        <span class='status-badge <%# GetStatusCssById(Eval("LevelStatusID"))%>'>
                                                            <i class='<%# GetStatusIconById(Eval("LevelStatusID"))%>'></i>
                                                            <%# GetStatusTitleSafe(Eval("StatusTitle_Ar"))%>
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="watch-progress-wrap" data-watch='<%# SafePercent(Eval("CompletionPercent"))%>'>
                                            <div class="watch-progress-head">
                                                <div class="label">نسبة المشاهدة</div>
                                                <div class="percent">0%</div>
                                            </div>
                                            <div class="watch-progress"><span style="width: 0%"></span></div>
                                        </div>
                                    </div>

                                    <div class="level-report-footer">
                                        <div class="footer-left">
                                            <a href="javascript:void(0);"
                                                class="mini text-decoration-none level-notes-link"
                                                data-notes='<%# HtmlAttr(Eval("Notes_Ar"))%>'
                                                data-leveltitle='<%# HtmlAttr("المستوى " & Eval("Item_Order") & ": " & Eval("Title_Ar"))%>'>
                                                <i class="bx bx-message-dots"></i>ملاحظات
                                            </a>

                                            <span class="mini"><i class="bx bx-task"></i>عناصر: <%# Eval("VideosCount")%></span>
                                        </div>

                                        <div class="footer-actions">
                                            <asp:HyperLink ID="lnkAction" runat="server"
                                                CssClass='<%# GetActionButtonCssById(Eval("LevelStatusID"))%>'
                                                Text='<%# GetActionButtonTextById(Eval("LevelStatusID"))%>'
                                                NavigateUrl='<%# GetLevelContentUrl(Eval("ID"), Eval("LevelStatusID"))%>' />
                                        </div>
                                    </div>

                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlNoData" runat="server" Visible="false" CssClass="col-12">
                        <div class="alert alert-warning mb-0">
                            لا توجد مستويات متاحة لعرضها حسب نوع المستخدم/نوع المستوى.
                        </div>
                    </asp:Panel>
                </div>

                <div id="noFilterResults" class="alert alert-info mt-3 d-none">
                    لا يوجد نتائج مشابهة.
                </div>

            </div>
        </div>
    </div>

    <!-- ✅ Notes Modal -->
    <div class="modal fade" id="notesModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content" style="border-radius: 14px;">
                <div class="modal-header">
                    <h5 class="modal-title" id="notesModalTitle">ملاحظات المستوى</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body" id="notesModalBody" style="line-height: 1.9; color: #374151;">
                    -
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-soft" data-bs-dismiss="modal">إغلاق</button>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        // ===== Filters (search + status) =====
        function applyFilters() {
            const q = (document.getElementById('txtSearch').value || '').trim().toLowerCase();
            const st = document.getElementById('ddlStatus').value;

            let visibleCount = 0;
            document.querySelectorAll('.level-item').forEach(function (item) {
                const title = (item.getAttribute('data-title') || '').toLowerCase();
                const status = item.getAttribute('data-status');

                const matchQ = (!q || title.includes(q));
                const matchS = (st === 'all' || status === st);

                const show = (matchQ && matchS);
                item.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });

            const noRes = document.getElementById('noFilterResults');
            if (noRes) noRes.classList.toggle('d-none', visibleCount > 0);
        }

        // ===== Progress bars (CompletionPercent) =====
        function initWatchBars() {
            document.querySelectorAll('.watch-progress-wrap').forEach(function (wrap) {
                const p = parseFloat(wrap.getAttribute('data-watch') || '0');
                const safe = Math.max(0, Math.min(100, isNaN(p) ? 0 : p));
                const bar = wrap.querySelector('.watch-progress > span');
                const percent = wrap.querySelector('.watch-progress-head .percent');
                if (bar) bar.style.width = safe + '%';
                if (percent) percent.textContent = Math.round(safe) + '%';
            });
        }

        // ===== Notes Popup =====
        function initNotesPopup() {
            document.querySelectorAll('.level-notes-link').forEach(function (lnk) {
                if (lnk.dataset.bound === "1") return;
                lnk.dataset.bound = "1";

                lnk.addEventListener('click', function () {
                    const title = (lnk.getAttribute('data-leveltitle') || 'ملاحظات المستوى');
                    let notes = (lnk.getAttribute('data-notes') || '').trim();
                    if (!notes) notes = "لا توجد ملاحظات لهذا المستوى.";

                    const modalTitle = document.getElementById('notesModalTitle');
                    const modalBody = document.getElementById('notesModalBody');
                    if (modalTitle) modalTitle.textContent = title;
                    if (modalBody) modalBody.textContent = notes;

                    if (window.bootstrap && document.getElementById('notesModal')) {
                        const m = new bootstrap.Modal(document.getElementById('notesModal'));
                        m.show();
                    } else {
                        alert(title + "\n\n" + notes);
                    }
                });
            });
        }

        // ===== Charts (ApexCharts) =====
        function initTrainingCharts() {
            if (typeof ApexCharts === 'undefined') return;

            var totalLevels = parseInt('<%=litTotalLevels.Text%>' || '0', 10) || 0;
            var openLevels = parseInt('<%=litOpenLevels.Text%>' || '0', 10) || 0;
            var doneLevels = parseInt('<%=litDoneLevels.Text%>' || '0', 10) || 0;
            var lockedLevels = parseInt('<%=litLockedLevels.Text%>' || '0', 10) || 0;

            var completionPercent = parseInt('<%=litCompletionPercent.Text%>' || '0', 10) || 0;
            completionPercent = Math.max(0, Math.min(100, completionPercent));

            if (window.__overallChart) { try { window.__overallChart.destroy(); } catch (e) { } }

            window.__overallChart = new ApexCharts(document.querySelector("#chartOverall"), {
                chart: { type: 'donut', height: 320 },
                labels: ['متاح حالياً', 'مكتمل', 'مغلق'],
                series: [openLevels, doneLevels, lockedLevels],
                colors: ['#22c55e', '#3b82f6', '#ef4444'], // ✅ أخضر / أزرق / أحمر
                legend: { position: 'bottom' },
                stroke: { width: 0 },
                dataLabels: { enabled: true },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '72%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'نسبة الإنجاز',
                                    formatter: function () { return completionPercent + '%'; }
                                },
                                value: {
                                    show: true,
                                    formatter: function () { return completionPercent + '%'; }
                                }
                            }
                        }
                    }
                }
            });

            window.__overallChart.render();
        }

        function initAll() {
            initWatchBars();
            initNotesPopup();
            applyFilters();
            initTrainingCharts();
        }

        document.addEventListener('DOMContentLoaded', function () {
            initAll();
        });

        // for UpdatePanel
        if (window.Sys && Sys.Application) {
            Sys.Application.add_load(function () {
                initAll();
            });
        }
    </script>
</asp:Content>
