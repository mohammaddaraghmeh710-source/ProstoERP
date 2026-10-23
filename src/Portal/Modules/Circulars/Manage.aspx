<%@ Page Title="إدارة التعاميم" Language="VB" AutoEventWireup="false" MasterPageFile="~/Site.Master" CodeBehind="Manage.aspx.vb" Inherits="CRM.CircularsManage" %>
<%@ Register TagPrefix="uc" TagName="CircularManagement" Src="~/Controls/CircularManagement.ascx" %>
<asp:Content ID="Head" runat="server" ContentPlaceHolderID="HeadContent"><link rel="stylesheet" href="/assets/vendor/fonts/fontawesome.css"/><link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css"/><link rel="stylesheet" href="/assets/css/crm.css?v=20260913c"/><link rel="stylesheet" href="/assets/css/crm-list.css?v=20261017c"/></asp:Content>
<asp:Content ID="Main" runat="server" ContentPlaceHolderID="ContentPlaceHolder1"><uc:CircularManagement ID="manager" runat="server"/></asp:Content>
