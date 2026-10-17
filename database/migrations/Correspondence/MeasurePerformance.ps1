param([int]$Actor=1)
$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
try {
 $db.Open()
 foreach($procedure in @('Select_Correspondence_Threads_ByUserID','Select_Correspondence_UnreadCount')) {
  $times=@()
  for($i=0;$i -lt 5;$i++) {
   $cmd=$db.CreateCommand();$cmd.CommandType='StoredProcedure';$cmd.CommandText=$procedure;$cmd.CommandTimeout=20
   [void]$cmd.Parameters.AddWithValue('@Actor',$Actor)
   $watch=[Diagnostics.Stopwatch]::StartNew();$reader=$cmd.ExecuteReader()
   while($reader.Read()){};$reader.Close();$watch.Stop();$cmd.Dispose()
   $times+=$watch.ElapsedMilliseconds
  }
  [pscustomobject]@{Procedure=$procedure;Milliseconds=$times;MedianMs=($times|Sort-Object)[2]}|ConvertTo-Json -Compress
 }
} finally {$db.Dispose()}
