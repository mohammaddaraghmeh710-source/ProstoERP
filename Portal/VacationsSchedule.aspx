<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="VacationsSchedule.aspx.vb" Inherits="CRM.VacationsSchedule" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Prosto ERP - جدول الإجازات الأسبوعي</title>

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <style>
    :root{
      --primary:#c41230;
      --primary-dark:#9f0e26;
      --primary-soft:#fff1f3;
      --blue:#5b8def;
      --blue-soft:#eef4ff;
      --green:#28c76f;
      --green-soft:#edfdf5;
      --orange:#ff9f43;
      --orange-soft:#fff5e8;
      --purple:#7367f0;
      --purple-soft:#f2f0ff;
      --body-bg:#f5f6fa;
      --card:#fff;
      --text:#24334d;
      --muted:#6b7890;
      --border:#dfe5ee;
      --border-soft:#e8edf5;
      --shadow:0 4px 22px rgba(67,89,113,.07);
      --radius:14px;
    }

    *{box-sizing:border-box;}

    body{
      margin:0;
      min-height:100vh;
      background:
        radial-gradient(circle at top right, rgba(196,18,48,.055), transparent 30%),
        radial-gradient(circle at top left, rgba(91,141,239,.08), transparent 27%),
        var(--body-bg);
      font-family:"Almarai","Tahoma","Arial",sans-serif;
      color:var(--text);
    }

    .app-wrapper{
      width:100%;
      max-width:1880px;
      margin:0 auto;
      padding:24px 46px;
    }

    .page-hero{
      background:
        linear-gradient(135deg, rgba(255,255,255,.96), rgba(255,255,255,.86)),
        radial-gradient(circle at 5% 20%, rgba(196,18,48,.12), transparent 34%);
      border:1px solid rgba(224,228,236,.9);
      border-radius:var(--radius);
      padding:20px 24px;
      margin-bottom:14px;
      box-shadow:var(--shadow);
    }

    .page-hero__content{
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:18px;
      flex-wrap:wrap;
    }

    .page-title{
      margin:0;
      font-size:24px;
      font-weight:800;
      line-height:1.4;
      color:#24334d;
    }

    .page-subtitle{
      max-width:1060px;
      margin:6px 0 0;
      font-size:14px;
      line-height:1.8;
      color:var(--muted);
    }

    .hero-actions{
      display:flex;
      gap:10px;
      flex-wrap:wrap;
    }

    .hero-btn{
      min-height:40px;
      border:1px solid #dbe7ff;
      background:var(--blue-soft);
      color:#4f7df3;
      border-radius:11px;
      padding:9px 14px;
      font-size:13px;
      font-weight:800;
      display:inline-flex;
      align-items:center;
      gap:7px;
      transition:.18s ease;
    }

    .hero-btn:hover{
      background:#e7f0ff;
      color:#376fe0;
      transform:translateY(-1px);
    }

    .hero-btn.primary{
      background:var(--blue);
      border-color:var(--blue);
      color:#fff;
      box-shadow:0 6px 14px rgba(91,141,239,.22);
    }

    .toolbar-card,
    .stats-row,
    .department-card{
      background:rgba(255,255,255,.92);
      border:1px solid rgba(224,228,236,.92);
      border-radius:var(--radius);
      box-shadow:var(--shadow);
    }

    .toolbar-card{
      padding:14px;
      margin-bottom:14px;
    }

    .form-label{
      margin-bottom:7px;
      color:#4b5563;
      font-size:12px;
      font-weight:800;
    }

    .form-control,
    .form-select{
      min-height:40px;
      border-radius:11px;
      border-color:var(--border);
      font-size:13px;
    }

    .form-control:focus,
    .form-select:focus{
      border-color:rgba(91,141,239,.55);
      box-shadow:0 0 0 .2rem rgba(91,141,239,.10);
    }

    .stats-row{
      display:grid;
      grid-template-columns:repeat(4, minmax(0,1fr));
      gap:10px;
      padding:12px;
      margin-bottom:14px;
    }

    .stat-card{
      width:100%;
      padding:12px 14px;
      background:#fff;
      border:1px solid var(--border-soft);
      border-radius:12px;
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:10px;
      box-shadow:0 2px 8px rgba(67,89,113,.04);
    }

    .stat-label{
      color:#6b7890;
      font-size:12px;
      line-height:1.5;
      font-weight:800;
    }

    .stat-value{
      margin-top:2px;
      color:#111827;
      font-size:22px;
      line-height:1.2;
      font-weight:800;
    }

    .stat-icon{
      width:36px;
      height:36px;
      border-radius:10px;
      display:flex;
      align-items:center;
      justify-content:center;
      background:var(--blue-soft);
      color:var(--blue);
      font-size:16px;
      flex:0 0 auto;
    }

    .departments-wrapper{
      display:grid;
      grid-template-columns:1fr;
      gap:14px;
    }

    .department-card{
      overflow:hidden;
    }

    .department-card.is-filtered-out{
      display:none;
    }

    .department-header{
      padding:14px 16px;
      border-bottom:1px solid var(--border-soft);
      background:#fff;
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:14px;
      flex-wrap:wrap;
    }

    .department-title-wrap{
      display:flex;
      align-items:center;
      gap:10px;
    }

    .department-icon{
      width:42px;
      height:42px;
      border-radius:12px;
      display:flex;
      align-items:center;
      justify-content:center;
      color:#fff;
      font-size:18px;
      flex:0 0 auto;
    }

    .department-icon.kitchen{background:var(--orange);}
    .department-icon.front{background:var(--green);}
    .department-icon.hall{background:var(--blue);}
    .department-icon.admin{background:var(--purple);}

    .department-name{
      margin:0;
      color:#24334d;
      font-size:18px;
      font-weight:800;
      line-height:1.4;
    }

    .department-brief{
      margin-top:3px;
      color:#6b7890;
      font-size:12px;
      font-weight:700;
    }

    .department-actions{
      display:flex;
      align-items:center;
      gap:8px;
      flex-wrap:wrap;
    }

    .dept-pill{
      min-height:32px;
      display:inline-flex;
      align-items:center;
      gap:6px;
      padding:6px 10px;
      border-radius:999px;
      background:#f8faff;
      border:1px solid #e4eaf4;
      color:#53657b;
      font-size:12px;
      font-weight:800;
    }

    .dept-pill strong{
      color:#24334d;
    }

    .week-grid{
      padding:14px;
      background:#fbfcff;
      display:grid;
      grid-template-columns:repeat(7, minmax(0, 1fr));
      gap:10px;
    }

    .day-card{
      min-height:142px;
      border:1px solid var(--border-soft);
      border-radius:14px;
      background:#fff;
      padding:10px;
      display:flex;
      flex-direction:column;
      transition:.18s ease;
      position:relative;
    }

    .day-card:hover{
      border-color:#cbd8ee;
      box-shadow:0 8px 18px rgba(67,89,113,.08);
      transform:translateY(-1px);
    }

    .day-card.has-employee{
      border-color:#b8d1ff;
      background:linear-gradient(180deg,#f7fbff,#ffffff);
    }

    .day-card.has-employee::before{
      content:"";
      position:absolute;
      top:0;
      right:0;
      left:0;
      height:4px;
      border-radius:14px 14px 0 0;
      background:var(--blue);
    }

    .day-title{
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:8px;
      padding-bottom:8px;
      margin-bottom:8px;
      border-bottom:1px solid #eef2f7;
    }

    .day-name{
      color:#24334d;
      font-size:14px;
      font-weight:800;
    }

    .day-status{
      min-width:24px;
      height:24px;
      border-radius:8px;
      display:flex;
      align-items:center;
      justify-content:center;
      background:#f2f5fa;
      color:#8a96a8;
      font-size:12px;
      flex:0 0 auto;
    }

    .day-card.has-employee .day-status{
      background:var(--blue-soft);
      color:#376fe0;
    }

    .selected-employee{
      flex:1;
      display:flex;
      align-items:center;
      justify-content:center;
      text-align:center;
      color:#8a96a8;
      font-size:12px;
      font-weight:800;
      line-height:1.7;
      padding:6px 0;
    }

    .day-card.has-employee .selected-employee{
      color:#24334d;
      font-size:14px;
    }

    .employee-sub{
      display:block;
      margin-top:3px;
      color:#7a8798;
      font-size:11px;
      font-weight:700;
    }

    .day-actions{
      display:grid;
      grid-template-columns:1fr;
      gap:6px;
      margin-top:8px;
    }

    .select-btn,
    .clear-btn{
      min-height:32px;
      border-radius:9px;
      font-size:12px;
      font-weight:800;
      display:flex;
      align-items:center;
      justify-content:center;
      gap:6px;
      transition:.16s ease;
    }

    .select-btn{
      border:1px solid #dbe7ff;
      background:var(--blue-soft);
      color:#376fe0;
    }

    .select-btn:hover{
      background:#e3edff;
      transform:translateY(-1px);
    }

    .clear-btn{
      display:none;
      border:1px solid #ffd9df;
      background:#fff7f8;
      color:var(--primary);
    }

    .day-card.has-employee .clear-btn{
      display:flex;
    }

    .modal-content{
      border:0;
      border-radius:18px;
      overflow:hidden;
      box-shadow:0 18px 50px rgba(30,41,59,.18);
    }

    .modal-header{
      padding:20px 22px 14px;
      border-bottom:0;
      background:#fff;
      position:relative;
    }

    .modal-title{
      margin:0;
      color:#4b5b6b;
      font-size:22px;
      font-weight:800;
      line-height:1.3;
    }

    .modal-subtitle{
      margin-top:8px;
      color:#7a8899;
      font-size:13px;
      line-height:1.7;
    }

    .modal-close-btn{
      position:absolute;
      top:20px;
      left:22px;
      width:36px;
      height:36px;
      border:0;
      border-radius:6px;
      background:#eef1f5;
      color:#8d98a7;
      display:flex;
      align-items:center;
      justify-content:center;
      font-size:17px;
    }

    .modal-close-btn:hover{
      background:#e3e7ed;
      color:#526273;
    }

    .modal-body{
      padding:8px 22px 22px;
    }

    .modal-footer{
      padding:18px 22px 24px;
      border-top:0;
      justify-content:flex-start;
      gap:8px;
    }

    .context-row{
      display:grid;
      grid-template-columns:repeat(3, minmax(0,1fr));
      gap:12px;
      margin-bottom:16px;
    }

    .context-field label{
      display:block;
      margin-bottom:7px;
      color:#6f7f92;
      font-size:12px;
      font-weight:800;
    }

    .context-field div{
      min-height:42px;
      display:flex;
      align-items:center;
      justify-content:flex-end;
      padding:9px 12px;
      border:1px solid #d8dee8;
      border-radius:6px;
      background:#fff;
      color:#4b5b6b;
      font-size:14px;
      font-weight:800;
    }

    .employee-picker{
      border:1px solid #d8dee8;
      border-radius:8px;
      overflow:hidden;
      background:#fff;
    }

    .employee-picker-toolbar{
      padding:14px;
      border-bottom:1px solid #e3e8f0;
      background:#fff;
    }

    .employee-picker-toolbar .input-group-text,
    .employee-picker-toolbar .form-control{
      border-color:#d8dee8;
      min-height:42px;
      font-size:13px;
    }

    .employee-options{
      max-height:390px;
      overflow:auto;
      padding:14px;
      display:grid;
      grid-template-columns:repeat(3, minmax(0,1fr));
      gap:10px;
      scrollbar-width:thin;
    }

    .employee-options::-webkit-scrollbar{
      width:6px;
    }

    .employee-options::-webkit-scrollbar-thumb{
      background:#c8d2e1;
      border-radius:20px;
    }

    .employee-option{
      border:1px solid #dfe5ee;
      border-radius:8px;
      background:#fff;
      padding:10px 12px;
      cursor:pointer;
      transition:.16s ease;
      min-height:54px;
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:8px;
    }

    .employee-option:hover{
      background:#f7f9fc;
      border-color:#cbd5e1;
    }

    .employee-option.is-unavailable{
      opacity:.48;
      cursor:not-allowed;
      background:#f5f6f8;
    }

    .employee-option-name{
      color:#4b5b6b;
      font-size:13px;
      font-weight:800;
      line-height:1.4;
    }

    .employee-option-code{
      display:block;
      margin-top:3px;
      color:#8a96a8;
      font-size:11px;
      font-weight:700;
    }

    .employee-option-icon{
      width:22px;
      height:22px;
      border-radius:7px;
      display:flex;
      align-items:center;
      justify-content:center;
      background:#eef4ff;
      color:#5b8def;
      font-size:12px;
      flex:0 0 auto;
    }

    .empty-picker{
      padding:28px 12px;
      text-align:center;
      color:#8a94a6;
      font-size:13px;
      line-height:1.8;
      grid-column:1 / -1;
    }

    .empty-picker i{
      display:block;
      margin-bottom:8px;
      color:#c1c7d0;
      font-size:28px;
    }

    .alert-mini{
      position:fixed;
      left:24px;
      bottom:24px;
      z-index:9999;
      max-width:440px;
      padding:12px 14px;
      border-radius:12px;
      background:#fff;
      border:1px solid #ffd9df;
      color:#9f0e26;
      box-shadow:0 10px 24px rgba(67,89,113,.16);
      font-size:13px;
      font-weight:800;
      display:none;
    }

    .alert-mini.show{
      display:flex;
      align-items:center;
      gap:8px;
      animation:fadeUp .18s ease;
    }

    @keyframes fadeUp{
      from{opacity:0; transform:translateY(8px);}
      to{opacity:1; transform:translateY(0);}
    }

    @media(max-width:1399px){
      .week-grid{
        grid-template-columns:repeat(4, minmax(0,1fr));
      }

      .employee-options{
        grid-template-columns:repeat(2, minmax(0,1fr));
      }
    }

    @media(max-width:991px){
      .app-wrapper{
        padding:14px;
      }

      .stats-row{
        grid-template-columns:repeat(2, minmax(0,1fr));
      }

      .week-grid{
        grid-template-columns:repeat(2, minmax(0,1fr));
      }

      .context-row{
        grid-template-columns:1fr;
      }
    }

    @media(max-width:575px){
      .page-title{
        font-size:20px;
      }

      .page-subtitle{
        font-size:13px;
      }

      .hero-actions{
        width:100%;
      }

      .hero-actions button{
        flex:1;
        justify-content:center;
      }

      .stats-row,
      .week-grid,
      .employee-options{
        grid-template-columns:1fr;
      }

      .department-actions{
        width:100%;
      }

      .dept-pill{
        flex:1;
        justify-content:center;
      }
    }

    @media print{
      body{
        background:#fff;
      }

      .app-wrapper{
        padding:0;
        max-width:none;
      }

      .page-hero,
      .toolbar-card,
      .hero-actions,
      .select-btn,
      .clear-btn,
      .alert-mini{
        display:none !important;
      }

      .stats-row,
      .department-card{
        box-shadow:none;
      }

      .week-grid{
        grid-template-columns:repeat(7, minmax(0,1fr));
      }

      .day-card{
        min-height:100px;
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
          <h1 class="page-title">تحديد جدول الإجازات الأسبوعي</h1>
          <p class="page-subtitle">
            لكل قسم يتم عرض أيام الأسبوع من السبت إلى الجمعة. يختار مدير الفرع موظفًا واحدًا فقط لكل يوم داخل القسم، ولا يمكن تكرار نفس الموظف أكثر من مرة خلال نفس الأسبوع.
          </p>
        </div>

        <div class="hero-actions">
          <button class="hero-btn" type="button" onclick="window.print()">
            <i class="bi bi-printer"></i>
            طباعة
          </button>
          <button class="hero-btn primary" type="button" id="btnSave">
            <i class="bi bi-check2-circle"></i>
            حفظ جدول الإجازات
          </button>
        </div>
      </div>
    </section>

    <section class="toolbar-card">
      <div class="row g-3 align-items-end">
        <div class="col-xl-3 col-md-6">
          <label class="form-label">العلامة التجارية</label>
          <select class="form-select">
            <option>Prosto</option>
          </select>
        </div>

        <div class="col-xl-3 col-md-6">
          <label class="form-label">الفرع</label>
          <select class="form-select">
            <option>فرع مكة مول</option>
            <option>فرع عبدون</option>
            <option>فرع المدينة</option>
          </select>
        </div>

        <div class="col-xl-3 col-md-6">
          <label class="form-label">الأسبوع</label>
          <input type="week" class="form-control" value="2026-W18">
        </div>

        <div class="col-xl-3 col-md-6">
          <label class="form-label">عرض قسم محدد</label>
          <select class="form-select" id="departmentFilter">
            <option value="all">جميع الأقسام</option>
            <option value="المطبخ">المطبخ</option>
            <option value="اللاين الأمامي">اللاين الأمامي</option>
            <option value="الصالة">الصالة</option>
            <option value="إداري">إداري</option>
          </select>
        </div>
      </div>
    </section>

    <section class="stats-row">
      <div class="stat-card">
        <div>
          <div class="stat-label">عدد الأقسام</div>
          <div class="stat-value" id="totalDepartments">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-diagram-3"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">إجمالي الموظفين</div>
          <div class="stat-value" id="totalEmployees">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-people"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">الإجازات المحددة</div>
          <div class="stat-value" id="assignedLeaves">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-calendar-check"></i></div>
      </div>

      <div class="stat-card">
        <div>
          <div class="stat-label">الخانات المتبقية</div>
          <div class="stat-value" id="remainingSlots">0</div>
        </div>
        <div class="stat-icon"><i class="bi bi-calendar-x"></i></div>
      </div>
    </section>

    <section class="departments-wrapper" id="departmentsWrapper"></section>
  </div>

  <div class="modal fade" id="employeeModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-xl">
      <div class="modal-content">
        <div class="modal-header">
          <div>
            <h5 class="modal-title">اختيار موظف للإجازة</h5>
            <div class="modal-subtitle">سيتم عرض موظفي القسم فقط. الموظف المحدد مسبقًا في يوم آخر لن يكون متاحًا للاختيار.</div>
          </div>
          <button type="button" class="modal-close-btn" data-bs-dismiss="modal" aria-label="Close">
            <i class="bi bi-x-lg"></i>
          </button>
        </div>

        <div class="modal-body">
          <div class="context-row">
            <div class="context-field">
              <label>القسم</label>
              <div id="modalDepartment">-</div>
            </div>

            <div class="context-field">
              <label>اليوم</label>
              <div id="modalDay">-</div>
            </div>

            <div class="context-field">
              <label>الموظف الحالي</label>
              <div id="modalCurrentEmployee">غير محدد</div>
            </div>
          </div>

          <div class="employee-picker">
            <div class="employee-picker-toolbar">
              <div class="input-group">
                <span class="input-group-text bg-white">
                  <i class="bi bi-search"></i>
                </span>
                <input type="text" class="form-control" id="employeeSearch" placeholder="بحث باسم الموظف...">
              </div>
            </div>

            <div class="employee-options" id="employeeOptions"></div>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary rounded-3" data-bs-dismiss="modal">إلغاء</button>
          <button type="button" class="btn btn-outline-danger rounded-3" id="btnRemoveLeave">
            <i class="bi bi-trash"></i>
            إزالة إجازة اليوم
          </button>
        </div>
      </div>
    </div>
  </div>

  <div class="alert-mini" id="alertMini">
    <i class="bi bi-exclamation-triangle"></i>
    <span id="alertText"></span>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <script>
      const days = ["السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"];

      const departments = [
          {
              id: "kitchen",
              name: "المطبخ",
              icon: "bi-egg-fried",
              colorClass: "kitchen",
              employees: [
                  { id: 1, name: "أحمد محمد", code: "EMP-001" },
                  { id: 2, name: "محمد خالد", code: "EMP-002" },
                  { id: 3, name: "عمر علي", code: "EMP-003" },
                  { id: 4, name: "خالد ناصر", code: "EMP-004" },
                  { id: 5, name: "فراس وليد", code: "EMP-005" },
                  { id: 6, name: "أنس سامر", code: "EMP-006" }
              ]
          },
          {
              id: "front",
              name: "اللاين الأمامي",
              icon: "bi-shop-window",
              colorClass: "front",
              employees: [
                  { id: 7, name: "يوسف سامر", code: "EMP-007" },
                  { id: 8, name: "سعيد أحمد", code: "EMP-008" },
                  { id: 9, name: "عبدالله محمود", code: "EMP-009" },
                  { id: 10, name: "لؤي رامي", code: "EMP-010" },
                  { id: 11, name: "رامي فادي", code: "EMP-011" }
              ]
          },
          {
              id: "hall",
              name: "الصالة",
              icon: "bi-cup-hot",
              colorClass: "hall",
              employees: [
                  { id: 12, name: "محمود حسن", code: "EMP-012" },
                  { id: 13, name: "مالك وليد", code: "EMP-013" },
                  { id: 14, name: "زياد محمد", code: "EMP-014" },
                  { id: 15, name: "قيس عمر", code: "EMP-015" },
                  { id: 16, name: "سامي خالد", code: "EMP-016" }
              ]
          },
          {
              id: "admin",
              name: "إداري",
              icon: "bi-person-badge",
              colorClass: "admin",
              employees: [
                  { id: 17, name: "نادر أحمد", code: "EMP-017" },
                  { id: 18, name: "باسل محمود", code: "EMP-018" },
                  { id: 19, name: "كريم علي", code: "EMP-019" },
                  { id: 20, name: "طارق ناصر", code: "EMP-020" }
              ]
          }
      ];

      /*
        leaveAssignments structure:
        key = `${departmentName}_${day}`
        value = { departmentName, day, employeeId, employeeName, employeeCode }
      */
      const leaveAssignments = new Map();

      let selectedDepartment = null;
      let selectedDay = null;

      const departmentsWrapper = document.getElementById("departmentsWrapper");
      const departmentFilter = document.getElementById("departmentFilter");
      const employeeModal = new bootstrap.Modal(document.getElementById("employeeModal"));
      const employeeSearch = document.getElementById("employeeSearch");

      function getKey(departmentName, day) {
          return `${departmentName}_${day}`;
      }

      function getEmployeeAssignedInDepartment(departmentName, employeeId) {
          return Array.from(leaveAssignments.values()).find(item =>
              item.departmentName === departmentName && item.employeeId === employeeId
          );
      }

      function getDepartmentByName(departmentName) {
          return departments.find(dept => dept.name === departmentName);
      }

      function renderDepartments() {
          departmentsWrapper.innerHTML = "";

          departments.forEach(dept => {
              const card = document.createElement("article");
              card.className = "department-card";
              card.dataset.department = dept.name;

              card.innerHTML = `
          <div class="department-header">
            <div class="department-title-wrap">
              <div class="department-icon ${dept.colorClass}">
                <i class="bi ${dept.icon}"></i>
              </div>
              <div>
                <h2 class="department-name">${dept.name}</h2>
                <div class="department-brief">لكل يوم يتم اختيار موظف واحد فقط من هذا القسم</div>
              </div>
            </div>

            <div class="department-actions">
              <span class="dept-pill">
                <i class="bi bi-people"></i>
                الموظفون: <strong>${dept.employees.length}</strong>
              </span>
              <span class="dept-pill">
                <i class="bi bi-calendar-check"></i>
                الإجازات: <strong id="deptAssigned_${dept.id}">0</strong> / 7
              </span>
              <span class="dept-pill">
                <i class="bi bi-calendar-x"></i>
                المتبقي: <strong id="deptRemaining_${dept.id}">7</strong>
              </span>
            </div>
          </div>

          <div class="week-grid">
            ${days.map(day => createDayCard(dept.name, day)).join("")}
          </div>
        `;

              departmentsWrapper.appendChild(card);
          });

          applyDepartmentFilter();
          refreshUI();
      }

      function createDayCard(departmentName, day) {
          return `
        <div class="day-card" data-department="${departmentName}" data-day="${day}">
          <div class="day-title">
            <span class="day-name">${day}</span>
            <span class="day-status"><i class="bi bi-calendar"></i></span>
          </div>

          <div class="selected-employee" data-selected="${departmentName}_${day}">
            لم يتم اختيار موظف
          </div>

          <div class="day-actions">
            <button type="button" class="select-btn" data-select-department="${departmentName}" data-select-day="${day}">
              <i class="bi bi-person-plus"></i>
              اختيار موظف
            </button>

            <button type="button" class="clear-btn" data-clear-department="${departmentName}" data-clear-day="${day}">
              <i class="bi bi-x-circle"></i>
              إزالة
            </button>
          </div>
        </div>
      `;
      }

      function attachEvents() {
          document.querySelectorAll("[data-select-department]").forEach(btn => {
              btn.addEventListener("click", () => {
                  openEmployeeModal(btn.dataset.selectDepartment, btn.dataset.selectDay);
              });
          });

          document.querySelectorAll("[data-clear-department]").forEach(btn => {
              btn.addEventListener("click", () => {
                  removeLeave(btn.dataset.clearDepartment, btn.dataset.clearDay);
              });
          });
      }

      function openEmployeeModal(departmentName, day) {
          selectedDepartment = departmentName;
          selectedDay = day;
          employeeSearch.value = "";

          const current = leaveAssignments.get(getKey(departmentName, day));

          document.getElementById("modalDepartment").textContent = departmentName;
          document.getElementById("modalDay").textContent = day;
          document.getElementById("modalCurrentEmployee").textContent = current ? current.employeeName : "غير محدد";

          renderEmployeeOptions();
          employeeModal.show();
      }

      function renderEmployeeOptions() {
          const dept = getDepartmentByName(selectedDepartment);
          const keyword = employeeSearch.value.trim().toLowerCase();
          const current = leaveAssignments.get(getKey(selectedDepartment, selectedDay));

          const employees = dept.employees.filter(emp => emp.name.toLowerCase().includes(keyword));

          const employeeOptions = document.getElementById("employeeOptions");
          employeeOptions.innerHTML = "";

          if (employees.length === 0) {
              employeeOptions.innerHTML = `
          <div class="empty-picker">
            <i class="bi bi-search"></i>
            لا يوجد موظفون مطابقون للبحث
          </div>
        `;
              return;
          }

          employees.forEach(emp => {
              const alreadyAssigned = getEmployeeAssignedInDepartment(selectedDepartment, emp.id);
              const isCurrent = current && current.employeeId === emp.id;
              const isUnavailable = alreadyAssigned && !isCurrent;

              const option = document.createElement("button");
              option.type = "button";
              option.className = "employee-option" + (isUnavailable ? " is-unavailable" : "");
              option.disabled = !!isUnavailable;

              option.innerHTML = `
          <span>
            <span class="employee-option-name">${emp.name}</span>
            <span class="employee-option-code">
              ${isUnavailable ? `محدد مسبقًا يوم ${alreadyAssigned.day}` : emp.code}
            </span>
          </span>
          <span class="employee-option-icon">
            <i class="bi ${isCurrent ? "bi-check2" : "bi-person-plus"}"></i>
          </span>
        `;

              option.addEventListener("click", () => {
                  if (isUnavailable) {
                      showAlert(`لا يمكن اختيار ${emp.name}، لأنه محدد مسبقًا في يوم ${alreadyAssigned.day} ضمن نفس القسم.`);
                      return;
                  }

                  assignEmployee(emp);
              });

              employeeOptions.appendChild(option);
          });
      }

      function assignEmployee(emp) {
          leaveAssignments.set(getKey(selectedDepartment, selectedDay), {
              departmentName: selectedDepartment,
              day: selectedDay,
              employeeId: emp.id,
              employeeName: emp.name,
              employeeCode: emp.code
          });

          employeeModal.hide();
          refreshUI();
      }

      function removeLeave(departmentName, day) {
          leaveAssignments.delete(getKey(departmentName, day));
          refreshUI();
      }

      document.getElementById("btnRemoveLeave").addEventListener("click", () => {
          if (!selectedDepartment || !selectedDay) return;
          removeLeave(selectedDepartment, selectedDay);
          employeeModal.hide();
      });

      function refreshUI() {
          document.querySelectorAll(".day-card").forEach(card => {
              const departmentName = card.dataset.department;
              const day = card.dataset.day;
              const assignment = leaveAssignments.get(getKey(departmentName, day));
              const selectedEl = card.querySelector(`[data-selected="${departmentName}_${day}"]`);

              card.classList.toggle("has-employee", !!assignment);

              if (assignment) {
                  selectedEl.innerHTML = `
            <span>
              ${assignment.employeeName}
              <span class="employee-sub">${assignment.employeeCode}</span>
            </span>
          `;
                  card.querySelector(".day-status").innerHTML = `<i class="bi bi-check2-circle"></i>`;
                  card.querySelector(".select-btn").innerHTML = `<i class="bi bi-pencil"></i> تعديل`;
              } else {
                  selectedEl.textContent = "لم يتم اختيار موظف";
                  card.querySelector(".day-status").innerHTML = `<i class="bi bi-calendar"></i>`;
                  card.querySelector(".select-btn").innerHTML = `<i class="bi bi-person-plus"></i> اختيار موظف`;
              }
          });

          updateStats();
          attachEvents();
      }

      function updateStats() {
          const totalDepartments = departments.length;
          const totalEmployees = departments.reduce((sum, dept) => sum + dept.employees.length, 0);
          const totalSlots = departments.length * days.length;
          const assigned = leaveAssignments.size;

          document.getElementById("totalDepartments").textContent = totalDepartments;
          document.getElementById("totalEmployees").textContent = totalEmployees;
          document.getElementById("assignedLeaves").textContent = assigned;
          document.getElementById("remainingSlots").textContent = totalSlots - assigned;

          departments.forEach(dept => {
              const assignedDept = Array.from(leaveAssignments.values()).filter(item => item.departmentName === dept.name).length;
              const assignedEl = document.getElementById(`deptAssigned_${dept.id}`);
              const remainingEl = document.getElementById(`deptRemaining_${dept.id}`);

              if (assignedEl) assignedEl.textContent = assignedDept;
              if (remainingEl) remainingEl.textContent = days.length - assignedDept;
          });
      }

      function applyDepartmentFilter() {
          const value = departmentFilter.value;

          document.querySelectorAll(".department-card").forEach(card => {
              const isVisible = value === "all" || card.dataset.department === value;
              card.classList.toggle("is-filtered-out", !isVisible);
          });
      }

      function showAlert(message) {
          const alertBox = document.getElementById("alertMini");
          const alertText = document.getElementById("alertText");

          alertText.textContent = message;
          alertBox.classList.add("show");

          clearTimeout(window.__leaveAlertTimer);
          window.__leaveAlertTimer = setTimeout(() => {
              alertBox.classList.remove("show");
          }, 3500);
      }

      employeeSearch.addEventListener("input", renderEmployeeOptions);
      departmentFilter.addEventListener("change", applyDepartmentFilter);

      document.getElementById("btnSave").addEventListener("click", () => {
          const payload = Array.from(leaveAssignments.values());
          console.log("Weekly Leaves Payload:", payload);
          alert("تم تجهيز بيانات جدول الإجازات للحفظ. يمكنك ربط الـ payload مع قاعدة البيانات من خلال Code Behind.");
      });

      renderDepartments();
      attachEvents();
  </script>
</body>
</html>