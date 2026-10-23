-- Apply after 015. Existing guides keep empty details; omitted fields preserve content.
IF COL_LENGTH('dbo.CRM_WorkGuide_Items','Details_AR') IS NULL
 ALTER TABLE dbo.CRM_WorkGuide_Items ADD Details_AR nvarchar(max) NOT NULL CONSTRAINT DF_CRMGuide_DetailsAR DEFAULT(N''),Details_EN nvarchar(max) NOT NULL CONSTRAINT DF_CRMGuide_DetailsEN DEFAULT(N'');
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Select_WorkGuide_Items @Actor_ID int,@ID int=NULL AS
BEGIN
 SET NOCOUNT ON;EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 SELECT i.ID,i.Brand_ID,b.Title_Ar Brand_Name,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Row_Version,
 STUFF((SELECT ','+CONVERT(nvarchar(12),c.ID) FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID AND c.Is_Deleted=0 ORDER BY c.Sort_Order,c.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,'') Category_IDs,
 STUFF((SELECT N'، '+c.Name_AR FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID AND c.Is_Deleted=0 ORDER BY c.Sort_Order,c.ID FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,2,N'') Category_Names
 FROM dbo.CRM_WorkGuide_Items i JOIN dbo.Brands b ON b.ID=i.Brand_ID WHERE i.Is_Deleted=0 AND (@ID IS NULL OR i.ID=@ID) ORDER BY i.Sort_Order,i.Name_AR,i.ID;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CRM_Save_WorkGuide_Item @Actor_ID int,@ID int=0,@Data xml,@Categories xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 DECLARE @Lock int;EXEC @Lock=sys.sp_getapplock @Resource=N'CRM_Write',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000;
 IF @Lock<0 THROW 51201,N'السجل مشغول؛ أعد المحاولة.',1;
 EXEC dbo.CRM_WorkGuide_CheckAdmin @Actor_ID;
 DECLARE @Brand_ID int=TRY_CONVERT(int,@Data.value('(/row/Brand_ID/text())[1]','nvarchar(30)'));
 IF @Brand_ID IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.Brands WHERE ID=@Brand_ID AND IsActive=1 AND ISNULL(IsDeleted,0)=0) THROW 51201,N'اختر علامة تجارية فعالة أولًا.',1;

 DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
 IF @Name_AR IS NULL OR LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم الدليل بالعربية (حتى 200 حرف).',1;
 DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
 IF @Name_EN IS NULL OR LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51201,N'أدخل اسم الدليل بالإنجليزية (حتى 200 حرف).',1;
 DECLARE @Summary_AR nvarchar(4000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Summary_AR/text())[1]','nvarchar(max)'))),N'');
 IF @Summary_AR IS NULL OR LEN(@Data.value('(/row/Summary_AR/text())[1]','nvarchar(max)'))>4000 THROW 51201,N'أدخل الملخص بالعربية (حتى 4000 حرف).',1;
 DECLARE @Summary_EN nvarchar(4000)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Summary_EN/text())[1]','nvarchar(max)'))),N'');
 IF @Summary_EN IS NULL OR LEN(@Data.value('(/row/Summary_EN/text())[1]','nvarchar(max)'))>4000 THROW 51201,N'أدخل الملخص بالإنجليزية (حتى 4000 حرف).',1;
 DECLARE @Details_AR nvarchar(max)=CASE WHEN @Data.exist('/row/Details_AR')=1 THEN ISNULL(@Data.value('(/row/Details_AR/text())[1]','nvarchar(max)'),N'') ELSE ISNULL((SELECT Details_AR FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID),N'') END;
 DECLARE @Details_EN nvarchar(max)=CASE WHEN @Data.exist('/row/Details_EN')=1 THEN ISNULL(@Data.value('(/row/Details_EN/text())[1]','nvarchar(max)'),N'') ELSE ISNULL((SELECT Details_EN FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID),N'') END;
 IF LEN(@Details_AR)>100000 OR LEN(@Details_EN)>100000 THROW 51201,N'نص التفاصيل يتجاوز الحد المسموح (100000 حرف لكل لغة).',1;
 IF (NULLIF(LTRIM(RTRIM(@Details_AR)),N'') IS NULL AND NULLIF(LTRIM(RTRIM(@Details_EN)),N'') IS NOT NULL) OR (NULLIF(LTRIM(RTRIM(@Details_EN)),N'') IS NULL AND NULLIF(LTRIM(RTRIM(@Details_AR)),N'') IS NOT NULL) THROW 51201,N'أدخل التفاصيل بالعربية والإنجليزية معًا.',1;
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
 IF EXISTS(SELECT 1 FROM @Selected s LEFT JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=s.ID AND c.Brand_ID=@Brand_ID AND c.Is_Deleted=0 WHERE c.ID IS NULL) THROW 51201,N'أحد التصنيفات غير متاح؛ حدّث القائمة.',1;
 DECLARE @File_Url nvarchar(260)=NULLIF(@Data.value('(/row/File_Url/text())[1]','nvarchar(max)'),N''),@File_Name nvarchar(200)=NULLIF(@Data.value('(/row/File_Name/text())[1]','nvarchar(max)'),N''),@File_Extension varchar(5)=NULLIF(@Data.value('(/row/File_Extension/text())[1]','varchar(10)'),''),@File_Size int=TRY_CONVERT(int,@Data.value('(/row/File_Size/text())[1]','nvarchar(30)'));
 IF @File_Url IS NULL AND @ID<>0 SELECT @File_Url=File_Url,@File_Name=File_Name,@File_Extension=File_Extension,@File_Size=File_Size FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 IF @File_Url IS NULL OR @File_Name IS NULL OR @File_Extension NOT IN('.pdf','.doc','.docx') OR @File_Extension IS NULL OR @File_Size IS NULL OR @File_Size NOT BETWEEN 1 AND 10485760 THROW 51201,N'أرفق ملف PDF أو Word صالحًا (حتى 10 ميجابايت).',1;
 IF @File_Url COLLATE Latin1_General_100_BIN2 NOT LIKE N'/FileManager/CRMWorkGuide/'+REPLICATE(N'[0-9a-f]',32)+CONVERT(nvarchar(5),@File_Extension) OR DATALENGTH(@File_Url)<>2*(26+32+LEN(@File_Extension)) OR LEN(@Data.value('(/row/File_Name/text())[1]','nvarchar(max)'))>200 OR CHARINDEX(CHAR(13),@File_Name)>0 OR CHARINDEX(CHAR(10),@File_Name)>0 OR CHARINDEX('/',@File_Name)>0 OR CHARINDEX(N'',@File_Name)>0 THROW 51201,N'بيانات الملف غير صحيحة.',1;
 DECLARE @Before xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 IF @ID<>0 DELETE dbo.CRM_WorkGuide_ItemCategories WHERE Item_ID=@ID;
 IF @ID=0 BEGIN
 INSERT dbo.CRM_WorkGuide_Items(Brand_ID,Name_AR,Name_EN,Summary_AR,Summary_EN,Details_AR,Details_EN,Sort_Order,File_Url,File_Name,File_Extension,File_Size,Is_Active,AddedUser) VALUES(@Brand_ID,@Name_AR,@Name_EN,@Summary_AR,@Summary_EN,@Details_AR,@Details_EN,@Sort_Order,@File_Url,@File_Name,@File_Extension,@File_Size,@Active,@Actor_ID);SET @ID=CONVERT(int,SCOPE_IDENTITY());END
 ELSE UPDATE dbo.CRM_WorkGuide_Items SET Brand_ID=@Brand_ID,Name_AR=@Name_AR,Name_EN=@Name_EN,Summary_AR=@Summary_AR,Summary_EN=@Summary_EN,Details_AR=@Details_AR,Details_EN=@Details_EN,Sort_Order=@Sort_Order,File_Url=@File_Url,File_Name=@File_Name,File_Extension=@File_Extension,File_Size=@File_Size,Is_Active=@Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 INSERT dbo.CRM_WorkGuide_ItemCategories(Item_ID,Category_ID,Brand_ID) SELECT @ID,ID,@Brand_ID FROM @Selected;
 DECLARE @After xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
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
 DECLARE @Before xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 UPDATE dbo.CRM_WorkGuide_Items SET Is_Active=@Is_Active,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
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
 DECLARE @Before xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
 (SELECT c.ID,c.Name_AR,c.Name_EN FROM dbo.CRM_WorkGuide_ItemCategories x JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID WHERE x.Item_ID=i.ID ORDER BY c.Sort_Order,c.ID FOR XML PATH('category'),ROOT('Categories'),TYPE)
 FROM dbo.CRM_WorkGuide_Items i WHERE i.ID=@ID FOR XML PATH('row'),TYPE);
 UPDATE dbo.CRM_WorkGuide_Items SET Is_Deleted=1,Is_Active=0,Modified_User=@Actor_ID,Modified_Date=SYSDATETIME() WHERE ID=@ID;
 DECLARE @After xml=(SELECT i.ID,i.Brand_ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,i.Details_AR,i.Details_EN,i.Sort_Order,i.File_Url,i.File_Name,i.File_Extension,i.File_Size,i.Is_Active,i.Is_Deleted,
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
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_List @AccountID int,@Stamp uniqueidentifier,@Category_ID int=NULL,@Items bit=0 AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brand_ID int=(SELECT Brand_ID FROM dbo.CRM_Accounts WHERE ID=@AccountID);
 IF @Category_ID IS NULL AND @Items=0
 SELECT c.ID,c.Parent_ID,c.Sort_Order,c.Name_AR,c.Name_EN,p.Can_View,p.Can_Download,COUNT(i.ID) Item_Count FROM dbo.CRM_WorkGuide_Access p
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 LEFT JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID LEFT JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Brand_ID=@Brand_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE c.Brand_ID=@Brand_ID AND p.Account_ID=@AccountID GROUP BY c.ID,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,p.Can_View,p.Can_Download ORDER BY c.Sort_Order,c.Name_AR,c.ID;
 ELSE BEGIN
 IF @Category_ID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID WHERE c.Brand_ID=@Brand_ID AND p.Account_ID=@AccountID AND c.ID=@Category_ID AND c.Is_Deleted=0) THROW 51912,N'التصنيف غير متاح.',1;
 SELECT i.ID,i.Name_AR,i.Name_EN,i.Summary_AR,i.Summary_EN,CASE WHEN p.Can_View=1 THEN i.Details_AR ELSE N'' END Details_AR,CASE WHEN p.Can_View=1 THEN i.Details_EN ELSE N'' END Details_EN,i.File_Extension,i.Sort_Order,p.Can_View,p.Can_Download,c.Name_AR Category_Name,c.ID Category_ID
 FROM dbo.CRM_WorkGuide_Access p JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=p.Category_ID AND c.Is_Deleted=0
 JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Category_ID=c.ID JOIN dbo.CRM_WorkGuide_Items i ON i.ID=x.Item_ID AND i.Brand_ID=@Brand_ID AND i.Is_Active=1 AND i.Is_Deleted=0
 WHERE c.Brand_ID=@Brand_ID AND p.Account_ID=@AccountID AND (@Category_ID IS NULL OR c.ID=@Category_ID) ORDER BY i.Sort_Order,i.Name_AR,i.ID;
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
 DECLARE @Brand_ID int=(SELECT Brand_ID FROM dbo.CRM_Accounts WHERE ID=@AccountID);
 IF @Action IS NULL OR @Action NOT IN('view','download','details') THROW 51912,N'العملية غير متاحة.',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.CRM_WorkGuide_Items i JOIN dbo.CRM_WorkGuide_ItemCategories x ON x.Item_ID=i.ID
 JOIN dbo.CRM_WorkGuide_Categories c ON c.ID=x.Category_ID JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
 WHERE c.Brand_ID=@Brand_ID AND i.Brand_ID=@Brand_ID AND i.ID=@ID AND c.ID=@Category_ID AND c.Is_Deleted=0 AND i.Is_Active=1 AND i.Is_Deleted=0 AND ((@Action IN('view','details') AND p.Can_View=1) OR (@Action='download' AND p.Can_Download=1))) THROW 51912,N'لا تملك صلاحية لهذه العملية ضمن التصنيف المحدد.',1;
 IF @Log=1 BEGIN
 DECLARE @Details xml=(SELECT @Category_ID Category_ID,c.Name_AR Category_Name,@Action Operation,i.Name_AR,i.Name_EN FROM dbo.CRM_WorkGuide_Items i CROSS JOIN dbo.CRM_WorkGuide_Categories c WHERE c.Brand_ID=@Brand_ID AND i.Brand_ID=@Brand_ID AND i.ID=@ID AND c.ID=@Category_ID FOR XML PATH('row'),TYPE);
 INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,After_Data,Note) VALUES(@AccountID,CASE @Action WHEN 'view' THEN 'guide-view' WHEN 'details' THEN 'guide-details' ELSE 'guide-download' END,N'WorkGuide_Items',@ID,@Details,CONCAT(N'التصنيف رقم ',@Category_ID));
 END;
 SELECT File_Url,File_Name,File_Extension,Name_AR,Name_EN,Details_AR,Details_EN FROM dbo.CRM_WorkGuide_Items WHERE ID=@ID;
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
-- Ancestors supply navigation context only, never inherited grants or extra documents.
CREATE OR ALTER PROCEDURE dbo.Customer_WorkGuide_Tree @AccountID int,@Stamp uniqueidentifier AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
 DECLARE @Brand int=(SELECT Brand_ID FROM dbo.CRM_Accounts WHERE ID=@AccountID);
 ;WITH Ancestors AS (
  SELECT c.ID,c.Parent_ID FROM dbo.CRM_WorkGuide_Categories c JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
  WHERE c.Brand_ID=@Brand AND c.Is_Deleted=0 AND (p.Can_View=1 OR p.Can_Download=1)
  UNION ALL SELECT c.ID,c.Parent_ID FROM dbo.CRM_WorkGuide_Categories c JOIN Ancestors a ON a.Parent_ID=c.ID WHERE c.Brand_ID=@Brand AND c.Is_Deleted=0
 )
 SELECT c.ID,c.Parent_ID,c.Name_AR,c.Name_EN,c.Sort_Order,CONVERT(bit,CASE WHEN p.Can_View=1 OR p.Can_Download=1 THEN 1 ELSE 0 END) Has_Access
 FROM dbo.CRM_WorkGuide_Categories c LEFT JOIN dbo.CRM_WorkGuide_Access p ON p.Category_ID=c.ID AND p.Account_ID=@AccountID
 WHERE c.Brand_ID=@Brand AND c.ID IN(SELECT ID FROM Ancestors) ORDER BY c.Sort_Order,c.Name_AR,c.ID OPTION(MAXRECURSION 32767);
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
CASE x.Action WHEN 'guide-details' THEN N'عرض تفاصيل دليل العمل' WHEN 'guide-list' THEN N'عرض قائمة دليل العمل' WHEN 'guide-view' THEN N'اطلاع على دليل العمل' WHEN 'guide-download' THEN N'تحميل دليل العمل' WHEN 'credentials' THEN N'تحديث بيانات الدخول' WHEN 'login' THEN N'تسجيل الدخول كعميل' WHEN 'logout' THEN N'تسجيل الخروج' WHEN 'login-failed' THEN N'محاولة دخول فاشلة' WHEN 'dashboard-view' THEN N'عرض لوحة العميل' WHEN 'contact-view' THEN N'عرض جهة اتصال' WHEN 'profile-update' THEN N'تعديل بيانات العميل' WHEN 'contact-create' THEN N'إضافة جهة اتصال' WHEN 'contact-update' THEN N'تعديل جهة اتصال / الحالة' WHEN 'contact-delete' THEN N'حذف جهة اتصال' WHEN 'feedback' THEN CONCAT(N'تقديم ',COALESCE(x.FeedbackTypeTitle,N'طلب')) ELSE x.Action END,x.Before_Data,x.After_Data,x.Note,
 CONVERT(datetime2,x.CreatedUtc AT TIME ZONE 'UTC' AT TIME ZONE 'Jordan Standard Time'),
 CASE WHEN x.ActorID IS NULL THEN COALESCE(a.Name_AR,N'زائر غير مصادق') ELSE u.FullName_Ar END,a.Name_AR,
 CASE WHEN x.ActorID IS NULL THEN N'بوابة العميل' ELSE N'إدارة النظام' END
FROM dbo.Customer_Portal_Activity x LEFT JOIN dbo.CRM_Accounts a ON a.ID=x.AccountID LEFT JOIN dbo.UsersMembers u ON u.ID=x.ActorID;
GO
