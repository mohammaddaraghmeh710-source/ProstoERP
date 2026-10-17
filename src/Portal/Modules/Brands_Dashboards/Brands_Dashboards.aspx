<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Brands_Dashboards.aspx.vb" Inherits="CRM.Brands_Dashboards" %>


<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .brands-dashboard-wrapper { direction: rtl; text-align: right; }

        /* ===== Welcome / Hero ===== */
        .brands-hero {
            border-radius: 1rem;
            /*background: linear-gradient(135deg, rgba(105,108,255,.18), rgba(255,0,128,.08));*/
            border: 1px solid rgba(105,108,255,.18);
        }
        .brands-hero .hero-title { font-weight: 800; color: #2d2f55; }
        .brands-hero .hero-sub { color: #6b7280; }

        .qr-btn {
            border-radius: .9rem;
            font-weight: 800;
            display: inline-flex;
            align-items: center;
            gap: .5rem;
            padding: .75rem 1rem;
            white-space: nowrap;
        }

        /* ===== Brand Cards (Centered Logo + Title) ===== */
        .brand-card {
            border-radius: 1rem;
            transition: transform .15s ease, box-shadow .15s ease;
            overflow: hidden;
            border: 1px solid rgba(15, 15, 20, .08);
        }
        .brand-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 28px rgba(15, 15, 20, .12);
        }

        .brand-logo-center {
            width: 86px;
            height: 86px;
            border-radius: 20px;
            object-fit: cover;
            box-shadow: 0 10px 20px rgba(0,0,0,.14);
            background: #fff;
        }

        .brand-title-center {
            font-weight: 900;
            color: #32475c;
            margin-top: .75rem;
            line-height: 1.35;
            text-align: center;

            /* Clamp to 2 lines (nice on mobile) */
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
            min-height: calc(1.35em * 2);
        }

        .brand-meta {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: .65rem;
            margin-top: 1rem;
            padding: .75rem;
            border-radius: .9rem;
            background: rgba(105,108,255,.06);
            border: 1px dashed rgba(105,108,255,.22);
            text-align: center;
        }
        .brand-meta .meta-label { color: #6b7280; font-size: .85rem; }
        .brand-meta .meta-value { font-weight: 900; font-size: 1.25rem; color: #111827; }

        .brand-actions .btn {
            border-radius: .9rem;
            font-weight: 900;
            padding: .85rem 1rem;
        }

        /* ===== Mobile ===== */
        @media (max-width: 576px) {
            .brands-hero { border-radius: .9rem; }
            .brand-card { border-radius: .9rem; }
            .brand-logo-center { width: 76px; height: 76px; border-radius: 18px; }
            .brand-meta .meta-value { font-size: 1.15rem; }
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
            border-radius: .95rem;
            background: #ffffff;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .18);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: .75rem;
        }
        .page-loader-text { font-size: .95rem; color: #4b5563; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y brands-dashboard-wrapper">

        <!-- Welcome + QR Button -->
        <div class="card mb-3 brands-hero">
            <div class="card-body d-flex flex-wrap align-items-center justify-content-between gap-2">
                <div class="me-2">
                    <h4 class="mb-1 hero-title">أهلاً بك، <asp:Literal ID="litUserName" runat="server" /></h4>
                    <p class="mb-0 hero-sub">
                        يمكنك استعراض العلامات التجارية واختيار الفروع بسهولة، أو استخدام زر <b>قراءة QRCode</b> للانتقال مباشرةً.
                    </p>
                </div>

                <a href="/modules/QRCode/QRCode_Reader.aspx"
                   class="btn btn-primary qr-btn"
                   onclick="showPageLoader()">
                    <i class="bx bx-qr-scan"></i>
                    قراءة QRCode
                </a>
            </div>
        </div>

        <!-- Brands List -->
        <div class="card">
            <div class="card-header d-flex flex-wrap align-items-center justify-content-between gap-2">
                <div>
                    <h4 class="mb-1">العلامات التجارية</h4>
                    <p class="text-muted mb-0">اختر العلامة التجارية لعرض فروعها.</p>
                </div>

                <span class="badge bg-label-primary fs-6">
                    عدد العلامات: <asp:Literal ID="litBrandsCount" runat="server" />
                </span>
            </div>

            <div class="card-body">

                <asp:PlaceHolder ID="phNoBrands" runat="server" Visible="False">
                    <div class="alert alert-warning" role="alert">
                        لا توجد علامات تجارية متاحة حالياً.
                    </div>
                </asp:PlaceHolder>

                <asp:Repeater ID="rptBrands" runat="server">
                    <HeaderTemplate>
                        <div class="row g-3">
                    </HeaderTemplate>

                    <ItemTemplate>
                        <div class="col-12 col-sm-6 col-lg-4 col-xl-3">
                            <div class="card h-100 brand-card">
                                <div class="card-body d-flex flex-column text-center">

                                    <!-- Logo Center -->
                                    <div class="d-flex justify-content-center">
                                        <img src='<%# Eval("Logo") %>' class="brand-logo-center" alt="Brand Logo" />
                                    </div>

                                    <!-- Name Under Logo -->
                                    <h6 class="brand-title-center mb-0"><%# Eval("Title") %></h6>

                                    <!-- Branches Count -->
                                    <div class="brand-meta mb-2">
                                        <i class="bx bx-store-alt fs-4 text-primary"></i>
                                        <div>
                                            <div class="meta-label">عدد الفروع</div>
                                            <div class="meta-value"><%# Eval("BranchesCount") %></div>
                                        </div>
                                    </div>

                                   <!-- Actions -->
<div class="brand-actions mt-3 mt-auto d-grid gap-2">
    <!-- اختيار الفرع -->
    <a href='<%# Eval("BranchesUrl") %>'
       class="btn btn-label-primary w-100 d-flex align-items-center justify-content-center"
       onclick="showPageLoader()">
        اختيار الفرع <i class="bx bx-chevron-left ms-1"></i>
    </a>

    <!-- احصائيات العلامة التجارية -->
    <a href='<%# Eval("StatisticsUrl") %>'
       class="btn btn-outline-primary w-100 d-flex align-items-center justify-content-center"
       onclick="showPageLoader()">
        <i class="bx bx-bar-chart-alt-2 me-1"></i>
        احصائيات العلامة التجارية
    </a>
</div>


                                </div>
                            </div>
                        </div>
                    </ItemTemplate>

                    <FooterTemplate>
                        </div>
                    </FooterTemplate>
                </asp:Repeater>

            </div>
        </div>

    </div>

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
    </script>

</asp:Content>
