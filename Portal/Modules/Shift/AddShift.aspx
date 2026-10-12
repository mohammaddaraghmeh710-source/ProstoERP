<%@ Page Title="" Language="vb" AutoEventWireup="false"
    MasterPageFile="~/Site.Master"
    CodeBehind="AddShift.aspx.vb"
    Inherits="CRM.AddShift" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">اضافة فترة عمل جديدة</h5>
            <div class="card-body">
                <h6 class="fw-normal">1. بيانات فترة العمل</h6>

                <div class="row g-3">

                    <!-- الاسم بالعربية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الاسم بالعربية</label>
                            <asp:TextBox ID="txtFullNameAr" runat="server" MaxLength="50"
                                CssClass="form-control" placeholder="اسم فترة العمل بالعربية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidator8" runat="server"
                                    ControlToValidate="txtFullNameAr"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- الاسم بالانجليزية -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">الاسم بالانجليزية</label>
                            <asp:TextBox ID="txtFullNameEn" runat="server" MaxLength="50"
                                CssClass="form-control" placeholder="اسم فترة العمل بالانجليزية"></asp:TextBox>
                            <div class="form-text">
                                <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server"
                                    ControlToValidate="txtFullNameEn"
                                    SetFocusOnError="true" Font-Size="Small"
                                    ErrorMessage="حقل اجباري"
                                    ForeColor="red"
                                    ValidationGroup="SaveForm"
                                    Display="Dynamic"></asp:RequiredFieldValidator>
                            </div>
                        </div>
                    </div>

                    <!-- وقت البدء -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">وقت البدء</label>
                            <asp:TextBox ID="txtStartTime" runat="server"
                                CssClass="form-control" TextMode="Time"></asp:TextBox>
                        </div>
                    </div>

                    <!-- وقت الانتهاء -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">وقت الانتهاء</label>
                            <asp:TextBox ID="txtEndTime" runat="server"
                                CssClass="form-control" TextMode="Time"></asp:TextBox>
                        </div>
                    </div>

                    <!-- وقت البدء في رمضان -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">وقت البدء في رمضان</label>
                            <asp:TextBox ID="txtStartTimeRamadan" runat="server"
                                CssClass="form-control" TextMode="Time"></asp:TextBox>
                        </div>
                    </div>

                    <!-- وقت الانتهاء في رمضان -->
                    <div class="col-md-6">
                        <div>
                            <label class="form-label">وقت الانتهاء في رمضان</label>
                            <asp:TextBox ID="txtEndTimeRamadan" runat="server"
                                CssClass="form-control" TextMode="Time"></asp:TextBox>
                        </div>
                    </div>

                   <%-- <!-- التفعيل -->
                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
                        <label class="switch switch-square">
                            <input type="checkbox" id="cbIsApproved" runat="server"
                                   checked="checked" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"><i class="bx bx-check"></i></span>
                                <span class="switch-off"><i class="bx bx-x"></i></span>
                            </span>
                            <span class="switch-label">تفعيل فترة العمل</span>
                        </label>
                    </div>--%>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" OnClick="btnSave_Click" runat="server"
                        ValidationGroup="SaveForm"
                        CssClass="btn btn-primary me-sm-3 me-1" Text="حفظ" />
                    <asp:Button ID="btnCancel" runat="server"
                        CssClass="btn btn-label-secondary" Text="اغلاق"
                        OnClick="btnCancel_Click" />
                </div>

                <%--Start_Popup--%>
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server"
                           Style="display: none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center">
                                    <asp:Literal runat="server" ID="Literal1">شكراً لك!</asp:Literal>
                                </h2>
                                <div class="swal2-html-container" id="swal2-html-container"
                                     style="display: block;">
                                    تمت الاضافة بنجاح!
                                </div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server"
                                    Text="اغلاق" CssClass="btn btn-primary"
                                    OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender"
                    PopupControlID="PanelPopUp"
                    BackgroundCssClass="OpacityBG" runat="server"
                    TargetControlID="LBLPOP">
                </cc11:ModalPopupExtender>
                <asp:Label ID="LBLPOP" runat="server" />
                <%--End_Popup--%>

            </div>
        </div>
    </div>

</asp:Content>
