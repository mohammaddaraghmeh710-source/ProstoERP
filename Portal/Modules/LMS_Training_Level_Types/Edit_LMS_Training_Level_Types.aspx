<%@ Page Title="تعديل نوع مستوى تدريبي" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="Edit_LMS_Training_Level_Types.aspx.vb"
    Inherits="CRM.Edit_LMS_Training_Level_Types" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y" style="direction: rtl; text-align: right;">
        <div class="row">
            <div class="col-12">

                <div class="card mb-4">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تعديل نوع مستوى تدريبي</h5>
                        <a class="btn btn-outline-secondary" href="/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx">رجوع</a>
                    </div>

                    <div class="card-body">
                        <asp:HiddenField ID="hfID" runat="server" />
                            <asp:HiddenField ID="hfLevelImagePath" runat="server" />

                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">الاسم عربي</label>
                                <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">الاسم إنجليزي</label>
                                <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" />
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">ملاحظات عربي</label>
                                <asp:TextBox ID="txtNotesAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">ملاحظات إنجليزي</label>
                                <asp:TextBox ID="txtNotesEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4" />
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">الترتيب</label>
                                <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number" />
                            </div>

                            <div class="col-md-3 d-flex align-items-end">
                                <div class="form-check">
                                    <asp:CheckBox ID="chkIsActive" runat="server" CssClass="form-check-input" />
                                    <label class="form-check-label" for="<%= chkIsActive.ClientID %>">نشط</label>
                                </div>
                            </div>


                              <!-- رابط فتح البلوك الإضافي -->
                    <div class="col-12">
                        <div class="mt-3 mb-1">
                            <a href="javascript:void(0)" class="fw-bold text-primary" onclick="toggleLevelMediaSection()">
                                صورة المستوى (اختياري)
                            </a>
                            <small class="text-muted d-block">اضغط هنا لعرض/إخفاء رفع صورة جديدة. إذا لم ترفع صورة سيبقى الحالي.</small>
                        </div>
                    </div>

                    <!-- البلوك المخفي لرفع الصورة -->
                    <div id="levelMediaSection" style="display:none;" class="col-12">
                        <div class="row g-3">

                            <div class="col-12">
                                <div class="form-example-int">
                                    <div class="form-group">
                                        <label>صورة المستوى (اختياري)</label>
                                        <div class="nk-int-st">
                                            <div class="form-group">
                                                <div class="col-sm-9" style="width: 100%">
                                                    <ajaxToolkit:AjaxFileUpload ID="LevelImageUploader"
                                                        AllowedFileTypes="jpeg,jpg,png,webp"
                                                        MaximumNumberOfFiles="1"
                                                        MaxFileSize="100024"
                                                        runat="server"
                                                        OnUploadComplete="LevelImageUploader_UploadComplete"
                                                        OnUploadStart="LevelImageUploader_UploadStart" />
                                                    <br />
                                                    <span class="text-danger" style="font-size:12px;">إذا لم ترفع صورة جديدة سيبقى الملف الحالي.</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <asp:Literal ID="litCurrentImage" runat="server"></asp:Literal>

                            </div>

                        </div>
                    </div>

                        </div>

                        <hr class="my-4" />

                        <asp:LinkButton ID="btnSave" runat="server" CssClass="btn btn-primary" OnClick="btnSave_Click">
                            حفظ التعديل
                        </asp:LinkButton>

                        <a class="btn btn-outline-secondary" href="/Modules/LMS_Training_Level_Types/Manage_LMS_Training_Level_Types.aspx">إلغاء</a>

                    </div>
                </div>

            </div>
        </div>
    </div>

     <script type="text/javascript">
        function toggleLevelMediaSection() {
            var sec = document.getElementById('levelMediaSection');
            if (!sec) return;
            if (sec.style.display === 'none' || sec.style.display === '') {
                sec.style.display = 'block';
            } else {
                sec.style.display = 'none';
            }
        }
     </script>

</asp:Content>
