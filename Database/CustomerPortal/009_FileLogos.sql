-- File URLs replace binary logo payloads. Apply CRM/012 first.
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
CREATE OR ALTER PROCEDURE dbo.Customer_SaveProfile @AccountID int,@Stamp uniqueidentifier,@Data xml,@Version binary(8),@Logo_Url nvarchar(260)=NULL AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 BEGIN TRY BEGIN TRAN;
 EXEC dbo.Customer_WriteCheck @AccountID,@Stamp;
IF @Data IS NULL OR @Data.value('count(/row)','int')<>1 OR @Data.exist('/row/*[not(local-name()=("Name_AR","Name_EN","Phone","Email","Address","Country","Website","Registration_Number"))]')=1 THROW 51910,N'بيانات النموذج غير صحيحة.',1;
DECLARE @Name_AR nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_AR/text())[1]','nvarchar(max)'))>200 OR @Name_AR IS NULL THROW 51910,N'يرجى استكمال حقل الاسم بالعربية ضمن الطول المسموح.',1;
DECLARE @Name_EN nvarchar(200)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Name_EN/text())[1]','nvarchar(max)'))>200 THROW 51910,N'يرجى استكمال حقل الاسم بالإنجليزية ضمن الطول المسموح.',1;
DECLARE @Phone nvarchar(50)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Phone/text())[1]','nvarchar(max)'))>50 THROW 51910,N'يرجى استكمال حقل Phone ضمن الطول المسموح.',1;
DECLARE @Email nvarchar(254)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Email/text())[1]','nvarchar(max)'))>254 THROW 51910,N'يرجى استكمال حقل Email ضمن الطول المسموح.',1;
DECLARE @Address nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Address/text())[1]','nvarchar(max)'))>500 THROW 51910,N'يرجى استكمال حقل Address ضمن الطول المسموح.',1;
DECLARE @Country nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Country/text())[1]','nvarchar(max)'))>100 THROW 51910,N'يرجى استكمال حقل Country ضمن الطول المسموح.',1;
DECLARE @Website nvarchar(500)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Website/text())[1]','nvarchar(max)'))>500 THROW 51910,N'يرجى استكمال حقل Website ضمن الطول المسموح.',1;
DECLARE @Registration_Number nvarchar(100)=NULLIF(LTRIM(RTRIM(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))),N'');
IF LEN(@Data.value('(/row/Registration_Number/text())[1]','nvarchar(max)'))>100 THROW 51910,N'يرجى استكمال حقل Registration_Number ضمن الطول المسموح.',1;
IF @Email IS NOT NULL AND @Email NOT LIKE N'%_@_%._%' THROW 51910,N'البريد الإلكتروني غير صحيح.',1;
IF @Website IS NOT NULL AND @Website NOT LIKE N'https://_%' AND @Website NOT LIKE N'http://_%' THROW 51910,N'أدخل رابطًا يبدأ بـ https أو http.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID=@AccountID AND Row_Version=@Version) THROW 51910,N'تم تعديل بياناتك؛ أعد فتح النموذج قبل الحفظ.',1;
IF @Logo_Url IS NOT NULL AND (@Logo_Url COLLATE Latin1_General_100_BIN2 NOT LIKE N'/FileManager/CustomerLogos/'+REPLICATE(N'[0-9a-f]',32)+N'.png' OR DATALENGTH(@Logo_Url)<>126) THROW 51910,N'مسار الشعار غير صحيح.',1;
IF EXISTS(SELECT 1 FROM dbo.CRM_Accounts WHERE ID<>@AccountID AND (UPPER(LTRIM(RTRIM(Name_AR)))=UPPER(@Name_AR) OR (@Registration_Number IS NOT NULL AND Registration_Number=@Registration_Number))) THROW 51910,N'اسم العميل أو رقم التسجيل مستخدم مسبقًا.',1;
DECLARE @Before xml=(SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version,CONVERT(bit,CASE WHEN Logo_Url IS NULL THEN 0 ELSE 1 END) HasLogo FROM dbo.CRM_Accounts WHERE ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
UPDATE dbo.CRM_Accounts SET Name_AR=@Name_AR,Name_EN=@Name_EN,Phone=@Phone,Email=@Email,Address=@Address,Country=@Country,Website=@Website,Registration_Number=@Registration_Number,Logo_Url=COALESCE(@Logo_Url,Logo_Url),Modified_User=NULL,Modified_Date=SYSDATETIME() WHERE ID=@AccountID;
DECLARE @After xml=(SELECT Name_AR,Name_EN,Phone,Email,Address,Country,Website,Registration_Number,Row_Version,CONVERT(bit,CASE WHEN Logo_Url IS NULL THEN 0 ELSE 1 END) HasLogo,CONVERT(bit,CASE WHEN @Logo_Url IS NULL THEN 0 ELSE 1 END) LogoChanged FROM dbo.CRM_Accounts WHERE ID=@AccountID FOR XML PATH('row'),BINARY BASE64,TYPE);
INSERT dbo.Customer_Portal_Activity(AccountID,Action,Entity,RecordID,Note,Before_Data,After_Data) VALUES(@AccountID,'profile-update',N'Accounts',@AccountID,N'تعديل بيانات العميل من بوابة العميل',@Before,@After);
 COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK;THROW;END CATCH
END;
GO
