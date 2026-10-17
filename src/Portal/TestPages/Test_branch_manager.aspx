<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_branch_manager.aspx.vb" Inherits="CRM.Test_branch_manager" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

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
                                 
                                        <li class="list-inline-item fw-semibold"><i class="bx bx-map"></i>فرع دابوق </li>
                                        <li class="list-inline-item fw-semibold">
                                            <i class="bx bx-calendar-alt"></i>10/10/2025
                              </li>
                                    </ul>
                                </div>
                                <a href="javascript:void(0)" class="btn btn-primary text-nowrap">
                                    <i class="bx bx-user-check"></i>تقييم الموظفين
                          </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!--/ Header -->

        <!-- Navbar pills -->
        <div class="row">
            <div class="col-md-12">
                <ul class="nav nav-pills flex-column flex-sm-row mb-4">
                    <li class="nav-item">
                        <a class="nav-link active" href="javascript:void(0);"><i class="bx bx-grid-alt"></i>لوحة المعلومات</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="pages-profile-teams.html"><i class="bx bx-group"></i>تحديد الموظفين</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="pages-profile-projects.html"><i class="bx bx-detail"></i>تحديد المهام</a>
                    </li>
                    
                </ul>
            </div>
        </div>
        <!--/ Navbar pills -->

        <!-- User Profile Content -->
        <div class="row ">


            <div class="col-lg-4 col-xl-4 col-md-12 mb-4">
                <div class="row mb-4">
                    <div class="col-12 mb-4">
                        <div class="card">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="avatar">
                                            <span class="avatar-initial bg-label-warning rounded-circle"><i class="bx bx-detail"></i></span>
                                        </div>
                                        <div class="card-info">
                                            <h5 class="card-title mb-0 me-2">50</h5>
                                            <small class="text-muted">المهام</small>
                                        </div>
                                    </div>
                                    <div id="incomeChart"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 ">
                        <div class="card">
                            <div class="card-body">
                                <div class="d-flex justify-content-between">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="avatar">
                                            <span class="avatar-initial bg-label-primary rounded-circle"><i class="bx bx-user fs-4"></i></span>
                                        </div>
                                        <div class="card-info">
                                            <h5 class="card-title mb-0 me-2">29</h5>
                                            <small class="text-muted">الموظفين</small>
                                        </div>
                                    </div>
                                    <div id="conversationChart"></div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
                <div class="row mb-4">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="card-title mb-0">تقييم الفرع</h5>
                            </div>
                            <div class="card-body">
                                <%--   <div class="d-flex justify-content-around align-items-center flex-wrap mb-4">
                        <div class="user-analytics text-center me-2">
                            <i class="bx bx-trending-up me-1"></i>
                            <span>شارع المدينة</span>
                            <div class="d-flex align-items-center mt-2">
                                <div class="chart-report" data-color="success" data-series="90"></div>
                                <h3 class="mb-0">90%</h3>
                            </div>
                        </div>
                    </div>--%>


                                <ul class="p-0 m-0">

                                    <li class="d-flex mb-4 pb-2">
                                        <div class="avatar avatar-sm flex-shrink-0 me-3">

                                            <span class="avatar-initial rounded-circle bg-label-success"><i class="bx bx-trending-up"></i></span>
                                        </div>
                                        <div class="d-flex flex-column w-100">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>المهام الجيدة</span>
                                                <span class="text-muted">50%</span>
                                            </div>
                                            <div class="progress" style="height: 6px">
                                                <div
                                                    class="progress-bar bg-success"
                                                    style="width: 50%"
                                                    role="progressbar"
                                                    aria-valuenow="50"
                                                    aria-valuemin="0"
                                                    aria-valuemax="100">
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                    <li class="d-flex mb-4 pb-2">
                                        <div class="avatar avatar-sm flex-shrink-0 me-3">

                                            <span class="avatar-initial rounded-circle bg-label-warning"><i class="bx bx-trending-up"></i></span>
                                        </div>
                                        <div class="d-flex flex-column w-100">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>المهام المقبولة</span>
                                                <span class="text-muted">40%</span>
                                            </div>
                                            <div class="progress" style="height: 6px">
                                                <div
                                                    class="progress-bar bg-warning"
                                                    style="width: 40%"
                                                    role="progressbar"
                                                    aria-valuenow="40"
                                                    aria-valuemin="0"
                                                    aria-valuemax="100">
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                    <li class="d-flex mb-2">
                                        <div class="avatar avatar-sm flex-shrink-0 me-3">

                                            <span class="avatar-initial rounded-circle bg-label-danger"><i class="bx bx-trending-up"></i></span>
                                        </div>
                                        <div class="d-flex flex-column w-100">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span>المهام الغير مقبول</span>
                                                <span class="text-muted">10%</span>
                                            </div>
                                            <div class="progress" style="height: 6px">
                                                <div
                                                    class="progress-bar bg-danger"
                                                    style="width: 10%"
                                                    role="progressbar"
                                                    aria-valuenow="10"
                                                    aria-valuemin="0"
                                                    aria-valuemax="100">
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-xl-8 col-lg-7 col-md-12">
               <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="card-title mb-0">الملاحظات التي تم اضافتها على المهام</h5>
                    </div>
                    
                    <div class="table-responsive">
                        <table class="table border-top">
                            <thead>
                                <tr>
                                    <th>عنوان الملاحظة</th>
                                     <th>فترة العمل</th>
                                     <th>الفسم </th>
                                </tr>
                            </thead>
                            <tbody class="table-border-bottom-0">
                                <tr>
                                    <td class="text-nowrap">الطاولات غير نظيفة
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">يجب التأكد من حرار الزيت 
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">التأكد من طلب النواقص
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">لا يوجد فاين في الحمامات 
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">الموظفين غير ملتزمين في اللبس المحدد
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">مشكلة في الاضاءة الخارجية
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">الساحة الخارجية غير نظيفة
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>

                                 <tr>
                                    <td class="text-nowrap">لا يوجد فاين في الحمامات 
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">الموظفين غير ملتزمين في اللبس المحدد
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">مشكلة في الاضاءة الخارجية
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">الساحة الخارجية غير نظيفة
                            </td>

                                    <td>الفترة الصباحية
                                    </td>
                                    <td>المطبخ
                                    </td>
                                </tr>

                            </tbody>
                        </table>
                    </div>
                </div>
           
            </div>
        </div>
        <!--/ User Profile Content -->
    </div>

</asp:Content>
