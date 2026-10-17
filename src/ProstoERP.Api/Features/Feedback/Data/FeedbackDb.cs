using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace Prosto_ERP_API.Mobile
{
    internal sealed class FeedbackDb : IDisposable {
        readonly SqlConnection connection; SqlTransaction transaction;
        internal FeedbackDb() { connection=new SqlConnection(ConfigurationManager.ConnectionStrings["Prosto_ERP_ConnectionConnection"].ConnectionString); connection.Open(); }
        internal void Begin() { transaction=connection.BeginTransaction(); }
        internal void Commit() { transaction.Commit(); transaction.Dispose(); transaction=null; }
        internal bool RollbackConfirmed() { try { if(transaction==null || transaction.Connection==null) return false; transaction.Rollback(); return true; } catch { return false; } }
        internal DataSet Proc(string name,params object[] parameters) { return Query(name,CommandType.StoredProcedure,parameters); }
        internal DataSet Text(string sql,params object[] parameters) { return Query(sql,CommandType.Text,parameters); }
        DataSet Query(string sql,CommandType type,object[] parameters) {
            using(var cmd=new SqlCommand(sql,connection,transaction)) {
                cmd.CommandType=type; cmd.CommandTimeout=60;
                for(int i=0;i<parameters.Length;i+=2) cmd.Parameters.AddWithValue("@"+parameters[i],parameters[i+1]??DBNull.Value);
                var result=new DataSet(); using(var adapter=new SqlDataAdapter(cmd)) adapter.Fill(result); return result;
            }
        }
        public void Dispose() { if(transaction!=null) transaction.Dispose(); connection.Dispose(); }
    }
}
