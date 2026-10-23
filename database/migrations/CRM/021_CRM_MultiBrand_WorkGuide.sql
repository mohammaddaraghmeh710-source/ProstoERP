-- Customer guide access is the intersection of current active brand membership and an explicit category grant.
-- Parent grants never inherit; separate category rights are never combined.
IF OBJECT_ID('dbo.CRM_Account_Brands','U') IS NULL THROW 51201,'Apply CRM multi-organization membership before this script.',1;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_WorkGuide_Permissions @Actor_ID int,@Account_ID int AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Shared',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0) THROW 51201,N'العميل غير متاح.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=@Account_ID) THROW 51201,N'حدد علامات تجارية فعالة للعميل قبل منح صلاحيات دليل العمل.',1;
 SELECT c.ID,c.Brand_ID,b.Title_Ar Brand_Name,b.Title_En Brand_Name_EN,(SELECT Row_Version FROM dbo.CRM_Accounts WHERE ID=@Account_ID) Account_Version,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,ISNULL(p.Can_View,CONVERT(bit,0)) Can_View,ISNULL(p.Can_Download,CONVERT(bit,0)) Can_Download,
 -- Preserve a real NULL when no permission version exists yet (first save).
 CASE WHEN s.Account_ID IS NULL THEN NULL ELSE CONVERT(varbinary(8),s.Row_Version) END Access_Version FROM dbo.CRM_WorkGuide_Categories c JOIN dbo.Brands b ON b.ID=c.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 JOIN dbo.CRM_Account_Brands ab ON ab.Brand_ID=c.Brand_ID AND ab.Account_ID=@Account_ID LEFT JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@Account_ID
 LEFT JOIN dbo.CRM_WorkGuide_AccessState s ON s.Account_ID=@Account_ID WHERE c.Is_Deleted=0 ORDER BY b.Title_Ar,c.Sort_Order,c.Name_AR,c.ID;
 EXEC dbo.CRM_Log_Read @Actor_ID,N'WorkGuide_Permissions',@Account_ID,@Account_ID;
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_WorkGuide_Permissions @Actor_ID int,@Account_ID int,@Data xml,@Version binary(8)=NULL,@Account_Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0) THROW 51201,N'العميل غير متاح.',1;
 IF @Account_Version IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Row_Version=@Account_Version) THROW 51201,N'تغيرت بيانات العميل أو علاماته التجارية؛ أعد تحميل الصلاحيات قبل الحفظ.',1;
 DECLARE @Brands TABLE(ID int PRIMARY KEY);
 INSERT @Brands SELECT ab.Brand_ID FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=@Account_ID;
 IF NOT EXISTS(SELECT 1 FROM @Brands) THROW 51201,N'حدد علامات تجارية فعالة للعميل قبل منح صلاحيات دليل العمل.',1;
 IF (@Version IS NULL AND EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID)) OR
 (@Version IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID AND Row_Version=@Version)) THROW 51201,N'تغيرت الصلاحيات؛ أعد تحميل بيانات العميل قبل الحفظ.',1;
 IF @Data IS NULL OR @Data.value('count(/grants)','int')<>1 OR @Data.value('count(/grants/grant)','int')>10000
 OR @Data.exist('/grants/*[not(local-name()="grant")]')=1 THROW 51201,N'بيانات الصلاحيات غير صحيحة.',1;
 DECLARE @Selected TABLE(ID int,Can_View int,Can_Download int);
 INSERT @Selected SELECT TRY_CONVERT(int,n.value('(@id)[1]','nvarchar(30)')),TRY_CONVERT(int,n.value('(@view)[1]','nvarchar(10)')),TRY_CONVERT(int,n.value('(@download)[1]','nvarchar(10)')) FROM @Data.nodes('/grants/grant') x(n);
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=s.ID AND c.Brand_ID IN(SELECT ID FROM @Brands) AND c.Is_Deleted=0 WHERE c.ID IS NULL OR s.Can_View IS NULL OR s.Can_Download IS NULL OR s.Can_View NOT IN(0,1) OR s.Can_Download NOT IN(0,1))
 OR EXISTS(SELECT ID FROM @Selected GROUP BY ID HAVING COUNT(*)>1) THROW 51201,N'أحد التصنيفات أو الصلاحيات غير صحيح؛ حدّث القائمة.',1;
 DECLARE @Before xml=(SELECT @Account_ID Account_ID,(SELECT ID FROM @Brands ORDER BY ID FOR XML PATH('Brand'),ROOT('Brands'),TYPE),(SELECT c.ID,c.Brand_ID,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE p.Account_ID=@Account_ID ORDER BY c.ID FOR XML PATH('grant'),ROOT('Permissions'),TYPE) FOR XML PATH('row'),TYPE);
 DELETE dbo.CRM_WorkGuide_Access WHERE Account_ID=@Account_ID;
 INSERT dbo.CRM_WorkGuide_Access SELECT @Account_ID,ID,Can_View,Can_Download FROM @Selected WHERE Can_View=1 OR Can_Download=1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID) UPDATE dbo.CRM_WorkGuide_AccessState SET Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE Account_ID=@Account_ID;
 ELSE INSERT dbo.CRM_WorkGuide_AccessState(Account_ID,Modified_User) VALUES(@Account_ID,@Actor_ID);
 DECLARE @After xml=(SELECT @Account_ID Account_ID,(SELECT ID FROM @Brands ORDER BY ID FOR XML PATH('Brand'),ROOT('Brands'),TYPE),(SELECT c.ID,c.Brand_ID,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE p.Account_ID=@Account_ID ORDER BY c.ID FOR XML PATH('grant'),ROOT('Permissions'),TYPE) FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Account_ID,N'WorkGuide_Permissions',@Account_ID,N'تعديل صلاحيات دليل العمل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_List @AccountID int,@Stamp uniqueidentifier,@Category_ID int=NULL,@Items bit=0,@Brand_ID int=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brands TABLE(ID int PRIMARY KEY);
 INSERT @Brands SELECT ab.Brand_ID FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=@AccountID AND (@Brand_ID IS NULL OR ab.Brand_ID=@Brand_ID);
 IF @Brand_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @Brands) THROW 51912,N'العلامة التجارية غير متاحة.',1;
 IF @Category_ID IS NULL AND @Items=0
 SELECT c.ID,c.Brand_ID,(SELECT Title_Ar FROM dbo.Brands WHERE ID=c.Brand_ID) Brand_Name,c.Parent_ID,c.Sort_Order,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download,COUNT(i.ID) Item_Count FROM dbo.CRM_WorkGuide_Access p
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 LEFT JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID LEFT JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Brand_ID=c.Brand_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND p.Account_ID=@AccountID GROUP BY c.ID,c.Brand_ID,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,p.Can_View,p.Can_Download ORDER BY Brand_Name,c.Sort_Order,c.Name_AR,c.ID;
 ELSE BEGIN
 IF @Category_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND p.Account_ID=@AccountID AND c.ID=@Category_ID AND c.Is_Deleted=0) THROW 51912,N'التصنيف غير متاح.',1;
 SELECT i.ID,i.Brand_ID,(SELECT Title_Ar FROM dbo.Brands WHERE ID=i.Brand_ID) Brand_Name,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,CASE WHEN p.Can_View=1 THEN i.Details_AR ELSE N'' END Details_AR,CASE WHEN p.Can_View=1 THEN i.Details_EN ELSE N'' END Details_EN,i.File_Extension,i.Sort_Order,p.Can_View,p.Can_Download,c.Name_AR Category_Name,c.ID Category_ID
 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Brand_ID=c.Brand_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND p.Account_ID=@AccountID AND (@Category_ID IS NULL OR c.ID=@Category_ID) ORDER BY Brand_Name,i.Sort_Order,i.Name_AR,i.ID,c.ID;
 END;
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note) VALUES(@AccountID,'guide-list',N'WorkGuide_Items',NULL,CONCAT(N'عرض قائمة دليل العمل؛ التصنيف: ',@Category_ID));
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_File @AccountID int,@Stamp uniqueidentifier,@ID int,@Category_ID int,@Action varchar(10),@Log bit=1 AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;

 IF @Action IS NULL OR @Action NOT IN('view','download','details') THROW 51912,N'العملية غير متاحة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items i JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Item_ID=i.ID
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
 JOIN dbo.CRM_Account_Brands ab ON ab.Account_ID=@AccountID AND ab.Brand_ID=c.Brand_ID JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0
 WHERE i.Brand_ID=c.Brand_ID AND i.ID=@ID AND c.ID=@Category_ID AND c.Is_Deleted=0 AND i.Is_Active=1 AND i.Is_Deleted=0 AND ((@Action IN('view','details') AND p.Can_View=1) OR (@Action='download' AND p.Can_Download=1))) THROW 51912,N'لا تملك صلاحية لهذه العملية ضمن التصنيف المحدد.',1;
 IF @Log=1 BEGIN
 DECLARE @Details xml=(SELECT @Category_ID Category_ID,c.Brand_ID,c.Name_AR Category_Name,@Action Operation,i.Name_AR,i.Name_EN FROM dbo.CRM_WorkGuide_Items i CROSS JOIN dbo.CRM_WorkGuide_Categories c WHERE i.Brand_ID=c.Brand_ID AND i.ID=@ID AND c.ID=@Category_ID FOR XML PATH('row'),TYPE);
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,After_Data,Note) VALUES(@AccountID,CASE @Action WHEN 'view' THEN 'guide-view' WHEN 'details' THEN 'guide-details' ELSE 'guide-download' END,N'WorkGuide_Items',@ID,@Details,CONCAT(N'التصنيف رقم ',@Category_ID));
 END;
 SELECT Brand_ID,File_Url,File_Name,File_Extension,Name_AR,Name_EN,Details_AR,Details_EN FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_Tree @AccountID int,@Stamp uniqueidentifier,@Brand_ID int=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brands TABLE(ID int PRIMARY KEY);
 INSERT @Brands SELECT ab.Brand_ID FROM dbo.CRM_Account_Brands ab JOIN dbo.Brands b ON b.ID=ab.Brand_ID AND b.IsActive=1 AND ISNULL(b.IsDeleted,0)=0 WHERE ab.Account_ID=@AccountID AND (@Brand_ID IS NULL OR ab.Brand_ID=@Brand_ID);
 IF @Brand_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @Brands) THROW 51912,N'العلامة التجارية غير متاحة.',1;
 ;WITH Ancestors AS (
  SELECT c.ID,c.Parent_ID,c.Brand_ID FROM dbo.CRM_WorkGuide_Categories c JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
  WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND c.Is_Deleted=0 AND (p.Can_View=1 OR p.Can_Download=1)
  UNION ALL SELECT c.ID,c.Parent_ID,c.Brand_ID FROM dbo.CRM_WorkGuide_Categories c JOIN Ancestors a ON a.Parent_ID=c.ID AND a.Brand_ID=c.Brand_ID WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND c.Is_Deleted=0
 )
 SELECT c.ID,c.Brand_ID,(SELECT Title_Ar FROM dbo.Brands WHERE ID=c.Brand_ID) Brand_Name,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,CONVERT(bit,CASE WHEN p.Can_View=1 OR p.Can_Download=1 THEN 1 ELSE 0 END) Has_Access
 FROM dbo.CRM_WorkGuide_Categories c LEFT JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
 WHERE c.Brand_ID IN(SELECT ID FROM @Brands) AND c.ID IN(SELECT ID FROM Ancestors) ORDER BY Brand_Name,c.Sort_Order,c.Name_AR,c.ID OPTION(MAXRECURSION 32767);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
