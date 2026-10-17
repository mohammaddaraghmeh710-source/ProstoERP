$ErrorActionPreference='Stop'
$config=[xml](Get-Content (Join-Path $PSScriptRoot '../../../src/Portal/Web.config'))
$db=[Data.SqlClient.SqlConnection]::new([string]($config.configuration.connectionStrings.add|Where-Object name -eq 'Prosto_ERP_ConnectionConnection').connectionString)
$tx=$null
function Q([string]$sql,[hashtable]$parameters=@{}){$cmd=$db.CreateCommand();$cmd.Transaction=$tx;$cmd.CommandText=$sql;foreach($key in $parameters.Keys){[void]$cmd.Parameters.AddWithValue($key,$parameters[$key])};$t=[Data.DataTable]::new();try{[void]([Data.SqlClient.SqlDataAdapter]::new($cmd)).Fill($t)}finally{$cmd.Dispose()};return ,$t}
function Assert([bool]$ok,[string]$msg){if(-not $ok){throw $msg}}
try{
 $db.Open();$tx=$db.BeginTransaction()
 $f=(Q @'
DECLARE @u int,@b int,@c1 int,@c2 int,@c3 int,@role int,@doc int;
SELECT TOP(1) @u=ID,@b=Brand_ID FROM UsersMembers WHERE Type=7 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND Brand_ID IS NOT NULL;
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,IsActive,IsDeleted) VALUES(@b,N'Multi test A',1,0);SET @c1=SCOPE_IDENTITY();
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,IsActive,IsDeleted) VALUES(@b,N'Multi test B',1,0);SET @c2=SCOPE_IDENTITY();
INSERT Work_Guide_Categories(Brand_ID,Title_Ar,IsActive,IsDeleted) VALUES(@b,N'Multi test blocked',1,0);SET @c3=SCOPE_IDENTITY();
INSERT Work_Guide_Roles(Title_Ar,Code,IsActive,IsDeleted) VALUES(N'Multi test role',CONVERT(nvarchar(36),NEWID()),1,0);SET @role=SCOPE_IDENTITY();
INSERT Work_Guide_Role_Permissions(Role_ID,Can_View_Category,Can_View_Document,Can_Download_Document,Can_Print_Document) VALUES(@role,1,1,1,0);
INSERT Work_Guide_User_Category_Roles(User_ID,Brand_ID,Category_ID,Role_ID,Apply_To_Children,IsActive,IsDeleted) VALUES(@u,@b,@c1,@role,0,1,0),(@u,@b,@c2,@role,0,1,0);
INSERT Work_Guide_Documents(Brand_ID,Category_ID,Title_Ar,IsActive,IsDeleted,Is_Download_Allowed,AddedDate) SELECT TOP(62) @b,@c1,N'Multi test document A',1,0,1,GETDATE() FROM sys.all_objects;
INSERT Work_Guide_Documents(Brand_ID,Category_ID,Title_Ar,IsActive,IsDeleted,Is_Download_Allowed,AddedDate) VALUES(@b,@c2,N'Multi test document B',1,0,0,GETDATE());SET @doc=SCOPE_IDENTITY();
INSERT Work_Guide_Documents(Brand_ID,Category_ID,Title_Ar,IsActive,IsDeleted,Is_Download_Allowed,AddedDate) VALUES(@b,@c3,N'Multi test blocked document',1,0,1,GETDATE());
SELECT @u U,@b B,@c1 C1,@c2 C2,@c3 C3,@doc Doc;
'@).Rows[0]
 $base='EXEC dbo.Select_Work_Guide_View_Documents_Multi @User_ID=@u,@Brand_ID=@b,@Category_IDs=@x'
 $p=@{'@u'=$f.U;'@b'=$f.B;'@x'="<items><item id='$($f.C1)'/><item id='$($f.C2)'/><item id='$($f.C1)'/><item id='$($f.C3)'/></items>"}
 $rows=Q $base $p
 Assert ($rows.Rows.Count -eq 63) 'Multi-category union / duplicates / all rows failed'
 Assert (@($rows.Rows|Where-Object Category_ID -eq $f.C3).Count -eq 0) 'Unauthorized category leaked'
 Assert (-not ($rows.Rows|Where-Object ID -eq $f.Doc).Can_Download_Document) 'Document download restriction lost'
 $p['@x']="<items><item id='$($f.C1)'/></items>";Assert ((Q $base $p).Rows.Count -eq 62) 'Single selection failed'
 $p['@x']='<items/>';Assert ((Q ($base+",@Search_Text=N'Multi test document'") $p).Rows.Count -eq 63) 'Empty selection / name search failed'
 $p['@b']=-1;Assert ((Q $base $p).Rows.Count -eq 0) 'Cross-brand access leak'
 Write-Output 'PASS multi-select union, no duplicate rows, more than 50 rows, search, no-selection, brand isolation and download permissions'
}finally{if($tx -and $tx.Connection){$tx.Rollback()};$db.Dispose()}
