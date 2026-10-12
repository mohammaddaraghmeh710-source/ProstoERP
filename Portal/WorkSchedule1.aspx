<%@ Page Language="vb" AutoEventWireup="false" CodeBehind="WorkSchedule1.aspx.vb" Inherits="CRM.WorkSchedule1" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Prosto ERP - توزيع جدول الدوام الأسبوعي</title>

  <!-- Pixinvent / Bootstrap Compatible Libraries -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <style>
    :root{
      --primary:#c41230;
      --primary-dark:#9f0e26;
      --primary-soft:#fff1f3;

      --body-bg:#f5f6fa;
      --card-bg:#ffffff;
      --text:#1f2937;
      --muted:#6b7280;
      --border:#e6e9ef;
      --border-dark:#d3d8e1;

      --kitchen:#f47c24;
      --front:#68ad45;
      --hall:#2f80ed;
      --admin:#7367f0;

      --job-bg:#edf3ff;
      --shift-bg:#e7f5df;
      --cell-bg:#ffffff;
      --cell-hover:#fffaf0;

      --shadow:0 10px 30px rgba(67,89,113,.08);
      --shadow-sm:0 4px 14px rgba(67,89,113,.06);
      --radius:16px;
    }

    *{
      box-sizing:border-box;
    }

    body{
      margin:0;
      background:
        radial-gradient(circle at top right, rgba(196,18,48,.08), transparent 30%),
        radial-gradient(circle at top left, rgba(115,103,240,.07), transparent 26%),
        var(--body-bg);
      font-family:"Almarai","Tahoma","Arial",sans-serif;
      color:var(--text);
      min-height:100vh;
    }

    .app-wrapper{
      padding:22px;
      max-width:1800px;
      margin:0 auto;
    }

    .page-hero{
      position:relative;
      overflow:hidden;
      border-radius:22px;
      padding:22px 24px;
      margin-bottom:18px;
      color:#fff;
      background:
        linear-gradient(135deg, rgba(196,18,48,.96), rgba(42,47,69,.96)),
        radial-gradient(circle at 10% 20%, rgba(255,255,255,.18), transparent 30%);
      box-shadow:var(--shadow);
    }

    .page-hero::before{
      content:"";
      position:absolute;
      inset:auto -80px -120px auto;
      width:290px;
      height:290px;
      border-radius:50%;
      background:rgba(255,255,255,.09);
    }

    .page-hero::after{
      content:"";
      position:absolute;
      inset:-130px auto auto -80px;
      width:240px;
      height:240px;
      border-radius:50%;
      background:rgba(255,255,255,.08);
    }

    .page-hero__content{
      position:relative;
      z-index:1;
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:18px;
      flex-wrap:wrap;
    }

    .page-title{
      margin:0;
      font-size:clamp(21px, 2vw, 30px);
      font-weight:800;
      letter-spacing:-.4px;
    }

    .page-subtitle{
      margin:8px 0 0;
      font-size:14px;
      opacity:.86;
      max-width:820px;
      line-height:1.8;
    }

    .hero-actions{
      display:flex;
      gap:10px;
      flex-wrap:wrap;
    }

    .hero-btn{
      border:1px solid rgba(255,255,255,.28);
      background:rgba(255,255,255,.13);
      color:#fff;
      border-radius:12px;
      padding:9px 14px;
      font-size:13px;
      font-weight:700;
      display:inline-flex;
      align-items:center;
      gap:7px;
      transition:.2s ease;
      backdrop-filter:blur(8px);
    }

    .hero-btn:hover{
      background:rgba(255,255,255,.22);
      color:#fff;
      transform:translateY(-1px);
    }

    .hero-btn.primary{
      background:#fff;
      color:var(--primary);
      border-color:#fff;
    }

    .toolbar-card{
      background:rgba(255,255,255,.86);
      backdrop-filter:blur(12px);
      border:1px solid rgba(255,255,255,.8);
      border-radius:var(--radius);
      box-shadow:var(--shadow-sm);
      padding:16px;
      margin-bottom:18px;
    }

    .form-label{
      font-size:12px;
      color:#4b5563;
      font-weight:800;
      margin-bottom:7px;
    }

    .form-control,
    .form-select{
      border-radius:12px;
      border-color:var(--border);
      min-height:42px;
      font-size:13px;
    }

    .form-control:focus,
    .form-select:focus{
      border-color:rgba(196,18,48,.45);
      box-shadow:0 0 0 .2rem rgba(196,18,48,.08);
    }

    .workspace{
      display:grid;
      grid-template-columns:minmax(170px, 210px) minmax(0,1fr);
      gap:18px;
      align-items:start;
    }

    .panel{
      background:var(--card-bg);
      border:1px solid rgba(230,233,239,.9);
      border-radius:var(--radius);
      box-shadow:var(--shadow);
      overflow:hidden;
    }

    .employees-panel{
      position:sticky;
      top:18px;
      max-height:calc(100vh - 36px);
      display:flex;
      flex-direction:column;
    }

    .panel-header{
      padding:12px 14px;
      border-bottom:1px solid var(--border);
      display:flex;
      align-items:flex-start;
      justify-content:space-between;
      gap:12px;
      background:#fff;
    }

    .panel-title{
      margin:0;
      font-size:14px;
      font-weight:800;
      color:#111827;
    }

    .panel-hint{
      margin-top:5px;
      color:var(--muted);
      font-size:12px;
      line-height:1.6;
    }

    .panel-icon{
      width:42px;
      height:42px;
      border-radius:14px;
      display:flex;
      align-items:center;
      justify-content:center;
      color:var(--primary);
      background:var(--primary-soft);
      flex:0 0 auto;
      font-size:18px;
    }

    .employee-search{
      padding:10px;
      border-bottom:1px solid var(--border);
      background:#fbfbfd;
    }

    .employee-scroll{
      padding:12px;
      overflow:auto;
      flex:1;
    }

    .employee-item{
      width:100%;
      border:1px solid var(--border);
      background:#fff;
      border-radius:14px;
      padding:8px 9px;
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:10px;
      margin-bottom:9px;
      cursor:pointer;
      transition:.18s ease;
      text-align:right;
    }

    .employee-item:hover{
      border-color:rgba(196,18,48,.45);
      background:#fffafa;
      box-shadow:0 8px 20px rgba(196,18,48,.08);
      transform:translateY(-1px);
    }

    .employee-item.is-assigned{
      border-color:#b9edd2;
      background:linear-gradient(0deg,#f4fff9,#ffffff);
    }

    .employee-main{
      display:flex;
      align-items:center;
      gap:7px;
      min-width:0;
    }

    .avatar{
      width:30px;
      height:30px;
      border-radius:10px;
      background:linear-gradient(135deg, var(--primary), #f05a6e);
      color:#fff;
      display:flex;
      align-items:center;
      justify-content:center;
      font-weight:800;
      flex:0 0 auto;
      box-shadow:0 8px 16px rgba(196,18,48,.16);
    }

    .employee-info{
      min-width:0;
    }

    .employee-name{
      display:block;
      font-size:10.5px;
      font-weight:800;
      color:#111827;
      white-space:nowrap;
      overflow:hidden;
      text-overflow:ellipsis;
      max-width:115px;
    }

    .employee-code{
      display:none;
    }

    .status-badge{
      display:none;
    }

    .employee-item.is-assigned .status-badge{
      background:#dff8ea;
      color:#16834a;
    }

    .table-panel{
      min-width:0;
    }

    .table-panel .panel-header{
      flex-wrap:wrap;
    }

    .table-actions{
      display:flex;
      gap:8px;
      flex-wrap:wrap;
    }

    .btn-soft{
      border:1px solid var(--border);
      background:#fff;
      border-radius:12px;
      padding:8px 12px;
      color:#4b5563;
      font-size:13px;
      font-weight:800;
      display:inline-flex;
      gap:7px;
      align-items:center;
      transition:.18s ease;
    }

    .btn-soft:hover{
      background:#f8f8fb;
      color:#111827;
      transform:translateY(-1px);
    }

    .btn-primary-prosto{
      background:var(--primary);
      border:1px solid var(--primary);
      color:#fff;
      border-radius:12px;
      padding:8px 12px;
      font-size:13px;
      font-weight:800;
      display:inline-flex;
      gap:7px;
      align-items:center;
      transition:.18s ease;
    }

    .btn-primary-prosto:hover{
      background:var(--primary-dark);
      border-color:var(--primary-dark);
      color:#fff;
      transform:translateY(-1px);
    }

    .stats-row{
      padding:14px 16px;
      border-bottom:1px solid var(--border);
      background:#fbfbfd;
      display:grid;
      grid-template-columns:repeat(4,minmax(120px,1fr));
      gap:10px;
    }

    .stat-card{
      background:#fff;
      border:1px solid var(--border);
      border-radius:14px;
      padding:12px;
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:10px;
    }

    .stat-label{
      font-size:11px;
      color:var(--muted);
      font-weight:700;
    }

    .stat-value{
      margin-top:5px;
      font-size:20px;
      color:#111827;
      font-weight:800;
    }

    .stat-icon{
      width:36px;
      height:36px;
      border-radius:12px;
      display:flex;
      align-items:center;
      justify-content:center;
      background:#f3f4f6;
      color:#4b5563;
    }

    .schedule-wrap{
      overflow:auto;
      max-height:calc(100vh - 300px);
      background:
        linear-gradient(to left, rgba(196,18,48,.06), rgba(196,18,48,0) 34px) right / 34px 100% no-repeat,
        #fff;
    }

    .schedule-table{
      width:100%;
      min-width:980px;
      border-collapse:separate;
      border-spacing:0;
      table-layout:fixed;
      direction:rtl;
    }

    .schedule-table th,
    .schedule-table td{
      border-left:1px solid var(--border-dark);
      border-bottom:1px solid var(--border-dark);
      vertical-align:top;
    }

    .schedule-table thead th{
      text-align:center;
      font-weight:800;
      padding:9px 8px;
      position:sticky;
      top:0;
      z-index:5;
    }

    .schedule-table thead tr:nth-child(2) th{
      top:39px;
      z-index:5;
    }

    .shift-head{
      width:105px;
      background:#fff;
      color:#111827;
      position:sticky !important;
      right:0;
      z-index:8 !important;
      border-right:1px solid var(--border-dark);
    }

    .department-head{
      color:#fff;
      font-size:13px;
      height:39px;
      box-shadow:inset 0 -1px 0 rgba(255,255,255,.2);
    }

    .dept-kitchen{background:linear-gradient(135deg,var(--kitchen),#ff9d4f);}
    .dept-front{background:linear-gradient(135deg,var(--front),#8bcf66);}
    .dept-hall{background:linear-gradient(135deg,var(--hall),#64a7ff);}
    .dept-admin{background:linear-gradient(135deg,var(--admin),#9a91ff);}

    .job-head{
      background:var(--job-bg);
      color:#111827;
      font-size:11px;
      height:34px;
    }

    .shift-cell{
      width:105px;
      background:var(--shift-bg);
      color:#111827;
      text-align:center;
      vertical-align:middle !important;
      font-weight:800;
      font-size:11px;
      padding:9px 7px;
      position:sticky;
      right:0;
      z-index:4;
      border-right:1px solid var(--border-dark);
      box-shadow:-8px 0 14px rgba(30,41,59,.04);
    }

    .shift-cell span{
      display:block;
      border-radius:12px;
      background:rgba(255,255,255,.58);
      padding:9px 7px;
      border:1px solid rgba(255,255,255,.7);
    }

    .assignment-cell{
      height:86px;
      min-height:86px;
      padding:5px;
      background:var(--cell-bg);
      cursor:pointer;
      transition:.16s ease;
    }

    .assignment-cell:hover{
      background:var(--cell-hover);
      box-shadow:inset 0 0 0 2px rgba(244,124,36,.2);
    }

    .assignment-cell.empty{
      position:relative;
    }

    .assignment-cell.empty::before{
      content:"اضغط للإضافة";
      position:absolute;
      inset:50% auto auto 50%;
      transform:translate(-50%,-50%);
      color:#9ca3af;
      font-size:12px;
      font-weight:700;
      opacity:.0;
      transition:.16s ease;
      white-space:nowrap;
    }

    .assignment-cell.empty:hover::before{
      opacity:1;
    }

    .employee-chip{
      display:flex;
      align-items:flex-start;
      justify-content:space-between;
      gap:7px;
      border:1px solid #e5e7eb;
      background:#fff;
      border-right:4px solid var(--primary);
      border-radius:12px;
      padding:5px 6px;
      margin-bottom:5px;
      box-shadow:0 6px 14px rgba(67,89,113,.06);
      animation:chipIn .18s ease;
    }

    @keyframes chipIn{
      from{opacity:0; transform:translateY(4px);}
      to{opacity:1; transform:translateY(0);}
    }

    .chip-name{
      font-size:10.5px;
      font-weight:800;
      color:#111827;
      line-height:1.5;
    }

    .chip-note{
      display:block;
      color:#6b7280;
      font-size:10px;
      font-weight:400;
      margin-top:2px;
      line-height:1.4;
    }

    .chip-remove{
      width:18px;
      height:18px;
      border:0;
      border-radius:50%;
      background:#fee2e2;
      color:#b91c1c;
      display:flex;
      align-items:center;
      justify-content:center;
      flex:0 0 auto;
      transition:.16s ease;
    }

    .chip-remove:hover{
      background:#fecaca;
      transform:scale(1.05);
    }

    .table-footer{
      padding:12px 16px;
      border-top:1px solid var(--border);
      background:#fbfbfd;
      color:var(--muted);
      font-size:12px;
      display:flex;
      justify-content:space-between;
      align-items:center;
      gap:10px;
      flex-wrap:wrap;
    }

    .legend{
      display:flex;
      gap:12px;
      flex-wrap:wrap;
      align-items:center;
    }

    .legend-item{
      display:flex;
      align-items:center;
      gap:6px;
      font-weight:700;
      color:#5c6575;
    }

    .legend-dot{
      width:10px;
      height:10px;
      border-radius:50%;
      display:inline-block;
    }

    .modal-content{
      border:0;
      border-radius:18px;
      box-shadow:0 18px 50px rgba(30,41,59,.18);
    }

    .modal-header{
      border-bottom:1px solid var(--border);
      padding:18px;
    }

    .modal-title{
      font-weight:800;
    }

    .modal-body{
      padding:18px;
    }

    .modal-footer{
      border-top:1px solid var(--border);
      padding:14px 18px;
    }

    .selected-box{
      border:1px dashed rgba(196,18,48,.35);
      background:var(--primary-soft);
      color:#8f1025;
      border-radius:14px;
      padding:13px;
      margin-bottom:15px;
      font-weight:800;
      display:flex;
      align-items:center;
      gap:9px;
    }

    .quick-info{
      border:1px solid var(--border);
      background:#fbfbfd;
      border-radius:14px;
      padding:12px;
      color:#4b5563;
      line-height:1.8;
      font-size:13px;
    }

    .empty-state{
      padding:24px 12px;
      text-align:center;
      color:#8a94a6;
      font-size:13px;
    }

    .empty-state i{
      display:block;
      font-size:28px;
      margin-bottom:8px;
      color:#c1c7d0;
    }


    .employees-panel .panel-icon{
      display:none;
    }

    .employees-panel .panel-hint{
      display:none;
    }

    .employees-panel .panel-header{
      justify-content:center;
      text-align:center;
    }

    .employee-item{
      justify-content:flex-start;
    }

    .employee-search .input-group-text{
      padding-inline:8px;
    }

    .employee-search .form-control{
      font-size:12px;
      min-height:36px;
    }

    .schedule-table thead th{
      padding:7px 5px;
    }

    .department-head{
      height:34px;
    }

    .shift-cell span{
      padding:6px 5px;
      border-radius:9px;
    }


    @media(max-width:1199px){
      .workspace{
        grid-template-columns:190px minmax(0,1fr);
      }

      .stats-row{
        grid-template-columns:repeat(2,minmax(120px,1fr));
      }
    }

    @media(max-width:991px){
      .app-wrapper{
        padding:10px;
      }

      .workspace{
        grid-template-columns:1fr;
      }

      .employees-panel{
        position:relative;
        top:auto;
        max-height:none;
      }

      .employee-scroll{
        max-height:320px;
      }

      .schedule-wrap{
        max-height:65vh;
      }

      .page-hero{
        padding:18px;
      }
    }

    @media(max-width:575px){
      .hero-actions{
        width:100%;
      }

      .hero-btn{
        flex:1;
        justify-content:center;
      }

      .stats-row{
        grid-template-columns:1fr;
      }

      .panel-header{
        padding:10px;
      }

      .table-actions{
        width:100%;
      }

      .table-actions button{
        flex:1;
        justify-content:center;
      }
    }


    /* ===== Requested compact calendar-like layout enhancements ===== */
    .app-wrapper{
      padding-left:42px !important;
      padding-right:42px !important;
    }

    .page-hero{
      padding:16px 20px !important;
      margin-bottom:14px !important;
      border-radius:14px !important;
      background:
        linear-gradient(135deg, rgba(255,255,255,.94), rgba(255,255,255,.84)),
        radial-gradient(circle at 5% 20%, rgba(196,18,48,.12), transparent 34%) !important;
      color:#24334d !important;
      border:1px solid rgba(224,228,236,.85);
      box-shadow:0 4px 22px rgba(67,89,113,.08) !important;
    }

    .page-hero::before,
    .page-hero::after{
      display:none !important;
    }

    .page-title{
      font-size:20px !important;
      color:#24334d !important;
    }

    .page-subtitle{
      color:#6b7890 !important;
      opacity:1 !important;
      font-size:12px !important;
      margin-top:5px !important;
    }

    .hero-btn{
      background:#eef4ff !important;
      color:#4f7df3 !important;
      border-color:#dbe7ff !important;
      box-shadow:none !important;
    }

    .hero-btn.primary{
      background:#5b8def !important;
      border-color:#5b8def !important;
      color:#fff !important;
      box-shadow:0 6px 14px rgba(91,141,239,.22) !important;
    }

    .toolbar-card{
      padding:12px 14px !important;
      border-radius:12px !important;
      margin-bottom:14px !important;
      box-shadow:0 4px 22px rgba(67,89,113,.06) !important;
    }

    .workspace{
      grid-template-columns:minmax(145px, 170px) minmax(0,1fr) !important;
      gap:14px !important;
    }

    .panel{
      border-radius:12px !important;
      box-shadow:0 4px 22px rgba(67,89,113,.07) !important;
      border-color:#dfe5ee !important;
    }

    .employees-panel{
      max-height:calc(100vh - 116px) !important;
    }

    .employees-panel .panel-header{
      padding:10px !important;
      background:#f8faff !important;
      border-bottom:1px solid #e4eaf4 !important;
    }

    .employees-panel .panel-title{
      font-size:13px !important;
      color:#5f6f85 !important;
    }

    .employee-search{
      padding:8px !important;
      background:#fff !important;
    }

    .employee-search .input-group-text{
      height:32px !important;
      border-radius:9px 0 0 9px !important;
      font-size:11px !important;
      color:#7a8aa0 !important;
    }

    .employee-search .form-control{
      min-height:32px !important;
      height:32px !important;
      font-size:11px !important;
      border-radius:0 9px 9px 0 !important;
    }

    .employee-scroll{
      padding:8px !important;
    }

    .employee-item{
      min-height:32px !important;
      margin-bottom:6px !important;
      padding:6px 7px !important;
      border-radius:10px !important;
      border-color:#e3e8f1 !important;
      background:#fff !important;
    }

    .employee-item:hover{
      background:#f5f8ff !important;
      border-color:#5b8def !important;
      box-shadow:0 4px 12px rgba(91,141,239,.12) !important;
    }

    .employee-item.is-assigned{
      background:#f2fbf7 !important;
      border-color:#bfead2 !important;
    }

    .avatar{
      display:none !important;
    }

    .employee-main{
      gap:0 !important;
      width:100%;
    }

    .employee-name{
      max-width:135px !important;
      font-size:11px !important;
      font-weight:700 !important;
      color:#3b4a5f !important;
    }

    .table-panel .panel-header{
      padding:12px 14px !important;
      background:#fff !important;
    }

    .table-panel .panel-title{
      font-size:15px !important;
      color:#24334d !important;
    }

    .table-panel .panel-hint{
      font-size:11px !important;
      margin-top:3px !important;
    }

    .table-actions button{
      padding:6px 10px !important;
      font-size:11px !important;
      border-radius:9px !important;
    }

    .stats-row{
      display:flex !important;
      grid-template-columns:none !important;
      gap:8px !important;
      padding:10px 14px !important;
      background:#f8faff !important;
      overflow-x:auto;
    }

    .stat-card{
      min-width:135px !important;
      padding:8px 10px !important;
      border-radius:10px !important;
      box-shadow:0 2px 8px rgba(67,89,113,.04);
    }

    .stat-label{
      font-size:10px !important;
    }

    .stat-value{
      font-size:16px !important;
      margin-top:2px !important;
    }

    .stat-icon{
      width:28px !important;
      height:28px !important;
      border-radius:9px !important;
      font-size:12px !important;
      background:#eef4ff !important;
      color:#5b8def !important;
    }

    .schedule-wrap{
      max-height:calc(100vh - 265px) !important;
      background:#fff !important;
      border-top:1px solid #e4eaf4;
      border-bottom:1px solid #e4eaf4;
    }

    .schedule-table{
      min-width:920px !important;
      font-size:10px !important;
      border-collapse:separate !important;
      border-spacing:0 !important;
    }

    .schedule-table th,
    .schedule-table td{
      border-left:1px solid #d8dee8 !important;
      border-bottom:1px solid #d8dee8 !important;
    }

    .schedule-table thead th{
      padding:5px 4px !important;
      font-size:10px !important;
      letter-spacing:0 !important;
    }

    .department-head{
      height:30px !important;
      font-size:11px !important;
      font-weight:800 !important;
      color:#fff !important;
    }

    .job-head{
      height:28px !important;
      font-size:9.5px !important;
      background:#f1f5fb !important;
      color:#53657b !important;
      font-weight:700 !important;
    }

    .shift-head{
      width:82px !important;
      min-width:82px !important;
      max-width:82px !important;
      background:#f8faff !important;
      color:#53657b !important;
      font-size:10px !important;
    }

    .shift-cell{
      width:82px !important;
      min-width:82px !important;
      max-width:82px !important;
      background:#f8faff !important;
      padding:5px !important;
      font-size:10px !important;
      color:#43546b !important;
    }

    .shift-cell span{
      padding:5px 4px !important;
      border-radius:8px !important;
      background:#eef4ff !important;
      border:1px solid #dbe7ff !important;
      color:#4f7df3 !important;
      font-weight:800 !important;
    }

    .assignment-cell{
      height:64px !important;
      min-height:64px !important;
      padding:3px 4px !important;
      background:#fff !important;
    }

    .assignment-cell:hover{
      background:#f8fbff !important;
      box-shadow:inset 0 0 0 2px rgba(91,141,239,.14) !important;
    }

    .assignment-cell.empty::before{
      content:"+" !important;
      width:20px;
      height:20px;
      border-radius:50%;
      background:#eef4ff;
      color:#5b8def !important;
      display:flex;
      align-items:center;
      justify-content:center;
      font-size:14px !important;
      font-weight:800 !important;
    }

    .employee-chip{
      padding:3px 5px !important;
      margin-bottom:3px !important;
      border-radius:7px !important;
      border-right-width:3px !important;
      box-shadow:none !important;
      background:#f9fbff !important;
      border-color:#dfe7f5 !important;
    }

    .chip-name{
      font-size:9px !important;
      line-height:1.35 !important;
      color:#334155 !important;
    }

    .chip-note{
      font-size:8.5px !important;
      line-height:1.3 !important;
    }

    .chip-remove{
      width:15px !important;
      height:15px !important;
      font-size:10px !important;
      background:#fff1f3 !important;
    }

    .table-footer{
      padding:8px 14px !important;
      font-size:10.5px !important;
      background:#f8faff !important;
    }

    .legend{
      gap:8px !important;
    }

    .legend-item{
      font-size:10px !important;
      gap:4px !important;
    }

    .legend-dot{
      width:8px !important;
      height:8px !important;
    }

    .dept-kitchen{background:#ff9f43 !important;}
    .dept-front{background:#28c76f !important;}
    .dept-hall{background:#5b8def !important;}
    .dept-admin{background:#7367f0 !important;}

    @media(max-width:991px){
      .app-wrapper{
        padding-left:14px !important;
        padding-right:14px !important;
      }

      .workspace{
        grid-template-columns:1fr !important;
      }

      .employees-panel{
        max-height:none !important;
      }

      .employee-scroll{
        display:grid;
        grid-template-columns:repeat(auto-fill,minmax(110px,1fr));
        gap:6px;
        max-height:190px !important;
      }

      .employee-item{
        margin-bottom:0 !important;
      }

      .employee-name{
        max-width:100% !important;
      }
    }


    /* ===== Final requested refinements ===== */
    .app-wrapper{
      padding:24px 46px !important;
    }

    .page-hero{
      margin-left:8px !important;
      margin-right:8px !important;
      padding:20px 24px !important;
    }

    .page-title{
      font-size:24px !important;
      line-height:1.4 !important;
    }

    .page-subtitle{
      font-size:14px !important;
      line-height:1.8 !important;
      max-width:980px !important;
    }

    .toolbar-card{
      margin-left:8px !important;
      margin-right:8px !important;
    }

    .workspace{
      padding:8px !important;
    }

    .panel{
      overflow:hidden;
    }

    .employees-panel{
      max-height:calc(100vh - 150px) !important;
    }

    .employee-scroll{
      max-height:calc(100vh - 245px) !important;
      overflow-y:auto !important;
      overflow-x:hidden !important;
      padding:10px !important;
      scrollbar-width:thin;
    }

    .employee-scroll::-webkit-scrollbar{
      width:6px;
    }

    .employee-scroll::-webkit-scrollbar-thumb{
      background:#c8d2e1;
      border-radius:20px;
    }

    .employee-scroll::-webkit-scrollbar-track{
      background:#f4f7fb;
    }

    .table-panel{
      padding:8px !important;
      background:#ffffff;
    }

    .table-panel > .panel-header,
    .stats-row,
    .schedule-wrap,
    .table-footer{
      margin-left:0 !important;
      margin-right:0 !important;
      border-radius:10px;
    }

    .table-panel .panel-header{
      border:1px solid #e4eaf4 !important;
      margin-bottom:8px;
      padding:14px 16px !important;
    }

    .table-panel .panel-title{
      font-size:18px !important;
      line-height:1.5 !important;
    }

    .table-panel .panel-hint{
      font-size:13px !important;
      line-height:1.7 !important;
    }

    .stats-row{
      width:100% !important;
      display:grid !important;
      grid-template-columns:repeat(4, minmax(0, 1fr)) !important;
      gap:10px !important;
      padding:12px !important;
      margin-bottom:8px !important;
      overflow:visible !important;
      border:1px solid #e4eaf4 !important;
    }

    .stat-card{
      width:100% !important;
      min-width:0 !important;
      padding:12px 14px !important;
    }

    .stat-label{
      font-size:12px !important;
      line-height:1.5 !important;
    }

    .stat-value{
      font-size:22px !important;
      line-height:1.2 !important;
    }

    .stat-icon{
      width:34px !important;
      height:34px !important;
      font-size:15px !important;
    }

    .schedule-wrap{
      padding:8px !important;
      border:1px solid #e4eaf4 !important;
      background:#f8faff !important;
      max-height:calc(100vh - 308px) !important;
    }

    .schedule-table{
      background:#fff !important;
      overflow:hidden;
      border-radius:8px;
    }

    .assignment-cell{
      padding:8px !important;
      height:74px !important;
      min-height:74px !important;
    }

    .employee-chip{
      padding:6px 8px !important;
      margin-bottom:6px !important;
      border-radius:8px !important;
      min-height:26px;
      align-items:center !important;
    }

    .chip-name{
      font-size:10px !important;
      line-height:1.45 !important;
    }

    .chip-remove{
      margin-inline-start:4px !important;
    }

    .table-footer{
      margin-top:8px !important;
      border:1px solid #e4eaf4 !important;
      padding:10px 14px !important;
      font-size:12px !important;
    }

    .legend-item{
      font-size:11px !important;
    }

    @media(max-width:1199px){
      .stats-row{
        grid-template-columns:repeat(2, minmax(0, 1fr)) !important;
      }
    }

    @media(max-width:991px){
      .app-wrapper{
        padding:14px !important;
      }

      .workspace{
        padding:4px !important;
      }

      .employee-scroll{
        max-height:220px !important;
        overflow-y:auto !important;
      }

      .stats-row{
        grid-template-columns:repeat(2, minmax(0, 1fr)) !important;
      }

      .schedule-wrap{
        max-height:65vh !important;
      }
    }

    @media(max-width:575px){
      .stats-row{
        grid-template-columns:1fr !important;
      }

      .page-title{
        font-size:20px !important;
      }

      .page-subtitle{
        font-size:13px !important;
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
      .employees-panel,
      .table-actions,
      .stats-row,
      .table-footer,
      .chip-remove{
        display:none !important;
      }

      .workspace{
        display:block;
      }

      .panel{
        box-shadow:none;
        border:0;
        border-radius:0;
      }

      .panel-header{
        padding:8px 0;
        border:0;
      }

      .schedule-wrap{
        overflow:visible;
        max-height:none;
      }

      .schedule-table{
        min-width:100%;
        font-size:10px;
      }

      .schedule-table thead th,
      .shift-cell{
        position:static !important;
      }

      .assignment-cell{
        height:auto;
        min-height:70px;
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
            واجهة مبسطة لمدير الفرع لتوزيع الموظفين حسب القسم، المسمى الوظيفي، والوردية، مع اعتماد نفس توزيع الموظف طوال الأسبوع.
          </p>
        </div>

        <div class="hero-actions">
          <button class="hero-btn" type="button" onclick="window.print()">
            <i class="bi bi-printer"></i>
            طباعة
          </button>
          <button class="hero-btn primary" type="button" id="btnSaveTop">
            <i class="bi bi-check2-circle"></i>
            حفظ الجدول
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
          <label class="form-label">حالة الجدول</label>
          <select class="form-select">
            <option>مسودة</option>
            <option>معتمد</option>
            <option>مرسل للموظفين</option>
          </select>
        </div>
      </div>
    </section>

    <section class="workspace">

      <aside class="panel employees-panel">
        <div class="panel-header">
          <div>
            <h2 class="panel-title">الموظفون</h2>
            <div class="panel-hint">اضغط على اسم الموظف لتحديد توزيعه الأسبوعي.</div>
          </div>
          <div class="panel-icon">
            <i class="bi bi-people"></i>
          </div>
        </div>

        <div class="employee-search">
          <div class="input-group">
            <span class="input-group-text bg-white border-end-0">
              <i class="bi bi-search"></i>
            </span>
            <input type="text" id="employeeSearch" class="form-control border-start-0" placeholder="بحث باسم الموظف...">
          </div>
        </div>

        <div class="employee-scroll" id="employeeList"></div>
      </aside>

      <main class="panel table-panel">
        <div class="panel-header">
          <div>
            <h2 class="panel-title">جدول التوزيع</h2>
            <div class="panel-hint">الأقسام والمسميات الوظيفية في الأعلى، والورديات في يمين الجدول كما في ملف الإكسل.</div>
          </div>

          <div class="table-actions">
            <button class="btn-soft" type="button" id="btnClear">
              <i class="bi bi-arrow-counterclockwise"></i>
              تفريغ
            </button>
            <button class="btn-soft" type="button" onclick="window.print()">
              <i class="bi bi-printer"></i>
              طباعة
            </button>
            <button class="btn-primary-prosto" type="button" id="btnSave">
              <i class="bi bi-save"></i>
              حفظ
            </button>
          </div>
        </div>

        <div class="stats-row">
          <div class="stat-card">
            <div>
              <div class="stat-label">إجمالي الموظفين</div>
              <div class="stat-value" id="totalEmployees">0</div>
            </div>
            <div class="stat-icon"><i class="bi bi-people"></i></div>
          </div>

          <div class="stat-card">
            <div>
              <div class="stat-label">تم توزيعهم</div>
              <div class="stat-value" id="assignedEmployees">0</div>
            </div>
            <div class="stat-icon"><i class="bi bi-check-circle"></i></div>
          </div>

          <div class="stat-card">
            <div>
              <div class="stat-label">غير موزعين</div>
              <div class="stat-value" id="unassignedEmployees">0</div>
            </div>
            <div class="stat-icon"><i class="bi bi-person-dash"></i></div>
          </div>

          <div class="stat-card">
            <div>
              <div class="stat-label">عدد الخانات</div>
              <div class="stat-value" id="totalSlots">0</div>
            </div>
            <div class="stat-icon"><i class="bi bi-grid-3x3-gap"></i></div>
          </div>
        </div>

        <div class="schedule-wrap">
          <table class="schedule-table" id="scheduleTable">
            <thead>
              <tr>
                <th class="shift-head" rowspan="2">الوردية</th>

                <th class="department-head dept-kitchen" colspan="3">المطبخ</th>
                <th class="department-head dept-front" colspan="3">اللاين الأمامي</th>
                <th class="department-head dept-hall" colspan="2">الصالة</th>
                <th class="department-head dept-admin" colspan="2">إداري</th>
              </tr>
              <tr>
                <th class="job-head">مسمى وظيفي 1</th>
                <th class="job-head">مسمى وظيفي 2</th>
                <th class="job-head">مسمى وظيفي 3</th>

                <th class="job-head">مسمى وظيفي 1</th>
                <th class="job-head">مسمى وظيفي 2</th>
                <th class="job-head">مسمى وظيفي 3</th>

                <th class="job-head">مسمى وظيفي 1</th>
                <th class="job-head">مسمى وظيفي 2</th>

                <th class="job-head">مسمى وظيفي 1</th>
                <th class="job-head">مسمى وظيفي 2</th>
              </tr>
            </thead>

            <tbody id="scheduleBody"></tbody>
          </table>
        </div>

        <div class="table-footer">
          <div class="legend">
            <span class="legend-item"><span class="legend-dot" style="background:var(--kitchen)"></span> المطبخ</span>
            <span class="legend-item"><span class="legend-dot" style="background:var(--front)"></span> اللاين الأمامي</span>
            <span class="legend-item"><span class="legend-dot" style="background:var(--hall)"></span> الصالة</span>
            <span class="legend-item"><span class="legend-dot" style="background:var(--admin)"></span> إداري</span>
          </div>
          <div>
            يمكن الضغط على الخلية مباشرة لإضافة موظف غير موزع.
          </div>
        </div>
      </main>

    </section>
  </div>

  <!-- Assign Employee Modal -->
  <div class="modal fade" id="assignModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">توزيع الموظف على جدول الأسبوع</h5>
          <button type="button" class="btn-close ms-0" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="selected-box" id="selectedEmployeeText">
            <i class="bi bi-person-check"></i>
            لم يتم اختيار موظف
          </div>

          <div class="row g-3">
            <div class="col-12">
              <label class="form-label">القسم</label>
              <select class="form-select" id="modalDepartment">
                <option value="">اختر القسم</option>
                <option>المطبخ</option>
                <option>اللاين الأمامي</option>
                <option>الصالة</option>
                <option>إداري</option>
              </select>
            </div>

            <div class="col-12">
              <label class="form-label">المسمى الوظيفي</label>
              <select class="form-select" id="modalJobTitle">
                <option value="">اختر المسمى الوظيفي</option>
              </select>
            </div>

            <div class="col-12">
              <label class="form-label">الوردية</label>
              <select class="form-select" id="modalShift">
                <option value="">اختر الوردية</option>
                <option>صباحي</option>
                <option>وسط</option>
                <option>مسائي</option>
              </select>
            </div>

            <div class="col-12">
              <label class="form-label">ملاحظات</label>
              <textarea class="form-control" id="modalNotes" rows="2" placeholder="ملاحظات اختيارية..."></textarea>
            </div>
          </div>

          <div class="alert alert-warning mt-3 mb-0 small rounded-3">
            <i class="bi bi-info-circle"></i>
            سيتم اعتماد هذا التوزيع للموظف طوال الأسبوع.
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary rounded-3" data-bs-dismiss="modal">إلغاء</button>
          <button type="button" class="btn btn-primary-prosto" id="btnAssignEmployee">
            <i class="bi bi-check2-circle"></i>
            اعتماد التوزيع
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Quick Add Modal -->
  <div class="modal fade" id="quickAddModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">إضافة موظف إلى الخانة</h5>
          <button type="button" class="btn-close ms-0" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <div class="quick-info mb-3" id="quickCellInfo"></div>

          <label class="form-label">اختر موظف غير موزع</label>
          <select class="form-select" id="quickEmployeeSelect"></select>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary rounded-3" data-bs-dismiss="modal">إلغاء</button>
          <button type="button" class="btn btn-primary-prosto" id="btnQuickAssign">
            <i class="bi bi-plus-circle"></i>
            إضافة
          </button>
        </div>
      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <script>
      const employees = [
          { id: 1, name: "أحمد محمد", code: "EMP-001" },
          { id: 2, name: "محمد خالد", code: "EMP-002" },
          { id: 3, name: "عمر علي", code: "EMP-003" },
          { id: 4, name: "يوسف سامر", code: "EMP-004" },
          { id: 5, name: "خالد ناصر", code: "EMP-005" },
          { id: 6, name: "سعيد أحمد", code: "EMP-006" },
          { id: 7, name: "عبدالله محمود", code: "EMP-007" },
          { id: 8, name: "محمود حسن", code: "EMP-008" },
          { id: 9, name: "أنس فراس", code: "EMP-009" },
          { id: 10, name: "لؤي رامي", code: "EMP-010" },
          { id: 11, name: "رامي فادي", code: "EMP-011" },
          { id: 12, name: "فراس وليد", code: "EMP-012" }
      ];

      const departments = [
          {
              name: "المطبخ",
              jobs: ["مسمى وظيفي 1", "مسمى وظيفي 2", "مسمى وظيفي 3"]
          },
          {
              name: "اللاين الأمامي",
              jobs: ["مسمى وظيفي 1", "مسمى وظيفي 2", "مسمى وظيفي 3"]
          },
          {
              name: "الصالة",
              jobs: ["مسمى وظيفي 1", "مسمى وظيفي 2"]
          },
          {
              name: "إداري",
              jobs: ["مسمى وظيفي 1", "مسمى وظيفي 2"]
          }
      ];

      const jobTitlesByDepartment = departments.reduce((acc, dept) => {
          acc[dept.name] = dept.jobs;
          return acc;
      }, {});

      const shifts = ["صباحي", "وسط", "مسائي"];

      const assignments = new Map();

      let selectedEmployeeId = null;
      let selectedCell = null;

      const employeeList = document.getElementById("employeeList");
      const employeeSearch = document.getElementById("employeeSearch");
      const scheduleBody = document.getElementById("scheduleBody");

      const assignModal = new bootstrap.Modal(document.getElementById("assignModal"));
      const quickAddModal = new bootstrap.Modal(document.getElementById("quickAddModal"));

      const selectedEmployeeText = document.getElementById("selectedEmployeeText");
      const modalDepartment = document.getElementById("modalDepartment");
      const modalJobTitle = document.getElementById("modalJobTitle");
      const modalShift = document.getElementById("modalShift");
      const modalNotes = document.getElementById("modalNotes");

      const quickCellInfo = document.getElementById("quickCellInfo");
      const quickEmployeeSelect = document.getElementById("quickEmployeeSelect");

      function getEmployeeById(id) {
          return employees.find(emp => emp.id === Number(id));
      }

      function getAssignmentByEmployee(id) {
          return assignments.get(Number(id));
      }

      function renderScheduleRows() {
          scheduleBody.innerHTML = "";

          shifts.forEach(shift => {
              const tr = document.createElement("tr");

              const shiftCell = document.createElement("td");
              shiftCell.className = "shift-cell";
              shiftCell.innerHTML = `<span>${shift}</span>`;
              tr.appendChild(shiftCell);

              departments.forEach(dept => {
                  dept.jobs.forEach(job => {
                      const td = document.createElement("td");
                      td.className = "assignment-cell empty";
                      td.dataset.dept = dept.name;
                      td.dataset.job = job;
                      td.dataset.shift = shift;
                      td.addEventListener("click", () => openQuickAdd(td));
                      tr.appendChild(td);
                  });
              });

              scheduleBody.appendChild(tr);
          });

          document.getElementById("totalSlots").textContent = document.querySelectorAll(".assignment-cell").length;
      }

      function renderEmployees() {
          const keyword = employeeSearch.value.trim().toLowerCase();
          employeeList.innerHTML = "";

          const filtered = employees.filter(emp =>
              emp.name.toLowerCase().includes(keyword) && !assignments.has(emp.id)
          );

          if (filtered.length === 0) {
              employeeList.innerHTML = `
          <div class="empty-state">
            <i class="bi bi-search"></i>
            لا يوجد موظفون غير موزعين
          </div>
        `;
              return;
          }

          filtered.forEach(emp => {
              const assignment = getAssignmentByEmployee(emp.id);
              const item = document.createElement("button");
              item.type = "button";
              item.className = "employee-item" + (assignment ? " is-assigned" : "");
              item.dataset.id = emp.id;

              item.innerHTML = `
          <span class="employee-main">
            <span class="avatar">${emp.name.charAt(0)}</span>
            <span class="employee-info">
              <span class="employee-name">${emp.name}</span>
              </span>
          </span>
        `;

              item.addEventListener("click", () => openAssignModal(emp.id));
              employeeList.appendChild(item);
          });

          updateSummary();
      }

      function openAssignModal(employeeId) {
          selectedEmployeeId = employeeId;
          const emp = getEmployeeById(employeeId);
          const assignment = getAssignmentByEmployee(employeeId);

          selectedEmployeeText.innerHTML = `<i class="bi bi-person-check"></i> ${emp.name}`;

          modalDepartment.value = assignment?.department || "";
          fillJobTitles(modalDepartment.value);
          modalJobTitle.value = assignment?.jobTitle || "";
          modalShift.value = assignment?.shift || "";
          modalNotes.value = assignment?.notes || "";

          assignModal.show();
      }

      function fillJobTitles(department) {
          modalJobTitle.innerHTML = `<option value="">اختر المسمى الوظيفي</option>`;

          if (!department || !jobTitlesByDepartment[department]) return;

          jobTitlesByDepartment[department].forEach(job => {
              const option = document.createElement("option");
              option.textContent = job;
              option.value = job;
              modalJobTitle.appendChild(option);
          });
      }

      modalDepartment.addEventListener("change", () => {
          fillJobTitles(modalDepartment.value);
      });

      document.getElementById("btnAssignEmployee").addEventListener("click", () => {
          const department = modalDepartment.value;
          const jobTitle = modalJobTitle.value;
          const shift = modalShift.value;
          const notes = modalNotes.value.trim();

          if (!selectedEmployeeId || !department || !jobTitle || !shift) {
              alert("يرجى اختيار القسم والمسمى الوظيفي والوردية.");
              return;
          }

          assignments.set(Number(selectedEmployeeId), {
              employeeId: Number(selectedEmployeeId),
              department,
              jobTitle,
              shift,
              notes
          });

          renderTableAssignments();
          renderEmployees();
          assignModal.hide();
      });

      function renderTableAssignments() {
          document.querySelectorAll(".assignment-cell").forEach(cell => {
              cell.innerHTML = "";
              cell.classList.add("empty");
          });

          assignments.forEach(assignment => {
              const cell = findCell(assignment.department, assignment.jobTitle, assignment.shift);
              if (!cell) return;

              const emp = getEmployeeById(assignment.employeeId);
              const chip = document.createElement("div");
              chip.className = "employee-chip";
              chip.innerHTML = `
          <span>
            <span class="chip-name">${emp.name}</span>
            ${assignment.notes ? `<span class="chip-note">${assignment.notes}</span>` : ""}
          </span>
          <button type="button" class="chip-remove" title="إزالة" data-id="${emp.id}">
            <i class="bi bi-x"></i>
          </button>
        `;

              chip.querySelector(".chip-remove").addEventListener("click", (event) => {
                  event.stopPropagation();
                  assignments.delete(emp.id);
                  renderTableAssignments();
                  renderEmployees();
              });

              cell.classList.remove("empty");
              cell.appendChild(chip);
          });

          updateSummary();
      }

      function findCell(department, jobTitle, shift) {
          return document.querySelector(
              `.assignment-cell[data-dept="${CSS.escape(department)}"][data-job="${CSS.escape(jobTitle)}"][data-shift="${CSS.escape(shift)}"]`
          );
      }

      function openQuickAdd(cell) {
          selectedCell = cell;

          quickCellInfo.innerHTML = `
        <strong>القسم:</strong> ${cell.dataset.dept}<br>
        <strong>المسمى الوظيفي:</strong> ${cell.dataset.job}<br>
        <strong>الوردية:</strong> ${cell.dataset.shift}
      `;

          quickEmployeeSelect.innerHTML = "";
          const unassigned = employees.filter(emp => !assignments.has(emp.id));

          if (unassigned.length === 0) {
              quickEmployeeSelect.innerHTML = `<option value="">لا يوجد موظفون غير موزعين</option>`;
          } else {
              quickEmployeeSelect.innerHTML = `<option value="">اختر الموظف</option>`;
              unassigned.forEach(emp => {
                  const option = document.createElement("option");
                  option.value = emp.id;
                  option.textContent = `${emp.name}`;
                  quickEmployeeSelect.appendChild(option);
              });
          }

          quickAddModal.show();
      }

      document.getElementById("btnQuickAssign").addEventListener("click", () => {
          if (!selectedCell || !quickEmployeeSelect.value) {
              alert("يرجى اختيار الموظف.");
              return;
          }

          assignments.set(Number(quickEmployeeSelect.value), {
              employeeId: Number(quickEmployeeSelect.value),
              department: selectedCell.dataset.dept,
              jobTitle: selectedCell.dataset.job,
              shift: selectedCell.dataset.shift,
              notes: ""
          });

          renderTableAssignments();
          renderEmployees();
          quickAddModal.hide();
      });

      employeeSearch.addEventListener("input", renderEmployees);

      document.getElementById("btnClear").addEventListener("click", () => {
          if (confirm("هل أنت متأكد من تفريغ جدول التوزيع؟")) {
              assignments.clear();
              renderTableAssignments();
              renderEmployees();
          }
      });

      function saveSchedule() {
          const payload = Array.from(assignments.values());

          console.log("Weekly Schedule Payload:", payload);

          alert("تم تجهيز بيانات الجدول للحفظ. يمكنك ربط الـ payload مع قاعدة البيانات من خلال Code Behind.");
      }

      document.getElementById("btnSave").addEventListener("click", saveSchedule);
      document.getElementById("btnSaveTop").addEventListener("click", saveSchedule);

      function updateSummary() {
          document.getElementById("totalEmployees").textContent = employees.length;
          document.getElementById("assignedEmployees").textContent = assignments.size;
          document.getElementById("unassignedEmployees").textContent = employees.length - assignments.size;
      }

      renderScheduleRows();
      renderEmployees();
      renderTableAssignments();
  </script>
</body>
</html>