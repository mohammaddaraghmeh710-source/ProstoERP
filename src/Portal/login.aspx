<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="Login.aspx.vb" Inherits="CRM.Login" %><!doctype html><html lang="ar" dir="rtl" class="light-style customizer-hide" data-theme="theme-default" data-assets-path="/assets/"><head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>تسجيل الدخول | مايوركا</title>
    <meta name="description" content="" />

    <link rel="icon" type="image/x-icon" href="../../assets/img/favicon/favicon.ico" />

    <link rel="stylesheet" href="../../assets/vendor/fonts/boxicons.css" />
    <link rel="stylesheet" href="../../assets/vendor/fonts/fontawesome.css" />
    <link rel="stylesheet" href="../../assets/vendor/fonts/flag-icons.css" />

    <link rel="stylesheet" href="../../assets/vendor/css/rtl/core.css" class="template-customizer-core-css" />
    <link rel="stylesheet" href="../../assets/vendor/css/rtl/theme-default.css" class="template-customizer-theme-css" />
    <link rel="stylesheet" href="../../assets/css/demo.css" />

    <link rel="stylesheet" href="../../assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.css" />
    <link rel="stylesheet" href="../../assets/vendor/libs/typeahead-js/typeahead.css" />
    <link rel="stylesheet" href="../../assets/vendor/libs/formvalidation/dist/css/formValidation.min.css" />

    <link rel="stylesheet" href="../../assets/vendor/css/pages/page-auth.css" />

    <script src="../../assets/vendor/js/helpers.js"></script>
    
    
    <link rel="stylesheet" href="/assets/css/erp-theme.css?v=20260906" />
</head><body class="erp-ui"><form runat="server"><div class="authentication-wrapper authentication-cover"><div class="authentication-inner row m-0"><div class="d-none d-lg-flex col-lg-7 col-xl-8 align-items-center justify-content-center p-5"><div class="text-center"><img src="/assets/img/pages/login-light.png" class="img-fluid authentication-cover-img" alt=""/><h2 class="mt-4">كل ما تحتاجه، في مكان واحد</h2><p class="text-muted">بوابة موحدة للموظفين والعملاء للتواصل والوصول إلى الخدمات.</p></div></div><div class="d-flex col-12 col-lg-5 col-xl-4 align-items-center authentication-bg p-sm-5 p-4"><div class="w-px-400 mx-auto"><div class="app-brand mb-5 d-flex align-items-center gap-3"><img src="/assets/img/Prosto/Logo_Circle.png" width="56" height="56" alt="مايوركا"/><span class="h3 mb-0">مايوركا</span></div><h3>أهلاً بعودتك</h3><p class="text-muted mb-4">اختر نوع الحساب وسجّل الدخول للمتابعة.</p><asp:Panel ID="pnlAlert" runat="server" CssClass="alert alert-danger" Visible="false" role="alert"><asp:Label ID="lblAlert" runat="server"/></asp:Panel><asp:Panel ID="pnlInfo" runat="server" CssClass="alert alert-info" Visible="false"><asp:Label ID="lblInfo" runat="server"/></asp:Panel><div class="mb-4"><asp:Label runat="server" AssociatedControlID="ddlAccountKind" CssClass="form-label" Text="نوع الحساب"/><asp:DropDownList ID="ddlAccountKind" runat="server" CssClass="form-select form-select-lg"><asp:ListItem Value="employee" Text="موظف"/><asp:ListItem Value="customer" Text="عميل"/></asp:DropDownList></div><div class="mb-3"><asp:Label runat="server" AssociatedControlID="txtUserName" CssClass="form-label" Text="اسم المستخدم"/><asp:TextBox ID="txtUserName" runat="server" CssClass="form-control" MaxLength="100" autocomplete="username"/></div><div class="mb-4"><asp:Label runat="server" AssociatedControlID="txtPassword" CssClass="form-label" Text="كلمة المرور"/><div class="input-group"><asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="current-password"/><button type="button" id="togglePwd" class="btn btn-outline-secondary" aria-label="إظهار كلمة المرور" aria-pressed="false"><i class="bx bx-hide"></i></button></div></div><asp:Button ID="btnLogin" runat="server" OnClick="btnLogin_Click" CssClass="btn btn-primary w-100" Text="تسجيل الدخول"/><div class="text-center mt-3"><a href="/ForgotPassword.aspx">نسيت كلمة المرور؟</a></div><p class="text-center text-muted small mt-4 mb-0">لإنشاء حساب عميل، تواصل مع مدير النظام.</p></div></div></div></div></form><script>document.getElementById('togglePwd').addEventListener('click',function(){var p=document.getElementById('<%=txtPassword.ClientID%>');var show=p.type==='password';p.type=show?'text':'password';this.setAttribute('aria-pressed',show);this.setAttribute('aria-label',show?'إخفاء كلمة المرور':'إظهار كلمة المرور');});</script></body></html>