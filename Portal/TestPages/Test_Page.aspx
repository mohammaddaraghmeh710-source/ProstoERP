<%@ Page Title="فيديو تدريب الموظفين" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Test_Page.aspx.vb"
    Inherits="CRM.Test_Page" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .secure-video-page {
            direction: rtl;
            text-align: right;
        }

        .secure-video-card {
            max-width: 800px;
            margin: 2.5rem auto;
        }

        .secure-video-wrapper {
            position: relative;
            width: 100%;
            padding-top: 56.25%; /* 16:9 ratio */
            background: #000;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 8px 20px rgba(15, 23, 42, 0.15);
        }

        .secure-video-wrapper video {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            border: none;
            outline: none;
            background: #000;
        }

        /* طبقة تمنع الضغط المباشر على الفيديو وتخفي الكليك يمين */
        .video-anticlick-layer {
            position: absolute;
            inset: 0;
            z-index: 3;
            background: transparent;
            cursor: pointer;
        }

        .video-anticlick-layer:focus {
            outline: none;
        }

        /* زر التشغيل في منتصف الفيديو */
        .video-play-btn {
            position: absolute;
            inset: 0;
            margin: auto;
            width: 72px;
            height: 72px;
            border-radius: 999px;
            background: rgba(15, 118, 110, 0.9);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 4;
            box-shadow: 0 8px 16px rgba(15, 23, 42, 0.4);
            transition: transform .15s ease, box-shadow .15s ease, background .15s ease;
        }

        .video-play-btn span {
            display: inline-block;
            margin-left: 4px;
            width: 0;
            height: 0;
            border-top: 10px solid transparent;
            border-bottom: 10px solid transparent;
            border-left: 16px solid #ffffff;
        }

        .video-play-btn:hover {
            transform: scale(1.05);
            background: rgba(5, 150, 105, 0.95);
            box-shadow: 0 10px 24px rgba(15, 23, 42, 0.55);
        }

        .video-title {
            font-weight: 600;
            font-size: 1.05rem;
        }

        .video-desc {
            font-size: .9rem;
            color: #6b7280;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y secure-video-page">
        <div class="card secure-video-card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <div>
                    <h5 class="video-title mb-1">فيديو تدريب الموظفين - تنظيف صالة مطعم بروستو</h5>
                    <p class="video-desc mb-0">
                        هذا الفيديو مخصص للاستخدام الداخلي فقط، ولا يمكن مشاركته خارج النظام.
                    </p>
                </div>
            </div>

            <div class="card-body">
                <div class="secure-video-wrapper" id="secureVideoContainer">
                    <!-- مشغّل الفيديو (المصدر من نفس الصفحة بوضع stream) -->
                    <video id="empVideo"
                           preload="metadata"
                           playsinline
                           controls
                           controlsList="nodownload noremoteplayback"
                           oncontextmenu="return false;">
                        <source src="<%= VideoUrl %>" type="video/mp4" />
                        المتصفح لا يدعم تشغيل عنصر الفيديو.
                    </video>

                    <!-- طبقة منع الضغط + إخفاء الكليك يمين -->
                    <button type="button"
                            id="videoClickLayer"
                            class="video-anticlick-layer"
                            oncontextmenu="return false;"
                            aria-label="تشغيل الفيديو">
                    </button>

                    <!-- زر تشغيل في المنتصف -->
                    <button type="button"
                            id="videoPlayBtn"
                            class="video-play-btn"
                            oncontextmenu="return false;"
                            aria-label="تشغيل الفيديو">
                        <span></span>
                    </button>
                </div>

                <small class="d-block mt-3 text-muted">
                    ملاحظة: يتم تقديم هذا الفيديو عبر قناة آمنة من الخادم، ولا يمكن الوصول إلى المسار الفعلي للملف.
                </small>
            </div>
        </div>
    </div>

    <script>
        (function () {
            var video = document.getElementById('empVideo');
            var layer = document.getElementById('videoClickLayer');
            var playBtn = document.getElementById('videoPlayBtn');

            if (!video || !layer || !playBtn) return;

            function startVideo() {
                // إخفاء طبقة الحماية فقط بعد التشغيل حتى يحصل المستخدم على تجربة أفضل
                layer.style.display = 'none';
                playBtn.style.display = 'none';

                try {
                    video.play();
                } catch (e) {
                    console.warn(e);
                }
            }

            layer.addEventListener('click', function (e) {
                e.preventDefault();
                startVideo();
            });

            playBtn.addEventListener('click', function (e) {
                e.preventDefault();
                startVideo();
            });

            // منع الكليك يمين على كامل الكارد (تخفيف الوصول السهل للرابط)
            document.getElementById('secureVideoContainer')
                .addEventListener('contextmenu', function (e) {
                    e.preventDefault();
                }, false);

            // محاولة منع بعض اختصارات الكيبورد الشائعة (يمكن تجاوزها لكن تقلل العبث)
            document.addEventListener('keydown', function (e) {
                if (e.key === 'F12' ||
                    (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'J')) ||
                    (e.ctrlKey && e.key.toLowerCase() === 'u')) {
                    e.preventDefault();
                }
            });
        })();
    </script>
</asp:Content>
