$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$cn=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$cn.Open()
function Run([string]$sql){$c=$cn.CreateCommand();$c.CommandText=$sql;try{[void]$c.ExecuteNonQuery()}finally{$c.Dispose()}}
try {
 Run ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'TestTypesAndApplicant.sql')))
 'PASS dynamic type/topic/request; automatic employee source; stable contact/organization snapshots and routing after profile change; anonymous contact privacy; owner access; source statistics; type editing and disabling.'
 foreach($sql in @(
  "EXEC dbo.Select_Employee_Feedback_Types @Actor=151,@Mode=1",
  "EXEC dbo.Save_Employee_Feedback_Type @Actor=151,@ID=0,@TitleAr=N'Test',@TitleEn=N'Test',@Order=1,@Active=1",
  "EXEC dbo.Select_Employee_Feedback_Contact @Actor=152,@ID=6",
  "EXEC dbo.Delete_Employee_Feedback_Type @Actor=1,@ID=1,@Version=0x0000000000000000"
 )) {
  $denied=$false
  try{Run $sql}catch{
   $e=$_.Exception;while($e.InnerException){$e=$e.InnerException}
   if($e -is [Data.SqlClient.SqlException] -and $e.Number -eq 51500){$denied=$true}else{throw}
  }
  if(-not $denied){throw 'Expected permission/linked-type rejection'}
 }
 Run "BEGIN TRAN; DECLARE @V binary(8)=(SELECT RowVersion FROM dbo.Employee_Feedback_Types WHERE ID=1); BEGIN TRY EXEC dbo.Delete_Employee_Feedback_Type @Actor=1,@ID=1,@Version=@V; ROLLBACK; THROW 51000,'Linked type deletion unexpectedly succeeded',1; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; IF ERROR_NUMBER()<>51500 THROW; END CATCH;"
 'PASS unauthorized type management/contact access and deletion of linked types denied.'
}finally{
 if($cn.State -eq 'Open'){Run 'IF @@TRANCOUNT>0 ROLLBACK'}
 $cn.Dispose()
}
