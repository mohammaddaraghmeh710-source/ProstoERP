-- Synthetic fixture only: invoked by Test-CustomerPortal -FeedbackOnly, never a source database.
IF DB_NAME() NOT LIKE 'Prosto[_]Customer[_]Test[_]%' THROW 51999,'Only a synthetic customer test database is allowed.',1;
SET NOCOUNT ON;
UPDATE dbo.Employee_Feedback_Permissions SET CanSubmit=1,CanTransfer=1,CanClose=1 WHERE UserTypeID IN(1,4);
INSERT dbo.Employee_Feedback_AllowedRecipients(SenderUserTypeID,RecipientUserTypeID)
SELECT x.Sender,x.Recipient FROM(VALUES(1,1),(1,4),(4,1)) x(Sender,Recipient)
WHERE NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_AllowedRecipients a WHERE a.SenderUserTypeID=x.Sender AND a.RecipientUserTypeID=x.Recipient);
DECLARE @ID int,@CustomerID int,@EmployeeOpenID int,@CustomerOpenID int,@Before int,@Version binary(8),@Stale binary(8),@Group uniqueidentifier;
DECLARE @Stamp uniqueidentifier=(SELECT SecurityStamp FROM dbo.Customer_Logins WHERE AccountID=1),@OtherStamp uniqueidentifier=(SELECT SecurityStamp FROM dbo.Customer_Logins WHERE AccountID=2);
DECLARE @EmployeeName nvarchar(max)=(SELECT FullName_Ar FROM dbo.UsersMembers WHERE ID=2);
IF @Stamp IS NULL OR @OtherStamp IS NULL THROW 51999,'Customer test identities must be seeded.',1;

EXEC dbo.Insert_Employee_Feedback_Request @Actor=2,@Type=1,@Topic=1,@Title=N'WS_EMPLOYEE_ANONYMOUS',@Details=N'Synthetic private employee complaint',@Disclose=0,@Target=1,@Files=N'<files/>';
SELECT @ID=ID FROM dbo.Employee_Feedback_Requests WHERE Title=N'WS_EMPLOYEE_ANONYMOUS';
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND NotificationType=1)<>3 THROW 51999,'Create must notify employee creator and both addressed administrators once.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND UserID=2 AND IsRead=0) THROW 51999,'Employee creator notice missing.',1;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND NotificationType=1 AND Action_ID IS NOT NULL) THROW 51999,'Creation notice changed the existing nullable action contract.',1;
IF EXISTS(SELECT 1 FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@ID) THROW 51999,'Employee complaint must not notify a customer principal.',1;
SELECT @Group=GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID;
BEGIN TRAN;EXEC dbo.Feedback_PublishNotifications @RequestID=@ID,@GroupID=@Group;COMMIT;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID)<>3 THROW 51999,'Repeated event publication duplicated a notice.',1;
SELECT @Stale=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
EXEC dbo.Update_Employee_Feedback_Read @Actor=1,@ID=@ID;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND UserID=1 AND IsRead=0) THROW 51999,'Authorized employee detail did not acknowledge own notices.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND UserID=2 AND IsRead=0) THROW 51999,'Opening one employee detail cleared another recipient notices.',1;
BEGIN TRY EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@ID,@Version=@Stale,@Action=2,@Comment=N'Stale action',@Files=N'<files/>',@TargetType=1;THROW 51999,'Stale read-state version accepted.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51500 THROW;END CATCH;
SELECT @Version=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@ID,@Version=@Version,@Action=2,@Comment=N'Forward to the other administrator',@Files=N'<files/>',@TargetType=1;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND NotificationType=2)<>3 THROW 51999,'Transfer must notify creator, prior receivers and new receivers without duplicates.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE ID=@ID AND Status=2) THROW 51999,'Transfer status was not preserved.',1;
SELECT @Version=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@ID;
BEGIN TRY EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@ID,@Version=@Version,@Action=3,@Comment=N'Old receiver action',@Files=N'<files/>';THROW 51999,'An old receiver acted on a newer route.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51500 THROW;END CATCH;
BEGIN TRY EXEC dbo.Update_Employee_Feedback_Read @Actor=4,@ID=@ID;THROW 51999,'An unrelated employee acknowledged private notices.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51500 THROW;END CATCH;
EXEC dbo.Update_Employee_Feedback_Action @Actor=3,@ID=@ID,@Version=@Version,@Action=3,@Comment=N'Closed after review',@Files=N'<files/>';
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE ID=@ID AND Status=3 AND CloseDate IS NOT NULL) THROW 51999,'Close state/date was not saved.',1;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID AND NotificationType=3)<>3 THROW 51999,'Close must notify the employee creator and every involved receiver.',1;
SELECT @Before=COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID;
BEGIN TRY EXEC dbo.Update_Employee_Feedback_Action @Actor=3,@ID=@ID,@Version=@Version,@Action=3,@Comment=N'Repeated close',@Files=N'<files/>';THROW 51999,'Repeated close accepted.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51500 THROW;END CATCH;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@ID)<>@Before THROW 51999,'Rejected action published notices.',1;
DECLARE @Logs table(Request_ID int,EventDate datetime,EventType nvarchar(max),ActorName nvarchar(max));
INSERT @Logs EXEC dbo.Select_Employee_Feedback_Logs @Actor=1,@ID=@ID;
IF EXISTS(SELECT 1 FROM @Logs WHERE ActorName=@EmployeeName) THROW 51999,'Anonymous employee identity leaked through notification logs.',1;
IF NOT EXISTS(SELECT 1 FROM @Logs WHERE EventType LIKE N'تنبيه:%') OR NOT EXISTS(SELECT 1 FROM @Logs WHERE EventType=N'قراءة تنبيه') THROW 51999,'Employee notification delivery/read events missing from unified logs.',1;
SELECT N'Employee create/transfer/close, recipients, dedupe, authorized read, stale actions and anonymous log masking' Passed;

DECLARE @Operation uniqueidentifier=NEWID();
EXEC dbo.Customer_SubmitFeedback @AccountID=1,@Stamp=@Stamp,@OperationID=@Operation,@Type=1,@Topic=1,@Brand=1,@Branch=1,@Mobile='0790000000',@Title=N'WS_CUSTOMER_NOTICES',@Details=N'Synthetic customer complaint',@Files=N'<files/>';
SELECT @CustomerID=RequestID FROM dbo.Customer_Portal_Feedback WHERE AccountID=1 AND OperationID=@Operation;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE ID=@CustomerID AND EmployeeID IS NULL AND SourceType=2 AND DiscloseIdentity=1) THROW 51999,'Customer complaint invented an employee identity or lost disclosed source.',1;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@CustomerID AND NotificationType=1)<>2 OR (SELECT COUNT(*) FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID AND AccountID=1 AND NotificationType=1)<>1 THROW 51999,'Customer create must notify both administrators and the real customer once.',1;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Workflow w JOIN dbo.UsersMembers u ON u.ID=w.ReceiverID WHERE w.Request_ID=@CustomerID AND u.Type<>1) THROW 51999,'Customer complaint routed to a nonadministrator.',1;
EXEC dbo.Customer_SubmitFeedback @AccountID=1,@Stamp=@Stamp,@OperationID=@Operation,@Type=1,@Topic=1,@Brand=1,@Branch=1,@Mobile='0790000000',@Title=N'WS_CUSTOMER_NOTICES',@Details=N'Synthetic customer complaint',@Files=N'<files/>';
IF (SELECT COUNT(*) FROM dbo.Customer_Portal_Feedback WHERE AccountID=1 AND OperationID=@Operation AND RequestID=@CustomerID)<>1 OR (SELECT COUNT(*) FROM dbo.Employee_Feedback_Requests WHERE Title=N'WS_CUSTOMER_NOTICES')<>1 OR (SELECT COUNT(*) FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID)<>1 THROW 51999,'Submission replay duplicated the customer event.',1;
BEGIN TRY EXEC dbo.Customer_Feedback_NoticeRead @AccountID=2,@Stamp=@OtherStamp,@RequestID=@CustomerID;THROW 51999,'Another customer acknowledged private notices.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51912 THROW;END CATCH;
IF NOT EXISTS(SELECT 1 FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID AND AccountID=1 AND IsRead=0) THROW 51999,'Denied customer acknowledgement changed unread state.',1;
EXEC dbo.Customer_Feedback_NoticeRead @AccountID=1,@Stamp=@Stamp,@RequestID=@CustomerID;
IF EXISTS(SELECT 1 FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID AND AccountID=1 AND IsRead=0) THROW 51999,'Own customer detail acknowledgement failed.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@CustomerID AND UserID=1 AND IsRead=0) THROW 51999,'Customer principal acknowledgement cleared colliding employee ID notices.',1;
SELECT @Version=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@CustomerID;
BEGIN TRY EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@CustomerID,@Version=@Version,@Action=2,@Comment=N'Forged customer transfer to employees',@Files=N'<files/>',@TargetType=4;THROW 51999,'Customer complaint transferred to an employee type.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51500 THROW;END CATCH;
IF (SELECT COUNT(*) FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID)<>1 OR NOT EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE ID=@CustomerID AND RowVersion=@Version) THROW 51999,'Rejected customer route mutated state or notices.',1;
EXEC dbo.Update_Employee_Feedback_Action @Actor=1,@ID=@CustomerID,@Version=@Version,@Action=2,@Comment=N'Forward within administrators',@Files=N'<files/>',@TargetType=1;
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@CustomerID AND NotificationType=2)<>2 OR (SELECT COUNT(*) FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID AND NotificationType=2 AND IsRead=0)<>1 THROW 51999,'Customer transfer notifications are incomplete.',1;
SELECT @Version=RowVersion FROM dbo.Employee_Feedback_Requests WHERE ID=@CustomerID;
EXEC dbo.Update_Employee_Feedback_Action @Actor=3,@ID=@CustomerID,@Version=@Version,@Action=3,@Comment=N'Customer complaint resolved',@Files=N'<files/>';
IF (SELECT COUNT(*) FROM dbo.Employee_Feedback_Notifications WHERE Request_ID=@CustomerID AND NotificationType=3)<>2 OR (SELECT COUNT(*) FROM dbo.Customer_Feedback_Notifications WHERE RequestID=@CustomerID AND NotificationType=3 AND IsRead=0)<>1 THROW 51999,'Customer close did not notify all real principals.',1;
DELETE @Logs;INSERT @Logs EXEC dbo.Select_Employee_Feedback_Logs @Actor=1,@ID=@CustomerID;
IF NOT EXISTS(SELECT 1 FROM @Logs WHERE EventType LIKE N'تنبيه عميل:%') OR NOT EXISTS(SELECT 1 FROM @Logs WHERE EventType=N'قراءة تنبيه عميل') THROW 51999,'Customer notification delivery/read events missing from unified logs.',1;
SELECT N'Customer principal isolation, replay, administrator-only routing and independent event/read notifications' Passed;

SET @Operation=NEWID();
BEGIN TRY EXEC dbo.Customer_SubmitFeedback @AccountID=1,@Stamp=@Stamp,@OperationID=@Operation,@Type=1,@Topic=1,@Brand=1,@Branch=2,@Mobile='0790000000',@Title=N'WS_FORGED_BRANCH',@Details=N'Should be rejected',@Files=N'<files/>';THROW 51999,'Unassigned same-brand branch accepted.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51910 THROW;END CATCH;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE Title=N'WS_FORGED_BRANCH') THROW 51999,'Rejected branch published a complaint.',1;
SET @Operation=NEWID();
BEGIN TRY EXEC dbo.Customer_SubmitFeedback @AccountID=1,@Stamp=@Stamp,@OperationID=@Operation,@Type=1,@Topic=1,@Brand=2,@Branch=3,@Mobile='0790000000',@Title=N'WS_FORGED_BRAND',@Details=N'Should be rejected',@Files=N'<files/>';THROW 51999,'Unassigned customer brand accepted.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51910 THROW;END CATCH;
IF EXISTS(SELECT 1 FROM dbo.Employee_Feedback_Requests WHERE Title=N'WS_FORGED_BRAND') THROW 51999,'Rejected brand published a complaint.',1;

-- Leave independent fresh requests for HTTP/UI/bell tests; no real users, messages or email.
EXEC dbo.Insert_Employee_Feedback_Request @Actor=2,@Type=1,@Topic=1,@Title=N'WS_EMPLOYEE_OPEN_HTTP',@Details=N'Fresh employee UI fixture',@Disclose=1,@Target=1,@Files=N'<files/>';
SET @Operation=NEWID();EXEC dbo.Customer_SubmitFeedback @AccountID=1,@Stamp=@Stamp,@OperationID=@Operation,@Type=2,@Topic=2,@Brand=1,@Branch=1,@Mobile='0790000000',@Title=N'WS_CUSTOMER_OPEN_HTTP',@Details=N'Fresh customer UI fixture',@Files=N'<files/>';
IF EXISTS(SELECT Request_ID,WorkflowGroup,UserID FROM dbo.Employee_Feedback_Notifications WHERE WorkflowGroup IS NOT NULL GROUP BY Request_ID,WorkflowGroup,UserID HAVING COUNT(*)>1) OR EXISTS(SELECT AccountID,RequestID,WorkflowGroup FROM dbo.Customer_Feedback_Notifications GROUP BY AccountID,RequestID,WorkflowGroup HAVING COUNT(*)>1) THROW 51999,'Workflow event notification duplicates found.',1;
SELECT @EmployeeOpenID=ID FROM dbo.Employee_Feedback_Requests WHERE Title=N'WS_EMPLOYEE_OPEN_HTTP';
SELECT @CustomerOpenID=RequestID FROM dbo.Customer_Portal_Feedback WHERE AccountID=1 AND OperationID=@Operation;
SELECT @ID EmployeeClosedRequest,@CustomerID CustomerClosedRequest,@EmployeeOpenID EmployeeOpenRequest,@CustomerOpenID CustomerOpenRequest;
SELECT N'No cross-brand/branch submission, rejected-action writes or duplicate workflow notifications' Passed;
