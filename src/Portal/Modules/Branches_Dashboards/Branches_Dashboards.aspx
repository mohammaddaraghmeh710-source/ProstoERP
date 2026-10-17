<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Branches_Dashboards.aspx.vb" Inherits="CRM.Branches_Dashboards" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .branches-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .branch-card {
            border-radius: .75rem;
            transition: transform .15s ease, box-shadow .15s ease;
        }

        .branch-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 10px 25px rgba(15, 15, 20, .12);
        }

        .branch-logo {
            width: 64px;
            height: 64px;
            border-radius: 50%;
            object-fit: cover;
            box-shadow: 0 3px 10px rgba(0, 0, 0, .18);
        }

        .branch-card-rating i {
            font-size: 1.1rem;
            margin-inline: 1px;
        }

        .branch-score-text {
            font-weight: 600;
        }

        .branch-metrics {
            gap: .75rem;
        }

        .branch-metrics-item {
            flex: 1 1 0;
        }

        .branch-metrics-item .metric-value {
            font-weight: 600;
            font-size: 1.2rem;
        }

        @media (max-width: 576px) {
            .branch-card {
                border-radius: .6rem;
            }
            .branch-metrics-item .metric-value {
                font-size: 1.05rem;
            }
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


    </style>
</asp:Content>


<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y branches-dashboard-wrapper">

        <!-- كامل الصفحة داخل Card -->
        <div class="card">

            <!-- Card Header -->
            <div class="card-header d-flex flex-wrap align-items-center justify-content-between gap-2">
                <div>
                    <h4 class="mb-1">تقييم الفروع</h4>
                    <p class="text-muted mb-0">
    أدناه ستجد تقييم كل فرع بناءً على جميع الورديات، مع عدد الموظفين، المهام غير المنجزة، والشكاوي،
    أو يمكنك استخدام زر <strong>قراءة QRCode</strong> للانتقال مباشرةً.
</p>

                </div>

               <div class="d-flex align-items-center gap-2">
    <span class="badge bg-label-primary fs-6">
        العلامة التجارية: <asp:Literal ID="litBrandName" runat="server" />
    </span>

    <a href="/modules/QRCode/QRCode_Reader.aspx"
       class="btn btn-outline-primary btn-sm d-flex align-items-center"
       onclick="showBranchLoader()">
        <i class="bx bx-qr-scan me-1"></i>
        قراءة QRCode
    </a>
</div>

            </div>

            <!-- Card Body -->
            <div class="card-body">

                <asp:PlaceHolder ID="phNoBranches" runat="server" Visible="False">
                    <div class="alert alert-warning" role="alert">
                        لا يوجد فروع مرتبطة بهذه العلامة التجارية حتى الآن.
                    </div>
                </asp:PlaceHolder>

                <asp:Repeater ID="rptBranches" runat="server">
                    <HeaderTemplate>
                        <div class="row g-3">
                    </HeaderTemplate>

                    <ItemTemplate>
    <div class="col-12 col-sm-6 col-lg-4 col-xl-3">
        <a href='<%# Eval("DetailsUrl") %>' 
           class="text-decoration-none"
           onclick="showBranchLoader()">
            <div class="card h-100 branch-card">
                <div class="card-body d-flex flex-column align-items-center text-center">

                    <!-- Logo + Name -->
                    <img src='<%# Eval("BrandLogo") %>' class="branch-logo mb-3">
                    <h6 class="mb-1 text-body"><%# Eval("BranchName") %></h6>

                    <!-- Rating -->
                    <div class="branch-card-rating mb-1">
                        <i class='<%# GetStarClass(Eval("Stars"), 1) %>'></i>
                        <i class='<%# GetStarClass(Eval("Stars"), 2) %>'></i>
                        <i class='<%# GetStarClass(Eval("Stars"), 3) %>'></i>
                        <i class='<%# GetStarClass(Eval("Stars"), 4) %>'></i>
                        <i class='<%# GetStarClass(Eval("Stars"), 5) %>'></i>
                    </div>
                    <div class="small text-muted mb-3 branch-score-text">
                        <%# String.Format("{0:0.0}%", Eval("Score")) %>
                    </div>

                    <!-- Metrics -->
                    <div class="d-flex justify-content-between w-100 branch-metrics mb-3 text-nowrap">
                        <div class="branch-metrics-item text-center">
                            <div class="metric-value text-danger"><%# Eval("ComplaintsCount") %></div>
                            <div class="text-muted small">عدد الشكاوي</div>
                        </div>

                        <div class="branch-metrics-item text-center">
                            <div class="metric-value text-warning"><%# Eval("UnfinishedTasksCount") %></div>
                            <div class="text-muted small">عدد المهام</div>
                        </div>

                        <div class="branch-metrics-item text-center">
                            <div class="metric-value text-primary"><%# Eval("EmployeesCount") %></div>
                            <div class="text-muted small">عدد الموظفين</div>
                        </div>
                    </div>

                    <!-- Button -->
                    <div class="mt-auto w-100">
                        <span class="btn btn-primary w-100 d-flex align-items-center justify-content-center">
                            تقييم الفرع <i class="bx bx-chevron-left ms-1"></i>
                        </span>
                    </div>

                </div>
            </div>
        </a>
    </div>
</ItemTemplate>


                    <FooterTemplate>
                        </div>
                    </FooterTemplate>
                </asp:Repeater>

            </div>
        </div> <!-- /card -->

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
       function showBranchLoader() {
           var loader = document.getElementById('pageLoader');
           if (loader) loader.classList.remove('d-none');
       }

       function hideBranchLoader() {
           var loader = document.getElementById('pageLoader');
           if (loader) loader.classList.add('d-none');
       }

       // 1) عند الرجوع للصفحة من Back (bfcache) أو إعادة عرضها
       window.addEventListener('pageshow', function () {
           hideBranchLoader();
       });

       // 2) لو المستخدم رجع/تقدم من المتصفح (مفيد لبعض الأجهزة)
       window.addEventListener('popstate', function () {
           hideBranchLoader();
       });

       // 3) إذا الصفحة رجعت للواجهة بعد ما كانت مخفية
       document.addEventListener('visibilitychange', function () {
           if (!document.hidden) hideBranchLoader();
       });

       // 4) احتياط: عند التحميل الطبيعي
       document.addEventListener('DOMContentLoaded', function () {
           hideBranchLoader();
       });


       function showBranchLoader() {
           var loader = document.getElementById('pageLoader');
           if (!loader) return;

           // تأخير بسيط يمنع “تعليق” لو ما صار انتقال فعلي
           setTimeout(function () {
               loader.classList.remove('d-none');
           }, 120);
       }


   </script>

</asp:Content>



