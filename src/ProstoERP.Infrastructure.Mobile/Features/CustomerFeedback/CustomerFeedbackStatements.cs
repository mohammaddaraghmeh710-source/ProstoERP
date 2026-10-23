using System.Collections.Generic;
using System.Data;
using ProstoERP.Application.Data;
using ProstoERP.Infrastructure.Mobile.Data;
namespace ProstoERP.Infrastructure.Mobile.Features.CustomerFeedback
{
    internal static class CustomerFeedbackStatements
    {
        internal static void Register(IDictionary<MobileStatement, MobileStatementDefinition> statements)
        {
            statements.Add(MobileStatement.CustomerFeedback_SelectCustomerFeedbackOptions, new MobileStatementDefinition("dbo.Select_Customer_Feedback_Options", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerFeedback_CreateLock, new MobileStatementDefinition("DECLARE @Result int; EXEC @Result=sys.sp_getapplock @Resource=@Key,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000; IF @Result<0 THROW 51802,'Operation busy.',1;", CommandType.Text));
            statements.Add(MobileStatement.CustomerFeedback_CreateCustomerFeedbackSubmissions, new MobileStatementDefinition("SELECT RequestID,PayloadHash FROM dbo.Customer_Feedback_Submissions WHERE OperationID=@Operation", CommandType.Text));
            statements.Add(MobileStatement.CustomerFeedback_InsertCustomerFeedbackRequest, new MobileStatementDefinition("dbo.Insert_Customer_Feedback_Request", CommandType.StoredProcedure));
            statements.Add(MobileStatement.CustomerFeedback_CreateEmployeeFeedbackWorkflow, new MobileStatementDefinition(@"INSERT dbo.Customer_Feedback_Submissions(OperationID,PayloadHash,RequestID,OccurredAt,ReceivedUtc,WorkflowGroupID)
                            SELECT @Operation,@Hash,@ID,@Occurred,@Received,GroupID FROM
                            (SELECT TOP(1) GroupID FROM dbo.Employee_Feedback_Workflow WHERE Request_ID=@ID ORDER BY ID DESC) w;", CommandType.Text));
            statements.Add(MobileStatement.CustomerFeedback_CustomerFeedbackCheckRate, new MobileStatementDefinition("dbo.Customer_Feedback_CheckRate", CommandType.StoredProcedure));
        }
    }
}
