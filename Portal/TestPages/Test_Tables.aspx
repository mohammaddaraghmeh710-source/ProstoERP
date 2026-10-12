<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Tables.aspx.vb" Inherits="CRM.Test_Tables" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .ERP_ProstoTBL th {
            min-width: 100px !important;
            font-family: 'Almarai-Regular' !important;
        }
    </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- Project table -->
                <div class="card cvv-code-mask mb-4">

                  
                        <div class="card-header flex-column flex-md-row">
                            <div class="head-label">
                                <h5 class="card-title mb-0">مهام الموظفين</h5>
                            </div>
                            <div class="dt-action-buttons text-end pt-3 pt-md-0">
                                <div class="dt-buttons">
                                    <button class="dt-button create-new btn btn-primary" tabindex="0" aria-controls="DataTables_Table_0" type="button"><span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">اضافة مهام جديدة</span></span></button>
                                </div>
                            </div>
                        </div>

                        <div class="card-body">
                            <%--<span>يرجى تحديد القسم والمسمى الوظيفي وفترة العمل وتحديد المهام المطلوبة</span>--%>
                            <div class="row g-3 mt-1 mb-4">
                                <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">


                                    <select id="multicol-country" class="select2 form-select" data-allow-clear="true">
                                        <option value="القسم">القسم</option>
                                        <option value="Australia">Australia</option>
                                        <option value="Bangladesh">Bangladesh</option>
                                        <option value="Belarus">Belarus</option>
                                        <option value="Brazil">Brazil</option>
                                    </select>

                                </div>
                                <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">
                                    <select id="multicol-country2" class="select2 form-select" data-allow-clear="true">
                                        <option value="المسمى الوظيفي">المسمى الوظيفي</option>
                                        <option value="Australia">Australia</option>
                                        <option value="Bangladesh">Bangladesh</option>
                                        <option value="Belarus">Belarus</option>
                                        <option value="Brazil">Brazil</option>
                                    </select>
                                </div>
                                <div class="col-xl-3 col-lg-3 col-md-12 order-0 order-md-1">
                                    <select id="multicol-country3" class="select2 form-select" data-allow-clear="true">
                                        <option value="فترة العمل">فترة العمل</option>
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
                     
                            <table id="ERPTable"
                                class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                                <thead>
                                    <tr>
                                        <th>العنوان بالعربيه</th>
                                        <th>العنوان بالانجليزيه</th>
                                        <th>تاريخ الإنشاء</th>
                                        <th>الإجراءات</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة الداخلية وزارة الداخلية وزارة الداخلية وزارة الداخلية وزارة الداخلية</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Interior Ministry of Interior Ministry of Interior Ministry of Interior Ministry of Interior </td>
                                        <td data-title="تاريخ الإنشاء">2023-09-14</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة الاقتصاد الرقمي والريادة</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Digital Economy and Entrepreneurship</td>
                                        <td data-title="تاريخ الإنشاء">2024-02-05</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">الهيئة المستقلة للانتخاب</td>
                                        <td data-title="العنوان بالانجليزيه">Independent Election Commission</td>
                                        <td data-title="تاريخ الإنشاء">2023-12-22</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">أمانة عمان الكبرى</td>
                                        <td data-title="العنوان بالانجليزيه">Greater Amman Municipality</td>
                                        <td data-title="تاريخ الإنشاء">2024-01-17</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">سلطة منطقة العقبة الاقتصادية الخاصة</td>
                                        <td data-title="العنوان بالانجليزيه">Aqaba Special Economic Zone Authority</td>
                                        <td data-title="تاريخ الإنشاء">2022-11-11</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة التربية والتعليم</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Education</td>
                                        <td data-title="تاريخ الإنشاء">2023-03-08</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة الطاقة والثروة المعدنية</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Energy and Mineral Resources</td>
                                        <td data-title="تاريخ الإنشاء">2024-04-09</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">هيئة تنظيم قطاع الطاقة والمعادن</td>
                                        <td data-title="العنوان بالانجليزيه">Energy and Minerals Regulatory Commission</td>
                                        <td data-title="تاريخ الإنشاء">2023-07-21</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة المياه والري</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Water and Irrigation</td>
                                        <td data-title="تاريخ الإنشاء">2023-10-01</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td data-title="العنوان بالعربيه">وزارة الشباب</td>
                                        <td data-title="العنوان بالانجليزيه">Ministry of Youth</td>
                                        <td data-title="تاريخ الإنشاء">2024-05-10</td>
                                        <td data-title="الإجراءات">
                                            <a href="#"><i class="fa fa-pencil" title="Edit"></i></a>
                                            <a href="#"><i class="fa fa-trash" title="Remove"></i></a>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>

                        </div>
                

                </div>
                <!-- /Project table -->
            </div>
            </div>
        </div>
   
}
</asp:Content>
