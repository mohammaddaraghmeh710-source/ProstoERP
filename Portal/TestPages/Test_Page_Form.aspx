<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Test_Page_Form.aspx.vb" Inherits="CRM.Test_Page_Form" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <%--Options--%>
    <%--<hr class="my-4 mx-n4" />--%>

    <div class="container-xxl flex-grow-1 container-p-y">
        <h4 class="py-3 breadcrumb-wrapper mb-4"><span class="text-muted fw-light">Forms/</span> Vertical Layouts </h4>
        <!-- Multi Column with Form Separator -->
        <div class="card mb-4  cvv-code-mask">
            <h5 class="card-header">Multi Column with Form Separator</h5>
            <div class="card-body">
                <h6 class="fw-normal">1. Account Details</h6>
                <div class="row g-3">



                    <div class="col-12">
                        <div>
                            <label for="defaultFormControlInput" class="form-label">Name</label>
                            <input type="text" class="form-control" id="defaultFormControlInput" placeholder="John Doe" aria-describedby="defaultFormControlHelp" />
                            <div id="defaultFormControlHelp" class="form-text">
                                Note below text box.
                           
                            </div>
                        </div>


                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-username">Username</label>
                        <input type="text" id="multicol-username" class="form-control" placeholder="john.doe" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-email">Email</label>
                        <div class="input-group input-group-merge">
                            <input
                                type="text"
                                id="multicol-email"
                                class="form-control"
                                placeholder="john.doe"
                                aria-label="john.doe"
                                aria-describedby="multicol-email2" />
                            <span class="input-group-text" id="multicol-email2">@example.com</span>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-password-toggle">
                            <label class="form-label" for="multicol-password">Password</label>
                            <div class="input-group input-group-merge">
                                <input
                                    type="password"
                                    id="multicol-password"
                                    class="form-control"
                                    placeholder="&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;"
                                    aria-describedby="multicol-password2" />
                                <span class="input-group-text cursor-pointer" id="multicol-password2"><i class="bx bx-hide"></i></span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-password-toggle">
                            <label class="form-label" for="multicol-confirm-password">Confirm Password</label>
                            <div class="input-group input-group-merge">
                                <input
                                    type="password"
                                    id="multicol-confirm-password"
                                    class="form-control"
                                    placeholder="&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;&#xb7;"
                                    aria-describedby="multicol-confirm-password2" />
                                <span class="input-group-text cursor-pointer" id="multicol-confirm-password2"><i class="bx bx-hide"></i></span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-first-name">First Name</label>
                        <input type="text" id="multicol-first-name" class="form-control" placeholder="John" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-last-name">Last Name</label>
                        <input type="text" id="multicol-last-name" class="form-control" placeholder="Doe" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-country">Country</label>
                        <select id="multicol-country" class="select2 form-select" data-allow-clear="true">
                            <option value="">Select</option>
                            <option value="Australia">Australia</option>
                            <option value="Bangladesh">Bangladesh</option>
                            <option value="Belarus">Belarus</option>
                            <option value="Brazil">Brazil</option>
                            <option value="Canada">Canada</option>
                            <option value="China">China</option>
                            <option value="France">France</option>
                            <option value="Germany">Germany</option>
                            <option value="India">India</option>
                            <option value="Indonesia">Indonesia</option>
                            <option value="Israel">Israel</option>
                            <option value="Italy">Italy</option>
                            <option value="Japan">Japan</option>
                            <option value="Korea">Korea, Republic of</option>
                            <option value="Mexico">Mexico</option>
                            <option value="Philippines">Philippines</option>
                            <option value="Russia">Russian Federation</option>
                            <option value="South Africa">South Africa</option>
                            <option value="Thailand">Thailand</option>
                            <option value="Turkey">Turkey</option>
                            <option value="Ukraine">Ukraine</option>
                            <option value="United Arab Emirates">United Arab Emirates</option>
                            <option value="United Kingdom">United Kingdom</option>
                            <option value="United States">United States</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-birthdate">Birth Date</label>
                        <input
                            type="text"
                            id="multicol-birthdate"
                            class="form-control dob-picker"
                            placeholder="YYYY-MM-DD" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="multicol-phone">Phone No</label>
                        <input
                            type="text"
                            id="multicol-phone"
                            class="form-control phone-mask"
                            placeholder="658 799 8941"
                            aria-label="658 799 8941" />
                    </div>

                    <div class="col-md-6 col-12 mb-4">
                        <label for="flatpickr-date" class="form-label">Date Picker</label>
                        <input type="text" class="form-control" placeholder="YYYY-MM-DD" id="flatpickr-date" />
                    </div>

                    <div class="col-md-6 col-12 mb-4">
                        <label for="flatpickr-time" class="form-label">Time Picker</label>
                        <input type="text" class="form-control" placeholder="HH:MM" id="flatpickr-time" />
                    </div>

                    <div class="col-md-6">
                        <label class="form-label" for="multicol-phone">DateTime </label>

                        <input
                            class="form-control"
                            type="datetime-local"
                            value="2021-06-18T12:30:00"
                            id="html5-datetime-local-input" />

                    </div>

                    <div class="col-sm-6">
                        <div class="text-light small fw-semibold mb-3">Default</div>
                        <label class="switch">
                            <input type="checkbox" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"></span>
                                <span class="switch-off"></span>
                            </span>
                            <span class="switch-label">Default</span>
                        </label>
                    </div>
                    <div class="col-sm-6">
                        <div class="text-light small fw-semibold mb-3">Square</div>
                        <label class="switch switch-square">
                            <input type="checkbox" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"></span>
                                <span class="switch-off"></span>
                            </span>
                            <span class="switch-label">Square</span>
                        </label>
                    </div>

                    <div class="col-sm-6">
                        <div class="text-light small fw-semibold mb-3">Default with icon</div>
                        <label class="switch">
                            <input type="checkbox" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on">
                                    <i class="bx bx-check"></i>
                                </span>
                                <span class="switch-off">
                                    <i class="bx bx-x"></i>
                                </span>
                            </span>
                            <span class="switch-label">With icon</span>
                        </label>
                    </div>
                    <div class="col-sm-6">
                        <div class="text-light small fw-semibold mb-3">Square with icon</div>
                        <label class="switch switch-square">
                            <input type="checkbox" class="switch-input" />
                            <span class="switch-toggle-slider">
                                <span class="switch-on"><i class="bx bx-check"></i></span>
                                <span class="switch-off"><i class="bx bx-x"></i></span>
                            </span>
                            <span class="switch-label">With icon</span>
                        </label>
                    </div>

                    <div class="col-12">
                        <div class="text-light small fw-semibold">Default</div>
                        <div class="demo-inline-spacing">
                            <label class="switch switch-primary">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Primary</span>
                            </label>

                            <label class="switch switch-secondary">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Secondary</span>
                            </label>

                            <label class="switch switch-success">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Success</span>
                            </label>

                            <label class="switch switch-danger">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Danger</span>
                            </label>

                            <label class="switch switch-warning">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Warning</span>
                            </label>

                            <label class="switch switch-info">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Info</span>
                            </label>

                            <label class="switch switch-dark">
                                <input type="checkbox" class="switch-input" checked />
                                <span class="switch-toggle-slider">
                                    <span class="switch-on">
                                        <i class="bx bx-check"></i>
                                    </span>
                                    <span class="switch-off">
                                        <i class="bx bx-x"></i>
                                    </span>
                                </span>
                                <span class="switch-label">Dark</span>
                            </label>
                        </div>
                    </div>

                    <div class="col-12">
                        <label class="form-label" for="collapsible-address">Address</label>
                        <textarea
                            name="collapsible-address"
                            class="form-control"
                            id="collapsible-address"
                            rows="2"
                            placeholder="1456, Mall Road"></textarea>
                    </div>

                    <div class="col-12">
                        <div id="full-editor">
                            <h6>Quill Rich Text Editor</h6>
                            <p>
                                Cupcake ipsum dolor sit amet. Halvah cheesecake chocolate bar gummi bears cupcake. Pie
                          macaroon bear claw. Soufflé I love candy canes I love cotton candy I love.
                       
                            </p>
                        </div>
                    </div>

                    <hr class="my-4 mx-n4" />
                    <h5 class="card-header">Radio and Check Buttons</h5>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-basic">
                                    <label class="form-check-label custom-option-content" for="customRadioTemp1">
                                        <input
                                            name="customRadioTemp"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioTemp1"
                                            checked />
                                        <span class="custom-option-header">
                                            <span class="h6 mb-0">Basic</span>
                                            <span>Free</span>
                                        </span>
                                        <span class="custom-option-body">
                                            <small>Get 1 project with 1 teams members.</small>
                                        </span>
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-basic">
                                    <label class="form-check-label custom-option-content" for="customRadioTemp2">
                                        <input
                                            name="customRadioTemp"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioTemp2" />
                                        <span class="custom-option-header">
                                            <span class="h6 mb-0">Premium</span>
                                            <span>$ 5.00</span>
                                        </span>
                                        <span class="custom-option-body">
                                            <small>Get 5 projects with 5 team members.</small>
                                        </span>
                                    </label>
                                </div>
                            </div>
                        </div>

                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-basic">
                                    <label class="form-check-label custom-option-content" for="customCheckTemp3">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckTemp3" checked />
                                        <span class="custom-option-header">
                                            <span class="h6 mb-0">Discount</span>
                                            <span>20%</span>
                                        </span>
                                        <span class="custom-option-body">
                                            <small class="option-text">wow Get 20% off on your next purchases!</small>
                                        </span>
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-basic">
                                    <label class="form-check-label custom-option-content" for="customCheckTemp4">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckTemp4" />
                                        <span class="custom-option-header">
                                            <span class="h6 mb-0">Updates</span>
                                            <span>Free</span>
                                        </span>
                                        <span class="custom-option-body">
                                            <small>Get Updates regarding related products.</small>
                                        </span>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioIcon1">
                                        <span class="custom-option-body">
                                            <i class="bx bx-rocket"></i>
                                            <span class="custom-option-title">Starter</span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input
                                            name="customRadioIcon"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioIcon1"
                                            checked />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioIcon2">
                                        <span class="custom-option-body">
                                            <i class="bx bx-user"></i>
                                            <span class="custom-option-title">Personal </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input
                                            name="customRadioIcon"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioIcon2" />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioIcon3">
                                        <span class="custom-option-body">
                                            <i class="bx bx-crown"></i>
                                            <span class="custom-option-title">Enterprise </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input
                                            name="customRadioIcon"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioIcon3" />
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxIcon1">
                                        <span class="custom-option-body">
                                            <i class="bx bx-server"></i>
                                            <span class="custom-option-title">Backup </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            value=""
                                            id="customCheckboxIcon1"
                                            checked />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxIcon2">
                                        <span class="custom-option-body">
                                            <i class="bx bx-shield"></i>
                                            <span class="custom-option-title">Encrypt </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckboxIcon2" />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxIcon3">
                                        <span class="custom-option-body">
                                            <i class="bx bx-lock"></i>
                                            <span class="custom-option-title">Site Lock </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckboxIcon3" />
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioSvg1">
                                        <span class="custom-option-body">
                                            <img
                                                src="../../assets/img/icons/unicons/paypal.png"
                                                class="w-px-40 mb-2"
                                                alt="paypal" />
                                            <span class="custom-option-title">Design </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input
                                            name="customRadioSvg"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioSvg1"
                                            checked />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioSvg2">
                                        <span class="custom-option-body">
                                            <img
                                                src="../../assets/img/icons/unicons/wallet.png"
                                                class="w-px-40 mb-2"
                                                alt="wallet" />
                                            <span class="custom-option-title">Development </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input
                                            name="customRadioSvg"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioSvg2" />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customRadioSvg3">
                                        <span class="custom-option-body">
                                            <img
                                                src="../../assets/img/icons/unicons/cc-success.png"
                                                class="w-px-40 mb-2"
                                                alt="cc-success" />
                                            <span class="custom-option-title">Native App </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input
                                            name="customRadioSvg"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioSvg3" />
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxSvg1">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/icons/unicons/chart.png" class="w-px-40 mb-2" alt="chart" />
                                            <span class="custom-option-title">Design </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            value=""
                                            id="customCheckboxSvg1"
                                            checked />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxSvg2">
                                        <span class="custom-option-body">
                                            <img
                                                src="../../assets/img/icons/unicons/cc-warning.png"
                                                class="w-px-40 mb-2"
                                                alt="cc-warning" />
                                            <span class="custom-option-title">Development </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o.</small>
                                        </span>
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckboxSvg2" />
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-icon">
                                    <label class="form-check-label custom-option-content" for="customCheckboxSvg3">
                                        <span class="custom-option-body">
                                            <img
                                                src="../../assets/img/icons/unicons/paypal.png"
                                                class="w-px-40 mb-2"
                                                alt="paypal" />
                                            <span class="custom-option-title">Native App </span>
                                            <small>Cake sugar plum fruitcake I love sweet roll jelly-o. </small>
                                        </span>
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckboxSvg3" />
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-image custom-option-image-radio">
                                    <label class="form-check-label custom-option-content" for="customRadioImg1">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/3.jpg" alt="radioImg" />
                                        </span>
                                    </label>
                                    <input
                                        name="customRadioImage"
                                        class="form-check-input"
                                        type="radio"
                                        value="customRadioImg1"
                                        id="customRadioImg1"
                                        checked />
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-image custom-option-image-radio">
                                    <label class="form-check-label custom-option-content" for="customRadioImg2">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/8.jpg" alt="radioImg" />
                                        </span>
                                    </label>
                                    <input
                                        name="customRadioImage"
                                        class="form-check-input"
                                        type="radio"
                                        value="customRadioImg2"
                                        id="customRadioImg2" />
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-image custom-option-image-radio">
                                    <label class="form-check-label custom-option-content" for="customRadioImg3">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/5.jpg" alt="radioImg" />
                                        </span>
                                    </label>
                                    <input
                                        name="customRadioImage"
                                        class="form-check-input"
                                        type="radio"
                                        value="customRadioImg3"
                                        id="customRadioImg3" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-6">
                        <div class="row">
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-image custom-option-image-check">
                                    <input class="form-check-input" type="checkbox" value="" id="customCheckboxImg1" checked />
                                    <label class="form-check-label custom-option-content" for="customCheckboxImg1">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/3.jpg" alt="cbImg" />
                                        </span>
                                    </label>
                                </div>
                            </div>
                            <div class="col-md mb-md-0 mb-2">
                                <div class="form-check custom-option custom-option-image custom-option-image-check">
                                    <input class="form-check-input" type="checkbox" value="" id="customCheckboxImg2" />
                                    <label class="form-check-label custom-option-content" for="customCheckboxImg2">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/5.jpg" alt="cbImg" />
                                        </span>
                                    </label>
                                </div>
                            </div>
                            <div class="col-md">
                                <div class="form-check custom-option custom-option-image custom-option-image-check">
                                    <input class="form-check-input" type="checkbox" value="" id="customCheckboxImg3" />
                                    <label class="form-check-label custom-option-content" for="customCheckboxImg3">
                                        <span class="custom-option-body">
                                            <img src="../../assets/img/backgrounds/8.jpg" alt="cbImg" />
                                        </span>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-xl-12">
                        <div class="card mb-4">
                            <h5 class="card-header">Checkboxes and Radios</h5>
                            <!-- Checkboxes and Radios -->
                            <div class="row row-bordered g-0">
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold">Checkboxes</small>
                                    <div class="form-check mt-3">
                                        <input class="form-check-input" type="checkbox" value="" id="defaultCheck1" />
                                        <label class="form-check-label" for="defaultCheck1">Unchecked </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" value="" id="defaultCheck2" checked />
                                        <label class="form-check-label" for="defaultCheck2">Indeterminate </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" value="" id="defaultCheck3" checked />
                                        <label class="form-check-label" for="defaultCheck3">Checked </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" value="" id="disabledCheck1" disabled />
                                        <label class="form-check-label" for="disabledCheck1">Disabled Unchecked </label>
                                    </div>
                                    <div class="form-check">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            value=""
                                            id="disabledCheck2"
                                            disabled
                                            checked />
                                        <label class="form-check-label" for="disabledCheck2">Disabled Checked </label>
                                    </div>
                                </div>
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold">Radio</small>
                                    <div class="form-check mt-3">
                                        <input
                                            name="default-radio-1"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="defaultRadio1" />
                                        <label class="form-check-label" for="defaultRadio1">Unchecked </label>
                                    </div>
                                    <div class="form-check">
                                        <input
                                            name="default-radio-1"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="defaultRadio2"
                                            checked />
                                        <label class="form-check-label" for="defaultRadio2">Checked </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" value="" id="disabledRadio1" disabled />
                                        <label class="form-check-label" for="disabledRadio1">Disabled unchecked </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" value="" id="disabledRadio2" disabled checked />
                                        <label class="form-check-label" for="disabledRadio2">Disabled checkbox </label>
                                    </div>
                                </div>
                            </div>
                            <hr class="m-0" />
                            <!-- Inline Checkboxes -->
                            <div class="row row-bordered g-0">
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold d-block">Inline Checkboxes</small>
                                    <div class="form-check form-check-inline mt-3">
                                        <input class="form-check-input" type="checkbox" id="inlineCheckbox1" value="option1" />
                                        <label class="form-check-label" for="inlineCheckbox1">1</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="checkbox" id="inlineCheckbox2" value="option2" />
                                        <label class="form-check-label" for="inlineCheckbox2">2</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            id="inlineCheckbox3"
                                            value="option3"
                                            disabled />
                                        <label class="form-check-label" for="inlineCheckbox3">3 (disabled)</label>
                                    </div>
                                </div>
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold d-block">Inline Radio</small>
                                    <div class="form-check form-check-inline mt-3">
                                        <input
                                            class="form-check-input"
                                            type="radio"
                                            name="inlineRadioOptions"
                                            id="inlineRadio1"
                                            value="option1" />
                                        <label class="form-check-label" for="inlineRadio1">1</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input
                                            class="form-check-input"
                                            type="radio"
                                            name="inlineRadioOptions"
                                            id="inlineRadio2"
                                            value="option2" />
                                        <label class="form-check-label" for="inlineRadio2">2</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input
                                            class="form-check-input"
                                            type="radio"
                                            name="inlineRadioOptions"
                                            id="inlineRadio3"
                                            value="option3"
                                            disabled />
                                        <label class="form-check-label" for="inlineRadio3">3 (disabled)</label>
                                    </div>
                                </div>
                            </div>
                            <hr class="m-0" />
                            <!-- Checkboxes & Radio Colors -->
                            <div class="row row-bordered g-0">
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold d-block">Checkboxes Colors</small>

                                    <div class="form-check form-check-primary mt-3">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckPrimary" checked />
                                        <label class="form-check-label" for="customCheckPrimary">Primary</label>
                                    </div>
                                    <div class="form-check form-check-secondary">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckSecondary" checked />
                                        <label class="form-check-label" for="customCheckSecondary">Secondary</label>
                                    </div>
                                    <div class="form-check form-check-success">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckSuccess" checked />
                                        <label class="form-check-label" for="customCheckSuccess">Success</label>
                                    </div>
                                    <div class="form-check form-check-danger">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckDanger" checked />
                                        <label class="form-check-label" for="customCheckDanger">Danger</label>
                                    </div>
                                    <div class="form-check form-check-warning">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckWarning" checked />
                                        <label class="form-check-label" for="customCheckWarning">Warning </label>
                                    </div>
                                    <div class="form-check form-check-info">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckInfo" checked />
                                        <label class="form-check-label" for="customCheckInfo">Info </label>
                                    </div>
                                    <div class="form-check form-check-dark">
                                        <input class="form-check-input" type="checkbox" value="" id="customCheckDark" checked />
                                        <label class="form-check-label" for="customCheckDark">Dark </label>
                                    </div>
                                </div>
                                <div class="col-md p-4">
                                    <small class="text-light fw-semibold d-block">Radio Color</small>
                                    <div class="form-check form-check-primary mt-3">
                                        <input
                                            name="customRadioPrimary"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioPrimary"
                                            checked />
                                        <label class="form-check-label" for="customRadioPrimary">Primary </label>
                                    </div>
                                    <div class="form-check form-check-secondary">
                                        <input
                                            name="customRadioSecondary"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioSecondary"
                                            checked />
                                        <label class="form-check-label" for="customRadioSecondary">Secondary </label>
                                    </div>
                                    <div class="form-check form-check-success">
                                        <input
                                            name="customRadioSuccess"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioSuccess"
                                            checked />
                                        <label class="form-check-label" for="customRadioSuccess">Success </label>
                                    </div>
                                    <div class="form-check form-check-danger">
                                        <input
                                            name="customRadioDanger"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioDanger"
                                            checked />
                                        <label class="form-check-label" for="customRadioDanger">Danger </label>
                                    </div>
                                    <div class="form-check form-check-warning">
                                        <input
                                            name="customRadioWarning"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioWarning"
                                            checked />
                                        <label class="form-check-label" for="customRadioWarning">Warning </label>
                                    </div>
                                    <div class="form-check form-check-info">
                                        <input
                                            name="customRadioInfo"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioInfo"
                                            checked />
                                        <label class="form-check-label" for="customRadioInfo">Info </label>
                                    </div>
                                    <div class="form-check form-check-dark">
                                        <input
                                            name="customRadioDark"
                                            class="form-check-input"
                                            type="radio"
                                            value=""
                                            id="customRadioDark"
                                            checked />
                                        <label class="form-check-label" for="customRadioDark">Dark </label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Switches -->
                        <div class="card mb-4">
                            <h5 class="card-header">Switches</h5>
                            <div class="card-body">
                                <div class="form-check form-switch mb-2">
                                    <input class="form-check-input" type="checkbox" id="flexSwitchCheckDefault" />
                                    <label class="form-check-label" for="flexSwitchCheckDefault">
                                        Default switch checkbox input</label>
                                </div>
                                <div class="form-check form-switch mb-2">
                                    <input class="form-check-input" type="checkbox" id="flexSwitchCheckChecked" checked />
                                    <label class="form-check-label" for="flexSwitchCheckChecked">
                                        Checked switch checkbox input</label>
                                </div>
                                <div class="form-check form-switch mb-2">
                                    <input class="form-check-input" type="checkbox" id="flexSwitchCheckDisabled" disabled />
                                    <label class="form-check-label" for="flexSwitchCheckDisabled">
                                        Disabled switch checkbox input</label>
                                </div>
                                <div class="form-check form-switch">
                                    <input
                                        class="form-check-input"
                                        type="checkbox"
                                        id="flexSwitchCheckCheckedDisabled"
                                        checked
                                        disabled />
                                    <label class="form-check-label" for="flexSwitchCheckCheckedDisabled">
                                        Disabled checked switch checkbox input</label>
                                </div>
                            </div>
                        </div>


                    </div>


                </div>
                <div class="pt-4">
                    <button type="submit" class="btn btn-primary me-sm-3 me-1">Submit</button>
                    <button type="reset" class="btn btn-label-secondary">Cancel</button>
                </div>




            </div>
        </div>
    </div>



</asp:Content>
