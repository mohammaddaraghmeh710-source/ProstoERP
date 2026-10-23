using System;
using System.Data;
using System.Data.SqlClient;
using ProstoERP.Application.Abstractions;
namespace ProstoERP.Infrastructure.Mobile.Data
{
    public interface IMobileQueryStore
    {
        DataSet Query(string procedure, params SqlParameter[] parameters);
    }
    public sealed class MobileQueryStore : IMobileQueryStore
    {
        private readonly Func<string> connectionString;
        public MobileQueryStore(Func<string> connectionString) { this.connectionString = connectionString; }
        public DataSet Query(string procedure, params SqlParameter[] parameters)
        {
            using (var connection = new SqlConnection(connectionString()))
            using (var command = new SqlCommand(procedure, connection))
            using (var adapter = new SqlDataAdapter(command))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddRange(parameters);
                var result = new DataSet();
                adapter.Fill(result);
                return result;
            }
        }
    }
}
