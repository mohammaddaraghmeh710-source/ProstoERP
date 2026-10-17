<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Tasks_Details.aspx.vb" Inherits="CRM.Test_Tasks_Details" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="cc11" %>
<%@ Register Assembly="CKEditor.NET" Namespace="CKEditor.NET" TagPrefix="CKEditor" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">


    <!-- Content -->

    <div class="container-xxl flex-grow-1 container-p-y">
        <div class="row invoice-edit cvv-code-mask">
            <!-- Invoice Edit-->
            <div class="col-lg-12 col-12 mb-lg-0 mb-4">
                <div class="card invoice-preview-card">
                    <div class="card-body">
                        <div class="row p-sm-3 p-0">
                            <div class="col-md-6 mb-md-0 mb-4">
                                <div class="d-flex svg-illustration mb-4 gap-2">
                                    <img src="/assets/img/Prosto/logo-Red.png" />
                                </div>
                                <p class="mb-1">التاريخ: 15/10/2025</p>
                                <p class="mb-1">الفرع: دابوق </p>

                            </div>
                            <div class="col-md-6">
                                <table>
                                    <tbody>
                                        <tr>
                                            <td class="pe-3">المدير المسؤول:</td>
                                            <td>محمد دراغمة</td>
                                        </tr>
                                        <tr>
                                            <td class="pe-3">القسم: </td>
                                            <td>المطبخ</td>
                                        </tr>
                                        <tr>
                                            <td class="pe-3">المسمى الوظيفي: </td>
                                            <td>طحان</td>
                                        </tr>

                                    </tbody>
                                </table>
                                <br />



                                <asp:LinkButton ID="btnEvaluation" CssClass="btn btn-primary d-grid w-100" runat="server" OnClick="btnEvaluation_Click">
                                           <span class="d-flex align-items-center justify-content-center text-nowrap">       <i class="fa-solid fa-list-check"></i> &nbsp; تقييم </span>
                                </asp:LinkButton>

                            </div>
                        </div>

                        <hr class="my-4 mx-n4" />

                        <div class="row p-sm-3 p-0">
                            <div class="col-md-12 col-sm-5 col-12 mb-sm-0 mb-4">
                                <h6 class="pb-2">عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة </h6>
                                <p class="mb-1">تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل تفاصيل  </p>

                            </div>

                        </div>


                        <!-- Bootstrap modals -->
                        <div class="row p-sm-3 p-0">
                            <h5 class="card-header">توضيح طريقة العمل </h5>

                            <div class="row gy-1">

                                <!-- Fullscreen Modal -->
                                <div class="col-lg-4 col-md-6">
                                    <small class="text-light fw-semibold">تفاصيل المهمة </small>
                                    <div class="mt-3">
                                        <button
                                            type="button"
                                            class="btn btn-primary"
                                            data-bs-toggle="modal"
                                            data-bs-target="#fullscreenModal">
                                            التفاصيل
                       
                                        </button>

                                        <!-- Modal -->
                                        <div class="modal fade" id="fullscreenModal" tabindex="-1" aria-hidden="true">
                                            <div class="modal-dialog modal-fullscreen" role="document">
                                                <div class="modal-content">
                                                    <div class="modal-header">
                                                        <h5 class="modal-title" id="modalFullTitle">التفاصيل</h5>
                                                        <button
                                                            type="button"
                                                            class="btn-close"
                                                            data-bs-dismiss="modal"
                                                            aria-label="Close">
                                                        </button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                        <p>
                                                            Cras mattis consectetur purus sit amet fermentum. Cras justo odio, dapibus ac
                                  facilisis in, egestas eget quam. Morbi leo risus, porta ac consectetur ac, vestibulum
                                  at eros.
                               
                                                        </p>
                                                        <p>
                                                            Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Vivamus sagittis
                                  lacus vel augue laoreet rutrum faucibus dolor auctor.
                               
                                                        </p>
                                                        <p>
                                                            Aenean lacinia bibendum nulla sed consectetur. Praesent commodo cursus magna, vel
                                  scelerisque nisl consectetur et. Donec sed odio dui. Donec ullamcorper nulla non metus
                                  auctor fringilla.
                               
                                                        </p>
                                                    </div>
                                                    <div class="modal-footer">
                                                        <button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">
                                                            Close
                               
                                                        </button>
                                                        <%--<button type="button" class="btn btn-primary">Save changes</button>--%>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Modal with YouTube Video -->
                                <div class="col-lg-4 col-md-6">
                                    <small class="text-light fw-semibold">كيفية التنفيذ</small>
                                    <div class="mt-3">
                                        <button
                                            type="button"
                                            class="btn btn-primary"
                                            data-bs-toggle="modal"
                                            data-bs-target="#youTubeModal"
                                            data-thevideo="https://www.youtube.com/embed/EngW7tLk6R8">
                                            مشاهدة
                       
                                        </button>

                                        <!-- Modal -->
                                        <div class="modal fade" id="youTubeModal" tabindex="-1" aria-hidden="true">
                                            <div class="modal-dialog" role="document">
                                                <div class="modal-content">
                                                    <iframe height="350" src="https://www.youtube.com/embed/EngW7tLk6R8"></iframe>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>


                                <div class="col-lg-4 col-md-6">
                                    <small class="text-light fw-semibold">كيفية التقييم</small>
                                    <div class="mt-3">
                                        <button
                                            type="button"
                                            class="btn btn-primary"
                                            data-bs-toggle="modal"
                                            data-bs-target="#youTubeModal2"
                                            data-thevideo="https://www.youtube.com/embed/0R8JXNSL7yI?si=m5E0aSaGcKKpZVEh">
                                            مشاهدة
                       
                                        </button>

                                        <!-- Modal -->
                                        <div class="modal fade" id="youTubeModal2" tabindex="-1" aria-hidden="true">
                                            <div class="modal-dialog" role="document">
                                                <div class="modal-content">
                                                    <iframe height="350" src="https://www.youtube.com/embed/0R8JXNSL7yI?si=m5E0aSaGcKKpZVEh"></iframe>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>




                            </div>


                        </div>
                        <!--/ Bootstrap modals -->




                        <div class="row g-3 p-sm-3 p-0">
                            <h6 class="pb-2">الموظفيين المعنيين :</h6>
                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>

                            <div class="col-md-4 col-12 mb-md-0 mb-4">
                                <img class="rounded-circle" src="../../assets/img/avatars/2.png" alt="avatar" height="32" width="32">
                                &nbsp;
                          <span>Reply to emails.
                          </span>
                            </div>
                        </div>






                        <%--Start_Popup--%>

                        <asp:Panel ID="PanelPopUp" Width="100%" runat="server" Style="display: none;" DefaultButton="btnClosePopup">
                            <div class="modal-dialog modal-xl" role="document">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <h5 class="modal-title" id="modalCenterTitle">
                                            <asp:Literal runat="server" ID="lblPopupTitle2"><i class="fa-solid fa-list-check"></i> &nbsp; تقييم</asp:Literal>
                                        </h5>
                                        <asp:Button ID="btnClosePopup" runat="server" CssClass="btn-close" OnClick="btnClosePopup_Click" />
                                    </div>
                                    <div class="modal-body">
                                        <div class="row">
                                            <div class="col-xl-12 col-lg-12 col-md-12 mb-3">
                                                <h6>عنوان المهمة عنوان المهمة عنوان المهمة عنوان المهمة </h6>
                                            </div>
                                        </div>

                                        <div class="row">
                                            <div class="col-xl-12 col-lg-12 col-md-12 mb-3">
                                                <ul class="list-inline mb-0 mt-2 d-flex align-items-center flex-wrap justify-content-sm-start justify-content-center gap-2">
                                                    <li class="list-inline-item fw-semibold badge bg-label-secondary rounded p-2"><i class="bx bx-user"></i><span>اسم المدير:</span> محمد دراغمة</li>
                                                    <li class="list-inline-item fw-semibold bg-label-secondary rounded p-2"><i class="bx bx-map"></i>دابوق</li>
                                                    <li class="list-inline-item fw-semibold bg-label-secondary rounded p-2"><i class="bx bx-calendar-alt"></i>11/10/2025 </li>
                                                </ul>
                                            </div>
                                        </div>
                                        <asp:UpdatePanel ID="updatepanel1" runat="server">
                                            <ContentTemplate>
                                                <div class="row g-2">

                                                    <div class="col-xl-6 col-lg-6 col-md-12 mb-0 ">

                                                        <div class="text-light small fw-semibold mb-3">الموظف المسؤول</div>

                                                        <asp:RadioButton ID="rdAll" GroupName="rdEmployees" runat="server" Checked="true" OnCheckedChanged="rdAll_CheckedChanged" AutoPostBack="true" />
                                                        <span class="switch-label">الكل</span>
                                                        &nbsp; &nbsp;
                                                      <asp:RadioButton ID="rdemployee" GroupName="rdEmployees" runat="server" OnCheckedChanged="rdAll_CheckedChanged" AutoPostBack="true" />
                                                        <span class="switch-label">موظف محدد</span>


                                                    </div>

                                                    <div runat="server" id="divEmployee" visible="false" class="col-xl-6 col-lg-6 col-md-12 mb-0">
                                                        <label class="form-label" for="multicol-country">اسم العامل</label>
                                                        <select id="WorkTime" class="select2 form-select" data-allow-clear="true">
                                                            <option value="الرجاء الاختيار">الرجاء الاختيار</option>
                                                            <option value="China">China</option>
                                                            <option value="Brazil">Brazil</option>
                                                            <option value="Canada">Canada</option>
                                                            <option value="China">China</option>
                                                        </select>
                                                    </div>


                                                    <div class="col-xl-12 col-lg-12 col-md-12 mb-0 ">
                                                        <div class="text-light small fw-semibold mb-3">ملاحظات</div>
                                                        <asp:TextBox ID="txtNotes" CssClass="form-control" TextMode="MultiLine" runat="server" placeholder="ادخل الملاحظات"></asp:TextBox>
                                                    </div>

                                                    <div class="col-xl-12 col-lg-12 col-md-12 mb-0 ">
                                                   
                                                        <div class="demo-inline-spacing">
                                                            

                                                            <label class="switch switch-success">
                                                                <input type="radio" class="switch-input" name="rdEvaluation" checked />
                                                                <span class="switch-toggle-slider">
                                                                    <span class="switch-on">
                                                                        <i class="bx bx-check"></i>
                                                                    </span>
                                                                    <span class="switch-off">
                                                                        <i class="bx bx-x"></i>
                                                                    </span>
                                                                </span>
                                                                <span class="switch-label">جيد</span>
                                                            </label>

                                                            <label class="switch switch-warning">
                                                                <input type="radio" class="switch-input" name="rdEvaluation" />
                                                                <span class="switch-toggle-slider">
                                                                    <span class="switch-on">
                                                                        <i class="bx bx-check"></i>
                                                                    </span>
                                                                    <span class="switch-off">
                                                                        <i class="bx bx-x"></i>
                                                                    </span>
                                                                </span>
                                                                <span class="switch-label">مقبول</span>
                                                            </label>


                                                            <label class="switch switch-danger">
                                                                <input type="radio" class="switch-input" name="rdEvaluation" />
                                                                <span class="switch-toggle-slider">
                                                                    <span class="switch-on">
                                                                        <i class="bx bx-check"></i>
                                                                    </span>
                                                                    <span class="switch-off">
                                                                        <i class="bx bx-x"></i>
                                                                    </span>
                                                                </span>
                                                                <span class="switch-label">غير مقبول</span>
                                                            </label>

                                                            

                                                            
                                                        </div>
                                                    </div>



                                                </div>

                                            </ContentTemplate>
                                        </asp:UpdatePanel>
                                </div>
                                <div class="modal-footer">
                                      
                                    <asp:Button ID="btnClose" runat="server" OnClick="btnClose_Click" CssClass="btn btn-label-secondary" Text="اغلاق" />
                                        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">
                                            اضافة
                                        </button>

                                    </div>
                                </div>
                            </div>


                        </asp:Panel>
                        <cc11:ModalPopupExtender ID="LBLPOP_ModalPopupExtender" PopupControlID="PanelPopUp"
                            BackgroundCssClass="OpacityBG" runat="server" TargetControlID="LBLPOP">
                        </cc11:ModalPopupExtender>
                        <asp:Label ID="LBLPOP" runat="server" />
                        <%--End_Popup--%>
                    </div>
                </div>
            </div>
            <!-- /Invoice Edit-->


        </div>

        <!-- Offcanvas -->


        <!-- /Offcanvas -->
    </div>
    <!--/ Content -->


</asp:Content>
