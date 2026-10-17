<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageBrands.aspx.vb" Inherits="CRM.ManageBrands" %>



<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <div class="container-xxl flex-grow-1 container-p-y">

        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <!-- Project table -->
                <div class="card cvv-code-mask mb-4">

                  
                        <div class="card-header flex-column flex-md-row">
                            <div class="head-label">
                                <h5 class="card-title mb-0">العلامات التجارية</h5>
                            </div>
                            <div class="dt-action-buttons text-end pt-3 pt-md-0">
                                <div class="dt-buttons">
                               
                                        <asp:LinkButton ID="btnAddNewItem" OnClick="btnAddNewItem_Click" runat="server" CssClass="dt-button create-new btn btn-primary" >
                                        <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">اضافة علامة تجارية جديدة</span></span></asp:LinkButton>
                                  
                                </div>
                            </div>
                        </div>

                        <div class="card-body">

                            <!-- Start Search -->
                            <%--     <span>يرجى تحديد القسم والمحطة التعريفية وفترة العمل وتحديد المهام المطلوبة</span>
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
                                        <option value="المحطة التعريفية">المحطة التعريفية</option>
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
                            </div>--%>
                            <!-- End Search -->
                           
                     
                            <table id="ERPTable"
                                class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                                <thead>
                                    <tr>
                                        <th>العنوان بالعربيه</th>
                                        <th>العنوان بالانجليزيه</th>
                                        <th>تاريخ الإنشاء</th>
                                         <th>QRCode</th>
                                        <th>تعديل</th>
                                         <th>حذف</th>
                                    </tr>
                                </thead>
                                <tbody>

                                    <asp:ListView runat="server" ID="lstData">
                                        <LayoutTemplate>
                                            <asp:PlaceHolder runat="server" ID="ItemPlaceHolder"></asp:PlaceHolder>
                                        </LayoutTemplate>
                                        <ItemTemplate>
                                            <tr>
                                                <td data-title="العنوان بالعربيه"><%#Eval("Title_Ar")%></td>
                                                <td data-title="العنوان بالانجليزيه"><%#Eval("Title_En")%></td>
                                                <td data-title="تاريخ الإنشاء"><%#Eval("AddedDate")%></td>
                                                <td data-title="QRCode">
                                                    <asp:LinkButton CssClass="btn btn-icon btn-label-success" ID="lnkQRCode" CommandName="QRCode" CommandArgument='<%#Eval("ID") %>' runat="server" ToolTip="طباعة QRCode">    <i class="bx bx-qr"></i> </asp:LinkButton>
                                                </td>
                                                <td data-title="تعديل">
                                                   
                                                    <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit" CommandName="Edit" CommandArgument='<%#Eval("ID") %>' runat="server" ToolTip="تعديل \ مشاهدة"> <i class="bx bx-edit-alt"></i> </asp:LinkButton>
                                                    
                                                </td>
                                                  <td data-title="حذف">
    <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
        CommandName="DeleteItem"
        CommandArgument='<%#Eval("ID") %>'
        runat="server"
        ToolTip="حذف"
        CausesValidation="false"
        OnClientClick="return confirm('هل أنت متأكد من حذف هذه العلامة التجارية؟');">
        <i class="bx bx-trash-alt"></i>
    </asp:LinkButton>
</td>
                                              

                                            </tr>

                                        </ItemTemplate>
                                        <EmptyDataTemplate>
                                            <span class="no-data-title">لا يوجد محتوى لعرضه
                                            </span>
                                        </EmptyDataTemplate>
                                    </asp:ListView>

                                   
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

