<%@ Page Title="مخالفات القسم" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Branch_Evaluations.aspx.vb" Inherits="CRM.Branch_Evaluations" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .dept-evals-wrapper { direction: rtl; text-align: right; }

        .task-note-card { border-radius: .75rem; }
        .brand-logo {
            width: 40px; height: 40px; object-fit: cover;
            border-radius: 8px; background: #f3f4f6;
            box-shadow: 0 3px 10px rgba(0, 0, 0, .12);
        }

        .task-title { font-weight: 600; color: #32475c; }
        .task-sub { font-size: .85rem; color: #6c757d; }

        .violation-badges { gap: .4rem; }
        .badge-chip { padding: .4rem .6rem; border-radius: 5px; font-weight: 500; font-size: .8rem; }
        .badge-danger-soft { background: #ffe4e6; color: #d2242a; }
        .badge-warning-soft { background: #fff4d6; color: #9a6b00; }
        .badge-primary-soft { background: #e6ecff; color: #3056ff; }
        .badge-info-soft { background: #e7f6ff; color: #117ea6; }

        /* Gauge */
        .branch-gauge {
            --value: 0;
            width: 160px; height: 160px; border-radius: 50%;
            background: conic-gradient(#28c76f calc(var(--value)*3.6deg), #e9ecef 0);
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto .75rem;
        }
        .branch-gauge-inner {
            width: 75%; height: 75%; border-radius: 50%;
            background: #fff; display: flex; align-items: center; justify-content: center;
            flex-direction: column; gap: .15rem;
        }
        .branch-gauge-inner .percentage { font-size: 1.8rem; font-weight: 600; color: #32475c; }
        .branch-gauge-inner small { font-size: .8rem; }

        .branch-gauge.gauge-green { background: conic-gradient(#28c76f calc(var(--value)*3.6deg), #e9ecef 0); }
        .branch-gauge.gauge-yellow { background: conic-gradient(#ffcc00 calc(var(--value)*3.6deg), #e9ecef 0); }
        .branch-gauge.gauge-red { background: conic-gradient(#ff4d4f calc(var(--value)*3.6deg), #e9ecef 0); }

        /* Summary pills */
        .metric-pill {
            display: flex; justify-content: space-between; align-items: center;
            padding: .5rem .75rem; border-radius: .5rem;
            background-color: #f5f5f9; font-size: .85rem; margin-bottom: .4rem;
        }
        .metric-pill strong { font-size: .9rem; }

        /* Attachments */
        .attachment-img { max-height: 420px; object-fit: contain; width: 100%; }
        @media (max-width: 576px) { .attachment-img { max-height: 260px; } }

        #attachmentsCarousel .carousel-control-prev,
        #attachmentsCarousel .carousel-control-next {
            display: flex !important; align-items: center; justify-content: center;
            opacity: 1 !important; width: 3rem;
        }
        #attachmentsCarousel .carousel-control-prev-icon,
        #attachmentsCarousel .carousel-control-next-icon {
            background-color: rgba(0, 0, 0, 0.45);
            border-radius: 50%;
            width: 2.4rem; height: 2.4rem;
            background-size: 1.3rem 1.3rem;
        }

        /* Loader */
        .page-loader-backdrop {
            position: fixed; inset: 0; background: rgba(255, 255, 255, 0.7);
            display: flex; align-items: center; justify-content: center; z-index: 9999;
        }
        .page-loader-backdrop.d-none { display: none !important; }
        .page-loader-box {
            padding: 1.5rem 2rem; border-radius: .75rem; background: #ffffff;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .18);
            display: flex; flex-direction: column; align-items: center; gap: .75rem;
        }
        .page-loader-text { font-size: .9rem; color: #4b5563; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y dept-evals-wrapper">

        <!-- عنوان الصفحة -->
        <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
            <div>
                <h5 class="mb-0">مخالفات القسم</h5>
                <div class="text-muted small">
                    <i class="bx bx-buildings ms-1"></i>
                    <asp:Literal ID="litDeptHeader" runat="server" Text="-" />
                    <span class="mx-1">•</span>
                    <i class="bx bx-store-alt ms-1"></i>
                    <asp:Literal ID="litBranchHeader" runat="server" Text="-" />
                </div>
            </div>

            <a href="javascript:void(0)" class="btn btn-outline-secondary btn-sm" onclick="history.back();">
                <i class="bx bx-chevron-right ms-1"></i> رجوع
            </a>
        </div>

        <div class="row">

            <!-- Left: Gauge + summary -->
            <div class="col-lg-4 col-md-12 mb-4">
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="card-title mb-0">تقييم القسم</h5>
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

                        <small class="text-muted d-block mt-2">
                            * في حال عدم وجود مخالفات أو شكاوي، يكون التقييم 100%.
                        </small>
                    </div>
                </div>
            </div>

            <!-- Right: Violations -->
            <div class="col-lg-8 col-md-12">

                <div class="card mb-4">
                    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
                        <h5 class="card-title mb-0">
                            مخالفات غير منجزة
                            <small class="text-muted">- عدد المخالفات <asp:Literal ID="litViolationsHeaderCount" runat="server" Text="0" /></small>
                        </h5>
                    </div>

                    <div class="card-body">
                        <asp:Panel ID="pnlNoViolations" runat="server" Visible="False">
                            <div class="alert alert-success mb-2" role="alert">
                                لا توجد مخالفات غير منجزة في هذا القسم.
                            </div>
                        </asp:Panel>

                        <div class="accordion" id="accordionViolations">

                            <asp:Repeater ID="rptViolations" runat="server" OnItemCommand="rptViolations_ItemCommand">
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
                                                    <div class="d-flex align-items-center gap-2 mb-2">
                                                        <img src='<%# Eval("BrandLogoUrl") %>' alt="Brand" class="brand-logo ms-1" />
                                                        <div>
                                                            <div class="task-title"><%# Eval("JobTitleName") %></div>
                                                            <div class="task-sub">
                                                                <i class="bx bx-time-five ms-1"></i> <%# Eval("ShiftName") %>
                                                                <span class="mx-1">•</span>
                                                                <i class="bx bx-calendar ms-1"></i> <%# String.Format("{0:dd/MM/yyyy HH:mm}", Eval("EvalDate")) %>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <div class="d-flex flex-wrap violation-badges mb-2">
                                                        <asp:Repeater ID="rptViolationChips" runat="server" DataSource='<%# Eval("Violations") %>'>
                                                            <ItemTemplate>
                                                                <span class='<%# Eval("CssClass") %>'><%# Eval("Title") %></span>
                                                            </ItemTemplate>
                                                        </asp:Repeater>
                                                    </div>
                                                </div>
                                            </button>

                                            <i class="bx bx-chevron-left text-muted ms-2"></i>
                                        </div>

                                        <div id='<%# "collapseViolation_" & Eval("EvaluationID") %>'
                                             class="accordion-collapse collapse" data-bs-parent="#accordionViolations">
                                            <div class="accordion-body pt-2">

                                                <div class="mb-3">
                                                    <span class="fw-semibold d-block mb-1">ملاحظات المفتش:</span>
                                                    <p class="mb-0"><%# If(String.IsNullOrWhiteSpace(Eval("Notes")), "لا يوجد ملاحظات", Eval("Notes")) %></p>
                                                </div>

                                                <div>
                                                    <asp:Button ID="btnShowAttachmentsViolation" runat="server"
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
        </Triggers>
    </asp:UpdatePanel>

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

            document.querySelectorAll('.branch-gauge').forEach(function (el) {
                var val = parseFloat(el.getAttribute('data-value')) || 0;
                val = Math.max(0, Math.min(100, val));
                el.style.setProperty('--value', val);
                var text = el.querySelector('.percentage');
                if (text) text.textContent = val.toFixed(1) + '%';
            });
        });

        window.addEventListener('pageshow', function () { hideLoader(); });

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
            prm.add_initializeRequest(function () { showLoader(); });
            prm.add_endRequest(function () { hideLoader(); });
        });
    </script>

</asp:Content>
