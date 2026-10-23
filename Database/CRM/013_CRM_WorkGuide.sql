-- New administrator-only CRM library. This does not restore retired guide tables/APIs.
IF OBJECT_ID('dbo.CRM_WorkGuide_Categories','U') IS NULL
BEGIN
 CREATE TABLE dbo.CRM_WorkGuide_Categories(
 ID int IDENTITY PRIMARY KEY,Parent_ID int NULL REFERENCES dbo.CRM_WorkGuide_Categories(ID),
 Name_AR nvarchar(200) NOT NULL,Name_EN nvarchar(200) NOT NULL,Sort_Order int NOT NULL DEFAULT(0),
 Parent_Key AS ISNULL(Parent_ID,0) PERSISTED,Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
 Is_Deleted bit NOT NULL DEFAULT(0),AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID),Modified_Date datetime2 NULL,Row_Version rowversion,
 CONSTRAINT CK_CRM_WorkGuide_Category CHECK(Parent_ID<>ID AND Sort_Order BETWEEN 0 AND 1000000));
 CREATE UNIQUE INDEX UX_CRM_WorkGuide_Category_Name ON dbo.CRM_WorkGuide_Categories(Parent_Key,Normalized_Name);
 CREATE INDEX IX_CRM_WorkGuide_Category_Parent ON dbo.CRM_WorkGuide_Categories(Parent_ID,Is_Deleted,Sort_Order);
END;
IF OBJECT_ID('dbo.CRM_WorkGuide_Items','U') IS NULL
BEGIN
 CREATE TABLE dbo.CRM_WorkGuide_Items(
 ID int IDENTITY PRIMARY KEY,Name_AR nvarchar(200) NOT NULL,Name_EN nvarchar(200) NOT NULL,
 Summary_AR nvarchar(4000) NOT NULL,Summary_EN nvarchar(4000) NOT NULL,Sort_Order int NOT NULL DEFAULT(0),
 File_Url nvarchar(260) NOT NULL,File_Name nvarchar(200) NOT NULL,File_Extension varchar(5) NOT NULL,File_Size int NOT NULL,
 Normalized_Name AS UPPER(LTRIM(RTRIM(Name_AR))) PERSISTED,
 Is_Active bit NOT NULL DEFAULT(1),Is_Deleted bit NOT NULL DEFAULT(0),
 AddedUser int NOT NULL REFERENCES dbo.UsersMembers(ID),AddedDate datetime2 NOT NULL DEFAULT(SYSDATETIME()),
 Modified_User int NULL REFERENCES dbo.UsersMembers(ID),Modified_Date datetime2 NULL,Row_Version rowversion,
 CONSTRAINT CK_CRM_WorkGuide_Item CHECK(Sort_Order BETWEEN 0 AND 1000000 AND File_Extension IN('.pdf','.doc','.docx') AND File_Size BETWEEN 1 AND 10485760));
 CREATE UNIQUE INDEX UX_CRM_WorkGuide_Item_Name ON dbo.CRM_WorkGuide_Items(Normalized_Name);
 CREATE INDEX IX_CRM_WorkGuide_Item_Status ON dbo.CRM_WorkGuide_Items(Is_Deleted,Is_Active,Sort_Order);
END;
IF OBJECT_ID('dbo.CRM_WorkGuide_ItemCategories','U') IS NULL
BEGIN
 CREATE TABLE dbo.CRM_WorkGuide_ItemCategories(Item_ID int NOT NULL REFERENCES dbo.CRM_WorkGuide_Items(ID),Category_ID int NOT NULL REFERENCES dbo.CRM_WorkGuide_Categories(ID),PRIMARY KEY(Item_ID,Category_ID));
 CREATE INDEX IX_CRM_WorkGuide_ItemCategory_Category ON dbo.CRM_WorkGuide_ItemCategories(Category_ID,Item_ID);
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_WorkGuide_CheckAdmin @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.UsersMembers WHERE ID=@Actor_ID AND Type=1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51200,N'إدارة دليل العمل متاحة لمدير النظام فقط.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_WorkGuide_Categories @Actor_ID int,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 SELECT ID,Parent_ID,Name_AR,Name_EN,Sort_Order,Row_Version FROM dbo.CRM_WorkGuide_Categories WHERE Is_Deleted=0 AND (@ID IS NULL OR ID=@ID) ORDER BY Sort_Order,Name_AR,ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_WorkGuide_Items @Actor_ID int,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Row_Version,
 STUFF((SELECT ','+CONVERT(nvarchar(12),c.ID) FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID AND c.Is_Deleted=0 ORDER BY c.Sort_Order,c.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'') Category_IDs,
 STUFF((SELECT N'، '+c.Name_AR FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID AND c.Is_Deleted=0 ORDER BY c.Sort_Order,c.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'') Category_Names
 FROM dbo.CRM_WorkGuide_Items i WHERE i.Is_Deleted=0 AND (@ID IS NULL OR i.ID=@ID) ORDER BY i.Sort_Order,i.Name_AR,i.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_WorkGuide_Category @Actor_ID int,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
 IF @Name_AR IS NULL OR LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم التصنيف بالعربية (حتى 200 حرف).',1;
 DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
 IF @Name_EN IS NULL OR LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم التصنيف بالإنجليزية (حتى 200 حرف).',1;
 DECLARE @Sort_Order int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Sort_Order/text())[1]','nvarchar(30)'))),N''));
 IF @Sort_Order IS NULL OR @Sort_Order NOT BETWEEN 0 AND 1000000 THROW 51201,N'أدخل ترتيبًا صحيحًا من 0 إلى 1000000.',1;
 IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;

 DECLARE @ParentText nvarchar(30)=NULLIF(@Data.value('(/row/Parent_ID/text())[1]','nvarchar(30)'),N''),@Parent_ID int;
 SET @Parent_ID=TRY_CONVERT(int,@ParentText);
 IF @ParentText IS NOT NULL AND (@Parent_ID IS NULL OR @Parent_ID<=0) THROW 51201,N'التصنيف الأب غير صحيح.',1;
 IF @Parent_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Categories WHERE ID=@Parent_ID AND Is_Deleted=0) THROW 51201,N'التصنيف الأب غير متاح.',1;
 IF @ID<>0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'التصنيف تغير أو حُذف؛ أعد فتح النموذج.',1;
 DECLARE @Cycle bit=0;
 ;WITH Ancestors AS(SELECT ID,Parent_ID FROM dbo.CRM_WorkGuide_Categories WHERE ID=@Parent_ID UNION ALL SELECT p.ID,p.Parent_ID FROM dbo.CRM_WorkGuide_Categories p JOIN Ancestors a ON a.Parent_ID=p.ID)
 SELECT @Cycle=1 FROM Ancestors WHERE ID=@ID OPTION(MAXRECURSION 32767);
 IF @Cycle=1 THROW 51201,N'لا يمكن وضع التصنيف تحت نفسه أو أحد فروعه.',1;
 DECLARE @New bit=CASE WHEN @ID=0 THEN 1 ELSE 0 END,@Before xml=(SELECT ID,Parent_ID,Name_AR,Name_EN,Sort_Order,Is_Deleted FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID FOR XML PATH('row'),TYPE);
 IF @ID=0 BEGIN INSERT dbo.CRM_WorkGuide_Categories(Parent_ID,Name_AR,Name_EN,Sort_Order,AddedUser) VALUES(@Parent_ID,@Name_AR,@Name_EN,@Sort_Order,@Actor_ID);SET @ID=CONVERT(int,SCOPE_IDENTITY());END
 ELSE UPDATE dbo.CRM_WorkGuide_Categories SET Parent_ID=@Parent_ID,Name_AR=@Name_AR,Name_EN=@Name_EN,Sort_Order=@Sort_Order,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT ID,Parent_ID,Name_AR,Name_EN,Sort_Order,Is_Deleted FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,N'WorkGuide_Categories',@ID,CASE WHEN @New=1 THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
 COMMIT;SELECT ID,Row_Version FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER() IN(2601,2627) THROW 51201,N'الاسم مستخدم مسبقًا؛ اختر اسمًا آخر.',1;
 THROW;
 END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_WorkGuide_Item @Actor_ID int,@ID int=0,@Data xml,@Categories xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
 IF @Name_AR IS NULL OR LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم الدليل بالعربية (حتى 200 حرف).',1;
 DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
 IF @Name_EN IS NULL OR LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم الدليل بالإنجليزية (حتى 200 حرف).',1;
 DECLARE @Summary_AR nvarchar(4000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Summary_AR/text())[1]','nvarchar(max)'))),N'');
 IF @Summary_AR IS NULL OR LEN(@Data.value('(/row/Summary_AR/text())[1]','nvarchar(max)'))>4000 THROW 51201,N'أدخل الملخص بالعربية (حتى 4000 حرف).',1;
 DECLARE @Summary_EN nvarchar(4000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Summary_EN/text())[1]','nvarchar(max)'))),N'');
 IF @Summary_EN IS NULL OR LEN(@Data.value('(/row/Summary_EN/text())[1]','nvarchar(max)'))>4000 THROW 51201,N'أدخل الملخص بالإنجليزية (حتى 4000 حرف).',1;
 DECLARE @Sort_Order int=TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(@Data.value('(/row/Sort_Order/text())[1]','nvarchar(30)'))),N''));
 IF @Sort_Order IS NULL OR @Sort_Order NOT BETWEEN 0 AND 1000000 THROW 51201,N'أدخل ترتيبًا صحيحًا من 0 إلى 1000000.',1;
 IF @ID<0 THROW 51201,N'رقم السجل غير صحيح.',1;

 DECLARE @ActiveText nvarchar(5)=@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)');
 IF @ActiveText NOT IN(N'0',N'1') OR @ActiveText IS NULL THROW 51201,N'حالة الدليل غير صحيحة.',1;
 DECLARE @Active bit=CONVERT(bit,@ActiveText),@New bit=CASE WHEN @ID=0 THEN 1 ELSE 0 END;
 IF @ID<>0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'الدليل تغير أو حُذف؛ أعد فتح النموذج.',1;
 DECLARE @Selected TABLE(ID int PRIMARY KEY);
 IF @Categories IS NULL OR @Categories.value('count(/categories/id)','int')=0 OR @Categories.value('count(/categories/id)','int')>1000 THROW 51201,N'اختر تصنيفًا واحدًا على الأقل (حتى 1000 تصنيف).',1;
 IF EXISTS(SELECT 1 FROM @Categories.nodes('/categories/id') x(n) WHERE TRY_CONVERT(int,x.n.value('(text())[1]','nvarchar(30)')) IS NULL) THROW 51201,N'التصنيفات غير صحيحة.',1;
 INSERT @Selected SELECT DISTINCT TRY_CONVERT(int,x.n.value('(text())[1]','nvarchar(30)')) FROM @Categories.nodes('/categories/id') x(n);
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=s.ID AND c.Is_Deleted=0 WHERE c.ID IS NULL) THROW 51201,N'أحد التصنيفات غير متاح؛ حدّث القائمة.',1;
 DECLARE @File_Url nvarchar(260)=NULLIF(@Data.value('(/row/File_Url/text())[1]','nvarchar(max)'),N''),@File_Name nvarchar(200)=NULLIF(@Data.value('(/row/File_Name/text())[1]','nvarchar(max)'),N''),@File_Extension varchar(5)=NULLIF(@Data.value('(/row/File_Extension/text())[1]','varchar(10)'),''),@File_Size int=TRY_CONVERT(int,@Data.value('(/row/File_Size/text())[1]','nvarchar(30)'));
 IF @File_Url IS NULL AND @ID<>0 SELECT @File_Url=File_Url,@File_Name=File_Name,@File_Extension=File_Extension,@File_Size=File_Size FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 IF @File_Url IS NULL OR @File_Name IS NULL OR @File_Extension NOT IN('.pdf','.doc','.docx') OR @File_Extension IS NULL OR @File_Size IS NULL OR @File_Size NOT BETWEEN 1 AND 10485760 THROW 51201,N'أرفق ملف PDF أو Word صالحًا (حتى 10 ميجابايت).',1;
 IF @File_Url COLLATE Latin1_General_100_BIN2 NOT LIKE N'/FileManager/CRMWorkGuide/'+REPLICATE(N'[0-9a-f]',32)+CONVERT(nvarchar(5),@File_Extension) OR DATALENGTH(@File_Url)<>2*(26+32+LEN(@File_Extension)) OR LEN(@Data.value('(/row/File_Name/text())[1]','nvarchar(max)'))>200 OR CHARINDEX(CHAR(13),@File_Name)>0 OR CHARINDEX(CHAR(10),@File_Name)>0 OR CHARINDEX('/',@File_Name)>0 OR CHARINDEX(N'',@File_Name)>0 THROW 51201,N'بيانات الملف غير صحيحة.',1;
 DECLARE @Before xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 IF @ID=0 BEGIN
 INSERT dbo.CRM_WorkGuide_Items(Name_AR,Name_EN,Summary_AR,Summary_EN,Sort_Order,File_Url,File_Name,File_Extension,File_Size,Is_Active,AddedUser) VALUES(@Name_AR,@Name_EN,@Summary_AR,@Summary_EN,@Sort_Order,@File_Url,@File_Name,@File_Extension,@File_Size,@Active,@Actor_ID);SET @ID=CONVERT(int,SCOPE_IDENTITY());END
 ELSE UPDATE dbo.CRM_WorkGuide_Items SET Name_AR=@Name_AR,Name_EN=@Name_EN,Summary_AR=@Summary_AR,Summary_EN=@Summary_EN,Sort_Order=@Sort_Order,File_Url=@File_Url,File_Name=@File_Name,File_Extension=@File_Extension,File_Size=@File_Size,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DELETE dbo.CRM_WorkGuide_ItemCategories WHERE Item_ID=@ID;
 INSERT dbo.CRM_WorkGuide_ItemCategories(Item_ID,Category_ID) SELECT @ID,ID FROM @Selected;
 DECLARE @After xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,N'WorkGuide_Items',@ID,CASE WHEN @New=1 THEN N'إضافة' ELSE N'تعديل' END,@Before,@After);
 COMMIT;SELECT ID,Row_Version FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER() IN(2601,2627) THROW 51201,N'الاسم مستخدم مسبقًا؛ اختر اسمًا آخر.',1;
 THROW;
 END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Set_WorkGuide_Active @Actor_ID int,@ID int,@Is_Active bit,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;

 IF @Is_Active IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'الدليل تغير أو حُذف؛ حدّث القائمة.',1;
 DECLARE @Before xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 UPDATE dbo.CRM_WorkGuide_Items SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,N'WorkGuide_Items',@ID,CASE WHEN @Is_Active=1 THEN N'تفعيل' ELSE N'إيقاف' END,@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER() IN(2601,2627) THROW 51201,N'الاسم مستخدم مسبقًا؛ اختر اسمًا آخر.',1;
 THROW;
 END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Delete_WorkGuide_Item @Actor_ID int,@ID int,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف؛ حدّث القائمة.',1;
 DECLARE @Before xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 UPDATE dbo.CRM_WorkGuide_Items SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,N'WorkGuide_Items',@ID,N'حذف',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER() IN(2601,2627) THROW 51201,N'الاسم مستخدم مسبقًا؛ اختر اسمًا آخر.',1;
 THROW;
 END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Delete_WorkGuide_Category @Actor_ID int,@ID int,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51201,N'السجل تغير أو حُذف؛ حدّث القائمة.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Categories WHERE Parent_ID=@ID AND Is_Deleted=0) THROW 51201,N'لا يمكن حذف تصنيف لديه فروع؛ انقل الفروع أو احذفها أولًا.',1;
 IF EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID WHERE x.Category_ID=@ID AND i.Is_Deleted=0) THROW 51201,N'لا يمكن حذف تصنيف مرتبط بأدلة؛ عدّل ارتباط الأدلة أولًا.',1;
 DECLARE @Before xml=(SELECT ID,Parent_ID,Name_AR,Name_EN,Sort_Order,Is_Deleted FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID FOR XML PATH('row'),TYPE);
 UPDATE dbo.CRM_WorkGuide_Categories SET Is_Deleted=1,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT ID,Parent_ID,Name_AR,Name_EN,Sort_Order,Is_Deleted FROM dbo.CRM_WorkGuide_Categories WHERE ID=@ID FOR XML PATH('row'),TYPE);
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action,Before_Data,After_Data) VALUES(@Actor_ID,N'WorkGuide_Categories',@ID,N'حذف',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF ERROR_NUMBER() IN(2601,2627) THROW 51201,N'الاسم مستخدم مسبقًا؛ اختر اسمًا آخر.',1;
 THROW;
 END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_WorkGuide_File @Actor_ID int,@ID int AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID AND Is_Deleted=0) THROW 51201,N'الملف غير متاح.',1;
 INSERT dbo.CRM_Activity_Logs(Actor_ID,Entity,Record_ID,Action) VALUES(@Actor_ID,N'WorkGuide_Items',@ID,N'تحميل الملف');
 SELECT File_Url,File_Name,File_Extension FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID AND Is_Deleted=0;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Overview_Extensions @Actor_ID int AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 SELECT (SELECT COUNT_BIG(*) FROM dbo.CRM_Contract_Types WHERE Is_Deleted=0) Contract_Types,
 (SELECT COUNT_BIG(*) FROM dbo.CRM_Payment_Methods WHERE Is_Deleted=0) Payment_Methods,
 (SELECT COUNT_BIG(*) FROM dbo.CRM_WorkGuide_Items WHERE Is_Deleted=0) WorkGuide_Items;
END;
GO
