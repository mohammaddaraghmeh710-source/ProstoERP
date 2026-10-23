<%@ Page Title="تعديل خبر" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Edit_News.aspx.vb"
    Inherits="CRM.Edit_News" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><script src="/ckeditor/ckeditor.js"></script><script src="/assets/js/news-editor.js?v=20261018a" defer></script></asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y" style="direction: rtl; text-align: right;">
        <div class="row">
            <div class="col-12">

                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تعديل خبر</h5>
                        <a class="btn btn-outline-secondary" href="/Modules/News/Manage_News.aspx">رجوع</a>
                    </div>

                    <div class="card-body">
                        <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block" Visible="false" role="alert" />
                        <asp:HiddenField ID="hfPID" runat="server" />
                        <asp:HiddenField ID="hfImagePath" runat="server" />

                        <div class="row g-3">
                            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="ddlBrand" CssClass="form-label" Text="العلامة التجارية"/><asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"/><asp:RequiredFieldValidator runat="server" ControlToValidate="ddlBrand" InitialValue="0" ValidationGroup="NewsForm" CssClass="text-danger" Display="Dynamic" ErrorMessage="اختر العلامة التجارية."/></div>
                            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtDate" CssClass="form-label" Text="تاريخ الخبر"/><asp:TextBox ID="txtDate" runat="server" CssClass="form-control" TextMode="DateTimeLocal"/></div>
                            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtTitleAr" CssClass="form-label" Text="اسم الخبر بالعربية"/><asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" /></div>
                            <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="txtTitleEn" CssClass="form-label" Text="اسم الخبر بالإنجليزية"/><asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" dir="ltr"/></div>
                            <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtBriefAr" CssClass="form-label" Text="الملخص بالعربية"/><asp:TextBox ID="txtBriefAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"/></div>
                            <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtBriefEn" CssClass="form-label" Text="الملخص بالإنجليزية"/><asp:TextBox ID="txtBriefEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" dir="ltr"/></div>
                            <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtDetails" CssClass="form-label" Text="التفاصيل بالعربية"/><asp:TextBox ID="txtDetails" runat="server" CssClass="form-control" ClientIDMode="Static" TextMode="MultiLine" Rows="8" ValidateRequestMode="Disabled"/></div>
                            <div class="col-12"><asp:Label runat="server" AssociatedControlID="txtDetailsEn" CssClass="form-label" Text="التفاصيل بالإنجليزية"/><asp:TextBox ID="txtDetailsEn" runat="server" CssClass="form-control" ClientIDMode="Static" TextMode="MultiLine" Rows="8" ValidateRequestMode="Disabled" dir="ltr"/></div>
                            <div class="col-md-2">
                                <label class="form-label">الترتيب</label>
                                <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number" />
                            </div>

                            <div class="col-md-3 d-flex align-items-end">
                                <div class="form-check">
                                    <asp:CheckBox ID="chkIsActive" runat="server" CssClass="form-check-input" />
                                    <label class="form-check-label" for="<%=chkIsActive.ClientID%>">نشط</label>
                                </div>
                            </div>

                            <!-- رابط فتح البلوك الإضافي -->
                            <div class="col-12">
                                <div class="mt-3 mb-1">
                                    <a href="javascript:void(0)" class="fw-bold text-primary" onclick="toggleNewsMediaSection()">
                                        صورة الخبر (اختياري)
                                    </a>
                                    <small class="text-muted d-block">اضغط هنا لعرض/إخفاء رفع صورة جديدة. إذا لم ترفع صورة سيبقى الحالي.</small>
                                </div>
                            </div>

                            <!-- بلوك رفع الصورة -->
                            <div id="newsMediaSection" style="display:none;" class="col-12">
                                <div class="row g-3">
                            
                                    <div class="col-12">
                                        <label class="form-label">صورة الخبر (اختياري)</label>

                                        <ajaxToolkit:AjaxFileUpload ID="NewsImageUploader"
                                            AllowedFileTypes="jpeg,jpg,png,webp"
                                            MaximumNumberOfFiles="1"
                                            MaxFileSize="100024"
                                            runat="server"
                                            OnUploadComplete="NewsImageUploader_UploadComplete"
                                            OnUploadStart="NewsImageUploader_UploadStart" />

                                        <span class="text-danger d-block mt-1" style="font-size:12px;">
                                            إذا لم ترفع صورة جديدة سيبقى الملف الحالي.
                                        </span>

                                        <asp:Literal ID="litCurrentImage" runat="server"></asp:Literal>
                                    </div>
                                </div>
                            </div>

                        </div>

                        <hr class="my-4" />

                        <asp:LinkButton ID="btnSave" runat="server" OnClientClick="crmNewsUpdateEditors();" ValidationGroup="NewsForm" CssClass="btn btn-primary" OnClick="btnSave_Click">
                            حفظ التعديل
                        </asp:LinkButton>

                        <a class="btn btn-outline-secondary" href="/Modules/News/Manage_News.aspx">إلغاء</a>

                    </div>
                </div>

            </div>
        </div>
    </div>

    <script type="text/javascript">
        function toggleNewsMediaSection() {
            var sec = document.getElementById('newsMediaSection');
            if (!sec) return;
            if (sec.style.display === 'none' || sec.style.display === '') sec.style.display = 'block';
            else sec.style.display = 'none';
        }
    </script>
</asp:Content>