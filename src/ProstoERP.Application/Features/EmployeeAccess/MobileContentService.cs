using System.Collections.Generic;
using System.Data;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProstoERP.Application.Abstractions;
using ProstoERP.Application.Data;
using ProstoERP.Contracts.Common;
using ProstoERP.Contracts.Features.EmployeeAccess;
using ProstoERP.Contracts.Features.News;

namespace ProstoERP.Application.Features.EmployeeAccess
{
    public sealed class MobileContentService
    {
        private readonly IMobileContentStore store;
        private readonly IAssetUrlBuilder assets;
        public MobileContentService(IMobileContentStore store, IAssetUrlBuilder assets)
        {
            this.store = store;
            this.assets = assets;
        }
        public CountResponse<NewsItem, Dictionary<string, object>> News(Dictionary<string, object> session, int brandID)
        {
            var result = store.News(session["UserID"], brandID);
            var news = result.Tables[0].Rows.Cast<DataRow>().Select(MobileRowMapper.Row).ToList();
            foreach (var item in news) item["Image"] = assets.AssetUrl(item["Image"]);
            return new CountResponse<NewsItem, Dictionary<string, object>>
            {
                Success = true, Count = news.Count,
                Data = news.Select(item => JObject.FromObject(item).ToObject<NewsItem>()).ToList(), Session = session
            };
        }
        public CountResponse<InformationPage, Dictionary<string, object>> InformationPages(Dictionary<string, object> session)
        {
            var result = store.InformationPages(session["UserID"]);
            var roles = result.Tables[1].Rows.Cast<DataRow>()
                .ToLookup(r => (int)r["PageID"], r => (int)r["UserTypeID"]);
            var pages = result.Tables[0].Rows.Cast<DataRow>().Select(MobileRowMapper.Row).ToList();
            foreach (var page in pages) page["UserTypeIDs"] = roles[(int)page["ID"]].ToArray();
            return new CountResponse<InformationPage, Dictionary<string, object>>
            {
                Success = true, Count = pages.Count,
                Data = pages.Select(item => JObject.FromObject(item).ToObject<InformationPage>()).ToList(), Session = session
            };
        }
        public void Logout(object tokenHash) { store.Logout(tokenHash); }
    }
}
