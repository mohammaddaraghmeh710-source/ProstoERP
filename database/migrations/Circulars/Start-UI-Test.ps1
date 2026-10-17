$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$stage=Join-Path $root 'tmp/circulars-stage';$portal=Join-Path $root 'ERP_Prosto/Portal'
$testDb=[IO.File]::ReadAllText((Join-Path $root 'tmp/circulars-test-database.txt')).Trim()
if($testDb -notmatch '^Prosto_Circulars_Test_[a-f0-9]{32}$'){throw 'Unexpected isolated database name'}
[void][IO.Directory]::CreateDirectory("$stage/bin");[void][IO.Directory]::CreateDirectory("$stage/Modules/Circulars")
Get-ChildItem "$root/tmp/circulars-portal-build" -File|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination "$stage/bin" -Force}
Get-ChildItem "$portal/Modules/Circulars" -File|Where-Object {$_.Extension -in @('.aspx','.config')}|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination "$stage/Modules/Circulars" -Force}
$cfg=[xml](Get-Content "$portal/Web.config");$setting=$cfg.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection'
$cs=[Data.SqlClient.SqlConnectionStringBuilder]::new([string]$setting.connectionString);$cs['Initial Catalog']=$testDb;$setting.connectionString=$cs.ConnectionString;$cfg.Save("$stage/Web.config")
$cn=[Data.SqlClient.SqlConnection]::new($cs.ConnectionString)
try{$cn.Open();$cmd=$cn.CreateCommand();$cmd.CommandText='SELECT TOP(1) FileBytes FROM Circulars ORDER BY ID';$bytes=[byte[]]$cmd.ExecuteScalar();[IO.File]::WriteAllBytes("$root/tmp/circulars-upload-test.pdf",$bytes)}finally{$cn.Dispose()}
$master=@'
<%@ Master Language="VB" %>
<!doctype html><html lang="ar" dir="rtl"><head runat="server"><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Circulars UI Test</title>
<link rel="stylesheet" href="/assets/vendor/fonts/boxicons.css"/><link rel="stylesheet" href="/assets/vendor/css/rtl/core.css"/><link rel="stylesheet" href="/assets/vendor/css/rtl/theme-default.css"/>
<link rel="stylesheet" href="/assets/vendor/libs/select2/select2.css"/><link rel="stylesheet" href="/assets/vendor/libs/datatables-bs5/datatables.bootstrap5.css"/><link rel="stylesheet" href="/assets/css/erp-theme.css"/>
<asp:ContentPlaceHolder ID="HeadContent" runat="server"/></head><body class="erp-ui"><form runat="server"><asp:ContentPlaceHolder ID="ContentPlaceHolder1" runat="server"/></form>
<script src="/assets/vendor/libs/jquery/jquery.js"></script><script src="/assets/vendor/js/bootstrap.js"></script><script src="/assets/vendor/libs/select2/select2.js"></script><script src="/assets/vendor/libs/datatables/jquery.dataTables.js"></script><script src="/assets/vendor/libs/datatables-bs5/datatables-bootstrap5.js"></script><script src="/assets/vendor/libs/datatables-responsive/datatables.responsive.js"></script>
</body></html>
'@
[IO.File]::WriteAllText("$stage/Site.Master",$master,[Text.UTF8Encoding]::new($true))
$entry=@'
<%@ Page Language="VB" %>
<script runat="server">
Protected Sub Page_Load(sender As Object,e As EventArgs)
 If Not Request.IsLocal Then Throw New HttpException(403,"Local test only")
 Dim c=System.Configuration.ConfigurationManager.ConnectionStrings("Prosto_ERP_ConnectionConnection").ConnectionString
 If Not New System.Data.SqlClient.SqlConnectionStringBuilder(c).InitialCatalog.StartsWith("Prosto_Circulars_Test_") Then Throw New HttpException(403,"Isolated database required")
 Dim actor=If(Request.QueryString("actor")="2",2,1)
 CRM.SessionManager.GetInstance.Users=New CRM.UserEntity With {.UserID=actor,.UserType=If(actor=1,1,4),.NameAr="اختبار التعاميم"}
 Response.Redirect("/Modules/Circulars/Index.aspx" & If(actor=1,"?admin=1",""))
End Sub
</script>
'@
[IO.File]::WriteAllText("$stage/UiEntry.aspx",$entry,[Text.UTF8Encoding]::new($true))
$hostConfig=[xml][IO.File]::ReadAllText("$root/ERP_Prosto/.vs/ERP_Prosto/config/applicationhost.config")
$sites=$hostConfig.configuration.'system.applicationHost'.sites;foreach($site in @($sites.site)){[void]$sites.RemoveChild($site)}
$site=$hostConfig.CreateElement('site');$site.SetAttribute('name','CircularsUiTest');$site.SetAttribute('id','76')
$app=$hostConfig.CreateElement('application');$app.SetAttribute('path','/');$app.SetAttribute('applicationPool','Clr4IntegratedAppPool')
foreach($pair in @(@('/',$stage),@('/assets',"$portal/assets"))){$v=$hostConfig.CreateElement('virtualDirectory');$v.SetAttribute('path',$pair[0]);$v.SetAttribute('physicalPath',([IO.Path]::GetFullPath($pair[1])).Replace('/','\'));[void]$app.AppendChild($v)}
[void]$site.AppendChild($app);$bindings=$hostConfig.CreateElement('bindings');$binding=$hostConfig.CreateElement('binding');$binding.SetAttribute('protocol','http');$binding.SetAttribute('bindingInformation','*:52249:localhost');[void]$bindings.AppendChild($binding);[void]$site.AppendChild($bindings);[void]$sites.AppendChild($site)
$configPath="$root/tmp/circulars-ui-host.config";$hostConfig.Save($configPath)
$p=Start-Process 'C:/Program Files/IIS Express/iisexpress.exe' -ArgumentList "/config:$configPath",'/site:CircularsUiTest','/systray:false' -WindowStyle Hidden -PassThru -RedirectStandardOutput "$root/tmp/circulars-ui-iis.log" -RedirectStandardError "$root/tmp/circulars-ui-iis-error.log"
$p.Id|Set-Content "$root/tmp/circulars-ui-iis.pid"
'Isolated UI ready: http://localhost:52249/UiEntry.aspx (actor=2 for employee).'
