-- Apply after CRM/011 and CustomerPortal/007. Legacy English titles remain NULL.
CREATE OR ALTER PROCEDURE dbo.Customer_Dashboard @AccountID int,@Stamp uniqueidentifier,@Section varchar(16)='profile' AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Logins l JOIN dbo.CRM_Accounts a ON a.ID=l.AccountID
 WHERE l.AccountID=@AccountID AND l.SecurityStamp=@Stamp AND l.IsActive=1 AND a.Is_Active=1 AND a.Is_Deleted=0)
 THROW 51911,N'انتهت صلاحية الدخول؛ سجل الدخول مجددًا.',1;
 IF @Section='profile'
 SELECT a.Name_AR,a.Name_EN,a.Phone,a.Email,t.Name_AR TypeName,b.Title_Ar BrandName,br.Title_Ar BranchName,
 (SELECT COUNT(*) FROM dbo.CRM_Contacts c WHERE c.Account_ID=a.ID AND c.Is_Deleted=0) ContactCount
 FROM dbo.CRM_Accounts a LEFT JOIN dbo.CRM_Account_Types t ON t.ID=a.Account_Type_ID
 LEFT JOIN dbo.Brands b ON b.ID=a.Brand_ID LEFT JOIN dbo.Branches br ON br.ID=a.Branch_ID WHERE a.ID=@AccountID;
 ELSE IF @Section='contacts'
 SELECT ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Row_Version FROM dbo.CRM_Contacts WHERE Account_ID=@AccountID AND Is_Deleted=0 ORDER BY Name_AR,ID;
 ELSE IF @Section='editor'
 SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version FROM dbo.CRM_Accounts WHERE ID=@AccountID;
 ELSE IF @Section='logo'
 SELECT Logo_Url FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Logo_Url IS NOT NULL;
 ELSE THROW 51910,N'الطلب غير متاح.',1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_SaveContact @AccountID int,@Stamp uniqueidentifier,@ID int=0,@Data xml,@Version binary(8)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF @Data IS NULL OR @Data.value('count(/row)','int')<>1 OR @Data.exist('/row/*[not(local-name()=("Name_AR","Name_EN","Job_Title","Job_Title_EN","Phone","Email","Gender","Is_Active"))]')=1 THROW 51910,N'بيانات النموذج غير صحيحة.',1;
DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 OR @Name_AR IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالعربية ضمن الطول المسموح.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 OR @Name_EN IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالإنجليزية ضمن الطول المسموح.',1;
DECLARE @Job_Title nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))),N'');
IF @Job_Title IS NULL OR LEN(@Data.value('(/row/Job_Title/text())[1]','nvarchar(max)'))>200 THROW 51910,N'أدخل المسمى الوظيفي بالعربية (حتى 200 حرف).',1;
DECLARE @Job_Title_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))),N'');
IF @Job_Title_EN IS NULL OR LEN(@Data.value('(/row/Job_Title_EN/text())[1]','nvarchar(max)'))>200 THROW 51910,N'أدخل المسمى الوظيفي بالإنجليزية (حتى 200 حرف).',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))>50 THROW 51910,N'يرجى استكمال حقل Phone ضمن الطول المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))>254 THROW 51910,N'يرجى استكمال حقل Email ضمن الطول المسموح.',1;
DECLARE @Gender nvarchar(20)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Gender/text())[1]','nvarchar(max)'))>20 THROW 51910,N'يرجى استكمال حقل Gender ضمن الطول المسموح.',1;
IF @Email IS NOT NULL AND @Email NOT LIKE N'%_@_%._%' THROW 51910,N'البريد الإلكتروني غير صحيح.',1;
DECLARE @Active bit=TRY_CONVERT(bit,@Data.value('(/row/Is_Active/text())[1]','nvarchar(5)'));
IF @Active IS NULL OR @ID<0 THROW 51910,N'حالة جهة الاتصال غير صحيحة.',1;
IF @Gender IS NOT NULL AND @Gender NOT IN(N'M',N'F') THROW 51910,N'الجنس غير صحيح.',1;
IF @ID<>0 AND NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Account_ID=@AccountID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51910,N'جهة الاتصال غير متاحة أو تم تعديلها؛ حدّث القائمة.',1;
DECLARE @Before xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
DECLARE @New bit=CASE WHEN @ID=0 THEN 1 ELSE 0 END;
IF @ID=0 BEGIN INSERT dbo.CRM_Contacts(Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,AddedUser) VALUES(@AccountID,@Name_AR,@Name_EN,@Job_Title,@Job_Title_EN,@Phone,@Email,@Gender,@Active,NULL);SET @ID=CONVERT(int,SCOPE_IDENTITY());END
ELSE UPDATE dbo.CRM_Contacts SET Name_AR=@Name_AR,Name_EN=@Name_EN,Job_Title=@Job_Title,Job_Title_EN=@Job_Title_EN,Phone=@Phone,Email=@Email,Gender=@Gender,Is_Active=@Active,Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@ID AND Account_ID=@AccountID;
DECLARE @After xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,CASE WHEN @New=1 THEN 'contact-create' ELSE 'contact-update' END,N'Contacts',@ID,N'حفظ جهة اتصال من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
CREATE OR ALTER PROCEDURE dbo.Customer_DeleteContact @AccountID int,@Stamp uniqueidentifier,@ID int,@Version binary(8) AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Contacts WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID AND Account_ID=@AccountID AND Is_Deleted=0 AND Row_Version=@Version) THROW 51910,N'جهة الاتصال غير متاحة أو تم تعديلها؛ حدّث القائمة.',1;
DECLARE @Before xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
UPDATE dbo.CRM_Contacts SET Is_Deleted=1,Is_Active=0,Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@ID AND Account_ID=@AccountID;
DECLARE @After xml=(SELECT ID,Account_ID,Name_AR,Name_EN,Job_Title,Job_Title_EN,Phone,Email,Gender,Is_Active,Is_Deleted,Row_Version FROM dbo.CRM_Contacts WHERE ID=@ID AND Account_ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,'contact-delete',N'Contacts',@ID,N'حذف جهة اتصال من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
