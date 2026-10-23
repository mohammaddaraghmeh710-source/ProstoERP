using System;
using System.Data;
using System.Linq;
using System.Collections.Generic;
namespace ProstoERP.Application.Data
{
    public static class MobileRowMapper
    {
        public static Dictionary<string, object> Row(DataRow row)
        {
            return row.Table.Columns.Cast<DataColumn>().ToDictionary(c => c.ColumnName, c =>
            {
                var value = row[c];
                if (value == DBNull.Value) return null;
                if (value is DateTime && (c.ColumnName.EndsWith("Utc") || c.ColumnName.EndsWith("ExpiresAt")))
                    return DateTime.SpecifyKind((DateTime)value, DateTimeKind.Utc);
                return value;
            });
        }
        public static List<Dictionary<string, object>> Rows(DataSet data, int table = 0)
        {
            if (data.Tables.Count <= table) return new List<Dictionary<string, object>>();
            return data.Tables[table].Rows.Cast<DataRow>().Select(r =>
            {
                var result = Row(r);
                foreach (var key in result.Keys.ToList())
                    if (result[key] is DateTime)
                        result[key] = DateTime.SpecifyKind((DateTime)result[key], DateTimeKind.Utc);
                return result;
            }).ToList();
        }
        public static List<Dictionary<string, object>> PortalRows(DataSet data, int index = 0)
        {
            return data.Tables.Count <= index ? new List<Dictionary<string, object>>() :
                data.Tables[index].Rows.Cast<DataRow>().Select(Row).ToList();
        }
    }
}
