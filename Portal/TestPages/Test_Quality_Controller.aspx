<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Quality_Controller.aspx.vb" Inherits="CRM.Test_Quality_Controller" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <!-- Content -->
    <div class="container-xxl flex-grow-1 container-p-y">
        <!-- Header -->
        <div class="row">
            <div class="col-12">
                <div class="card mb-4">
                    <div class="user-profile-header-banner">

                        <%--assets/img/Prosto/Background_Prosto.png--%>
                        <img src="/assets/img/Prosto/Background_Prosto.png" alt="Banner image" class="rounded-top" />
                    </div>
                    <div class="user-profile-header d-flex flex-column flex-sm-row text-sm-start text-center mb-4">
                        <div class="flex-shrink-0 mt-n2 mx-sm-0 mx-auto">
                            <img
                                src="../../assets/img/avatars/1.png"
                                alt="user image"
                                class="d-block h-auto ms-0 ms-sm-4 rounded-3 user-profile-img" />
                        </div>
                        <div class="flex-grow-1 mt-3 mt-sm-5">
                            <div
                                class="d-flex align-items-md-end align-items-sm-start align-items-center justify-content-md-between justify-content-start mx-4 flex-md-row flex-column gap-4">
                                <div class="user-profile-info">
                                    <h4>محمد دراغمة</h4>
                                    <ul
                                        class="list-inline mb-0 d-flex align-items-center flex-wrap justify-content-sm-start justify-content-center gap-2">


                                        <li class="list-inline-item fw-semibold">
                                            <i class="bx bx-calendar-alt"></i>10/10/2025
                              </li>
                                    </ul>
                                </div>
                             <%--   <a href="javascript:void(0)" class="btn btn-primary text-nowrap">
                                    <i class="bx bx-user-check"></i>تقييم الموظفين
                          </a>--%>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!--/ Header -->

        <div class="row">
            <div class="col-lg-12 col-md-12 mb-4">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">تقييم الافرع</h5>
                        <%-- <div class="dropdown">
                            <button
                                class="btn p-0"
                                type="button"
                                id="analyticsOptions"
                                data-bs-toggle="dropdown"
                                aria-haspopup="true"
                                aria-expanded="false">
                                <i class="bx bx-dots-vertical-rounded"></i>
                            </button>
                            <div class="dropdown-menu dropdown-menu-end" aria-labelledby="analyticsOptions">
                                <a class="dropdown-item" href="javascript:void(0);">Select All</a>
                                <a class="dropdown-item" href="javascript:void(0);">Refresh</a>
                                <a class="dropdown-item" href="javascript:void(0);">Share</a>
                            </div>
                        </div>--%>
                    </div>
                    <div class="card-body pb-2">
                        <div class="d-flex justify-content-around align-items-center flex-wrap mb-4">


                            <div class="user-analytics text-center me-2">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>شارع المدينة</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="success" data-series="90"></div>
                                    <h3 class="mb-0">90%</h3>
                                </div>
                            </div>


                            <div class="sessions-analytics text-center me-2">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>عبدالله غوشة</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="warning" data-series="60"></div>
                                    <h3 class="mb-0">60%</h3>
                                </div>
                            </div>

                            <div class="bounce-rate-analytics text-center">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>دابوق</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="danger" data-series="45"></div>
                                    <h3 class="mb-0">45%</h3>
                                </div>
                            </div>


                            <div class="bounce-rate-analytics text-center">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>طبربور</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="success" data-series="80"></div>
                                    <h3 class="mb-0">80%</h3>
                                </div>
                            </div>

                            <div class="bounce-rate-analytics text-center">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>ابو نصير</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="danger" data-series="30"></div>
                                    <h3 class="mb-0">30%</h3>
                                </div>
                            </div>


                            <div class="bounce-rate-analytics text-center">
                                <i class="bx bx-trending-up me-1"></i>
                                <span>البيادر</span>
                                <div class="d-flex align-items-center mt-2">
                                    <div class="chart-report" data-color="warning" data-series="65"></div>
                                    <h3 class="mb-0">65%</h3>
                                </div>
                            </div>






                        </div>

                    </div>
                </div>
            </div>

        </div>

        <!-- Connection Cards -->
        <div class="row g-4">
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title"> شارع المدينة</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title"> عبدالله غوشة</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title">دابوق</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title">طبربور</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title">ابو نصير</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-lg-6 col-md-6">
                <div class="card">
                    <div class="card-body text-center">
                        
                        <div class="mx-auto mb-3">
                            <img src="/assets/img/Prosto/Logo_Circle.png" alt="Avatar Image" class="rounded-circle w-px-100" />
                        </div>
                        <h5 class="mb-1 card-title">البيادر</h5>

                        <div class="d-flex align-items-center justify-content-around my-4 py-2">
                            <div>
                                <h4 class="mb-1">18</h4>
                                <span>عدد الموظفين</span>
                            </div>
                            <div>
                                <h4 class="mb-1">834</h4>
                                <span>عدد المهام</span>
                            </div>
                            <div>
                                <h4 class="mb-1">129</h4>
                                <span>عدد الشكاوي</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center justify-content-center">
                            <a href="javascript:;" class="btn btn-primary d-flex align-items-center me-3"><i class="bx bx-user-check me-1"></i>تقييم الفرع </a>
                          <%--  <a href="javascript:;" class="btn btn-label-secondary btn-icon"><i class="bx bx-envelope"></i></a>--%>
                        </div>
                    </div>
                </div>
            </div>
            
        </div>
        <!--/ Connection Cards -->


    </div>
    <!--/ Content -->





</asp:Content>
