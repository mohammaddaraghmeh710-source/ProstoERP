using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using Prosto_ERP_API.Mobile;
using ProstoERP.Application.Data;
using ProstoERP.Contracts.Common;

namespace ProstoERP.Application.Features.Circulars
{
    public sealed class CircularService
    {
        private readonly ICircularStore store;
        public CircularService(ICircularStore store) { this.store = store; }

        public CountedPage<Dictionary<string, object>, Dictionary<string, object>> List(int actor, int employeeNumber,
            int page, int pageSize, string search, bool unreadOnly)
        {
            store.Employee(actor, employeeNumber);
            var data = store.List(actor, page, pageSize, search, unreadOnly);
            return new CountedPage<Dictionary<string, object>, Dictionary<string, object>>
            {
                Counts = MobileRowMapper.Row(data.Tables[0].Rows[0]),
                TotalItems = data.Tables[1].Rows[0]["TotalItems"], Page = page, PageSize = pageSize,
                Items = data.Tables[2].Rows.Cast<DataRow>().Select(Item).ToList()
            };
        }
        public Dictionary<string, object> Detail(int actor, int id, int employeeNumber)
        {
            store.Employee(actor, employeeNumber);
            return Item(store.Detail(actor, id).Tables[0].Rows[0]);
        }
        public CircularFile File(int actor, int id, CircularFileEvent model, object tokenHash)
        {
            store.Employee(actor, model.EmployeeNumber);
            var row = store.File(actor, id, model, tokenHash).Tables[0].Rows[0];
            return new CircularFile
            {
                Bytes = (byte[])row["FileBytes"], FileName = Convert.ToString(row["FileName"]),
                Version = Convert.ToString(row["Version"])
            };
        }
        private static Dictionary<string, object> Item(DataRow row)
        {
            var item = MobileRowMapper.Row(row);
            item["CircularDate"] = Convert.ToDateTime(row["CircularDate"])
                .ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            item["FileEndpoint"] = "/api/v1/circulars/" + row["ID"] + "/file";
            return item;
        }
    }

    public sealed class CircularFile
    {
        public byte[] Bytes { get; set; }
        public string FileName { get; set; }
        public string Version { get; set; }
    }
}
