<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddWorkGuide_Documents.aspx.vb" Inherits="CRM.AddWorkGuide_Documents" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajaxToolkit" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <h5 class="card-header">إضافة ملف جديد لدليل العمل</h5>

            <div class="card-body">
                <h6 class="fw-normal">1. بيانات الملف</h6>

                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label">العلامة التجارية</label>
                        <asp:DropDownList ID="ddlBrand" runat="server" CssClass="form-select"
                            AutoPostBack="true" OnSelectedIndexChanged="ddlBrand_SelectedIndexChanged">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvBrand" runat="server"
                            ControlToValidate="ddlBrand"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">التصنيف</label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-select">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvCategory" runat="server"
                            ControlToValidate="ddlCategory"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">العنوان بالعربية</label>
                        <asp:TextBox ID="txtTitleAr" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>

                        <asp:RequiredFieldValidator ID="rfvTitleAr" runat="server"
                            ControlToValidate="txtTitleAr"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">العنوان بالإنجليزية</label>
                        <asp:TextBox ID="txtTitleEn" runat="server" CssClass="form-control" MaxLength="500"></asp:TextBox>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الترتيب</label>
                        <asp:TextBox ID="txtItemOrder" runat="server" CssClass="form-control" TextMode="Number"></asp:TextBox>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالعربية</label>
                        <asp:TextBox ID="txtDescriptionAr" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                    <div class="col-md-12">
                        <label class="form-label">الوصف بالإنجليزية</label>
                        <asp:TextBox ID="txtDescriptionEn" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3"></asp:TextBox>
                    </div>

                    <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12 mt-3">
                        <div class="form-group">
                            <label class="form-label">ملف دليل العمل PDF</label>

                            <ajaxToolkit:AjaxFileUpload ID="WorkGuidePDF"
                                AllowedFileTypes="pdf"
                                MaximumNumberOfFiles="1"
                                MaxFileSize="51200"
                                runat="server"
                                OnUploadComplete="WorkGuidePDF_UploadComplete"
                                OnUploadStart="WorkGuidePDF_UploadStart" />

                            <br />
                            <span class="text-danger">يسمح بتحميل ملف PDF فقط.</span>
                        </div>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server" Text="حفظ" CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm" OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server" Text="إغلاق" CssClass="btn btn-label-secondary"
                        CausesValidation="false" OnClick="btnCancel_Click" />
                </div>

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
                                <div class="swal2-html-container" style="display: block;">تمت الإضافة بنجاح!</div>
                            </div>
                            <div class="text-center m-4">
                                <asp:Button ID="btnClosePopup" runat="server" Text="إغلاق" CssClass="btn btn-primary" OnClick="btnClosePopup_Click" />
                            </div>
                        </div>
                    </div>
                </asp:Panel>

                <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" PopupControlID="PanelPopUp"
                    BackgroundCssClass="OpacityBG" runat="server" TargetControlID="LBLPOP">
                </cc11:ModalPopupExtender>

                <asp:Label ID="LBLPOP" runat="server" />

            </div>
        </div>
    </div>

</asp:Content>
