<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="VacationsSchedule_Final.aspx.vb" Inherits="CRM.VacationsSchedule_Final" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Prosto ERP - توزيع الدوام الأسبوعي</title>

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <style>
    :root {
      --primary: #c41230;
      --primary-dark: #9f0e26;
      --primary-soft: #fff1f3;
      --blue: #5b8def;
      --blue-soft: #eef4ff;
      --body-bg: #f5f6fa;
      --card-bg: #ffffff;
      --text: #24334d;
      --muted: #6b7890;
      --border: #e4eaf4;
      --border-dark: #d8dee8;
      --cell-bg: #ffffff;
      --cell-hover: #f8fbff;
      --vacation: #ff9f43;
      --employee: #5b8def;
      --manager: #7367f0;
      --success: #28c76f;
      --danger: #ea5455;
      --shadow: 0 4px 22px rgba(67, 89, 113, .07);
      --radius: 12px;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      background:
        radial-gradient(circle at top right, rgba(196,18,48,.08), transparent 30%),
        radial-gradient(circle at top left, rgba(115,103,240,.07), transparent 26%),
        var(--body-bg);
      font-family: "Almarai", "Tahoma", "Arial", sans-serif;
      color: var(--text);
      min-height: 100vh;
    }

    .app-wrapper {
      padding: 24px 46px;
      max-width: 1800px;
      margin: 0 auto;
    }

    .page-hero {
      position: relative;
      overflow: hidden;
      border-radius: 14px;
      padding: 20px 24px;
      margin-bottom: 14px;
      background:
        linear-gradient(135deg, rgba(255,255,255,.94), rgba(255,255,255,.84)),
        radial-gradient(circle at 5% 20%, rgba(196,18,48,.12), transparent 34%);
      color: var(--text);
      border: 1px solid rgba(224,228,236,.85);
      box-shadow: var(--shadow);
    }

    .page-hero__content {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 18px;
      flex-wrap: wrap;
    }

    .page-title {
      margin: 0;
      font-size: 24px;
      line-height: 1.4;
      font-weight: 800;
      color: var(--text);
    }

    .page-subtitle {
      margin: 7px 0 0;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.8;
      max-width: 980px;
    }

    .hero-actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }

    .hero-btn {
      border: 1px solid #dbe7ff;
      background: var(--blue-soft);
      color: var(--blue);
      border-radius: 10px;
      padding: 9px 14px;
      font-size: 13px;
      font-weight: 800;
      display: inline-flex;
      align-items: center;
      gap: 7px;
      transition: .18s ease;
    }

    .hero-btn:hover {
      transform: translateY(-1px);
      color: var(--blue);
      background: #e6efff;
    }

    .hero-btn.primary {
      background: var(--blue);
      border-color: var(--blue);
      color: #fff;
      box-shadow: 0 6px 14px rgba(91,141,239,.22);
    }

    .toolbar-card {
      background: rgba(255,255,255,.92);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255,255,255,.85);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 14px;
      margin-bottom: 14px;
    }

    .form-label {
      font-size: 12px;
      color: #4b5563;
      font-weight: 800;
      margin-bottom: 7px;
    }

    .form-control,
    .form-select {
      border-radius: 10px;
      border-color: var(--border);
      min-height: 42px;
      font-size: 13px;
    }

    .form-control:focus,
    .form-select:focus {
      border-color: rgba(196,18,48,.45);
      box-shadow: 0 0 0 .2rem rgba(196,18,48,.08);
    }

    .panel {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      overflow: hidden;
    }

    .panel-header {
      padding: 14px 16px;
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
      background: #fff;
      flex-wrap: wrap;
    }

    .panel-title {
      margin: 0;
      font-size: 18px;
      line-height: 1.5;
      font-weight: 800;
      color: var(--text);
    }

    .panel-hint {
      margin-top: 3px;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.7;
    }

    .table-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .btn-soft,
    .btn-primary-prosto,
    .btn-success-prosto {
      border-radius: 9px;
      padding: 8px 12px;
      font-size: 12px;
      font-weight: 800;
      display: inline-flex;
      gap: 7px;
      align-items: center;
      transition: .18s ease;
      border: 1px solid transparent;
    }

    .btn-soft {
      border-color: var(--border);
      background: #fff;
      color: #4b5563;
    }

    .btn-soft:hover {
      background: #f8faff;
      color: #111827;
      transform: translateY(-1px);
    }

    .btn-primary-prosto {
      background: var(--primary);
      border-color: var(--primary);
      color: #fff;
    }

    .btn-primary-prosto:hover {
      background: var(--primary-dark);
      border-color: var(--primary-dark);
      color: #fff;
      transform: translateY(-1px);
    }

    .btn-success-prosto {
      background: var(--success);
      border-color: var(--success);
      color: #fff;
    }

    .btn-success-prosto:hover {
      background: #20a85d;
      color: #fff;
      transform: translateY(-1px);
    }

    .settings-days {
      border: 1px solid var(--border);
      background: #f8faff;
      border-radius: 12px;
      padding: 12px;
      margin-top: 14px;
    }

    .days-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .day-option {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 8px 11px;
      font-size: 12px;
      font-weight: 800;
      color: #4b5563;
      cursor: pointer;
      user-select: none;
    }

    .day-option input {
      accent-color: var(--primary);
    }

    .stats-row {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(5, minmax(0, 1fr));
      gap: 10px;
      padding: 12px;
      background: #f8faff;
      border-bottom: 1px solid var(--border);
    }

    .stat-card {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 12px 14px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 10px;
      box-shadow: 0 2px 8px rgba(67,89,113,.04);
    }

    .stat-label {
      font-size: 12px;
      line-height: 1.5;
      color: var(--muted);
      font-weight: 800;
    }

    .stat-value {
      margin-top: 2px;
      font-size: 22px;
      line-height: 1.2;
      color: #111827;
      font-weight: 800;
    }

    .stat-icon {
      width: 34px;
      height: 34px;
      border-radius: 9px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--blue-soft);
      color: var(--blue);
      font-size: 15px;
      flex: 0 0 auto;
    }

    /* Table without scroll */
    .schedule-wrap {
      padding: 8px;
      overflow: visible;
      max-height: none;
      background: #f8faff;
    }

    .schedule-table {
      width: 100%;
      min-width: 0;
      border-collapse: separate;
      border-spacing: 0;
      table-layout: fixed;
      direction: rtl;
      background: #fff;
      border-radius: 8px;
      overflow: hidden;
    }

    .schedule-table th,
    .schedule-table td {
      border-left: 1px solid var(--border-dark);
      border-bottom: 1px solid var(--border-dark);
      vertical-align: top;
    }

    .schedule-table thead th {
      text-align: center;
      font-weight: 800;
      padding: 8px 6px;
      position: sticky;
      top: 0;
      z-index: 5;
      font-size: 12px;
    }

    .day-head {
      width: 92px;
      min-width: 92px;
      max-width: 92px;
      background: #f8faff;
      color: #53657b;
      position: sticky !important;
      right: 0;
      z-index: 8 !important;
      border-right: 1px solid var(--border-dark);
    }

    .shift-head {
      color: #fff;
      height: 36px;
      font-size: 12px;
    }

    .head-vacation { background: #ff9f43; }
    .head-employee { background: #5b8def; }
    .head-manager { background: #7367f0; }

    .day-cell {
      width: 92px;
      background: #f8faff;
      color: #43546b;
      text-align: center;
      vertical-align: middle !important;
      font-weight: 800;
      font-size: 12px;
      padding: 6px;
      position: sticky;
      right: 0;
      z-index: 4;
      border-right: 1px solid var(--border-dark);
      box-shadow: -8px 0 14px rgba(30,41,59,.04);
    }

    .day-cell span {
      display: block;
      border-radius: 8px;
      background: var(--blue-soft);
      border: 1px solid #dbe7ff;
      color: var(--blue);
      padding: 7px 5px;
      font-weight: 800;
    }

    .assignment-cell {
      height: auto;
      min-height: 82px;
      padding: 7px;
      background: var(--cell-bg);
      cursor: pointer;
      transition: .16s ease;
    }

    .assignment-cell:hover {
      background: var(--cell-hover);
      box-shadow: inset 0 0 0 2px rgba(91,141,239,.14);
    }

    .assignment-cell.empty {
      position: relative;
    }

    .assignment-cell.empty::before {
      content: "+";
      position: absolute;
      inset: 50% auto auto 50%;
      transform: translate(-50%, -50%);
      width: 22px;
      height: 22px;
      border-radius: 50%;
      background: var(--blue-soft);
      color: var(--blue);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 15px;
      font-weight: 800;
      opacity: .0;
      transition: .16s ease;
    }

    .assignment-cell.empty:hover::before {
      opacity: 1;
    }

    .assignment-cell.drag-over {
      background: #eef4ff !important;
      box-shadow: inset 0 0 0 2px rgba(91,141,239,.35);
    }

    .assignment-cell.not-allowed {
      background: #fff1f3 !important;
      box-shadow: inset 0 0 0 2px rgba(234,84,85,.28);
    }

    .employee-chip {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 7px;
      border: 1px solid #dfe7f5;
      background: #f9fbff;
      border-right: 4px solid var(--primary);
      border-radius: 8px;
      padding: 6px 8px;
      margin-bottom: 6px;
      min-height: 28px;
      cursor: grab;
      user-select: none;
      animation: chipIn .18s ease;
    }

    .employee-chip:active {
      cursor: grabbing;
    }

    .employee-chip.vacation {
      border-right-color: var(--vacation);
      background: #fff8ed;
    }

    .employee-chip.employee {
      border-right-color: var(--employee);
      background: #f4f8ff;
    }

    .employee-chip.manager {
      border-right-color: var(--manager);
      background: #f6f4ff;
    }

    @keyframes chipIn {
      from { opacity: 0; transform: translateY(4px); }
      to { opacity: 1; transform: translateY(0); }
    }

    .chip-name {
      font-size: 10.5px;
      font-weight: 800;
      color: #334155;
      line-height: 1.45;
    }

    .chip-role {
      color: #6b7280;
      font-size: 9px;
      font-weight: 700;
      white-space: nowrap;
    }

    .table-footer {
      padding: 10px 14px;
      border-top: 1px solid var(--border);
      background: #f8faff;
      color: var(--muted);
      font-size: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }

    .legend {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
      align-items: center;
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-weight: 800;
      color: #5c6575;
      font-size: 11px;
    }

    .legend-dot {
      width: 9px;
      height: 9px;
      border-radius: 50%;
      display: inline-block;
    }

    .result-card {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 16px;
      margin-top: 14px;
      display: none;
    }

    .result-card.show {
      display: block;
    }

    .result-card h3 {
      margin: 0 0 12px;
      font-size: 16px;
      font-weight: 800;
    }

    .name-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }

    .name-pill {
      background: #f8faff;
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 8px 12px;
      font-size: 12px;
      font-weight: 800;
      color: #4b5563;
    }

    .prosto-modal {
      border: 0;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 12px 44px rgba(47,60,74,.22);
    }

    .prosto-modal-header {
      min-height: 82px;
      padding: 22px 28px 14px !important;
      background: #fff;
      border-bottom: 0;
      align-items: flex-start;
      position: relative;
    }

    .prosto-modal .modal-title {
      color: #4b5b6b;
      font-size: 22px;
      font-weight: 800;
      line-height: 1.3;
    }

    .modal-subtitle {
      color: #7a8899;
      font-size: 13px;
      margin-top: 8px;
      line-height: 1.7;
    }

    .modal-close-btn {
      position: absolute;
      top: 22px;
      left: 28px;
      width: 36px;
      height: 36px;
      border: 0;
      border-radius: 6px;
      background: #eef1f5;
      color: #8d98a7;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .employees-modal-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 10px;
    }

    .employee-mini-card {
      border: 1px solid #dfe5ee;
      background: #fff;
      border-radius: 6px;
      padding: 12px;
    }

    .employee-mini-name {
      font-size: 13px;
      font-weight: 800;
      color: #4b5b6b;
      margin-bottom: 5px;
    }

    .employee-mini-role {
      font-size: 12px;
      color: #7a8899;
    }

    .toast-prosto {
      position: fixed;
      bottom: 24px;
      left: 24px;
      background: #111827;
      color: #fff;
      padding: 12px 16px;
      border-radius: 10px;
      box-shadow: var(--shadow);
      font-size: 13px;
      opacity: 0;
      transform: translateY(10px);
      pointer-events: none;
      transition: .25s ease;
      z-index: 2000;
    }

    .toast-prosto.show {
      opacity: 1;
      transform: translateY(0);
    }

    .print-area {
      display: none;
    }

    @media (max-width: 1199px) {
      .stats-row {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .app-wrapper {
        padding: 18px;
      }
    }

    @media (max-width: 991px) {
      .app-wrapper {
        padding: 14px;
      }

      .employees-modal-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .schedule-table {
        font-size: 11px;
      }

      .assignment-cell {
        padding: 5px;
      }

      .employee-chip {
        flex-direction: column;
        align-items: flex-start;
        gap: 2px;
      }
    }

    @media (max-width: 575px) {
      .stats-row {
        grid-template-columns: 1fr;
      }

      .page-title {
        font-size: 20px;
      }

      .page-subtitle {
        font-size: 13px;
      }

      .employees-modal-grid {
        grid-template-columns: 1fr;
      }
    }

    @media print {
      @page {
        size: A4 landscape;
        margin: 12mm;
      }

      body {
        background: #fff !important;
      }

      body * {
        visibility: hidden !important;
      }

      .print-area,
      .print-area * {
        visibility: visible !important;
      }

      .print-area {
        display: block !important;
        position: absolute;
        inset: 0;
        width: 100%;
        background: #fff;
        color: #24334d;
        font-family: "Almarai", "Tahoma", "Arial", sans-serif;
      }

      .app-wrapper,
      .toast-prosto,
      .modal,
      .modal-backdrop {
        display: none !important;
      }

      .print-page {
        page-break-after: always;
        break-after: page;
        min-height: 180mm;
        padding: 0;
        background: #fff;
      }

      .print-page:last-child {
        page-break-after: auto;
        break-after: auto;
      }

      .print-header {
        margin-bottom: 12px;
        padding: 12px 14px;
        border: 1px solid #d8dee8;
        border-radius: 10px;
        background: #f8faff !important;
      }

      .print-header h2 {
        margin: 0;
        font-size: 20px;
        font-weight: 800;
        color: #24334d;
      }

      .print-header p {
        margin: 6px 0 0;
        font-size: 12px;
        color: #6b7890;
        line-height: 1.7;
      }

      .print-summary {
        margin-top: 10px;
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
      }

      .print-summary-item {
        border: 1px solid #d8dee8;
        background: #fff !important;
        border-radius: 8px;
        padding: 7px 10px;
        font-size: 11px;
        font-weight: 800;
        color: #4b5563;
      }

      .print-table,
      .print-table-rows {
        width: 100%;
        border-collapse: collapse;
        table-layout: fixed;
        direction: rtl;
        font-size: 11px;
      }

      .print-table-rows th {
        background: #24334d !important;
        color: #fff !important;
        border: 1px solid #d8dee8;
        padding: 10px 8px;
        font-size: 12px;
        text-align: center;
        font-weight: 800;
      }

      .print-table-rows td {
        border: 1px solid #d8dee8;
        padding: 10px;
        vertical-align: top;
        min-height: 55px;
      }

      .print-row-label {
        font-weight: 800;
        text-align: center;
        vertical-align: middle !important;
        color: #fff !important;
      }

      .vacation-label {
        background: #ff9f43 !important;
      }

      .employee-label {
        background: #5b8def !important;
      }

      .manager-label {
        background: #7367f0 !important;
      }

      .print-count-cell {
        text-align: center;
        vertical-align: middle !important;
        font-weight: 800;
        color: #24334d;
        background: #f8faff !important;
      }

      .print-chip {
        display: inline-block;
        border: 1px solid #dfe7f5;
        border-right: 4px solid #5b8def;
        border-radius: 7px;
        padding: 6px 8px;
        margin: 3px;
        background: #f9fbff !important;
        color: #334155;
        font-size: 10.5px;
        font-weight: 800;
        line-height: 1.5;
      }

      .print-chip.vacation {
        border-right-color: #ff9f43;
        background: #fff8ed !important;
      }

      .print-chip.manager {
        border-right-color: #7367f0;
        background: #f6f4ff !important;
      }

      .print-chip small {
        display: block;
        color: #6b7280;
        font-size: 9px;
        font-weight: 700;
        margin-top: 2px;
      }

      .print-names-list {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 8px;
      }

      .print-name-pill {
        border: 1px solid #d8dee8;
        background: #f8faff !important;
        border-radius: 8px;
        padding: 9px 10px;
        font-size: 12px;
        font-weight: 800;
        color: #334155;
      }
    }
  </style>
    <link rel="stylesheet" href="/assets/css/erp-theme.css?v=20260906" />
</head>

<body class="erp-ui">

<div class="app-wrapper">

  <section class="page-hero">
    <div class="page-hero__content">
      <div>
        <h1 class="page-title">توزيع جدول دوام الموظفين الأسبوعي</h1>
        <p class="page-subtitle">
          واجهة لتوزيع الموظفين والمدراء تلقائيًا حسب عدد الموظفين المطلوبين على رأس العمل، وعدد الإجازات اليومية، مع دعم السحب والإفلات بعد التوزيع.
        </p>
      </div>

      <div class="hero-actions">
        <button class="hero-btn" type="button" onclick="printWeeklySchedule()">
          <i class="bi bi-printer"></i>
          طباعة
        </button>

        <button class="hero-btn primary" type="button" onclick="saveSchedule()">
          <i class="bi bi-check2-circle"></i>
          حفظ الجدول
        </button>
      </div>
    </div>
  </section>

  <section class="toolbar-card">
    <div class="row g-3 align-items-end">
      <div class="col-xl-2 col-md-6">
        <label class="form-label">العلامة التجارية</label>
        <select class="form-select">
          <option>Prosto</option>
        </select>
      </div>

      <div class="col-xl-2 col-md-6">
        <label class="form-label">الفرع</label>
        <select class="form-select">
          <option>فرع مكة مول</option>
          <option>فرع عبدون</option>
          <option>فرع المدينة</option>
        </select>
      </div>

      <div class="col-xl-2 col-md-6">
        <label class="form-label">الأسبوع</label>
        <input type="week" class="form-control">
      </div>

      <div class="col-xl-2 col-md-6">
        <label class="form-label">عدد الموظفين على رأس عملهم يوميًا</label>
        <input type="number" id="dailyWorkingEmployees" class="form-control" min="1" value="10">
      </div>

      <div class="col-xl-2 col-md-6">
        <label class="form-label">إجازات الموظفين يوميًا</label>
        <input type="number" id="dailyVacationLimit" class="form-control" min="0" value="5">
      </div>

      <div class="col-xl-2 col-md-6">
        <label class="form-label">إجازات المدراء يوميًا</label>
        <input type="number" id="dailyManagerVacationLimit" class="form-control" min="0" max="1" value="1">
      </div>
    </div>

    <div class="settings-days">
      <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-2">
        <label class="form-label mb-0">أيام الأسبوع المسموح فيها بالتعطيل</label>

        <div class="d-flex gap-2 flex-wrap">
          <button class="btn-soft" type="button" onclick="openEmployeesModal()">
            <i class="bi bi-people"></i>
            عدد موظفين الفرع <span id="totalEmployeesLabel"></span>
          </button>

          <button class="btn-success-prosto" type="button" onclick="generateSchedule()">
            <i class="bi bi-shuffle"></i>
            توزيع الموظفين
          </button>
        </div>
      </div>

      <div class="days-list">
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الأحد" checked> الأحد</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الاثنين" checked> الاثنين</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الثلاثاء" checked> الثلاثاء</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الأربعاء" checked> الأربعاء</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الخميس" checked> الخميس</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="الجمعة"> الجمعة</label>
        <label class="day-option"><input type="checkbox" class="allowed-day" value="السبت"> السبت</label>
      </div>
    </div>
  </section>

  <main class="panel table-panel">
    <div class="panel-header">
      <div>
        <h2 class="panel-title">جدول التوزيع</h2>
        <div class="panel-hint">
          الجدول يبدأ فارغًا، وبعد التوزيع يمكنك نقل الموظفين والمدراء بين خانة العطلة والخانة المناسبة بالسحب والإفلات.
        </div>
      </div>

      <div class="table-actions">
        <button class="btn-soft" type="button" onclick="clearSchedule()">
          <i class="bi bi-arrow-counterclockwise"></i>
          تفريغ
        </button>

        <button class="btn-soft" type="button" onclick="showNoVacationEmployees()">
          <i class="bi bi-person-dash"></i>
          الغير مجازين
        </button>

        <button class="btn-soft" type="button" onclick="printWeeklySchedule()">
          <i class="bi bi-printer"></i>
          طباعة
        </button>

        <button class="btn-primary-prosto" type="button" onclick="saveSchedule()">
          <i class="bi bi-save"></i>
          حفظ
        </button>
      </div>
    </div>

    <div class="stats-row">
      <div class="stat-card">
        <div>
          <div class="stat-label">إجمالي الموظفين</div>
          <div class="stat-value" id="statTotalEmployees">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-people"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">عدد الموظفين العاملين</div>
          <div class="stat-value" id="statDailyWorking">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-person-check"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">إجازات الموظفين</div>
          <div class="stat-value" id="statEmployeeVacation">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-calendar-minus"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">إجازات المدراء</div>
          <div class="stat-value" id="statManagerVacation">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-person-badge"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">غير مجازين هذا الأسبوع</div>
          <div class="stat-value" id="statNoVacation">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-person-lines-fill"></i></div>
      </div>
    </div>

    <div class="schedule-wrap">
      <table class="schedule-table">
        <thead>
          <tr>
            <th class="day-head">اليوم</th>
            <th class="shift-head head-vacation">عطلة</th>
            <th class="shift-head head-employee">موظف فرع</th>
            <th class="shift-head head-manager">مدير شفت صباحي</th>
            <th class="shift-head head-manager">مدير شفت Between</th>
            <th class="shift-head head-manager">مدير شفت مسائي</th>
            <th class="shift-head head-manager">مدير فرع</th>
          </tr>
        </thead>

        <tbody id="scheduleBody"></tbody>
      </table>
    </div>

    <div class="table-footer">
      <div class="legend">
        <span class="legend-item"><span class="legend-dot" style="background:var(--vacation)"></span> عطلة</span>
        <span class="legend-item"><span class="legend-dot" style="background:var(--employee)"></span> موظف فرع</span>
        <span class="legend-item"><span class="legend-dot" style="background:var(--manager)"></span> المدراء</span>
      </div>
      <div>عند الطباعة سيتم طباعة كل يوم في صفحة منفصلة، وصفحة أخيرة للموظفين غير المجازين.</div>
    </div>
  </main>

  <section class="result-card" id="noVacationCard">
    <h3>موظفين لم تأخذ إجازة هذا الأسبوع</h3>
    <div class="name-list" id="noVacationList"></div>
  </section>

</div>

<div class="modal fade" id="employeesModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-xl">
    <div class="modal-content prosto-modal">
      <div class="modal-header prosto-modal-header">
        <div>
          <h5 class="modal-title">موظفين الفرع</h5>
          <div class="modal-subtitle">قائمة الموظفين والمدراء المستخدمة في توزيع الدوام الأسبوعي.</div>
        </div>
        <button type="button" class="modal-close-btn" data-bs-dismiss="modal" aria-label="Close">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>

      <div class="modal-body">
        <div class="employees-modal-grid" id="employeesModalList"></div>
      </div>
    </div>
  </div>
</div>

<div class="modal fade" id="noVacationModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg">
    <div class="modal-content prosto-modal">
      <div class="modal-header prosto-modal-header">
        <div>
          <h5 class="modal-title">الموظفين الغير مجازيين هذا الأسبوع</h5>
          <div class="modal-subtitle">قائمة بالأسماء التي لم يتم إدراجها في خانة عطلة خلال الأسبوع.</div>
        </div>
        <button type="button" class="modal-close-btn" data-bs-dismiss="modal" aria-label="Close">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>

      <div class="modal-body">
        <div class="name-list" id="noVacationModalList"></div>
      </div>
    </div>
  </div>
</div>

<div class="print-area" id="printArea">
  <div id="printDaysContainer"></div>

  <section class="print-page print-no-vacation-page">
    <div class="print-header">
      <h2>الموظفين الغير مجازيين هذا الأسبوع</h2>
      <p>قائمة الموظفين والمدراء الذين لم يتم إدراجهم في خانة عطلة خلال الأسبوع.</p>
    </div>

    <div class="print-names-list" id="printNoVacationList"></div>
  </section>
</div>

<div class="toast-prosto" id="toast"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    const days = [
        "الأحد",
        "الاثنين",
        "الثلاثاء",
        "الأربعاء",
        "الخميس",
        "الجمعة",
        "السبت"
    ];

    const employees = [
        { id: 1, name: "أبو احمد", role: "مدير فرع" },
        { id: 2, name: "فرحان", role: "مدير شفت صباحي" },
        { id: 3, name: "باسل خدام", role: "مدير شفت مسائي" },
        { id: 4, name: "حسام خدام", role: "مدير شفت Between" },
        { id: 5, name: "محمد حسن", role: "موظف" },
        { id: 6, name: "أحمد الخطيب", role: "موظف" },
        { id: 7, name: "يوسف العلي", role: "موظف" },
        { id: 8, name: "عمر الحسن", role: "موظف" },
        { id: 9, name: "خالد المصري", role: "موظف" },
        { id: 10, name: "محمود الزعبي", role: "موظف" },
        { id: 11, name: "أنس الرواشدة", role: "موظف" },
        { id: 12, name: "حمزة القضاة", role: "موظف" },
        { id: 13, name: "ليث النجار", role: "موظف" },
        { id: 14, name: "معاذ بني ياسين", role: "موظف" },
        { id: 15, name: "طارق الشوابكة", role: "موظف" },
        { id: 16, name: "سامر أبو زيد", role: "موظف" },
        { id: 17, name: "رامي الحوراني", role: "موظف" },
        { id: 18, name: "فراس العجارمة", role: "موظف" },
        { id: 19, name: "بلال الكيلاني", role: "موظف" },
        { id: 20, name: "يزن العبادي", role: "موظف" },
        { id: 21, name: "علاء السرحان", role: "موظف" },
        { id: 22, name: "هيثم الجبور", role: "موظف" },
        { id: 23, name: "قصي المومني", role: "موظف" },
        { id: 24, name: "إياد الطراونة", role: "موظف" },
        { id: 25, name: "سيف المعايطة", role: "موظف" },
        { id: 26, name: "مالك الخصاونة", role: "موظف" },
        { id: 27, name: "نادر العتوم", role: "موظف" },
        { id: 28, name: "باسل الحمود", role: "موظف" },
        { id: 29, name: "زيد العمري", role: "موظف" },
        { id: 30, name: "منتصر الشريدة", role: "موظف" },
        { id: 31, name: "يحيى أبو غزالة", role: "موظف" },
        { id: 32, name: "عبد الرحمن مراد", role: "موظف" },
        { id: 33, name: "عدي السقا", role: "موظف" },
        { id: 34, name: "فادي حداد", role: "موظف" },
        { id: 35, name: "مازن سلامة", role: "موظف" },
        { id: 36, name: "حازم عيسى", role: "موظف" },
        { id: 37, name: "رائد نصار", role: "موظف" },
        { id: 38, name: "براء أبو رمان", role: "موظف" },
        { id: 39, name: "كرم العواملة", role: "موظف" }
    ];

    let lastScheduleData = [];
    let vacationEmployeeIds = new Set();
    let draggedScheduleChip = null;

    const employeesModal = new bootstrap.Modal(document.getElementById("employeesModal"));
    const noVacationModal = new bootstrap.Modal(document.getElementById("noVacationModal"));

    document.addEventListener("DOMContentLoaded", function () {
        document.getElementById("totalEmployeesLabel").textContent = `(${employees.length})`;
        renderEmptySchedule();
        renderEmployeesModal();
        updateStats();
    });

    function renderEmptySchedule() {
        const scheduleBody = document.getElementById("scheduleBody");
        scheduleBody.innerHTML = "";

        days.forEach(day => {
            scheduleBody.innerHTML += `
        <tr>
          <td class="day-cell"><span>${day}</span></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="عطلة"></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="موظف فرع"></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="مدير شفت صباحي"></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="مدير شفت Between"></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="مدير شفت مسائي"></td>
          <td class="assignment-cell empty" data-day="${day}" data-shift="مدير فرع"></td>
        </tr>
      `;
        });

        activateTableDragAndDrop();
    }

    function generateSchedule() {
        clearSchedule(false);

        const dailyWorkingCount = parseInt(document.getElementById("dailyWorkingEmployees").value, 10);
        const dailyEmployeeVacationLimit = parseInt(document.getElementById("dailyVacationLimit").value, 10);
        const dailyManagerVacationLimit = parseInt(document.getElementById("dailyManagerVacationLimit").value, 10);
        const allowedVacationDays = getAllowedVacationDays();

        const branchEmployees = employees.filter(e => e.role === "موظف");
        const managers = employees.filter(e => e.role !== "موظف");

        if (!dailyWorkingCount || dailyWorkingCount <= 0) {
            showToast("يرجى إدخال عدد الموظفين على رأس عملهم يوميًا.");
            return;
        }

        if (dailyWorkingCount > branchEmployees.length) {
            showToast("عدد الموظفين على رأس عملهم أكبر من عدد الموظفين المتاحين.");
            return;
        }

        if (isNaN(dailyEmployeeVacationLimit) || dailyEmployeeVacationLimit < 0) {
            showToast("يرجى إدخال عدد صحيح لإجازات الموظفين يوميًا.");
            return;
        }

        if (isNaN(dailyManagerVacationLimit) || dailyManagerVacationLimit < 0) {
            showToast("يرجى إدخال عدد صحيح لإجازات المدراء يوميًا.");
            return;
        }

        if (dailyManagerVacationLimit > 1) {
            showToast("لا يمكن تعطيل أكثر من مدير واحد في نفس اليوم.");
            return;
        }

        if (allowedVacationDays.length === 0 && (dailyEmployeeVacationLimit > 0 || dailyManagerVacationLimit > 0)) {
            showToast("يرجى تحديد أيام الأسبوع المسموح فيها بالتعطيل.");
            return;
        }

        vacationEmployeeIds = new Set();
        lastScheduleData = [];

        const employeeVacationIds = new Set();
        const managerVacationIds = new Set();

        days.forEach(day => {
            const isVacationAllowedToday = allowedVacationDays.includes(day);

            let todayVacationEmployees = [];
            let todayVacationManagers = [];

            if (isVacationAllowedToday) {
                const availableEmployeesForVacation = branchEmployees.filter(e => !employeeVacationIds.has(e.id));

                const maxEmployeeVacationToday = Math.min(
                    dailyEmployeeVacationLimit,
                    Math.max(branchEmployees.length - dailyWorkingCount, 0),
                    availableEmployeesForVacation.length
                );

                todayVacationEmployees = getRandomItems(availableEmployeesForVacation, maxEmployeeVacationToday);

                todayVacationEmployees.forEach(employee => {
                    employeeVacationIds.add(employee.id);
                    vacationEmployeeIds.add(employee.id);
                });

                const availableManagersForVacation = managers.filter(m => !managerVacationIds.has(m.id));

                const maxManagerVacationToday = Math.min(
                    dailyManagerVacationLimit,
                    1,
                    availableManagersForVacation.length
                );

                todayVacationManagers = getRandomItems(availableManagersForVacation, maxManagerVacationToday);

                todayVacationManagers.forEach(manager => {
                    managerVacationIds.add(manager.id);
                    vacationEmployeeIds.add(manager.id);
                });
            }

            const todayVacationEmployeeIds = new Set(todayVacationEmployees.map(e => e.id));
            const todayVacationManagerIds = new Set(todayVacationManagers.map(e => e.id));

            const availableForWork = branchEmployees.filter(e => !todayVacationEmployeeIds.has(e.id));
            const todayWorkingEmployees = getRandomItems(availableForWork, dailyWorkingCount);

            todayWorkingEmployees.forEach(employee => {
                addEmployeeToCell(day, "موظف فرع", employee, "employee");
            });

            todayVacationEmployees.forEach(employee => {
                addEmployeeToCell(day, "عطلة", employee, "vacation");
            });

            todayVacationManagers.forEach(manager => {
                addEmployeeToCell(day, "عطلة", manager, "vacation");
            });

            managers.forEach(manager => {
                if (todayVacationManagerIds.has(manager.id)) return;
                addEmployeeToCell(day, manager.role, manager, "manager");
            });
        });

        rebuildScheduleDataFromTable();
        showNoVacationEmployees(false);
        updateStats();

        showToast("تم توزيع الموظفين والمدراء بنجاح.");
    }

    function addEmployeeToCell(day, shift, employee, chipType) {
        const zone = document.querySelector(`.assignment-cell[data-day="${day}"][data-shift="${shift}"]`);

        if (!zone) return;

        zone.classList.remove("empty");

        const chip = document.createElement("div");
        chip.className = `employee-chip ${chipType}`;
        chip.draggable = true;

        chip.dataset.employeeId = employee.id;
        chip.dataset.employeeName = employee.name;
        chip.dataset.employeeRole = employee.role;

        chip.innerHTML = `
      <span class="chip-name">${employee.name}</span>
      <small class="chip-role">${employee.role}</small>
    `;

        chip.addEventListener("dragstart", function (e) {
            draggedScheduleChip = this;

            e.dataTransfer.setData("text/plain", JSON.stringify({
                id: this.dataset.employeeId,
                name: this.dataset.employeeName,
                role: this.dataset.employeeRole
            }));
        });

        chip.addEventListener("dragend", function () {
            draggedScheduleChip = null;
        });

        zone.appendChild(chip);
    }

    function activateTableDragAndDrop() {
        const cells = document.querySelectorAll(".assignment-cell");

        cells.forEach(cell => {
            cell.ondragover = function (e) {
                e.preventDefault();

                if (!draggedScheduleChip) return;

                const employeeRole = draggedScheduleChip.dataset.employeeRole;
                const targetShift = this.dataset.shift;

                if (canMoveToShift(employeeRole, targetShift, this)) {
                    this.classList.add("drag-over");
                    this.classList.remove("not-allowed");
                } else {
                    this.classList.add("not-allowed");
                    this.classList.remove("drag-over");
                }
            };

            cell.ondragleave = function () {
                this.classList.remove("drag-over", "not-allowed");
            };

            cell.ondrop = function (e) {
                e.preventDefault();

                this.classList.remove("drag-over", "not-allowed");

                if (!draggedScheduleChip) return;

                const employeeRole = draggedScheduleChip.dataset.employeeRole;
                const targetShift = this.dataset.shift;

                if (!canMoveToShift(employeeRole, targetShift, this)) {
                    showToast("لا يمكن نقل هذا الموظف إلى هذه الخانة.");
                    return;
                }

                const oldCell = draggedScheduleChip.closest(".assignment-cell");

                this.appendChild(draggedScheduleChip);

                updateCellEmptyStatus(oldCell);
                updateCellEmptyStatus(this);
                rebuildScheduleDataFromTable();
                showNoVacationEmployees(false);
                updateStats();

                showToast("تم نقل الموظف بنجاح.");
            };
        });
    }

    function canMoveToShift(employeeRole, targetShift, targetCell) {
        const targetDay = targetCell.dataset.day;

        if (targetShift === "عطلة") {
            return canMoveToVacation(employeeRole, targetDay, targetCell);
        }

        if (employeeRole === "موظف" && targetShift === "موظف فرع") {
            return true;
        }

        if (employeeRole !== "موظف" && employeeRole === targetShift) {
            return true;
        }

        return false;
    }

    function canMoveToVacation(employeeRole, targetDay, targetCell) {
        const allowedVacationDays = getAllowedVacationDays();

        if (!allowedVacationDays.includes(targetDay)) {
            return false;
        }

        const employeeId = draggedScheduleChip.dataset.employeeId;

        const alreadyHasVacationThisWeek = Array.from(
            document.querySelectorAll(`.assignment-cell[data-shift="عطلة"] .employee-chip[data-employee-id="${employeeId}"]`)
        ).some(chip => chip !== draggedScheduleChip);

        if (alreadyHasVacationThisWeek) {
            return false;
        }

        if (employeeRole === "موظف") {
            const employeeVacationLimit = parseInt(document.getElementById("dailyVacationLimit").value, 10);

            const employeesInVacationToday = Array.from(targetCell.querySelectorAll(".employee-chip"))
                .filter(chip => chip.dataset.employeeRole === "موظف" && chip !== draggedScheduleChip);

            if (employeesInVacationToday.length >= employeeVacationLimit) {
                return false;
            }
        }

        if (employeeRole !== "موظف") {
            const managerVacationLimit = parseInt(document.getElementById("dailyManagerVacationLimit").value, 10);

            const managersInVacationToday = Array.from(targetCell.querySelectorAll(".employee-chip"))
                .filter(chip => chip.dataset.employeeRole !== "موظف" && chip !== draggedScheduleChip);

            if (managersInVacationToday.length >= managerVacationLimit) {
                return false;
            }

            if (managerVacationLimit > 1) {
                return false;
            }
        }

        return true;
    }

    function updateCellEmptyStatus(cell) {
        if (!cell) return;

        const hasEmployees = cell.querySelectorAll(".employee-chip").length > 0;
        cell.classList.toggle("empty", !hasEmployees);
    }

    function rebuildScheduleDataFromTable() {
        lastScheduleData = [];
        vacationEmployeeIds = new Set();

        document.querySelectorAll(".assignment-cell").forEach(cell => {
            const day = cell.dataset.day;
            const shift = cell.dataset.shift;

            cell.querySelectorAll(".employee-chip").forEach(chip => {
                const status = shift === "عطلة" ? "Vacation" : "Working";

                if (status === "Vacation") {
                    vacationEmployeeIds.add(parseInt(chip.dataset.employeeId, 10));
                }

                lastScheduleData.push({
                    employeeId: parseInt(chip.dataset.employeeId, 10),
                    employeeName: chip.dataset.employeeName,
                    employeeRole: chip.dataset.employeeRole,
                    day: day,
                    shift: shift,
                    status: status
                });
            });
        });
    }

    function getAllowedVacationDays() {
        return Array.from(document.querySelectorAll(".allowed-day:checked")).map(input => input.value);
    }

    function getRandomItems(array, count) {
        const copiedArray = [...array];

        for (let i = copiedArray.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [copiedArray[i], copiedArray[j]] = [copiedArray[j], copiedArray[i]];
        }

        return copiedArray.slice(0, count);
    }

    function clearSchedule(showMessage = true) {
        renderEmptySchedule();

        lastScheduleData = [];
        vacationEmployeeIds = new Set();

        document.getElementById("noVacationCard").classList.remove("show");
        document.getElementById("noVacationList").innerHTML = "";

        updateStats();

        if (showMessage) {
            showToast("تم تفريغ جدول الدوام.");
        }
    }

    function showNoVacationEmployees(openModal = true) {
        rebuildScheduleDataFromTable();

        const notVacationEmployees = employees.filter(e => !vacationEmployeeIds.has(e.id));

        const card = document.getElementById("noVacationCard");
        const list = document.getElementById("noVacationList");
        const modalList = document.getElementById("noVacationModalList");

        list.innerHTML = "";
        modalList.innerHTML = "";

        if (notVacationEmployees.length === 0) {
            list.innerHTML = `<span class="name-pill">جميع الموظفين حصلوا على إجازة خلال الأسبوع</span>`;
            modalList.innerHTML = `<span class="name-pill">جميع الموظفين حصلوا على إجازة خلال الأسبوع</span>`;
        } else {
            notVacationEmployees.forEach(employee => {
                list.innerHTML += `<span class="name-pill">${employee.name}</span>`;
                modalList.innerHTML += `<span class="name-pill">${employee.name}</span>`;
            });
        }

        card.classList.add("show");

        if (openModal) {
            noVacationModal.show();
        }

        updateStats();
    }

    function openEmployeesModal() {
        employeesModal.show();
    }

    function renderEmployeesModal() {
        const container = document.getElementById("employeesModalList");
        container.innerHTML = "";

        employees.forEach(employee => {
            container.innerHTML += `
        <div class="employee-mini-card">
          <div class="employee-mini-name">${employee.name}</div>
          <div class="employee-mini-role">${employee.role}</div>
        </div>
      `;
        });
    }

    function saveSchedule() {
        rebuildScheduleDataFromTable();

        if (lastScheduleData.length === 0) {
            showToast("لا يوجد توزيع لحفظه.");
            return;
        }

        console.log("Schedule Data:", lastScheduleData);
        showToast("تم تجهيز بيانات التوزيع. يمكن ربطها لاحقًا مع قاعدة البيانات.");
    }

    function updateStats() {
        const dailyWorking = document.getElementById("dailyWorkingEmployees").value || 0;
        const employeeVacation = document.getElementById("dailyVacationLimit").value || 0;
        const managerVacation = document.getElementById("dailyManagerVacationLimit").value || 0;

        rebuildScheduleDataFromTable();

        const notVacationCount = employees.filter(e => !vacationEmployeeIds.has(e.id)).length;

        document.getElementById("statTotalEmployees").textContent = employees.length;
        document.getElementById("statDailyWorking").textContent = dailyWorking;
        document.getElementById("statEmployeeVacation").textContent = employeeVacation;
        document.getElementById("statManagerVacation").textContent = managerVacation;
        document.getElementById("statNoVacation").textContent = notVacationCount;
    }

    function printWeeklySchedule() {
        rebuildScheduleDataFromTable();
        buildPrintPages();
        window.print();
    }

    function buildPrintPages() {
        const printDaysContainer = document.getElementById("printDaysContainer");
        const printNoVacationList = document.getElementById("printNoVacationList");

        printDaysContainer.innerHTML = "";
        printNoVacationList.innerHTML = "";

        days.forEach(day => {
            const dayPage = document.createElement("section");
            dayPage.className = "print-page";

            const dayData = getPrintDayData(day);

            dayPage.innerHTML = `
        <div class="print-header">
          <h2>جدول دوام يوم ${day}</h2>
          <p>توزيع الموظفين والمدراء حسب الخانات المعتمدة لهذا اليوم.</p>

          <div class="print-summary">
            <span class="print-summary-item">عدد موظفين الفرع: ${dayData.employeeCount}</span>
            <span class="print-summary-item">عدد الإجازات: ${dayData.vacationCount}</span>
            <span class="print-summary-item">عدد المدراء العاملين: ${dayData.managerCount}</span>
          </div>
        </div>

        <table class="print-table print-table-rows">
          <thead>
            <tr>
              <th style="width: 22%;">الخانة</th>
              <th>الأسماء</th>
              <th style="width: 12%;">العدد</th>
            </tr>
          </thead>

          <tbody>
            <tr>
              <td class="print-row-label vacation-label">عطلة</td>
              <td>${getPrintCellContent(day, "عطلة")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "عطلة")}</td>
            </tr>

            <tr>
              <td class="print-row-label employee-label">موظف فرع</td>
              <td>${getPrintCellContent(day, "موظف فرع")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "موظف فرع")}</td>
            </tr>

            <tr>
              <td class="print-row-label manager-label">مدير شفت صباحي</td>
              <td>${getPrintCellContent(day, "مدير شفت صباحي")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "مدير شفت صباحي")}</td>
            </tr>

            <tr>
              <td class="print-row-label manager-label">مدير شفت Between</td>
              <td>${getPrintCellContent(day, "مدير شفت Between")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "مدير شفت Between")}</td>
            </tr>

            <tr>
              <td class="print-row-label manager-label">مدير شفت مسائي</td>
              <td>${getPrintCellContent(day, "مدير شفت مسائي")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "مدير شفت مسائي")}</td>
            </tr>

            <tr>
              <td class="print-row-label manager-label">مدير فرع</td>
              <td>${getPrintCellContent(day, "مدير فرع")}</td>
              <td class="print-count-cell">${getPrintCellCount(day, "مدير فرع")}</td>
            </tr>
          </tbody>
        </table>
      `;

            printDaysContainer.appendChild(dayPage);
        });

        const notVacationEmployees = employees.filter(e => !vacationEmployeeIds.has(e.id));

        if (notVacationEmployees.length === 0) {
            printNoVacationList.innerHTML = `
        <div class="print-name-pill">جميع الموظفين حصلوا على إجازة خلال الأسبوع</div>
      `;
        } else {
            notVacationEmployees.forEach(employee => {
                printNoVacationList.innerHTML += `
          <div class="print-name-pill">${employee.name}</div>
        `;
            });
        }
    }

    function getPrintCellContent(day, shift) {
        const cell = document.querySelector(
            `.assignment-cell[data-day="${CSS.escape(day)}"][data-shift="${CSS.escape(shift)}"]`
        );

        if (!cell) return "";

        const chips = Array.from(cell.querySelectorAll(".employee-chip"));

        if (chips.length === 0) {
            return `<span style="color:#9ca3af;font-weight:700;">فارغ</span>`;
        }

        return chips.map(chip => {
            let typeClass = "";

            if (shift === "عطلة") {
                typeClass = "vacation";
            } else if (chip.dataset.employeeRole !== "موظف") {
                typeClass = "manager";
            }

            return `
        <span class="print-chip ${typeClass}">
          ${chip.dataset.employeeName}
        </span>
      `;
        }).join("");
    }

    function getPrintCellCount(day, shift) {
        const cell = document.querySelector(
            `.assignment-cell[data-day="${CSS.escape(day)}"][data-shift="${CSS.escape(shift)}"]`
        );

        if (!cell) return 0;

        return cell.querySelectorAll(".employee-chip").length;
    }

    function getPrintDayData(day) {
        const dayChips = Array.from(document.querySelectorAll(`.assignment-cell[data-day="${CSS.escape(day)}"] .employee-chip`));

        const employeeCount = dayChips.filter(chip => {
            const parentCell = chip.closest(".assignment-cell");
            return chip.dataset.employeeRole === "موظف" && parentCell.dataset.shift === "موظف فرع";
        }).length;

        const vacationCount = dayChips.filter(chip => {
            const parentCell = chip.closest(".assignment-cell");
            return parentCell.dataset.shift === "عطلة";
        }).length;

        const managerCount = dayChips.filter(chip => {
            const parentCell = chip.closest(".assignment-cell");
            return chip.dataset.employeeRole !== "موظف" && parentCell.dataset.shift !== "عطلة";
        }).length;

        return {
            employeeCount,
            vacationCount,
            managerCount
        };
    }

    document.getElementById("dailyWorkingEmployees").addEventListener("input", updateStats);
    document.getElementById("dailyVacationLimit").addEventListener("input", updateStats);
    document.getElementById("dailyManagerVacationLimit").addEventListener("input", updateStats);

    function showToast(message) {
        const toast = document.getElementById("toast");
        toast.textContent = message;
        toast.classList.add("show");

        setTimeout(() => {
            toast.classList.remove("show");
        }, 2800);
    }
</script>

</body>
</html>