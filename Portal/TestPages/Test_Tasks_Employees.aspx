<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Tasks_Employees.aspx.vb" Inherits="CRM.Test_Tasks_Employees" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <!-- Content -->


    <div class="container-xxl flex-grow-1 container-p-y">
    
        <div class="row">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">
                <!-- User Pills -->
                <ul class="nav nav-pills flex-column flex-md-row mb-3">
                    <li class="nav-item">
                        <a class="nav-link active" href="app-user-view-account.html"><i class="bx bx-user me-1"></i>تحضير</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="app-user-view-security.html"><i class="bx bx-lock-alt me-1"></i>طباخ</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="app-user-view-billing.html"><i class="bx bx-detail me-1"></i>متابعة</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="app-user-view-notifications.html"><i class="bx bx-bell me-1"></i>تعبئة</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link " href="javascript:void(0);"><i class="bx bx-link-alt me-1"></i>تغليف</a>
                    </li>
                </ul>
                <!--/ User Pills -->
            </div>
        </div>

        <div class="row">
            <div class="col-xl-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">المطبخ</h5>

                    </div>
                    <div class="card-body">
                        <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
                            <div class="d-flex justify-content-between align-content-center flex-wrap gap-4">
                                <div class="d-flex align-items-center gap-2">
                                    <div id="marketingCampaignChart1"></div>
                                    <div>
                                        <div class="d-flex align-items-center">
                                            <h6 class="mb-0 me-2">25,768</h6>
                                            <span class="text-success">(+16.2%)</span>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <span class="badge badge-dot bg-success me-2"></span>ممتاز
                             
                                        </div>
                                    </div>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <div id="marketingCampaignChart2"></div>
                                    <div>
                                        <div class="d-flex align-items-center">
                                            <h6 class="mb-0 me-2">5,352</h6>
                                            <span class="text-warning">(-4.9%)</span>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <span class="badge badge-dot bg-warning me-2"></span>مقبول
                             
                                        </div>
                                    </div>
                                </div>


                                <div class="d-flex align-items-center gap-2">
                                    <div id="marketingCampaignChart3"></div>
                                    <div>
                                        <div class="d-flex align-items-center">
                                            <h6 class="mb-0 me-2">5,352</h6>
                                            <span class="text-danger">(-4.9%)</span>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <span class="badge badge-dot bg-danger me-2"></span>غير مقبول
                             
                                        </div>
                                    </div>
                                </div>

                            </div>
                            <a href="javascript:;" class="btn btn-sm btn-primary" type="button">
                                <i class="bx bx-user me-1"></i>
                                عدد الموظفين 15</a>
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table class="table border-top">
                            <thead>
                                <tr>
                                    <th>عنوان المهمة </th>
                                    <th>التفاصيل </th>
                                </tr>
                            </thead>
                            <tbody class="table-border-bottom-0">
                                <tr>
                                    <td class="text-nowrap">
                                        <img
                                            src="../../assets/img/icons/brands/fastrack.png"
                                            class="me-3"
                                            width="22"
                                            alt="Fastrack" />Fastrack Watches Fastrack Watches Fastrack Watches Fastrack Watches Fastrack Watches
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/puma.png"
                                            class="me-3"
                                            width="22"
                                            alt="Puma" />Puma Shoes
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/nike.png"
                                            class="me-3"
                                            width="22"
                                            alt="Nike" />Nike Air Jordan
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/oneplus.png"
                                            class="me-3"
                                            width="22"
                                            alt="OnePlus" />Oneplus 7 Pro
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/google.png"
                                            class="me-3"
                                            width="22"
                                            alt="Google" />Google Pixal 6
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">
                                        <img
                                            src="../../assets/img/icons/brands/fastrack.png"
                                            class="me-3"
                                            width="22"
                                            alt="Fastrack" />Fastrack Watches Fastrack Watches Fastrack Watches Fastrack Watches Fastrack Watches
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/puma.png"
                                            class="me-3"
                                            width="22"
                                            alt="Puma" />Puma Shoes
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/nike.png"
                                            class="me-3"
                                            width="22"
                                            alt="Nike" />Nike Air Jordan
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/oneplus.png"
                                            class="me-3"
                                            width="22"
                                            alt="OnePlus" />Oneplus 7 Pro
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <img
                                            src="../../assets/img/icons/brands/google.png"
                                            class="me-3"
                                            width="22"
                                            alt="Google" />Google Pixal 6
                            </td>

                                    <td>
                                        <button type="button" class="btn btn-icon btn-label-secondary">
                                            <i class="bx bx-detail"></i>
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>

    </div>
    <!--/ Content -->


</asp:Content>
