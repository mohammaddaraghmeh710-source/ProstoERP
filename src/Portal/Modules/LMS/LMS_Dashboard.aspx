<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="LMS_Dashboard.aspx.vb" Inherits="CRM.LMS_Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .inspector-dashboard-wrapper { direction: rtl; text-align: right; }
        .employee-hover-banner { display: none !important; }

        /* ===== Header ===== */
        .lt-header-card {
            background: linear-gradient(135deg, #f4f5fb 0%, #ffffff 40%, #fef9f5 100%);
            border: 1px solid #e5e7eb;
            border-radius: 1rem;
        }
        .lt-header-inner { padding: 1.25rem; }
        .lt-title { font-weight: 800; margin: 0; }
        .lt-sub { margin-top: .5rem; color: #6b7280; }

        /* ===== Cards ===== */
        .lt-card {
            border: 1px solid #e5e7eb;
            border-radius: 1rem;
            overflow: hidden;
            transition: .2s ease;
            height: 100%;
            background: #fff;
        }
        .lt-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(0,0,0,.06);
        }
        .lt-img { width: 100%; height: 130px; object-fit: cover; display: block; }
        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .lt-meta { display: flex; flex-wrap: wrap; gap: .5rem; margin-top: .75rem; }
        .lt-pill {
            padding: .25rem .6rem;
            border-radius: 999px;
            background: #f3f4f6;
            border: 1px solid #e5e7eb;
            font-size: .8rem;
            white-space: nowrap;
            color: #374151;
        }

        /* progress */
        .lt-progress-wrap {
            margin-top: .9rem;
            padding: .75rem;
            border: 1px dashed #e5e7eb;
            border-radius: .85rem;
            background: #fafafa;
        }
        .lt-progress-top {
            display: flex;
            justify-content: space-between;
            margin-bottom: .35rem;
            font-weight: 700;
            color: #111827;
        }
        .progress { height: 8px; border-radius: 999px; background: #e5e7eb; }
        .progress-bar { border-radius: 999px; }
        .btn-soft { border-radius: .85rem; padding: .55rem .9rem; }

        /* empty state */
        .lt-empty {
            border: 1px dashed #e5e7eb;
            border-radius: 1rem;
            padding: 1.25rem;
            background: #fafafa;
            color: #6b7280;
        }

        /* ===== News Section ===== */
        .lt-news-card {
            border: 1px solid #e5e7eb;
            border-radius: 1rem;
            background: #fff;
        }
        .lt-news-item {
            display: flex;
            gap: 1rem;
            padding: 1rem;
            border-bottom: 1px solid #f1f5f9;
        }
        .lt-news-item:last-child { border-bottom: 0; }
        .lt-news-thumb {
            width: 110px;
            height: 80px;
            object-fit: cover;
            border-radius: .85rem;
            border: 1px solid #e5e7eb;
            background: #f3f4f6;
            flex: 0 0 auto;
        }
        .lt-news-title { font-weight: 800; margin: 0; font-size: 1rem; }
        .lt-news-brief { margin: .35rem 0 0 0; color: #6b7280; }
        .lt-news-meta {
            margin-top: .5rem;
            display: flex;
            gap: .5rem;
            flex-wrap: wrap;
            align-items: center;
        }
        .lt-news-date { font-size: .8rem; color: #6b7280; }
        .lt-news-pill {
            padding: .2rem .55rem;
            border-radius: 999px;
            background: #f3f4f6;
            border: 1px solid #e5e7eb;
            font-size: .75rem;
            color: #374151;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

        <!-- ===== Header ===== -->
        <div class="card lt-header-card mb-4">
            <div class="lt-header-inner">
                <h4 class="lt-title">أنواع التدريب</h4>
                <p class="lt-sub">اختر نوع التدريب التي ترغب به للاطلاع على المستويات التابعه وله</p>
            </div>
        </div>

        <!-- ===== Types Grid ===== -->
        <asp:Panel ID="pnlGrid" runat="server">
            <div class="row g-4">
                <asp:Repeater ID="rptTypes" runat="server">
                    <ItemTemplate>
                        <div class="col-12 col-md-6 col-xl-4">
                            <div class="card lt-card">
                                <img class="lt-img" style="height: auto !important" src="<%# Eval("ImageUrl")%>" alt="<%# Eval("TitleAr")%>" />

                                <div class="card-body">
                                    <h5 class="fw-bold mb-1"><%# Eval("TitleAr")%></h5>

                                    <p class="text-muted text-truncate-2 mb-0"><%# Eval("NotesAr")%></p>

                                    <div class="lt-meta">
                                        <span class="lt-pill"><%# Eval("LevelsCount")%> مستويات</span>
                                        <span class="lt-pill"><%# Eval("VideosCount")%> فيديو</span>
                                        <span class="lt-pill"><%# Eval("TotalDurationHHMMSS")%> ساعة</span>
                                    </div>

                                    <div class="lt-progress-wrap">
                                        <div class="lt-progress-top">
                                            <span>نسبة الإنجاز</span>
                                            <span><%# Eval("CompletionPercentAvg")%>%</span>
                                        </div>
                                        <div class="progress">
                                            <div class="progress-bar"
                                                style='width: <%# Eval("CompletionPercentAvg")%>%'
                                                role="progressbar"
                                                aria-valuenow="<%# Eval("CompletionPercentAvg")%>"
                                                aria-valuemin="0"
                                                aria-valuemax="100"></div>
                                        </div>
                                    </div>

                                    <div class="mt-3">
                                        <a class="btn btn-primary btn-soft w-100 <%# If(CBool(Eval("HasLevels")), "", "disabled")%>"
                                            href="<%# Eval("LevelsUrl")%>">مشاهدة المستويات</a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>
        </asp:Panel>

        <!-- Empty Types -->
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
            <div class="lt-empty">لا يوجد أنواع تدريب لعرضها حالياً.</div>
        </asp:Panel>

        <!-- ===== News ===== -->
        <div class="card lt-news-card mt-4">
          <%--  <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="card-title mb-0">الأخبار</h5>
                <a class="btn btn-outline-secondary btn-sm" href="/Modules/News/Manage_News.aspx">إدارة الأخبار</a>
            </div>--%>

            <div class="card-body">

                <asp:Panel ID="pnlNews" runat="server">
                    <asp:Repeater ID="rptNews" runat="server" OnItemCommand="rptNews_ItemCommand">
                        <ItemTemplate>
                            <div class="lt-news-item">
                                <img class="lt-news-thumb" src="<%# Eval("ImageUrl")%>" alt="news" />

                                <div class="flex-grow-1">
                                    <p class="lt-news-title"><%# Eval("TitleAr")%></p>

                                    <p class="lt-news-brief text-truncate-2"><%# Eval("BriefAr")%></p>

                                    <div class="lt-news-meta">
                                        <span class="lt-news-date"><%# Eval("DisplayDate")%></span>
<%--                                        <span class="lt-news-pill">خبر</span>--%>

                                        <!-- زر تفاصيل يفتح Modal -->
                                        <asp:LinkButton ID="btnNewsDetails"
                                            runat="server"
                                            CssClass="btn btn-primary btn-soft btn-sm ms-auto"
                                            CommandName="NewsDetails"
                                            CommandArgument='<%# Eval("PID")%>'
                                            CausesValidation="false">
                                            عرض التفاصيل
                                        </asp:LinkButton>
                                    </div>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </asp:Panel>

                <asp:Panel ID="pnlNewsEmpty" runat="server" Visible="false">
                    <div class="lt-empty">لا يوجد أخبار لعرضها حالياً.</div>
                </asp:Panel>

            </div>
        </div>

        <!-- ===== News Details Modal ===== -->
        <div class="modal fade" id="newsDetailsModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content" style="border-radius: 1rem;">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <asp:Literal ID="litNewsTitle" runat="server"></asp:Literal>
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body" style="direction: rtl; text-align: right;">

                        <asp:Panel ID="pnlNewsImage" runat="server" Visible="false" CssClass="mb-3" style="text-align:center">
                            <img id="imgNewsModal" runat="server" class="img-fluid"
                                style="border-radius: .85rem; border: 1px solid #e5e7eb;width:40%" alt="news" />
                        </asp:Panel>

                        <div class="text-muted mb-2" style="font-size: .9rem;">
                            <i class="bx bx-time"></i>
                            <asp:Literal ID="litNewsDate" runat="server"></asp:Literal>
                        </div>

                        <div class="mb-3">
                            <div class="fw-bold mb-1">النبذة</div>
                            <div class="text-muted">
                                <asp:Literal ID="litNewsBrief" runat="server"></asp:Literal>
                            </div>
                        </div>

                        <div>
                            <div class="fw-bold mb-1">التفاصيل</div>
                            <div>
                                <asp:Literal ID="litNewsDetails" runat="server"></asp:Literal>
                            </div>
                        </div>

                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">إغلاق</button>
                    </div>
                </div>
            </div>
        </div>

       <script type="text/javascript">
           function openNewsDetailsModal() {
               var el = document.getElementById('newsDetailsModal');
               if (!el) return;

               // Bootstrap 5
               if (window.bootstrap && bootstrap.Modal) {
                   var m = bootstrap.Modal.getOrCreateInstance(el);
                   m.show();
                   return;
               }

               // Bootstrap 4 (jQuery)
               if (window.jQuery && $('#newsDetailsModal').modal) {
                   $('#newsDetailsModal').modal('show');
                   return;
               }

               console.log("Bootstrap modal library not found.");
           }
       </script>

    </div>
</asp:Content>