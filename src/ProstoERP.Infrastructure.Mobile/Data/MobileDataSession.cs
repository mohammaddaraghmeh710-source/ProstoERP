using System;
using ProstoERP.Application.Abstractions;
using System.Data;
using System.Data.SqlClient;

namespace ProstoERP.Infrastructure.Mobile.Data
{
    public sealed class MobileDataSession : IMobileDataSession
    {
        private readonly SqlConnection connection;
        private SqlTransaction transaction;

        public MobileDataSession(string connectionString)
        {
            connection = new SqlConnection(connectionString);
            connection.Open();
        }

        public void Dispose()
        {
            if (transaction != null) transaction.Dispose();
            connection.Dispose();
        }

        public void Begin()
        {
            transaction = connection.BeginTransaction();
        }

        public void Commit()
        {
            transaction.Commit();
            transaction.Dispose();
            transaction = null;
        }

        public bool RollbackConfirmed()
        {
            try
            {
                if (transaction == null || transaction.Connection == null) return false;
                transaction.Rollback();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public DataSet Execute(ProstoERP.Application.Data.MobileStatement statement, params object[] parameters)
        {
            var definition = MobileStatements.Get(statement);
            return Query(definition.Text, definition.Type, parameters);
        }

        private DataSet Query(string sql, CommandType type, object[] parameters)
        {
            using (var cmd = new SqlCommand(sql, connection, transaction))
            {
                cmd.CommandType = type;
                cmd.CommandTimeout = 60;
                for (var i = 0; i < parameters.Length; i += 2)
                    cmd.Parameters.AddWithValue("@" + parameters[i], parameters[i + 1] ?? DBNull.Value);
                var result = new DataSet();
                using (var adapter = new SqlDataAdapter(cmd))
                {
                    adapter.Fill(result);
                }

                return result;
            }
        }
    }
}
