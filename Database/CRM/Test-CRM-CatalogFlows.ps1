# Runs inside the shared isolated ASP.NET management test host.
foreach($catalog in @(@('Contract_Types','أنواع العقود','نوع العقد'),@('Payment_Methods','طرق الدفع','طريقة الدفع'))) {
 $entity=$catalog[0];$script:target='/Modules/CRM_'+$entity+'/ManageCRM'+$entity.Replace('_','')+'.aspx';$script:testActor=1
 $page=$hostObject.Request($target,$null);CheckHtml $page;CheckCounts $page 0 0 0
 Assert ($page -match 'typeDeleteModal' -and $page -notmatch 'return confirm\(|href="(?:Add|Edit)CRM') 'Catalog kept old navigation/confirmation.'
 $page=Post $page ($prefix+'btnNewType')
 Assert ($page -match ('إضافة '+$(if($entity -eq 'Contract_Types'){'نوع عقد'}else{'طريقة دفع'}))) 'Catalog editor uses the wrong title.'
 $name=$catalog[1]+' من الاختبار'
 $page=Post $page ($prefix+'btnSaveType') (EditorValues $name)
 Assert ($page -match ('تمت إضافة '+$catalog[2]+' بنجاح')) 'Catalog create failed.';CheckCounts $page 1 1 0
 $id=[int](Q $test.ConnectionString ('SELECT ID FROM CRM_'+$entity+' WHERE Name_AR=@name') @{'@name'=$name}).Rows[0].ID
 $page=Post $page ($prefix+'btnSearch') @{'filterName'='not-found'};Assert ((CountRows $page) -eq 0) 'Catalog name search failed.';CheckCounts $page 1 1 0
 $page=Post $page ($prefix+'btnReset')
 $page=Post $page (Action $page 'تعديل')
 $page=Post $page ($prefix+'btnSaveType') (EditorValues ($name+' معدل') 'ملاحظات & محفوظة')
 Assert ($page -match 'تم حفظ تعديلات' -and $page -match 'ملاحظات &amp; محفوظة') 'Catalog inline edit failed.'
 $page=Post $page (Action $page 'إيقاف');CheckCounts $page 1 0 1
 $page=Post $page ($prefix+'btnSearch') @{'filterStatus'='1'};Assert ((CountRows $page) -eq 0) 'Catalog status filter failed.'
 $page=Post $page ($prefix+'btnReset');$page=Post $page (Action $page 'تفعيل');CheckCounts $page 1 1 0
 $fixture=if($entity -eq 'Contract_Types'){'contract-types.html'}else{'payment-methods.html'}
 [IO.File]::WriteAllText((Join-Path $output $fixture),$page,[Text.UTF8Encoding]::new($true))
 $page=Post $page (Action $page 'حذف')
 Assert ($page -match "getElementById\('typeDeleteModal'\)") 'Catalog delete confirmation missing.'
 Assert (-not(Q $test.ConnectionString ('SELECT Is_Deleted FROM CRM_'+$entity+' WHERE ID=@id') @{'@id'=$id}).Rows[0].Is_Deleted) 'Catalog deleted before confirmation.'
 $page=Post $page ($prefix+'btnConfirmDelete');CheckCounts $page 0 0 0
 $page=$hostObject.Request($target+'?testActor=2',$null);CheckHtml $page
 Assert ($page -match 'مدير النظام فقط' -and $page -notmatch 'id="typeEditor"') 'Owner reached catalog editor.'
}
'PASS contract-type/payment-method statistics, filters, inline editors, status actions, modal deletion and administrator scope.'
