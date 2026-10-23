using System.Collections.Generic;
using System.Data;
using ProstoERP.Application.Data;
using ProstoERP.Infrastructure.Mobile.Data;
namespace ProstoERP.Infrastructure.Mobile.Features.Feedback
{
    internal static class FeedbackStatements
    {
        internal static void Register(IDictionary<MobileStatement, MobileStatementDefinition> statements)
        {
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackTypes, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Types", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackTopics, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Topics", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackTransferTargets, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_TransferTargets", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackRecipients, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Recipients", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_MobileApiFeedbackRequests, new MobileStatementDefinition("dbo." + "MobileApi_FeedbackRequests", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_UploadEmployeeFeedbackRequests, new MobileStatementDefinition("SELECT Status,RowVersion FROM dbo.Employee_Feedback_Requests WITH(UPDLOCK,HOLDLOCK) WHERE ID=@ID", CommandType.Text));
            statements.Add(MobileStatement.Feedback_UpdateEmployeeFeedbackAction, new MobileStatementDefinition("dbo." + "Update_Employee_Feedback_Action", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_InsertEmployeeFeedbackRequest, new MobileStatementDefinition("dbo." + "Insert_Employee_Feedback_Request", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_UpdateEmployeeFeedbackRead, new MobileStatementDefinition("dbo." + "Update_Employee_Feedback_Read", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackRequest, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Request", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_OpenEmployeeFeedbackTypes, new MobileStatementDefinition("SELECT Title_Ar,Title_En FROM dbo.Employee_Feedback_Types WHERE ID=@Type", CommandType.Text));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackAttachments, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Attachments", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackContact, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Contact", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackWorkflow, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Workflow", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackDownload, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Download", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackNotifications, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Notifications", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_MobileApiFeedbackActor, new MobileStatementDefinition("dbo." + "MobileApi_FeedbackActor", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackPermissions, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_Permissions", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_SelectEmployeeFeedbackTargetTypes, new MobileStatementDefinition("dbo." + "Select_Employee_Feedback_TargetTypes", CommandType.StoredProcedure));
            statements.Add(MobileStatement.Feedback_RequireAccessEmployeeFeedbackAccess, new MobileStatementDefinition("SELECT ID FROM dbo.Employee_Feedback_Access(@Actor,0) WHERE ID=@ID", CommandType.Text));
            statements.Add(MobileStatement.Feedback_FindReplayLock, new MobileStatementDefinition("DECLARE @Result int; EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000; IF @Result<0 THROW 51802,'Operation busy.',1;", CommandType.Text));
            statements.Add(MobileStatement.Feedback_FindReplayMobileApiFeedbackEvents, new MobileStatementDefinition("SELECT RequestID,PayloadHash FROM dbo.MobileApi_FeedbackEvents WHERE ActorID=@Actor AND OperationID=@Operation", CommandType.Text));
            statements.Add(MobileStatement.Feedback_RecordEmployeeFeedbackWorkflow, new MobileStatementDefinition(@"INSERT dbo.MobileApi_FeedbackEvents(ActorID,OperationID,PayloadHash,RequestID,EventType,OccurredAt,ReceivedUtc,WorkflowGroupID,ViewID)
                SELECT @Actor,@Operation,@Hash,@ID,@Event,@Occurred,@Received,
                CASE WHEN @Event='open' THEN NULL ELSE (SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC) END,
                CASE WHEN @Event='open' THEN (SELECT MAX(ID) FROM dbo.Employee_Feedback_Views WHERE Request_ID=@ID AND UserID=@Actor) ELSE NULL END;", CommandType.Text));
        }
    }
}
