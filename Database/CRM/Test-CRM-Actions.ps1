$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$tx=$null
function Q([string]$sql,[hashtable]$parameters=@{}) {
 $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$sql
 foreach($key in $parameters.Keys){if($key -eq '@v'){$p=$cmd.Parameters.Add($key,[Data.SqlDbType]::Binary,8);$p.Value=$parameters[$key]}else{[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])}}
 $table=[Data.DataTable]::new();try{[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($table)}finally{$cmd.Dispose()};return ,$table
}
function Assert([bool]$ok,[string]$message){if(-not $ok){throw $message}}
function NewRecord([string]$entity,[string]$extra='') {
 $name='CRM actions '+[guid]::NewGuid()
 return (Q "EXEC CRM_Save_$entity @Actor_ID=@a,@Data=@x" @{'@a'=$admin;'@x'="<row><Name_AR>$name</Name_AR>$extra</row>"}).Rows[0]
}
function DeleteRecord([string]$entity,$record,[int]$actor) {
 [void](Q 'EXEC CRM_Delete @Actor_ID=@a,@Entity=@e,@ID=@id,@Version=@v' @{'@a'=$actor;'@e'=$entity;'@id'=$record.ID;'@v'=$record.Row_Version})
}
try {
 $db.Open()
 $users=(Q 'SELECT (SELECT TOP(1) ID FROM UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) A,(SELECT TOP(1) ID FROM UsersMembers WHERE Type<>1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) U').Rows[0]
 $admin=[int]$users.A;$other=[int]$users.U
 $tx=$db.BeginTransaction()
 $account=NewRecord 'Accounts' "<Owner_ID>$other</Owner_ID>"
 foreach($entity in @('Account_Types','Contract_Types','Payment_Methods','Contacts','Accounts')) {
  $actor=$admin
  if($entity -eq 'Accounts'){$record=$account;$actor=$other}
  elseif($entity -eq 'Contacts'){$record=NewRecord $entity "<Account_ID>$($account.ID)</Account_ID>";$actor=$other}
  else{$record=NewRecord $entity}
  foreach($active in @(0,1)){
   [void](Q 'EXEC CRM_Set_Active @Actor_ID=@a,@Entity=@e,@ID=@id,@Is_Active=@s,@Version=@v' @{'@a'=$actor;'@e'=$entity;'@id'=$record.ID;'@s'=$active;'@v'=$record.Row_Version})
   $record=(Q "EXEC CRM_Select_$entity @Actor_ID=@a,@ID=@id" @{'@a'=$actor;'@id'=$record.ID}).Rows[0]
   Assert ([int]$record.Is_Active -eq $active) "$entity status mismatch"
  }
  DeleteRecord $entity $record $actor
  Assert ((Q "EXEC CRM_Select_$entity @Actor_ID=@a,@ID=@id" @{'@a'=$admin;'@id'=$record.ID}).Rows.Count -eq 0) "$entity still listed after deletion"
  $stored=(Q "SELECT Is_Deleted,Is_Active,Modified_User FROM CRM_$entity WHERE ID=@id" @{'@id'=$record.ID}).Rows[0]
  Assert ($stored.Is_Deleted -and -not $stored.Is_Active -and $stored.Modified_User -eq $actor) "$entity soft-delete metadata mismatch"
  $audit=(Q 'SELECT COUNT(*) N FROM CRM_Activity_Logs WHERE Entity=@e AND Record_ID=@id AND Before_Data IS NOT NULL AND After_Data IS NOT NULL' @{'@e'=$entity;'@id'=$record.ID}).Rows[0].N
  Assert ($audit -eq 3) "$entity missing activate/deactivate/delete audit"
  Write-Output "PASS $entity activate/deactivate/delete, hidden row and retained audit"
 }
 $tx.Rollback();$tx=$null
 foreach($case in @('LinkedAccount','LinkedType','StaleVersion','UnauthorizedOwner','UnauthorizedLookup')){
  $tx=$db.BeginTransaction()
  $entity='Accounts';$actor=$admin;$expected=51201
  if($case -eq 'LinkedType'){$entity='Account_Types';$record=NewRecord $entity;$child=NewRecord 'Accounts' "<Account_Type_ID>$($record.ID)</Account_Type_ID>"}
  elseif($case -eq 'UnauthorizedLookup'){$entity='Payment_Methods';$record=NewRecord $entity;$actor=$other;$expected=51200}
  else{$record=NewRecord $entity}
  if($case -eq 'LinkedAccount'){$child=NewRecord 'Contacts' "<Account_ID>$($record.ID)</Account_ID>"}
  if($case -eq 'StaleVersion'){[void](Q 'EXEC CRM_Set_Active @Actor_ID=@a,@Entity=@e,@ID=@id,@Is_Active=0,@Version=@v' @{'@a'=$admin;'@e'=$entity;'@id'=$record.ID;'@v'=$record.Row_Version})}
  if($case -eq 'UnauthorizedOwner'){$actor=$other;$expected=51200}
  try{DeleteRecord $entity $record $actor;throw "Expected rejection: $case"}
  catch{$errorDetail=$_.Exception;while($errorDetail.InnerException){$errorDetail=$errorDetail.InnerException};if($errorDetail -isnot [Data.SqlClient.SqlException] -or $errorDetail.Number -ne $expected){throw}}
  if($tx.Connection){$tx.Rollback()};$tx=$null
  Write-Output "PASS rejection: $case"
 }
}finally{if($tx -and $tx.Connection){$tx.Rollback()};$db.Dispose()}
Write-Output 'All test data rolled back.'
