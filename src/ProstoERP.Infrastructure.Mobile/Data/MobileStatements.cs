using System;
using System.Data;
using System.Collections.Generic;
using ProstoERP.Application.Data;
namespace ProstoERP.Infrastructure.Mobile.Data
{
    internal sealed class MobileStatementDefinition
    {
        internal readonly string Text;
        internal readonly CommandType Type;
        internal MobileStatementDefinition(string text, CommandType type) { Text = text; Type = type; }
    }
    internal static class MobileStatements
    {
        private static readonly IDictionary<MobileStatement, MobileStatementDefinition> Definitions = Create();
        private static IDictionary<MobileStatement, MobileStatementDefinition> Create()
        {
            var statements = new Dictionary<MobileStatement, MobileStatementDefinition>();
            Features.Feedback.FeedbackStatements.Register(statements);
            Features.Correspondence.CorrespondenceStatements.Register(statements);
            Features.CustomerFeedback.CustomerFeedbackStatements.Register(statements);
            Features.CustomerPortal.CustomerPortalStatements.Register(statements);
            return statements;
        }
        internal static MobileStatementDefinition Get(MobileStatement statement)
        {
            return Definitions[statement];
        }
    }
}
