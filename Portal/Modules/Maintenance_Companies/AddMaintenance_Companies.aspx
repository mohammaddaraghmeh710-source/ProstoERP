<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddMaintenance_Companies.aspx.vb" Inherits="CRM.AddMaintenance_Companies" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc1" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"></asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4 cvv-code-mask" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة شركة صيانة</h5>

            <div class="card-body">
                <h6 class="fw-normal">1. بيانات شركة الصيانة</h6>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">الاسم بالعربية</label>
                        <asp:TextBox ID="txtTitleAr" runat="server" MaxLength="100" CssClass="form-control"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                                ControlToValidate="txtTitleAr"
                                ErrorMessage="حقل إجباري"
                                ValidationGroup="SaveForm"
                                Display="Dynamic"
                                ForeColor="Red" />
                        </div>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الاسم بالإنجليزية</label>
                        <asp:TextBox ID="txtTitleEn" runat="server" MaxLength="100" CssClass="form-control"></asp:TextBox>
                        <div class="form-text">
                            <asp:RequiredFieldValidator ID="rfvTitleEn" runat="server"
                                ControlToValidate="txtTitleEn"
                                ErrorMessage="حقل إجباري"
                                ValidationGroup="SaveForm"
                                Display="Dynamic"
                                ForeColor="Red" />
                        </div>
                    </div>
                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />
                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق" CssClass="btn btn-label-secondary"
                        OnClick="btnCancel_Click" />
                </div>

                <!-- Popup -->
                <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display:none;" DefaultButton="btnClosePopup">
                    <div class="modal-dialog modal-dialog-centered" role="document">
                        <div class="modal-content">
                            <div class="text-center m-4">
                                <img src="/assets/img/Prosto/Success_Icon.png" />
                            </div>
                            <div class="modal-body">
                                <h2 class="text-center">
                                    <asp:Literal ID="Literal1" runat="server">شكراً لك!</asp:Literal>
                                </h2>
                                <div class="swal2-html-container" style="display:block;">تمت الإضافة بنجاح!</div>
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

</ContentTemplate></asp:UpdatePanel></asp:Content>
