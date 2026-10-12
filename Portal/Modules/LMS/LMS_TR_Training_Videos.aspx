<%@ Page Title="فيديوهات المستوى" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="LMS_TR_Training_Videos.aspx.vb" Inherits="CRM.LMS_TR_Training_Videos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">



    <style>
        .inspector-dashboard-wrapper {
            direction: rtl;
            text-align: right;
        }

        .text-truncate-2 {
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .status-badge {
            font-size: .75rem;
            border-radius: 6px;
            padding: .2rem .6rem;
            border: 1px solid transparent;
            white-space: nowrap;
            display: inline-flex;
            align-items: center;
            gap: .35rem;
        }

        /* 1=open green, 2=done blue, 3=locked red */
        .status-green {
            background: #dcfce7;
            color: #166534;
            border-color: #bbf7d0;
        }

        .status-blue {
            background: #dbeafe;
            color: #1d4ed8;
            border-color: #bfdbfe;
        }

        .status-red {
            background: #fee2e2;
            color: #b91c1c;
            border-color: #fecaca;
        }

        .video-card {
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            overflow: hidden;
            height: 100%;
        }

        .video-card-inner {
            padding: 16px 18px;
        }

        .video-title {
            font-weight: 800;
            color: #111827;
            font-size: 1.0rem;
            margin: 0;
        }

        .video-subtitle {
            color: #6b7280;
            font-size: .9rem;
            line-height: 1.7;
            margin-top: 6px;
        }

        .meta-row {
            display: flex;
            gap: 14px;
            flex-wrap: wrap;
            align-items: center;
            color: #6b7280;
            font-size: .85rem;
            margin-top: 10px;
        }

            .meta-row .mini {
                display: inline-flex;
                align-items: center;
                gap: .35rem;
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

        .watch-progress-wrap {
            margin-top: 12px;
        }

        .watch-progress-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            gap: 10px;
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
                transition: width .25s ease;
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

        .player-card {
            border-radius: 14px;
            border: 1px solid #e5e7eb;
            background: #fff;
            overflow: hidden;
        }

        .player-head {
            padding: 14px 16px;
            border-bottom: 1px solid #eef2f7;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

        .player-body {
            padding: 14px 16px;
        }

            .player-body video {
                width: 100%;
                border-radius: 12px;
                background: #111827;
            }

        /* Start panel when all videos locked */
        .start-box {
            border: 1px dashed #d1d5db;
            border-radius: 14px;
            padding: 18px;
            background: #fcfcfd;
            color: #374151;
        }

        /* نفس ستايل الفيديو الآمن */
        .secure-video-wrapper {
            position: relative;
        }

            .secure-video-wrapper video {
                display: block;
                width: 100%;
                border-radius: 12px;
            }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <!-- مهم جداً لتفعيل PageMethods داخل Content -->
    <asp:ScriptManagerProxy ID="ScriptManagerProxy1" runat="server" />

    <div class="container-xxl flex-grow-1 container-p-y inspector-dashboard-wrapper">

        <!-- Hidden fields -->
        <asp:HiddenField ID="hfFirstVideoId" runat="server" />
        <asp:HiddenField ID="hfFirstVideoTitle" runat="server" />
        <asp:HiddenField ID="hfFirstVideoSecureUrl" runat="server" />
        <asp:HiddenField ID="hfCurrentVideoId" runat="server" />
        <asp:HiddenField ID="hfLevelId" runat="server" />

        <!-- Page Header -->
        <div class="row">
            <div class="col-12">
                <div class="card mb-4 employee-header-card">
                    <div class="row">
                        <div class="col-12 mb-3">
                            <div class="card-body d-flex justify-content-between align-items-center flex-wrap gap-2">
                                <div>
                                    <h5 class="mb-1">فيديوهات مستوى:
                                        <span id="LevelTitleText" runat="server">-</span>
                                    </h5>
                                    <div class="text-muted" style="font-size: .9rem;">
                                        <i class="bx bx-info-circle ms-1"></i>لا يمكن مشاهدة الفيديوهات إلا بالترتيب.
                                    </div>
                                </div>

                                <!-- ✅ Back link with querystring -->
                                <a id="lnkBackLevels" runat="server" class="btn btn-sm btn-soft">
                                    <i class="bx bx-left-arrow-alt ms-1"></i>الرجوع للمستويات
                                </a>

                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3">

            <!-- Player -->
            <div class="col-lg-8 col-md-12">

                <asp:Panel ID="pnlPlayer" runat="server">
                    <div class="player-card">
                        <div class="player-head">
                            <div class="d-flex flex-column">
                                <div class="fw-bold" style="color: #111827;" id="playerTitle">-</div>
                                <div class="text-muted" style="font-size: .9rem;" id="playerSummary">-</div>
                            </div>

                            <span id="playerBadge" class="status-badge status-green">
                                <i class="bx bx-play-circle"></i>متاح حاليا
                            </span>
                        </div>

                        <div class="player-body">
                            <div class="secure-video-wrapper" oncontextmenu="return false;">
                                <video id="trainingVideo"
                                    controls
                                    playsinline
                                    controlslist="nodownload noplaybackrate"
                                    disablepictureinpicture
                                    preload="metadata">
                                    <source id="videoSource" src="" type="video/mp4" />
                                    المتصفح لا يدعم تشغيل الفيديو.
                                </video>
                            </div>

                            <small class="d-block mt-2 text-center text-muted">هذا الفيديو مخصص للاستخدام الداخلي لموظفي بروستو فقط.
                            </small>

                            <div class="mt-3">
                                <div class="watch-progress-wrap">
                                    <div class="watch-progress-head">
                                        <div class="label">نسبة المشاهدة</div>
                                        <div class="percent" id="playerPercent">0%</div>
                                    </div>
                                    <div class="watch-progress">
                                        <span id="playerBar" style="width: 0%"></span>
                                    </div>
                                </div>

                                <div class="d-flex flex-wrap gap-2 mt-3">
                                    <span class="date-pill start">
                                        <i class="bx bx-calendar"></i>بداية المشاهدة:
                                        <span id="playerStartDate">-</span>
                                    </span>
                                    <span class="date-pill end">
                                        <i class="bx bx-calendar-x"></i>نهاية المشاهدة:
                                        <span id="playerEndDate">-</span>
                                    </span>
                                </div>

                                <div class="meta-row mt-2">
                                    <span class="mini"><i class="bx bx-time-five"></i>المدة: <span id="playerDuration">-</span></span>
                                    <span class="mini"><i class="bx bx-map-pin"></i>آخر نقطة: <span id="playerLastPos">-</span></span>
                                </div>
                            </div>

                        </div>
                    </div>
                </asp:Panel>

                <!-- Start Panel -->
                <asp:Panel ID="pnlStart" runat="server" Visible="false">
                    <div class="start-box">
                        <div class="d-flex align-items-start gap-2">
                            <i class="bx bx-info-circle" style="font-size: 1.6rem;"></i>
                            <div>
                                <div class="fw-bold mb-1">لم يتم البدء بمشاهدة فيديوهات هذا المستوى بعد</div>
                                <div class="text-muted">اضغط على زر "بدء المشاهدة" لتفعيل الفيديو الأول والبدء بالتقدم.</div>
                            </div>
                        </div>

                        <div class="mt-3 d-flex gap-2">
                            <button type="button" class="btn btn-primary btn-sm" onclick="openStartFirstVideoModal();">
                                <i class="bx bx-play-circle ms-1"></i>بدء المشاهدة
                            </button>

                            <a id="lnkBackLevels2" runat="server" class="btn btn-soft btn-sm">الرجوع للمستويات</a>
                        </div>
                    </div>
                </asp:Panel>

            </div>

            <!-- Videos list -->
            <div class="col-lg-4 col-md-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h6 class="card-title mb-0">قائمة الفيديوهات</h6>
                        <span class="text-muted" style="font-size: .85rem;">
                            <span id="VideosCountText" runat="server">0</span> فيديو
                        </span>
                    </div>

                    <div class="card-body">
                        <div class="row g-2" id="videosList">

                            <asp:Repeater ID="rptVideos" runat="server">
                                <ItemTemplate>

                                    <div class="col-12 video-item"
                                        data-videoid="<%# Eval("VideoID") %>"
                                        data-statusid="<%# Eval("Status") %>"
                                        data-src="<%# Eval("SecureUrl") %>"
                                        data-title="<%# Eval("VideoTitle_Ar") %>"
                                        data-summary="<%# Eval("Summary_Ar") %>"
                                        data-duration="<%# Eval("DurationSeconds") %>"
                                        data-start="<%# Eval("StartDateText") %>"
                                        data-end="<%# Eval("EndDateText") %>"
                                        data-lastpos="<%# Eval("LastPositionSeconds") %>"
                                        data-percent="<%# Eval("CompletionPercent") %>">

                                        <div class="video-card">
                                            <div class="video-card-inner">

                                                <div class="d-flex justify-content-between align-items-start gap-2">
                                                    <div style="flex: 1;">
                                                        <h6 class="video-title mb-1"><%# Eval("CardTitle") %></h6>
                                                        <div class="video-subtitle text-truncate-2"><%# Eval("Summary_Ar") %></div>
                                                    </div>

                                                    <span class='status-badge <%# Eval("StatusCss") %>'>
                                                        <i class='bx <%# Eval("StatusIcon") %>'></i><%# Eval("StatusText") %>
                                                    </span>
                                                </div>

                                                <div class="meta-row">
                                                    <span class="mini"><i class="bx bx-time-five"></i><%# Eval("DurationText") %></span>
                                                    <span class="mini"><i class="bx bx-percentage"></i><%# Eval("CompletionPercent") %>%</span>
                                                </div>

                                                <div class="watch-progress-wrap" data-watch="<%# Eval("CompletionPercent") %>">
                                                    <div class="watch-progress">
                                                        <span style='width: <%# Eval("CompletionPercent") %>%'></span>
                                                    </div>
                                                </div>

                                                <div class="d-flex justify-content-end mt-2">
                                                    <asp:PlaceHolder ID="phWatch" runat="server" Visible='<%# Eval("CanWatch") %>'>
                                                        <button type="button"
                                                            class='btn btn-sm <%# Eval("ActionBtnCss") %>'
                                                            onclick="selectVideoFromCard(this)">
                                                            <%# Eval("ActionText") %>
                                                        </button>
                                                    </asp:PlaceHolder>

                                                    <asp:PlaceHolder ID="phLocked" runat="server" Visible='<%# Not CBool(Eval("CanWatch")) %>'>
                                                        <button type="button" class="btn btn-sm btn-soft btn-disabled" disabled>غير متاح</button>
                                                    </asp:PlaceHolder>
                                                </div>

                                            </div>
                                        </div>

                                    </div>

                                </ItemTemplate>
                            </asp:Repeater>

                            <!-- Next Level Button (shown only when all videos are completed) -->
                            <asp:Panel ID="pnlNextLevel" runat="server" Visible="false">
                                <asp:LinkButton ID="btnGoNextLevel" runat="server"
                                    CssClass="btn btn-danger w-100 mt-3"
                                    OnClick="btnGoNextLevel_Click">
        الانتقال الى المستوى التالي
                                    <i class="bx bx-left-arrow-alt ms-1"></i>
                                </asp:LinkButton>
</asp:Panel>


                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- ✅ Start First Video Modal -->
    <div class="modal fade" id="startFirstVideoModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content" style="border-radius: 14px;">
                <div class="modal-header">
                    <h5 class="modal-title">بدء مشاهدة فيديوهات المستوى</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body" style="line-height: 1.9; color: #374151;">
                    <div class="d-flex align-items-start gap-2">
                        <i class="bx bx-play-circle" style="font-size: 1.6rem;"></i>
                        <div>
                            <div class="fw-bold mb-1">سيتم تفعيل الفيديو الأول للبدء</div>
                            <div class="text-muted">
                                اسم الفيديو:
                                <span class="fw-bold" id="firstVideoNameText">-</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <asp:LinkButton ID="btnConfirmStart"
                        runat="server"
                        CssClass="btn btn-sm btn-primary"
                        OnClick="btnConfirmStart_Click">
                        موافق
                    </asp:LinkButton>

                    <button type="button" class="btn btn-sm btn-soft" data-bs-dismiss="modal">إلغاء</button>
                </div>
            </div>
        </div>
    </div>

    <!-- ✅ Video Completed Modal -->
    <div class="modal fade" id="videoCompletedModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content" style="border-radius: 14px;">
                <div class="modal-header">
                     <i class="bx bx-check-circle" style="font-size: 1.8rem;"></i>
                    <h5 class="modal-title">تم إنهاء الفيديو</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body" style="line-height: 1.9; color: #374151;">
                    <div class="d-flex align-items-start gap-2">
                       
                        <div>
                            <div class="mt-2">
                              <span class="fw-bold" id="completedVideoTitle">-</span>
                            </div>
                            <div class="fw-bold mb-1">أحسنت! تم إنهاء الفيديو الحالي بنجاح.</div>
                            <div class="text-muted">
                                سيتم تفعيل الفيديو التالي عند الضغط على <span class="fw-bold">موافق</span>.
                            </div>
                            
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-sm btn-primary" onclick="confirmUnlockNextVideo()">
                        موافق
                    </button>
                    <button type="button" class="btn btn-sm btn-soft" data-bs-dismiss="modal" onclick="confirmUnlockNextVideo()">إغلاق</button>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function clamp(n, a, b) { return Math.max(a, Math.min(b, n)); }

        function secondsToText(sec) {
            sec = Math.max(0, sec || 0);
            var h = Math.floor(sec / 3600);
            var m = Math.floor((sec % 3600) / 60);
            var s = Math.floor(sec % 60);
            if (h > 0) return h + "h " + m + "m";
            if (m > 0) return m + "m " + s + "s";
            return s + "s";
        }

        function setPlayerStatusBadge(statusId) {
            var el = document.getElementById('playerBadge');
            if (!el) return;

            el.classList.remove('status-green', 'status-blue', 'status-red');

            if (statusId === 1) {
                el.classList.add('status-green');
                el.innerHTML = '<i class="bx bx-play-circle"></i> متاح حاليا';
            } else if (statusId === 2) {
                el.classList.add('status-blue');
                el.innerHTML = '<i class="bx bx-check-circle"></i> مكتمل';
            } else {
                el.classList.add('status-red');
                el.innerHTML = '<i class="bx bx-lock"></i> مغلق';
            }
        }

        function setPlayerProgress(p, lastPos, duration) {
            p = clamp(isNaN(p) ? 0 : p, 0, 100);
            var pp = Math.round(p);

            document.getElementById('playerPercent').innerText = pp + "%";
            document.getElementById('playerBar').style.width = pp + "%";
            document.getElementById('playerLastPos').innerText = (lastPos || 0) + "s";
            document.getElementById('playerDuration').innerText = secondsToText(duration || 0);
        }

        // ========= PageMethods Helper =========
        function callPageMethod_Save(videoId, lastPos, percent, isEnded, onOk) {
            if (!window.PageMethods || !PageMethods.SaveVideoProgress) return;
            PageMethods.SaveVideoProgress(videoId, lastPos, percent, isEnded === true,
                function () { if (onOk) onOk(); },
                function () { /* silent */ }
            );
        }

        function callPageMethod_Complete(levelId, videoId, onOk) {
            if (!window.PageMethods || !PageMethods.CompleteAndUnlockNext) return;
            PageMethods.CompleteAndUnlockNext(levelId, videoId,
                function () { if (onOk) onOk(); },
                function () { /* silent */ }
            );
        }

        // ========= Current Context =========
        var currentVideoId = 0;
        var currentVideoTitle = "-";
        var currentVideoStatusId = 0; // 1=open,2=done,3=locked

        var saveGuardLastPos = -999;

        // آخر نقطة مسموحة للتقديم (من DB + تتحدث أثناء المشاهدة)
        var maxAllowedSeconds = 0;
        var SEEK_TOLERANCE = 2;

        // يمنع الحفظ أثناء الاسترجاع بعد reload
        var restoreInProgress = false;

        // ✅ Start from last position ONLY when user presses Play
        var pendingStartPos = 0;     // آخر نقطة من DB
        var pendingApplied = false;  // هل طبقناها؟
        var playHooked = false;      // هل ربطنا حدث play؟

        function setCurrentVideoContext(videoId, title, statusId, lastPos) {
            currentVideoId = parseInt(videoId || 0, 10) || 0;
            currentVideoTitle = title || "-";
            currentVideoStatusId = parseInt(statusId || 0, 10) || 0;

            maxAllowedSeconds = parseInt(lastPos || 0, 10) || 0;

            var hf = document.getElementById('<%= hfCurrentVideoId.ClientID %>');
            if (hf) hf.value = currentVideoId;
        }

        function safeSaveProgress(force) {
            var v = document.getElementById('trainingVideo');
            if (!v || !v.duration || currentVideoId <= 0) return;

            // ✅ لا تحفظ أثناء Restore أو قبل تطبيق pendingStartPos
            if (restoreInProgress || !pendingApplied) return;

            // ✅ إذا مكتمل لا تحفظ نهائياً
            if (currentVideoStatusId === 2) return;

            var pos = Math.floor(v.currentTime || 0);
            var dur = Math.floor(v.duration || 0);
            if (dur <= 0) return;

            // ✅ منع downgrade/reset: لا تسمح بحفظ قيمة أقل من آخر نقطة مسموحة
            if (maxAllowedSeconds > 0 && (pos + 1) < maxAllowedSeconds) return;

            if (!force) {
                // حفظ كل ~10 ثواني
                if (Math.abs(pos - saveGuardLastPos) < 10) return;
            }

            saveGuardLastPos = pos;

            // تحديث آخر نقطة مسموحة للتقديم للأمام
            maxAllowedSeconds = Math.max(maxAllowedSeconds || 0, pos || 0);

            var percent = Math.floor((pos / dur) * 100);
            percent = clamp(percent, 0, 100);

            // تحديث UI
            setPlayerProgress(percent, pos, dur);

            callPageMethod_Save(currentVideoId, pos, percent, false);
        }

        function hookPlayStartOnce() {
            var v = document.getElementById('trainingVideo');
            if (!v || playHooked) return;

            playHooked = true;

            // ✅ أول مرة المستخدم يضغط Play: نرجّع لآخر pendingStartPos ثم نبدأ تشغيل
            v.addEventListener('play', function onFirstPlay() {

                // إذا طبقناها مسبقاً أو لا يوجد pending
                if (pendingApplied) return;

                // إذا الفيديو مكتمل: لا داعي
                if (currentVideoStatusId === 2) {
                    pendingApplied = true;
                    return;
                }

                var target = parseInt(pendingStartPos || 0, 10) || 0;

                // لا يوجد lastPos
                if (target <= 0) {
                    pendingApplied = true;
                    saveGuardLastPos = Math.floor(v.currentTime || 0);
                    maxAllowedSeconds = Math.max(maxAllowedSeconds || 0, saveGuardLastPos || 0);
                    return;
                }

                // أوقف التشغيل لحظة، اعمل seek، ثم شغّل
                try { v.pause(); } catch (e) { }

                restoreInProgress = true;

                try {
                    // منع seek خارج المدة
                    if (v.duration && target >= v.duration) target = Math.max(0, Math.floor(v.duration - 1));
                    v.currentTime = target;
                } catch (e) {
                    restoreInProgress = false;
                    pendingApplied = true;
                    try { v.play(); } catch (x) { }
                    return;
                }

                var onSeeked = function () {
                    v.removeEventListener('seeked', onSeeked);

                    restoreInProgress = false;

                    // ✅ الآن طبقنا start pos
                    pendingApplied = true;

                    // ✅ اعتبرنا أننا وصلنا لهذه النقطة حتى لا يعمل حفظ 0
                    saveGuardLastPos = target;
                    maxAllowedSeconds = Math.max(maxAllowedSeconds || 0, target || 0);

                    // تحديث UI مباشرة
                    setPlayerProgress(clamp(Math.floor((target / (v.duration || 1)) * 100), 0, 100), target, Math.floor(v.duration || 0));

                    // شغّل الفيديو من نفس النقطة
                    try { v.play(); } catch (e) { }
                };

                v.addEventListener('seeked', onSeeked);
            });
        }

        function wireVideoEventsOnce() {
            var v = document.getElementById('trainingVideo');
            if (!v || v.dataset.wired === "1") return;
            v.dataset.wired = "1";

            // ✅ hook play once (start from lastPos)
            hookPlayStartOnce();

            v.addEventListener('timeupdate', function () {
                safeSaveProgress(false);
            });

            v.addEventListener('pause', function () {
                safeSaveProgress(true);
            });

            // ✅ منع التقديم للأمام أكثر من آخر نقطة (إلا إذا مكتمل)
            v.addEventListener('seeking', function () {

                if (!v) return;

                // إذا مكتمل => يسمح بالتنقل بحرية
                if (currentVideoStatusId === 2) return;

                // إذا لم يتم تطبيق pending بعد، لا نسمح بأي seeking (حتى لا نخرب start)
                if (!pendingApplied) {
                    try { v.currentTime = Math.max(0, pendingStartPos || 0); } catch (e) { }
                    return;
                }

                var current = Math.floor(v.currentTime || 0);
                var allowed = Math.floor(maxAllowedSeconds || 0) + SEEK_TOLERANCE;

                if (current > allowed) {
                    try {
                        v.currentTime = Math.max(0, maxAllowedSeconds || 0);
                    } catch (e) { }
                }

                safeSaveProgress(true);
            });

            v.addEventListener('ended', function () {

                // إذا مكتمل سابقاً لا نعمل أي شيء
                if (currentVideoStatusId === 2) return;

                // لا تعتمد على ended قبل تطبيق pending
                if (!pendingApplied) pendingApplied = true;

                var pos = Math.floor(v.duration || 0);

                callPageMethod_Save(currentVideoId, pos, 100, true, function () {
                    document.getElementById('completedVideoTitle').innerText = currentVideoTitle;

                    var modalEl = document.getElementById('videoCompletedModal');
                    if (window.bootstrap && bootstrap.Modal) {
                        bootstrap.Modal.getOrCreateInstance(modalEl).show();
                    } else if (window.$) {
                        $(modalEl).modal('show');
                    } else {
                        modalEl.classList.add('show');
                        modalEl.style.display = 'block';
                    }
                });
            });
        }

        function loadVideoToPlayer(title, summary, src, statusId, duration, start, end, lastPos, percent) {

            document.getElementById('playerTitle').innerText = title || "-";
            document.getElementById('playerSummary').innerText = summary || "-";
            document.getElementById('playerStartDate').innerText = start || "-";
            document.getElementById('playerEndDate').innerText = end || "-";

            setPlayerStatusBadge(statusId);
            setPlayerProgress(percent, lastPos, duration);

            var v = document.getElementById('trainingVideo');
            var srcEl = document.getElementById('videoSource');

            if (!v || !srcEl) return;

            // ✅ تحديث الكونتكست (status + lastPos)
            setCurrentVideoContext(currentVideoId, title, statusId, lastPos);

            // ✅ reset play hook flags لكل فيديو جديد
            pendingStartPos = parseInt(lastPos || 0, 10) || 0;
            pendingApplied = (pendingStartPos <= 0); // إذا لا يوجد lastPos اعتبره مطبق
            restoreInProgress = false;

            playHooked = false; // نعيد الربط لكل فيديو جديد

            srcEl.src = src || "";
            v.load();

            wireVideoEventsOnce();

            // ✅ لا نعمل seek هنا
            // فقط نضمن أن maxAllowedSeconds = lastPos حتى نمنع التقديم للأمام قبل play
            maxAllowedSeconds = pendingStartPos;

            // ✅ لو المستخدم ضغط play مباشرة قبل metadata، عادي: play handler يعالج بعد metadata تلقائياً
        }

        function selectVideoFromCard(btn) {
            var card = btn.closest('.video-item');
            if (!card) return;

            var statusId = parseInt(card.getAttribute('data-statusid') || '1', 10);
            if (statusId === 3) return; // locked

            var videoId = parseInt(card.getAttribute('data-videoid') || '0', 10) || 0;
            var src = card.getAttribute('data-src') || "";
            var title = card.getAttribute('data-title') || "-";
            var summary = card.getAttribute('data-summary') || "-";
            var duration = parseInt(card.getAttribute('data-duration') || "0", 10) || 0;
            var start = card.getAttribute('data-start') || "-";
            var end = card.getAttribute('data-end') || "-";
            var lastPos = parseInt(card.getAttribute('data-lastpos') || "0", 10) || 0;
            var percent = parseFloat(card.getAttribute('data-percent') || "0") || 0;

            // ✅ set context with status + lastPos
            setCurrentVideoContext(videoId, title, statusId, lastPos);

            // reset save guard when switching
            saveGuardLastPos = -999;

            loadVideoToPlayer(title, summary, src, statusId, duration, start, end, lastPos, percent);
        }

        // ===== Start First Video Modal =====
        function openStartFirstVideoModal() {
            var title = document.getElementById('<%= hfFirstVideoTitle.ClientID %>').value || "-";
            document.getElementById('firstVideoNameText').innerText = title;

            var modalEl = document.getElementById('startFirstVideoModal');
            if (!modalEl) return;

            if (window.bootstrap && bootstrap.Modal) {
                bootstrap.Modal.getOrCreateInstance(modalEl).show();
            } else if (window.$) {
                $(modalEl).modal('show');
            } else {
                modalEl.classList.add('show');
                modalEl.style.display = 'block';
            }
        }

        // ===== Unlock next on confirm =====
        function confirmUnlockNextVideo() {
            var modalEl = document.getElementById('videoCompletedModal');
            try { if (window.bootstrap) bootstrap.Modal.getOrCreateInstance(modalEl).hide(); } catch (e) { }

            var levelId = parseInt(document.getElementById('<%= hfLevelId.ClientID %>').value || '0', 10) || 0;

            callPageMethod_Complete(levelId, currentVideoId, function () {
                // Refresh page using JavaScript
                window.location.reload();
            });
        }

        // ===== Auto-load first open video =====
        function autoLoadFirstOpenVideo() {
            var container = document.getElementById('videosList');
            if (!container) return;

            var items = container.querySelectorAll('.video-item');
            var openCard = null;

            items.forEach(function (c) {
                var st = parseInt(c.getAttribute('data-statusid') || '3', 10);
                if (openCard === null && st === 1) openCard = c;
            });

            if (!openCard) {
                items.forEach(function (c) {
                    var st = parseInt(c.getAttribute('data-statusid') || '3', 10);
                    if (openCard === null && st === 2) openCard = c;
                });
            }

            if (!openCard) return;

            var vid = parseInt(openCard.getAttribute('data-videoid') || "0", 10) || 0;
            var title = openCard.getAttribute('data-title') || "-";
            var statusId = parseInt(openCard.getAttribute('data-statusid') || '1', 10) || 1;
            var lastPos = parseInt(openCard.getAttribute('data-lastpos') || '0', 10) || 0;

            setCurrentVideoContext(vid, title, statusId, lastPos);
            saveGuardLastPos = -999;

            loadVideoToPlayer(
                openCard.getAttribute('data-title'),
                openCard.getAttribute('data-summary'),
                openCard.getAttribute('data-src'),
                statusId,
                parseInt(openCard.getAttribute('data-duration') || '0', 10),
                openCard.getAttribute('data-start'),
                openCard.getAttribute('data-end'),
                lastPos,
                parseFloat(openCard.getAttribute('data-percent') || '0')
            );
        }
    </script>
</asp:Content>
