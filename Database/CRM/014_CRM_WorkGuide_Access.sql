-- Exact-category grants. A request always carries one category; rights never aggregate.
IF OBJECT_ID('dbo.Customer_WriteCheck','P') IS NULL OR OBJECT_ID('dbo.Customer_Portal_Activity','U') IS NULL
 THROW 51201,'Apply the current CustomerPortal self-service migrations before CRM work-guide access (014).',1;
IF OBJECT_ID('dbo.CRM_WorkGuide_AccessState','U') IS NULL
 CREATE TABLE dbo.CRM_WorkGuide_AccessState(Account_ID int NOT NULL PRIMARY KEY REFERENCES dbo.CRM_Accounts(ID), Modified_User int NULL REFERENCES dbo.UsersMembers(ID), Modified_Date datetime2 NOT NULL DEFAULT SYSDATETIME(), Row_Version rowversion);
IF OBJECT_ID('dbo.CRM_WorkGuide_Access','U') IS NULL
 CREATE TABLE dbo.CRM_WorkGuide_Access(Account_ID int NOT NULL REFERENCES dbo.CRM_Accounts(ID), Category_ID int NOT NULL REFERENCES dbo.CRM_WorkGuide_Categories(ID), Can_View bit NOT NULL, Can_Download bit NOT NULL,
 CONSTRAINT PK_CRM_WorkGuide_Access PRIMARY KEY(Account_ID,Category_ID), CONSTRAINT CK_CRM_WorkGuide_Access_Rights CHECK(Can_View=1 OR Can_Download=1));
GO
CREATE OR ALTER PROCEDURE dbo.CRM_WorkGuide_Permissions @Actor_ID int,@Account_ID int AS
BEGIN
 SET NOCOUNT ON; EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0) THROW 51201,N'العميل غير متاح.',1;
 SELECT c.ID,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,ISNULL(p.Can_View,CONVERT(bit,0)) Can_View,ISNULL(p.Can_Download,CONVERT(bit,0)) Can_Download,
 -- Preserve a real NULL when no permission version exists yet (first save).
 CASE WHEN s.Account_ID IS NULL THEN NULL ELSE CONVERT(varbinary(8),s.Row_Version) END Access_Version FROM dbo.CRM_WorkGuide_Categories c LEFT JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@Account_ID
 LEFT JOIN dbo.CRM_WorkGuide_AccessState s ON s.Account_ID=@Account_ID WHERE c.Is_Deleted=0 ORDER BY c.Sort_Order,c.Name_AR,c.ID;
 EXEC dbo.CRM_Log_Read @Actor_ID,N'WorkGuide_Permissions',@Account_ID,@Account_ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_WorkGuide_Permissions @Actor_ID int,@Account_ID int,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@Account_ID AND Is_Deleted=0) THROW 51201,N'العميل غير متاح.',1;
 IF (@Version IS NULL AND EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID)) OR
 (@Version IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID AND Row_Version=@Version)) THROW 51201,N'تغيرت الصلاحيات؛ أعد تحميل بيانات العميل قبل الحفظ.',1;
 IF @Data IS NULL OR @Data.value('count(/grants)','int')<>1 OR @Data.value('count(/grants/grant)','int')>10000
 OR @Data.exist('/grants/*[not(local-name()="grant")]')=1 THROW 51201,N'بيانات الصلاحيات غير صحيحة.',1;
 DECLARE @Selected TABLE(ID int,Can_View int,Can_Download int);
 INSERT @Selected SELECT TRY_CONVERT(int,n.value('(@id)[1]','nvarchar(30)')),TRY_CONVERT(int,n.value('(@view)[1]','nvarchar(10)')),TRY_CONVERT(int,n.value('(@download)[1]','nvarchar(10)')) FROM @Data.nodes('/grants/grant') x(n);
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=s.ID AND c.Is_Deleted=0 WHERE c.ID IS NULL OR s.Can_View IS NULL OR s.Can_Download IS NULL OR s.Can_View NOT IN(0,1) OR s.Can_Download NOT IN(0,1))
 OR EXISTS(SELECT ID FROM @Selected GROUP BY ID HAVING COUNT(*)>1) THROW 51201,N'أحد التصنيفات أو الصلاحيات غير صحيح؛ حدّث القائمة.',1;
 DECLARE @Before xml=(SELECT @Account_ID Account_ID,(SELECT c.ID,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE p.Account_ID=@Account_ID ORDER BY c.ID FOR XML PATH('grant'),ROOT('Permissions'),TYPE) FOR XML PATH('row'),TYPE);
 DELETE dbo.CRM_WorkGuide_Access WHERE Account_ID=@Account_ID;
 INSERT dbo.CRM_WorkGuide_Access SELECT @Account_ID,ID,Can_View,Can_Download FROM @Selected WHERE Can_View=1 OR Can_Download=1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_AccessState WHERE Account_ID=@Account_ID) UPDATE dbo.CRM_WorkGuide_AccessState SET Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE Account_ID=@Account_ID;
 ELSE INSERT dbo.CRM_WorkGuide_AccessState(Account_ID,Modified_User) VALUES(@Account_ID,@Actor_ID);
 DECLARE @After xml=(SELECT @Account_ID Account_ID,(SELECT c.ID,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE p.Account_ID=@Account_ID ORDER BY c.ID FOR XML PATH('grant'),ROOT('Permissions'),TYPE) FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Account_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,@Account_ID,N'WorkGuide_Permissions',@Account_ID,N'تعديل صلاحيات دليل العمل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_List @AccountID int,@Stamp uniqueidentifier,@Category_ID int=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 IF @Category_ID IS NULL
 SELECT c.ID,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download,COUNT(i.ID) Item_Count FROM dbo.CRM_WorkGuide_Access p
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 LEFT JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID LEFT JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE p.Account_ID=@AccountID GROUP BY c.ID,c.Name_AR,c.Name_EN,c.Sort_Order,p.Can_View,p.Can_Download ORDER BY c.Sort_Order,c.Name_AR,c.ID;
 ELSE BEGIN
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE p.Account_ID=@AccountID AND c.ID=@Category_ID AND c.Is_Deleted=0) THROW 51912,N'التصنيف غير متاح.',1;
 SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.File_Extension,i.Sort_Order,p.Can_View,p.Can_Download,c.Name_AR Category_Name,c.ID Category_ID
 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE p.Account_ID=@AccountID AND c.ID=@Category_ID ORDER BY i.Sort_Order,i.Name_AR,i.ID;
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
 IF @Action IS NULL OR @Action NOT IN('view','download') THROW 51912,N'العملية غير متاحة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items i JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Item_ID=i.ID
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
 WHERE i.ID=@ID AND c.ID=@Category_ID AND c.Is_Deleted=0 AND i.Is_Active=1 AND i.Is_Deleted=0 AND ((@Action='view' AND p.Can_View=1) OR (@Action='download' AND p.Can_Download=1))) THROW 51912,N'لا تملك صلاحية لهذه العملية ضمن التصنيف المحدد.',1;
 IF @Log=1 BEGIN
 DECLARE @Details xml=(SELECT @Category_ID Category_ID,c.Name_AR Category_Name,@Action Operation,i.Name_AR,i.Name_EN FROM dbo.CRM_WorkGuide_Items i CROSS JOIN dbo.CRM_WorkGuide_Categories c WHERE i.ID=@ID AND c.ID=@Category_ID FOR XML PATH('row'),TYPE);
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,After_Data,Note) VALUES(@AccountID,CASE WHEN @Action='view' THEN 'guide-view' ELSE 'guide-download' END,N'WorkGuide_Items',@ID,@Details,CONCAT(N'التصنيف رقم ',@Category_ID));
 END;
 SELECT File_Url,File_Name,File_Extension FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO

CREATE OR ALTER VIEW dbo.CRM_v_Activity AS
SELECT l.ID,l.Actor_ID,l.Account_ID,l.Entity,l.Record_ID,l.Action,l.Before_Data,l.After_Data,l.Note,l.AddedDate,
 u.FullName_Ar User_Name,a.Name_AR Account_Name,CONVERT(nvarchar(40),N'إدارة النظام') Source_Name
FROM dbo.CRM_Activity_Logs l LEFT JOIN dbo.UsersMembers u ON u.ID=l.Actor_ID LEFT JOIN dbo.CRM_Accounts a ON a.ID=l.Account_ID
UNION ALL
SELECT -x.ID,x.ActorID,x.AccountID,COALESCE(x.Entity,CASE WHEN x.Action IN('login','logout','credentials','login-failed') THEN N'Customer_Session' ELSE N'Accounts' END),COALESCE(x.RecordID,x.AccountID),
CASE x.Action WHEN 'guide-list' THEN N'عرض قائمة دليل العمل' WHEN 'guide-view' THEN N'اطلاع على دليل العمل' WHEN 'guide-download' THEN N'تحميل دليل العمل' WHEN 'credentials' THEN N'تحديث بيانات الدخول' WHEN 'login' THEN N'تسجيل الدخول كعميل' WHEN 'logout' THEN N'تسجيل الخروج' WHEN 'login-failed' THEN N'محاولة دخول فاشلة' WHEN 'dashboard-view' THEN N'عرض لوحة العميل' WHEN 'contact-view' THEN N'عرض جهة اتصال' WHEN 'profile-update' THEN N'تعديل بيانات العميل' WHEN 'contact-create' THEN N'إضافة جهة اتصال' WHEN 'contact-update' THEN N'تعديل جهة اتصال / الحالة' WHEN 'contact-delete' THEN N'حذف جهة اتصال' WHEN 'feedback' THEN CONCAT(N'تقديم ',COALESCE(x.FeedbackTypeTitle,N'طلب')) ELSE x.Action END,x.Before_Data,x.After_Data,x.Note,
 CONVERT(datetime2,x.CreatedUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time'),
 CASE WHEN x.ActorID IS NULL THEN COALESCE(a.Name_AR,N'زائر غير مصادق') ELSE u.FullName_Ar END,a.Name_AR,
 CASE WHEN x.ActorID IS NULL THEN N'بوابة العميل' ELSE N'إدارة النظام' END
FROM dbo.Customer_Portal_Activity x LEFT JOIN dbo.CRM_Accounts a ON a.ID=x.AccountID LEFT JOIN dbo.UsersMembers u ON u.ID=x.ActorID;
GO
