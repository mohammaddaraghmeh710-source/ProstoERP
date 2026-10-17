<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="Edit_LMS_Training_Levels.aspx.vb"
    Inherits="CRM.Edit_LMS_Training_Levels" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">

            <h5 class="card-header d-flex justify-content-between align-items-center">
                <span>تعديل مستوى تدريبي</span>
                <a class="btn btn-outline-secondary" href="/Modules/LMS_Training_Levels/Manage_LMS_Training_Levels.aspx">رجوع</a>
            </h5>

            <div class="card-body">

                <h6 class="fw-normal">1. بيانات المستوى</h6>

                <asp:HiddenField ID="hfID" runat="server" />
                <asp:HiddenField ID="hfLevelImagePath" runat="server" />

                <div class="row g-3">

                   
<!-- ✅ العلامة التجارية -->
<div class="col-md-6">
  <div>
    <label class="form-label">العلامة التجارية <span class="text-danger">*</span></label>
    <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"></asp:DropDownList>
    <div class="form-text">
      <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
          ControlToValidate="ddlBrand" InitialValue=""
          SetFocusOnError="true" Font-Size="Small"
          ErrorMessage="حقل اجباري"
          ForeColor="red"
          ValidationGroup="SaveForm"
          Display="Dynamic"></asp:RequiredFieldValidator>
    </div>
  </div>
</div>

<!-- نوع المستوى -->
<div class="col-md-6">
  <div>
    <label class="form-label">نوع المستوى <span class="text-danger">*</span></label>
    <asp:DropDownList ID="ddlLevelType" runat="server" CssClass="form-select"></asp:DropDownList>
    <div class="form-text">
      <asp:RequiredFieldValidator ID="rfvLevelType" runat="server"
          ControlToValidate="ddlLevelType" InitialValue=""
          SetFocusOnError="true" Font-Size="Small"
          ErrorMessage="حقل اجباري"
          ForeColor="red"
          ValidationGroup="SaveForm"
          Display="Dynamic"></asp:RequiredFieldValidator>
    </div>
  </div>
</div>

                    <!-- الترتيب -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الترتيب</label>
                            <asp:TextBox ID="txtOrder" runat="server" CssClass="form-control" TextMode="Number"></asp:TextBox>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <div>
                        </div>
                    </div>


                    <!-- الاسم بالعربية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">اسم المستوى بالعربية <span class="text-danger">*</span></label>
                            <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                    ControlToValidate="txtTitleAr"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالإنجليزية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">اسم المستوى بالإنجليزية <span class="text-danger">*</span></label>
                            <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                    ControlToValidate="txtTitleEn"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- ملخص عربي -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">ملخص بالعربية <span class="text-danger">*</span></label>
                            <asp:TextBox ID="txtSummaryAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvSummaryAr" runat="server"
                                    ControlToValidate="txtSummaryAr"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- ملخص إنجليزي -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">ملخص بالإنجليزية <span class="text-danger">*</span></label>
                            <asp:TextBox ID="txtSummaryEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="rfvSummaryEn" runat="server"
                                    ControlToValidate="txtSummaryEn"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- ملاحظات عربي -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">ملاحظات بالعربية</label>
                            <asp:TextBox ID="txtNotesAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                        </div>
                    </div>

                    <!-- ملاحظات إنجليزي -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">ملاحظات بالإنجليزية</label>
                            <asp:TextBox ID="txtNotesEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="4"></asp:TextBox>
                        </div>
                    </div>

                    <!-- ✅ Checkbox عادية (بدون switch) -->
                    <div class="col-12 mt-2">
                        <div class="form-check">
                            <asp:CheckBox ID="cbIsActive" style="border:none" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label" for="cbIsActive">تفعيل المستوى</label>
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

                <h6 class="fw-normal">2. صلاحيات أنواع المستخدمين</h6>

                <asp:CustomValidator ID="cvUserTypes" runat="server"
                    ErrorMessage="يرجى اختيار نوع مستخدم واحد على الأقل."
                    ForeColor="red"
                    ValidationGroup="SaveForm"
                    Display="Dynamic"
                    OnServerValidate="cvUserTypes_ServerValidate" />

                <div class="mt-2">

                    <!-- ✅ Checkboxes عادية داخل Repeater -->
                    <asp:Repeater ID="rptUserTypes" runat="server">
                        <ItemTemplate>
                            <div class="form-check d-inline-block me-4 mb-2">
                                <asp:CheckBox ID="chkUT" style="border:none" runat="server" CssClass="form-check-input" />
                                <label class="form-check-label"><%# Eval("Title_Ar")%></label>
                                <asp:HiddenField ID="hfUTID" runat="server" Value='<%# Eval("ID")%>' />
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ"
                        CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm"
                        OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق"
                        CssClass="btn btn-label-secondary"
                        OnClick="btnCancel_Click" />
                </div>

                <%--Start_Popup--%>
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center">
                                    <asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal>
                                </h2>
                                <div class="swal2-html-container" style="display: block;">تم التعديل بنجاح!</div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender"
                    PopupControlID="PanelPopUp"
                    BackgroundCssClass="OpacityBG"
                    runat="server"
                    TargetControlID="LBLPOP">
                </cc11:ModalPopupExtender>
                <asp:Label ID="LBLPOP" runat="server" />
                <%--End_Popup--%>

                <asp:Label ID="lblMsg" runat="server" Visible="false" CssClass="alert alert-danger d-block mt-3"></asp:Label>

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
