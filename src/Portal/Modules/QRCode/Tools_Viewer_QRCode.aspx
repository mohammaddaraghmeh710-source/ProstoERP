<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Tools_Viewer_QRCode.aspx.vb" Inherits="CRM.Tools_Viewer_QRCode" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .tools-viewer-wrapper { direction: rtl; text-align: right; }

        .tool-card {
            border-radius: .75rem;
            transition: transform .15s ease, box-shadow .15s ease;
        }
        .tool-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(15, 15, 20, .12);
        }

        .brand-logo {
            width: 64px;
            height: 64px;
            border-radius: 50%;
            object-fit: cover;
            box-shadow: 0 3px 10px rgba(0, 0, 0, .18);
            background: #f3f4f6;
        }

        .tool-header-badges { gap: .5rem; }

        .tool-kv {
            border: 1px solid rgba(105,108,255,.14);
            border-radius: .6rem;
            padding: .65rem .75rem;
            background: #fff;
            height: 100%;
        }
        .tool-kv .k {
            color: #6b7280;
            font-size: .82rem;
            margin-bottom: .15rem;
        }
        .tool-kv .v {
            font-weight: 700;
            color: #32475c;
            font-size: .98rem;
            line-height: 1.35;
            word-break: break-word;
        }

        .tool-actions .btn {
            border-radius: .65rem;
            font-weight: 700;
            padding: .75rem .9rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: .45rem;
        }
        .tool-actions .btn i { font-size: 1.1rem; }

        @media (max-width: 576px) {
            .tool-card { border-radius: .6rem; }
            .brand-logo { width: 56px; height: 56px; }
            .tool-actions .btn { padding: .7rem .75rem; }
        }

        /* ===== Loader عام للصفحة (نفس ستايل صفحة الفروع) ===== */
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
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y tools-viewer-wrapper">

        <!-- كامل الصفحة داخل Card (نفس فلسفة صفحة الفروع) -->
        <div class="card">

            <!-- Card Header -->
            <div class="card-header d-flex flex-wrap align-items-center justify-content-between gap-2">
                <div>
                    <h4 class="mb-1">تفاصيل الأداة / المادة</h4>
                    <p class="text-muted mb-0">
                        أدناه تفاصيل الأداة المرتبطة بالـ QR Code، ويمكنك استخدام زر <strong>تقييم</strong> للانتقال مباشرة لصفحة التقييم بعد اختيار نوع التقييم.
                    </p>
                </div>

                <div class="d-flex align-items-center gap-2 tool-header-badges">
                    <span class="badge bg-label-primary fs-6">
                        <i class="bx bx-qr me-1"></i> QR
                    </span>

                    <span class="badge bg-label-info fs-6">
                        رقم المادة: <asp:Literal ID="litToolNumberHeader" runat="server" />
                    </span>
                </div>
            </div>

            <!-- Card Body -->
            <div class="card-body">

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger">
                    <i class="bx bx-error-circle me-1"></i>
                    <asp:Literal ID="litError" runat="server"></asp:Literal>
                </asp:Panel>

                <!-- بطاقة تفاصيل -->
                <div class="card tool-card">
                    <div class="card-body">

                        <!-- Top: Logo + Org line -->
                        <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 mb-3">
                            <div class="d-flex align-items-center gap-3">
                                <asp:Image ID="imgBrandLogo" runat="server" CssClass="brand-logo" />
                                <div>
                                    <h6 class="mb-1 text-body">
                                        <asp:Literal ID="litItemTitle" runat="server" />
                                    </h6>
                                    <div class="small text-muted">
                                        <asp:Literal ID="litOrgLine" runat="server" />
                                    </div>
                                </div>
                            </div>

                            <!-- Quick actions (desktop aligned) -->
                            <div class="tool-actions d-none d-md-flex gap-2">
                                <!-- ✅ تم التعديل: فتح مودال اختيار النوع بدل التوجيه المباشر -->
                                <button type="button" class="btn btn-primary" onclick="openTypeModalForTool();">
                                    <i class="bx bx-check-shield"></i> تقييم
                                </button>

                                <button type="button" class="btn btn-outline-secondary" onclick="showWIP();">
                                    <i class="bx bx-wrench"></i> الصيانة
                                </button>

                                <button type="button" class="btn btn-outline-secondary" onclick="showWIP();">
                                    <i class="bx bx-transfer-alt"></i> نقل إلى فرع آخر
                                </button>

                                <button type="button" class="btn btn-outline-danger" onclick="showWIP();">
                                    <i class="bx bx-x-circle"></i> إلغاء
                                </button>
                            </div>
                        </div>

                        <!-- Details grid -->
                        <div class="row g-3">

                            <div class="col-12">
                                <div class="tool-kv">
                                    <div class="k">اسم المادة</div>
                                    <div class="v"><asp:Literal ID="litItemTitle2" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">رقم المادة</div>
                                    <div class="v"><asp:Literal ID="litToolNumber" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">نوع الأداة</div>
                                    <div class="v"><asp:Literal ID="litItemType" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12">
                                <div class="tool-kv">
                                    <div class="k">العلامة التجارية</div>
                                    <div class="v"><asp:Literal ID="litBrand" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">الفرع</div>
                                    <div class="v"><asp:Literal ID="litBranch" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">القسم</div>
                                    <div class="v"><asp:Literal ID="litDepartment" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12">
                                <div class="tool-kv">
                                    <div class="k">المحطة التعريفية</div>
                                    <div class="v"><asp:Literal ID="litJobTitle" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">الشركة الموردة</div>
                                    <div class="v"><asp:Literal ID="litSupplier" runat="server" /></div>
                                </div>
                            </div>

                            <div class="col-12 col-md-6">
                                <div class="tool-kv">
                                    <div class="k">شركة الصيانة</div>
                                    <div class="v"><asp:Literal ID="litMaintenance" runat="server" /></div>
                                </div>
                            </div>

                        </div>

                        <!-- Mobile actions -->
                        <div class="tool-actions d-grid gap-2 mt-3 d-md-none">
                            <!-- ✅ تم التعديل: نفس زر التقييم على الموبايل -->
                            <button type="button" class="btn btn-primary" onclick="openTypeModalForTool();">
                                <i class="bx bx-check-shield"></i> تقييم
                            </button>

                            <button type="button" class="btn btn-outline-secondary" onclick="showWIP();">
                                <i class="bx bx-wrench"></i> الصيانة
                            </button>

                            <button type="button" class="btn btn-outline-secondary" onclick="showWIP();">
                                <i class="bx bx-transfer-alt"></i> نقل إلى فرع آخر
                            </button>

                            <button type="button" class="btn btn-outline-danger" onclick="showWIP();">
                                <i class="bx bx-x-circle"></i> إلغاء
                            </button>
                        </div>

                    </div>
                </div>

            </div>
        </div> <!-- /card -->

    </div>

    <!-- ✅ Hidden: JobTitle_ItemsID لاستخدامه عند التوجيه -->
    <asp:HiddenField ID="hidJobTitleItemsID" runat="server" />

    <!-- Loader عام للصفحة (نفس صفحة الفروع) -->
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

    <!-- ✅ Evaluation Type Modal -->
    <div class="modal fade" id="evaluationTypeModal" tabindex="-1" aria-labelledby="evaluationTypeModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-md modal-dialog-centered">
            <div class="modal-content" style="border-radius: .75rem;">
                <div class="modal-header">
                    <h6 id="evaluationTypeModalLabel" class="modal-title">اختيار نوع التقييم</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
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
                                onclick="selectEvalTypeForTool('<%# Eval("ID") %>');">
                                <span><%# Eval("Title_Ar") %></span>
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

    <!-- WIP Modal (جاري العمل عليها) -->
    <div class="modal fade" id="wipModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content" style="border-radius: .75rem;">
                <div class="modal-header">
                    <h6 class="modal-title">تنبيه</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div class="d-flex align-items-center gap-2">
                        <i class="bx bx-loader-alt bx-spin" style="font-size: 1.2rem;"></i>
                        <span>جاري العمل عليها</span>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-primary" data-bs-dismiss="modal">حسناً</button>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function showPageLoader() {
            var loader = document.getElementById('pageLoader');
            if (!loader) return;

            setTimeout(function () {
                loader.classList.remove('d-none');
            }, 120);
        }

        function hidePageLoader() {
            var loader = document.getElementById('pageLoader');
            if (loader) loader.classList.add('d-none');
        }

        window.addEventListener('pageshow', function () { hidePageLoader(); });
        window.addEventListener('popstate', function () { hidePageLoader(); });
        document.addEventListener('visibilitychange', function () { if (!document.hidden) hidePageLoader(); });
        document.addEventListener('DOMContentLoaded', function () { hidePageLoader(); });

        function showWIP() {
            try {
                var el = document.getElementById('wipModal');
                if (!el) return;
                var m = bootstrap.Modal.getOrCreateInstance(el);
                m.show();
            } catch (e) { }
        }

        // ✅ فتح مودال اختيار النوع
        function openTypeModalForTool() {
            try {
                var el = document.getElementById('evaluationTypeModal');
                if (!el) return;
                var m = bootstrap.Modal.getOrCreateInstance(el);
                m.show();
            } catch (e) { }
        }

        // ✅ بعد اختيار النوع: توجيه لصفحة تقييم الأداة مع Type
        function selectEvalTypeForTool(typeId) {
            var hf = document.getElementById('<%= hidJobTitleItemsID.ClientID %>');
            var jobTitleItemsId = hf ? hf.value : '';

            if (!jobTitleItemsId) {
                alert('حدث خطأ: لم يتم تحديد رقم الأداة.');
                return;
            }

            showPageLoader();

            var url = '/Modules/Evaluations/Tools_Evaluation.aspx?JobTitle_ItemsID='
                + encodeURIComponent(jobTitleItemsId)
                + '&Type=' + encodeURIComponent(typeId);

            window.location.href = url;
        }
    </script>

</asp:Content>
