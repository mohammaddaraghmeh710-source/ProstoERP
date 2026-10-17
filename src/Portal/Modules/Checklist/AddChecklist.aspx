<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddChecklist.aspx.vb" Inherits="CRM.AddChecklist" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

            <div class="container-xxl flex-grow-1 container-p-y">
                <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
                    <h5 class="card-header">إضافة بند تقييم جديد</h5>
                    <div class="card-body">

                        <!-- 1. بيانات البند -->
                        <h6 class="fw-normal">1. بيانات البند</h6>
                        <div class="row g-3 mb-4">

                             <div class="col-md-4">
                                <label class="form-label">النوع</label>
                                <asp:DropDownList ID="ddlType" runat="server" CssClass="form-select">
                                </asp:DropDownList>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">العنوان (عربي)</label>
                                <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control"></asp:TextBox>
                                <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                    ControlToValidate="txtTitleAr"
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red" />
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">العنوان (إنجليزي)</label>
                                <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control"></asp:TextBox>
                                <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                    ControlToValidate="txtTitleEn"
                                    ErrorMessage="حقل إجباري"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"
                                    ForeColor="Red" />
                            </div>

                            <div class="col-md-6">
                                <label class="form-label">الوصف (عربي)</label>
                                <asp:TextBox ID="txtBriefAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">الوصف (إنجليزي)</label>
                                <asp:TextBox ID="txtBriefEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">الوزن</label>
                                <asp:TextBox ID="txtWeight" runat="server" CssClass="form-control"></asp:TextBox>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">التصنيف</label>
                                <asp:DropDownList ID="ddlChecklistCategories" runat="server" CssClass="form-select">
                                </asp:DropDownList>
                            </div>
                        </div>

                        <!-- 2. الهيكل التنظيمي -->
                        <h6 class="fw-normal">2. الهيكل التنظيمي</h6>
                        <div class="row g-3 mb-3">

                            <!-- Brand مخفي وقيمته ثابتة 26 في الكود -->

                            <div class="col-md-4">
                                <label class="form-label">الفرع</label>
                                <asp:DropDownList ID="ddlBranch" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlBranch_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">القسم</label>
                                <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlDepartment_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">المحطة التعريفية</label>
                                <asp:DropDownList ID="ddlJobTitle" runat="server" CssClass="form-select"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="ddlJobTitle_SelectedIndexChanged">
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="row g-3 mb-4">
                            <!-- JobTitle_Items (اختياري) -->
                            <div class="col-md-4">
                                <label class="form-label">البند الوظيفي (اختياري)</label>
                                <asp:DropDownList ID="ddlJobTitleItem" runat="server" CssClass="form-select">
                                </asp:DropDownList>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label">الوردية</label>
                                <asp:DropDownList ID="ddlShift" runat="server" CssClass="form-select"></asp:DropDownList>
                            </div>
                        </div>

                        <!-- حالة البند (مخفية حالياً) -->
                        <div class="col-md-12" style="display:none">
                            <label class="switch switch-square">
                                <input id="cbIsActive" runat="server" type="checkbox" class="switch-input" checked="true" />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on"><i class="bx bx-check"></i></span>
                                    <span class="switch-off"><i class="bx bx-x"></i></span>
                                </span>
                                <span class="switch-label">فعال</span>
                            </label>
                        </div>

                        <div class="pt-4">
                            <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary me-sm-3 me-1"
                                Text="حفظ" ValidationGroup="SaveForm" OnClick="btnSave_Click" />
                            <asp:Button ID="btnCancel" runat="server" CssClass="btn btn-label-secondary"
                                Text="إغلاق" OnClick="btnCancel_Click" />
                        </div>

                        <!-- Popup نجاح -->
                        <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display:none;" DefaultButton="btnClosePopup">
                            <div class="modal-dialog modal-dialog-centered" role="document">
                                <div class="modal-content">
                                    <div class="text-center m-4">
                                        <img src="/assets/img/Prosto/Success_Icon.png" />
                                    </div>
                                    <div class="modal-body">
                                        <h2 class="text-center">شكراً لك!</h2>
                                        <div class="swal2-html-container" style="display:block;">تم الحفظ بنجاح!</div>
                                    </div>
                                    <div class="text-center m-4">
                                        <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق"
                                            CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                                    </div>
                                </div>
                            </div>
                        </asp:Panel>

                        <cc1:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" runat="server"
                            PopupControlID="PanelPopUp"
                            TargetControlID="LBLPOP"
                            BackgroundCssClass="OpacityBG" />
                        <asp:Label ID="LBLPOP" runat="server" />

                    </div>
                </div>
            </div>

        </ContentTemplate>
    </asp:UpdatePanel>

</asp:Content>
