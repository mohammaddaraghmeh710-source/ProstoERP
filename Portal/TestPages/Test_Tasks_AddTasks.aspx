<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Tasks_AddTasks.aspx.vb" Inherits="CRM.Test_Tasks_AddTasks" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <!-- Content -->

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">

            <!-- User Content -->
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">


                <!-- Project table -->
                <div class="card">
                    <!-- Notifications -->
                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">تحديد مهام الموظفين</h5>
                        </div>
                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <button class="dt-button create-new btn btn-primary" tabindex="0" aria-controls="DataTables_Table_0" type="button"><span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">اضافة مهام جديدة</span></span></button>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">
                        <span>يرجى تحديد القسم والمسمى الوظيفي وفترة العمل وتحديد المهام المطلوبة</span>
                        <div class="row g-3 mt-1">
                            <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">


                                <select id="multicol-country" class="select2 form-select" data-allow-clear="true">
                                    <option value="">القسم</option>
                                    <option value="Australia">Australia</option>
                                    <option value="Bangladesh">Bangladesh</option>
                                    <option value="Belarus">Belarus</option>
                                    <option value="Brazil">Brazil</option>
                                </select>

                            </div>
                            <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">
                                <select id="multicol-country2" class="select2 form-select" data-allow-clear="true">
                                    <option value="">المسمى الوظيفي</option>
                                    <option value="Australia">Australia</option>
                                    <option value="Bangladesh">Bangladesh</option>
                                    <option value="Belarus">Belarus</option>
                                    <option value="Brazil">Brazil</option>
                                </select>
                            </div>
                            <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">
                                <select id="multicol-country3" class="select2 form-select" data-allow-clear="true">
                                    <option value="">فترة العمل</option>
                                    <option value="Australia">Australia</option>
                                    <option value="Bangladesh">Bangladesh</option>
                                    <option value="Belarus">Belarus</option>
                                    <option value="Brazil">Brazil</option>
                                </select>
                            </div>
                            <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">
                                <a href="javascript:void(0)" class="btn btn-secondary text-nowrap">
                                    <i class="bx bx-user-check"></i>مشاهدة المهام
                          </a>
                            </div>
                        </div>

                    </div>

                    <div class="table-responsive">
                        <table class="table table-striped table-borderless">
                            <thead>
                                <tr>
                                    <th class="text-nowrap">عنوان المهمة</th>
                                    <th class="text-nowrap text-center">تحديد </th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td class="text-nowrap">New for you</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck1" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">Account activity</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck4" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new browser used to sign in</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck7" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new device is linked</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck10" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">New for you</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck11" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">Account activity</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck41" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new browser used to sign in</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck71" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new device is linked</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck101" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">New for you</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck12" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">Account activity</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck42" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new browser used to sign in</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck72" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new device is linked</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck102" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">New for you</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck13" checked />
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-nowrap">Account activity</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck43" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new browser used to sign in</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck73" checked />
                                        </div>
                                    </td>

                                </tr>
                                <tr>
                                    <td class="text-nowrap">A new device is linked</td>
                                    <td>
                                        <div class="form-check d-flex justify-content-center">
                                            <input class="form-check-input" type="checkbox" id="defaultCheck104" checked />
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="card-body">
                        <button type="submit" class="btn btn-primary me-2">حفظ المهام</button>
                        <button type="reset" class="btn btn-label-secondary">اغلاق</button>
                    </div>
                    <!-- /Notifications -->
                </div>
                <!-- /Project table -->
            </div>
            <!--/ User Content -->
        </div>

   

      

        <!-- /Modals -->
    </div>
    <!--/ Content -->


</asp:Content>
