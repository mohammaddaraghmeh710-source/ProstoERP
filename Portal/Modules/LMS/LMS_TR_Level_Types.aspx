<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="LMS_TR_Level_Types.aspx.vb" Inherits="CRM.LMS_TR_Level_Types" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .employee-hover-banner {
            display: none !important;
        }

        /* ===== Header ===== */
        .lt-header-card {
            background: linear-gradient(135deg, #f4f5fb 0%, #ffffff 40%, #fef9f5 100%);
            border: 1px solid #e5e7eb;
            border-radius: 1rem;
        }

        .lt-header-inner {
            padding: 1.25rem;
        }

        .lt-title {
            font-weight: 800;
            margin: 0;
        }

        .lt-sub {
            margin-top: .5rem;
            color: #6b7280;
        }

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

        .lt-img {
            width: 100%;
            height: 130px;
            object-fit: cover;
            display: block;
        }

        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .lt-meta {
            display: flex;
            flex-wrap: wrap;
            gap: .5rem;
            margin-top: .75rem;
        }

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

        .progress {
            height: 8px;
            border-radius: 999px;
            background: #e5e7eb;
        }

        .progress-bar {
            border-radius: 999px;
        }

        .btn-soft {
            border-radius: .85rem;
            padding: .55rem .9rem;
        }

        /* empty state */
        .lt-empty {
            border: 1px dashed #e5e7eb;
            border-radius: 1rem;
            padding: 1.25rem;
            background: #fafafa;
            color: #6b7280;
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

        <!-- ===== Grid ===== -->
        <asp:Panel ID="pnlGrid" runat="server">
            <div class="row g-4">
                <asp:Repeater ID="rptTypes" runat="server">
                    <ItemTemplate>
                        <div class="col-12 col-md-6 col-xl-4">
                            <div class="card lt-card">
                                <img class="lt-img" style="height: auto !important" src="<%# Eval("ImageUrl") %>" alt="<%# Eval("TitleAr") %>" />

                                <div class="card-body">
                                    <h5 class="fw-bold mb-1"><%# Eval("TitleAr") %></h5>

                                    <p class="text-muted text-truncate-2 mb-0">
                                        <%# Eval("NotesAr") %>
                                    </p>

                                    <div class="lt-meta">
                                        <span class="lt-pill"><%# Eval("LevelsCount") %> مستويات</span>
                                        <span class="lt-pill"><%# Eval("VideosCount") %> فيديو</span>
                                        <span class="lt-pill"><%# Eval("TotalDurationHHMMSS") %> ساعة</span>
                                    </div>

                                    <div class="lt-progress-wrap">
                                        <div class="lt-progress-top">
                                            <span>نسبة الإنجاز</span>
                                            <span><%# Eval("CompletionPercentAvg") %>%</span>
                                        </div>
                                        <div class="progress">
                                            <div class="progress-bar"
                                                style='width: <%# Eval("CompletionPercentAvg") %>%'
                                                role="progressbar"
                                                aria-valuenow="<%# Eval("CompletionPercentAvg") %>"
                                                aria-valuemin="0"
                                                aria-valuemax="100">
                                            </div>
                                        </div>
                                    </div>

                                    <div class="mt-3">
                                        <a class="btn btn-primary btn-soft w-100 <%# If(CBool(Eval("HasLevels")), "", "disabled") %>"
                                            href="<%# Eval("LevelsUrl") %>">مشاهدة المستويات
                                        </a>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>
        </asp:Panel>

        <!-- Empty -->
        <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
            <div class="lt-empty">
                لا يوجد أنواع تدريب لعرضها حالياً.
            </div>
        </asp:Panel>

    </div>

</asp:Content>


