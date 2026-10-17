<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="AddWorkGuide_User_Category_Role.aspx.vb" Inherits="CRM.AddWorkGuide_User_Category_Role" %>


<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="/assets/css/work-guide-access.css?v=20260912b" />

    <style>
        .select2-container {
            width: 100% !important;
        }

        .select2-container--default .select2-selection--multiple {
            min-height: 40px;
            border: 1px solid #d9dee3;
            border-radius: 0.375rem;
        }

        .select2-container--default .select2-selection--multiple .select2-selection__choice {
            background-color: #696cff;
            border: none;
            color: #fff;
            padding: 2px 8px;
            margin-top: 6px;
        }

        .select2-container--default .select2-selection--multiple .select2-selection__choice__remove {
            color: #fff;
            margin-left: 5px;
        }
    </style>

</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="card mb-4" style="min-height: -webkit-fill-available;">
            <div class="card-header">
                <h5 class="mb-0">إضافة صلاحية عميل على تصنيفات دليل العمل</h5>
                <small class="text-muted">يمكن منح العميل نفس الدور على أكثر من تصنيف دفعة واحدة</small>
            </div>

            <div class="card-body">

                <asp:Label ID="lblError" runat="server" CssClass="alert alert-danger d-block" Visible="false"></asp:Label>

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
                        <label class="form-label">العميل</label>

                        <asp:DropDownList ID="ddlUser" runat="server" CssClass="form-select">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvUser" runat="server"
                            ControlToValidate="ddlUser"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">الدور / الصلاحية</label>

                        <asp:DropDownList ID="ddlRole" data-wg-role="true" runat="server" CssClass="form-select">
                        </asp:DropDownList>

                        <asp:RequiredFieldValidator ID="rfvRole" runat="server"
                            ControlToValidate="ddlRole"
                            InitialValue="0"
                            ErrorMessage="حقل إجباري"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">التصنيفات</label>

                        <asp:ListBox ID="lstCategories"
                            runat="server"
                            CssClass="form-select" data-wg-tree="multiple"
                            SelectionMode="Multiple"
                            Rows="8">
                        </asp:ListBox>

                        <asp:CustomValidator ID="cvCategories"
                            runat="server"
                            ErrorMessage="يرجى اختيار تصنيف واحد على الأقل"
                            ForeColor="Red"
                            ValidationGroup="SaveForm"
                            Display="Dynamic"
                            OnServerValidate="cvCategories_ServerValidate">
                        </asp:CustomValidator>

                        <small class="text-muted d-block mt-1">
                            يمكنك البحث وتحديد التصنيفات منفردة أو تحديد المجموعة الحالية.
                        </small>
                    </div>

                    <div class="col-md-12">
                        <div class="alert alert-info mb-0">
                            سيتم منح العميل صلاحية الوصول إلى التصنيفات المحددة حسب الدور المختار.
                            في حال كانت التصنيفات تحتوي على ملفات، سيتمكن العميل من مشاهدة أو تحميل الملفات حسب إعدادات الدور.
                        </div>
                    </div>

                </div>

                <div class="pt-4">
                    <asp:Button ID="btnSave" runat="server"
                        Text="حفظ"
                        CssClass="btn btn-primary me-sm-3 me-1"
                        ValidationGroup="SaveForm"
                        OnClick="btnSave_Click" />

                    <asp:Button ID="btnCancel" runat="server"
                        Text="إغلاق"
                        CssClass="btn btn-label-secondary"
                        CausesValidation="false"
                        OnClick="btnCancel_Click" />
                </div>

            </div>
        </div>

    </div>

    <script src="/assets/js/work-guide-tree.js?v=20260912b"></script>

</asp:Content>