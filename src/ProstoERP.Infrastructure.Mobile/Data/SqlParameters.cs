using System;
using System.Data;
using System.Data.SqlClient;
namespace ProstoERP.Infrastructure.Mobile.Data
{
    public static class SqlParameters
    {
        public static SqlParameter P(string name, SqlDbType type, object value, int size = 0)
        {
            return new SqlParameter(name, type) { Size = size, Value = value ?? DBNull.Value };
        }
    }
}
