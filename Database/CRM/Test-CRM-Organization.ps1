$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$tx=$null
function Q([string]$sql,[hashtable]$parameters=@{}) {
 $cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$sql
 foreach($key in $parameters.Keys){if($key -eq '@v'){$p=$cmd.Parameters.Add($key,[Data.SqlDbType]::Binary,8);$p.Value=$parameters[$key]}else{[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])}}
 $t=[Data.DataTable]::new();try{[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($t)}finally{$cmd.Dispose()};return ,$t
}
function Assert([bool]$ok,[string]$message){if(-not $ok){throw $message}}
function Payload([string]$brand,[string]$branch='') {return "<row><Name_AR>CRM organization $([guid]::NewGuid())</Name_AR><Brand_ID>$brand</Brand_ID><Branch_ID>$branch</Branch_ID><Owner_ID>$other</Owner_ID><Is_Active>0</Is_Active></row>"}
try {
 $db.Open()
 $ids=(Q 'SELECT (SELECT TOP(1) ID FROM UsersMembers WHERE Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) A,(SELECT TOP(1) ID FROM UsersMembers WHERE Type NOT IN (1,7) AND IsActive=1 AND ISNULL(IsDeleted,0)=0 ORDER BY ID) U').Rows[0]
 $admin=[int]$ids.A;$other=[int]$ids.U
 $branch=(Q 'SELECT TOP(1) br.ID,br.BrandID FROM Branches br JOIN Brands b ON b.ID=br.BrandID WHERE br.IsActive=1 AND ISNULL(br.IsDeleted,0)=0 AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 ORDER BY br.ID').Rows[0]
 $brand=[int]$branch.BrandID;$branchID=[int]$branch.ID
 $second=(Q 'SELECT TOP(1) ID FROM Brands WHERE ID<>@b AND IsActive=1 AND ISNULL(IsDeleted,0)=0' @{'@b'=$brand}).Rows[0].ID
 Assert ($admin -gt 0 -and $other -gt 0 -and $brand -gt 0 -and $branchID -gt 0 -and $second -gt 0) 'Requires admin, employee, two brands and one branch.'
 $tx=$db.BeginTransaction()
 $before=(Q 'EXEC CRM_Dashboard_Counts @Actor_ID=@a' @{'@a'=$admin}).Rows[0]
 $account=(Q 'EXEC CRM_Save_Accounts @Actor_ID=@a,@Data=@x' @{'@a'=$admin;'@x'=(Payload $brand)}).Rows[0]
 $stored=(Q 'EXEC CRM_Select_Accounts @Actor_ID=@a,@ID=@id' @{'@a'=$other;'@id'=$account.ID}).Rows[0]
 Assert ($stored.Brand_ID -eq $brand -and $stored.IsNull('Branch_ID') -and -not $stored.Is_Active) 'Brand-only inactive customer save failed.'
 $edited=(Q 'EXEC CRM_Save_Accounts @Actor_ID=@a,@ID=@id,@Version=@v,@Data=@x' @{'@a'=$other;'@id'=$account.ID;'@v'=$account.Row_Version;'@x'=(Payload $brand $branchID)}).Rows[0]
 $stored=(Q 'EXEC CRM_Select_Accounts @Actor_ID=@a,@ID=@id' @{'@a'=$admin;'@id'=$account.ID}).Rows[0]
 Assert ($stored.Brand_ID -eq $brand -and $stored.Branch_ID -eq $branchID -and $stored.Owner_ID -eq $other -and $stored.Brand_Name -ne [DBNull]::Value -and $stored.Branch_Name -ne [DBNull]::Value) 'Owner edit / organization display failed.'
 [void](Q 'EXEC CRM_Save_Accounts @Actor_ID=@a,@ID=@id,@Version=@v,@Data=@x' @{'@a'=$admin;'@id'=$account.ID;'@v'=$edited.Row_Version;'@x'=(Payload $second)})
 $stored=(Q 'EXEC CRM_Select_Accounts @Actor_ID=@a,@ID=@id' @{'@a'=$admin;'@id'=$account.ID}).Rows[0]
 Assert ($stored.Brand_ID -eq $second -and $stored.IsNull('Branch_ID')) 'Changing brand / clearing optional branch failed.'
 $audit=(Q "SELECT COUNT(*) N FROM CRM_Activity_Logs WHERE Account_ID=@id AND After_Data.exist('/row/Brand_ID')=1" @{'@id'=$account.ID}).Rows[0].N
 Assert ($audit -eq 3) 'Organization changes missing from atomic audit.'
 $counts=(Q 'EXEC CRM_Dashboard_Counts @Actor_ID=@a' @{'@a'=$admin}).Rows[0]
 Assert ($counts.Accounts -eq $before.Accounts+1 -and $counts.Account_Types -eq $before.Account_Types -and $counts.Contacts -eq $before.Contacts) 'Dashboard count failed for inactive account.'
 [void](Q 'EXEC CRM_Delete @Actor_ID=@a,@Entity=@e,@ID=@id,@Version=@v' @{'@a'=$admin;'@e'='Accounts';'@id'=$stored.ID;'@v'=$stored.Row_Version})
 $counts=(Q 'EXEC CRM_Dashboard_Counts @Actor_ID=@a' @{'@a'=$admin}).Rows[0]
 Assert ($counts.Accounts -eq $before.Accounts) 'Dashboard includes deleted account.'
 $tx.Rollback();$tx=$null
 Write-Output 'PASS brand required, optional branch, owner edit, brand switch, names, audit and counts (including inactive / excluding deleted).'
 foreach($case in @('MissingBrand','MalformedBrand','UnknownBrand','MalformedBranch','UnknownBranch','CrossBrandBranch','InactiveBrand','InactiveBranch','StaleVersion','UnauthorizedEdit','UnauthorizedCounts')) {
  $tx=$db.BeginTransaction()
  $actor=$admin;$sql='EXEC CRM_Save_Accounts @Actor_ID=@a,@Data=@x';$parameters=@{'@a'=$actor;'@x'=(Payload $brand $branchID)};$expected=51201
  switch($case) {
   'MissingBrand' {$parameters['@x']=Payload ''}
   'MalformedBrand' {$parameters['@x']=Payload 'abc'}
   'UnknownBrand' {$parameters['@x']=Payload '2147483647'}
   'MalformedBranch' {$parameters['@x']=Payload $brand 'abc'}
   'UnknownBranch' {$parameters['@x']=Payload $brand '2147483647'}
   'CrossBrandBranch' {$parameters['@x']=Payload $second $branchID}
   'InactiveBrand' {[void](Q 'UPDATE Brands SET IsActive=0 WHERE ID=@b' @{'@b'=$brand})}
   'InactiveBranch' {[void](Q 'UPDATE Branches SET IsActive=0 WHERE ID=@b' @{'@b'=$branchID})}
   'StaleVersion' {
    $row=(Q $sql $parameters).Rows[0];[void](Q 'EXEC CRM_Set_Active @Actor_ID=@a,@Entity=@e,@ID=@id,@Is_Active=1,@Version=@v' @{'@a'=$admin;'@e'='Accounts';'@id'=$row.ID;'@v'=$row.Row_Version})
    $sql='EXEC CRM_Save_Accounts @Actor_ID=@a,@ID=@id,@Version=@v,@Data=@x';$parameters['@id']=$row.ID;$parameters['@v']=$row.Row_Version
   }
   'UnauthorizedEdit' {
    $parameters['@x']=(Payload $brand).Replace("<Owner_ID>$other</Owner_ID>","<Owner_ID>$admin</Owner_ID>");$row=(Q $sql $parameters).Rows[0]
    $sql='EXEC CRM_Save_Accounts @Actor_ID=@a,@ID=@id,@Version=@v,@Data=@x';$parameters['@a']=$other;$parameters['@id']=$row.ID;$parameters['@v']=$row.Row_Version
   }
   'UnauthorizedCounts' {$sql='EXEC CRM_Dashboard_Counts @Actor_ID=@a';$parameters=@{'@a'=$other};$expected=51200}
  }
  try {[void](Q $sql $parameters);throw "Expected rejection: $case"} catch {$detail=$_.Exception;while($detail.InnerException){$detail=$detail.InnerException};if($detail -isnot [Data.SqlClient.SqlException] -or $detail.Number -ne $expected){throw}}
  if($tx.Connection){$tx.Rollback()};$tx=$null
  Write-Output "PASS rejection: $case"
 }
} finally {if($tx -and $tx.Connection){$tx.Rollback()};$db.Dispose()}
Write-Output 'All test writes rolled back.'
