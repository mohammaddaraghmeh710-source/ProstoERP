<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="ManageUsers.aspx.vb" Inherits="CRM.ManageUsers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.device-id{direction:ltr;unicode-bidi:isolate;overflow-wrap:anywhere;font-family:monospace;font-size:.8rem}
.device-dialog .nav-pills{gap:.4rem}.device-dialog .table td{vertical-align:middle}
.device-history{border-inline-start:2px solid #e5e7eb;margin-inline-start:.5rem;padding-inline-start:1.2rem}
.device-event{position:relative;padding-bottom:1.2rem}.device-event:before{content:"";position:absolute;inset-inline-start:-1.62rem;top:.25rem;width:.7rem;height:.7rem;border-radius:50%;background:var(--erp-primary,#3056b9);box-shadow:0 0 0 4px #edf1fb}
.device-dialog .modal-body{padding:1.25rem}
@media(max-width:575px){.device-dialog .modal-body{padding:1rem}.device-dialog .nav-link{font-size:.85rem;padding:.55rem}.device-dialog .btn{white-space:normal}}
</style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server"><asp:UpdatePanel ID="systemAdminPanel" runat="server" UpdateMode="Conditional"><ContentTemplate>

    <div class="container-xxl flex-grow-1 container-p-y">

        <asp:Literal ID="litDeviceOverview" runat="server" />
        <div class="row gy-4">
            <div class="col-xl-12 col-lg-12 col-md-12 order-0 order-md-1">

                <div class="card cvv-code-mask mb-4">

                    <div class="card-header flex-column flex-md-row">
                        <div class="head-label">
                            <h5 class="card-title mb-0">المستخدمون</h5>
                        </div>
                        <div class="dt-action-buttons text-end pt-3 pt-md-0">
                            <div class="dt-buttons">
                                <a class="btn btn-outline-primary" href="/Modules/Employees/AttendanceHistory.aspx">حركات دوام الموظفين</a>
                                <asp:LinkButton ID="btnAddNewItem" runat="server" CssClass="dt-button create-new btn btn-primary" OnClick="btnAddNewItem_Click">
                                    <span><i class="bx bx-plus me-sm-2"></i><span class="d-none d-sm-inline-block">إضافة مستخدم جديد</span></span>
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">

                        <!-- Filters -->
                        <div class="mb-3"><asp:CheckBox ID="chkPendingDevices" runat="server" AutoPostBack="true" OnCheckedChanged="DeviceFilterChanged" Text=" موظفون لديهم طلبات أجهزة بانتظار الموافقة" /></div>
                        <div class="row g-3 mb-4">
                            <div class="col-md-4">
                                <label class="form-label">نوع المستخدم</label>
                                <asp:DropDownList ID="ddlUserType" runat="server" CssClass="form-select"></asp:DropDownList>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">حالة المستخدم</label>
                                <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select"></asp:DropDownList>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">بحث بالاسم / اسم المستخدم</label>
                                <div class="input-group">
                                    <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="اكتب جزء من الاسم أو اسم المستخدم"></asp:TextBox>
                                    <button type="button" class="btn btn-secondary" onclick="__doPostBack('<%= btnSearch.UniqueID %>','')">
                                        بحث
                                    </button>
                                </div>
                            </div>
                        </div>

                        <table id="ERPTable"
                            class="ERP_ProstoTBL card-list-table table table-bordered dt-responsive nowrap">
                            <thead>
                                <tr>
                                    <th>المستخدم</th> <!-- صورة + اسم -->
                                    <th>رقم الموظف</th>
                                    <th>نوع المستخدم</th>
                                    <th>الحالة</th>
                                    <th>تاريخ الإنشاء</th>
                                    <th>أجهزة التطبيق</th><th>QRCode</th>
                                    <th>تعديل</th>
                                    <th>حذف</th>
                                </tr>
                            </thead>
                            <tbody>

                                <asp:ListView runat="server" ID="lstData" OnItemCommand="lstData_ItemCommand">
                                    <LayoutTemplate>
                                        <asp:PlaceHolder runat="server" ID="ItemPlaceHolder"></asp:PlaceHolder>
                                    </LayoutTemplate>
                                    <ItemTemplate>
                                        <tr data-admin-name='<%#: CRM.SystemAdministrationUI.SearchName(Container.DataItem) %>' data-admin-id='<%#: Eval("ID") %>' data-admin-active='<%# CRM.SystemAdministrationUI.State(Container.DataItem) %>'>
                                            <td data-title="المستخدم">
                                                <div class="d-flex align-items-center">
                                                    <img src='<%#: Eval("UserImageUrl") %>'
                                                         class="rounded-circle"
                                                         style="width:40px;height:40px;object-fit:cover;" />
                                                    <div class="ms-2">
                                                        <div><%#: Eval("FullName_Ar") %></div>
                                                        <small class="text-muted"><%#: Eval("UserName") %></small>
                                                    </div>
                                                </div>
                                            </td>
                                            <td data-title="رقم الموظف"><%#: Eval("Employee_Number") %></td>
                                            <td data-title="نوع المستخدم"><%#: Eval("UserTypeTitle") %></td>
                                            <td data-title="الحالة"><%#: Eval("StatusTitle") %></td>
                                            <td data-title="تاريخ الإنشاء">
                                                <%#: Eval("AddedDate", "{0:yyyy/MM/dd HH:mm}") %>
                                            </td>

                                            <td data-title="أجهزة التطبيق">
                                                <asp:LinkButton ID="btnDevices" runat="server" CommandName="Devices" CommandArgument='<%#: Eval("ID") %>' CssClass="btn btn-sm btn-label-primary"><i class="bx bx-mobile-alt me-1"></i> إدارة الأجهزة <span class="badge bg-primary ms-1"><%#: Eval("PendingDevices") %></span></asp:LinkButton>
                                            </td>
                                            <td data-title="QRCode">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-success" ID="lnkQRCode" CommandName="QRCode" CommandArgument='<%#: Eval("ID") %>' runat="server" ToolTip="طباعة QRCode">    <i class="bx bx-qr"></i> </asp:LinkButton>
                                            </td>
                                            <td data-title="تعديل">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-secondary" ID="btnEdit" CommandName="Edit" CommandArgument='<%#: Eval("ID") %>' runat="server" ToolTip="تعديل">
                                                    <i class="bx bx-edit-alt"></i>
                                                </asp:LinkButton>
                                            </td>
                                            <td data-title="حذف">
                                                <asp:LinkButton CssClass="btn btn-icon btn-label-danger" ID="btnDelete"
                                                    CommandName="DeleteItem"
                                                    CommandArgument='<%#: Eval("ID") %>'
                                                    runat="server"
                                                    ToolTip="حذف"
                                                    CausesValidation="false"
                                                    OnClientClick="return confirm('هل أنت متأكد من حذف هذا المستخدم؟');">
                                                    <i class="bx bx-trash-alt"></i>
                                                </asp:LinkButton>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                    <EmptyDataTemplate>
                                        <span class="no-data-title">لا يوجد محتوى لعرضه</span>
                                    </EmptyDataTemplate>
                                </asp:ListView>

                            </tbody>
                        </table>

                        <asp:Button ID="btnSearch" runat="server" Text="بحث" CssClass="d-none" OnClick="btnSearch_Click" />

                    </div>

                </div>
            </div>
        </div>
    </div>

    <asp:Panel ID="pnlDevices" runat="server" Visible="false">
      <div class="modal fade device-dialog" id="deviceModal" tabindex="-1" aria-labelledby="deviceTitle" aria-hidden="true">
        <div class="modal-dialog modal-xl modal-dialog-scrollable modal-fullscreen-sm-down"><div class="modal-content">
          <div class="modal-header border-bottom">
            <div><h5 class="modal-title" id="deviceTitle"><i class="bx bx-shield-quarter me-2 text-primary"></i>أجهزة تطبيق الهاتف</h5><div class="text-muted small mt-1"><asp:Literal ID="litDeviceEmployee" runat="server" /></div></div>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="إغلاق"></button>
          </div>
          <div class="modal-body">
            <asp:Panel ID="pnlDeviceMessage" runat="server" Visible="false" role="status" CssClass="alert alert-info"><asp:Literal ID="litDeviceMessage" runat="server" /></asp:Panel>
            <asp:Literal ID="litDeviceSummary" runat="server" />
            <ul class="nav nav-pills flex-wrap mb-3" role="tablist">
              <li class="nav-item" role="presentation"><button class="nav-link active" id="requests-tab" data-bs-toggle="tab" data-bs-target="#deviceRequests" type="button" role="tab" aria-controls="deviceRequests" aria-selected="true"><i class="bx bx-time-five me-1"></i>طلبات الموافقة</button></li>
              <li class="nav-item" role="presentation"><button class="nav-link" id="devices-tab" data-bs-toggle="tab" data-bs-target="#deviceList" type="button" role="tab" aria-controls="deviceList" aria-selected="false"><i class="bx bx-mobile-alt me-1"></i>الأجهزة المسجلة</button></li>
              <li class="nav-item" role="presentation"><button class="nav-link" id="history-tab" data-bs-toggle="tab" data-bs-target="#deviceHistory" type="button" role="tab" aria-controls="deviceHistory" aria-selected="false"><i class="bx bx-history me-1"></i>سجل القرارات</button></li>
            </ul>
            <div class="tab-content p-0 shadow-none">
              <div class="tab-pane fade show active" id="deviceRequests" role="tabpanel" aria-labelledby="requests-tab">
                <asp:ListView ID="lstDeviceRequests" runat="server" OnItemCommand="DeviceCommand">
                  <LayoutTemplate><div class="vstack gap-3"><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></div></LayoutTemplate>
                  <ItemTemplate>
                    <div class="border rounded p-3">
                      <div class="d-flex flex-wrap justify-content-between gap-2 mb-2"><strong><i class="bx bx-mobile-alt me-1 text-primary"></i><%#: Eval("DeviceModel") %></strong><span class="badge bg-label-warning"><%# DeviceLabel(Eval("Status")) %></span></div>
                      <div class="small text-muted mb-2"><%#: Eval("DeviceManufacturer") %> · <%#: Eval("DevicePlatform") %> / <%#: Eval("OSVersion") %> · التطبيق <%#: Eval("AppVersion") %> (<%#: Eval("AppBuild") %>) · <%# DeviceDate(Eval("CreatedUtc")) %></div>
                      <div class="device-id mb-1"><%#: Eval("DeviceID") %></div><div class="small mb-2">MAC: <bdi><%#: Eval("MACID") %></bdi></div>
                      <asp:Panel runat="server" Visible='<%# CStr(Eval("Status")) = "Pending" %>' CssClass="d-flex flex-wrap gap-2">
                        <asp:LinkButton runat="server" CssClass="btn btn-sm btn-primary" CommandName="ApproveReplace" CommandArgument='<%#: Eval("ID") %>' OnClientClick="return confirm('اعتماد هذا الجهاز وإلغاء جميع الأجهزة الأخرى وتوكناتها؟');"><i class="bx bx-transfer me-1"></i>الموافقة وإلغاء الأجهزة القديمة</asp:LinkButton>
                        <asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-success" CommandName="ApproveAdd" CommandArgument='<%#: Eval("ID") %>' OnClientClick="return confirm('السماح بهذا الجهاز مع الاحتفاظ بجميع الأجهزة المعتمدة؟');"><i class="bx bx-plus-circle me-1"></i>الموافقة مع الإبقاء على الأجهزة</asp:LinkButton>
                        <asp:LinkButton runat="server" CssClass="btn btn-sm btn-label-danger" CommandName="Reject" CommandArgument='<%#: Eval("ID") %>' OnClientClick="return confirm('رفض طلب اعتماد هذا الجهاز؟');">رفض الطلب</asp:LinkButton>
                      </asp:Panel>
                      <asp:Panel runat="server" Visible='<%# CStr(Eval("Status")) <> "Pending" %>' CssClass="small text-muted"><%# DeviceLabel(Eval("Decision")) %> · <%# DeviceDate(Eval("DecidedUtc")) %><div><%#: Eval("Comment") %></div></asp:Panel>
                    </div>
                  </ItemTemplate>
                  <EmptyDataTemplate><div class="text-center border rounded p-4 text-muted"><i class="bx bx-check-shield fs-1 d-block mb-2"></i>لا توجد طلبات أجهزة لهذا الموظف.</div></EmptyDataTemplate>
                </asp:ListView>
              </div>
              <div class="tab-pane fade" id="deviceList" role="tabpanel" aria-labelledby="devices-tab">
                <asp:ListView ID="lstDevices" runat="server" OnItemCommand="DeviceCommand">
                  <LayoutTemplate><div class="table-responsive"><table class="table table-hover border-top"><thead><tr><th>الجهاز</th><th>التطبيق والنظام</th><th>حالة الوصول</th><th>آخر دخول</th><th>الإجراء</th></tr></thead><tbody><asp:PlaceHolder ID="itemPlaceholder" runat="server" /></tbody></table></div></LayoutTemplate>
                  <ItemTemplate><tr>
                    <td><strong><i class="bx bx-mobile-alt text-primary me-1"></i><%#: Eval("DeviceModel") %></strong><div class="small text-muted"><%#: Eval("DeviceManufacturer") %></div><div class="device-id"><%#: Eval("DeviceID") %></div><div class="small">MAC: <bdi><%#: Eval("MACID") %></bdi></div></td>
                    <td><bdi><%#: Eval("DevicePlatform") %> <%#: Eval("OSVersion") %></bdi><div class="small text-muted">التطبيق <%#: Eval("AppVersion") %> (<%#: Eval("AppBuild") %>)</div></td>
                    <td><span class='<%# If(CBool(Eval("IsApproved")), "badge bg-label-success", "badge bg-label-secondary") %>'><%# If(CBool(Eval("IsApproved")), "مسموح", "غير مسموح") %></span></td>
                    <td><%# DeviceDate(Eval("LastLoginUtc")) %><div class="small text-muted">التسجيل: <%# DeviceDate(Eval("FirstSeenUtc")) %></div></td>
                    <td><asp:LinkButton runat="server" Visible='<%# CBool(Eval("IsApproved")) %>' CssClass="btn btn-sm btn-label-danger" CommandName="Revoke" CommandArgument='<%#: Eval("ID") %>' OnClientClick="return confirm('إلغاء هذا الجهاز وإنهاء جميع جلساته؟ لن يعتمد جهاز بديل تلقائيًا.');"><i class="bx bx-block me-1"></i>إلغاء الجهاز</asp:LinkButton></td>
                  </tr></ItemTemplate>
                  <EmptyDataTemplate><div class="text-center border rounded p-4 text-muted">لم يسجل الموظف أي جهاز بعد.</div></EmptyDataTemplate>
                </asp:ListView>
              </div>
              <div class="tab-pane fade" id="deviceHistory" role="tabpanel" aria-labelledby="history-tab"><div class="device-history"><asp:Literal ID="litDeviceHistory" runat="server" /></div></div>
            </div>
            <div class="border-top mt-3 pt-3">
              <asp:Label runat="server" AssociatedControlID="txtDeviceComment" CssClass="form-label" Text="ملاحظة القرار (اختياري)" />
              <asp:TextBox ID="txtDeviceComment" runat="server" CssClass="form-control" MaxLength="500" placeholder="تُحفظ مع الموافقة أو الرفض أو الإلغاء" />
              <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mt-3">
                <div class="small text-muted"><i class="bx bx-info-circle me-1"></i>إلغاء الجميع ينهي الجلسات ويلغي الطلبات المعلقة، ويعتمد أول جهاز عند الدخول التالي.</div>
                <asp:LinkButton ID="btnResetDevices" runat="server" CssClass="btn btn-label-danger" OnClick="ResetDevices" OnClientClick="return confirm('إلغاء جميع الأجهزة والجلسات والطلبات المعلقة، والسماح باعتماد أول جهاز عند الدخول التالي؟');"><i class="bx bx-reset me-1"></i>إلغاء الجميع والسماح بجهاز عند الدخول التالي</asp:LinkButton>
              </div>
            </div>
          </div>
          <div class="modal-footer border-top py-2"><small class="text-muted me-auto">الأوقات بتوقيت الأردن</small><button type="button" class="btn btn-label-secondary" data-bs-dismiss="modal">إغلاق</button></div>
        </div></div>
      </div>
    </asp:Panel>

</ContentTemplate></asp:UpdatePanel></asp:Content>
