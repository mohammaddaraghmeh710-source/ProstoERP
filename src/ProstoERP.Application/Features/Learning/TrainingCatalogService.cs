using System.Linq;
using Prosto_ERP_ClassLibrary;

namespace ProstoERP.Application.Training
{
    public sealed class TrainingCatalogService
    {
        public object GetVideosStatus()
        {
            using (var db = new Prosto_ERP_DataClassesDataContext())
            {
                var items = db.Select_TR_Training_Videos_Status_All()
                    .Select(x => new
                    {
                        x.ID,
                        x.Title_Ar,
                        x.Title_En,
                        x.Item_Order,
                        x.AddedUser,
                        x.AddedDate,
                        x.ModifyUser,
                        x.ModifyDate,
                        x.IsDeleted,
                        x.IsActive
                    })
                    .ToList();

                return new
                {
                    Success = true,
                    Data = items
                };
            }
        }

        public object GetLevelsStatus()
        {
            using (var db = new Prosto_ERP_DataClassesDataContext())
            {
                var items = db.Select_TR_Training_Levels_Status_All()
                    .Select(x => new
                    {
                        x.ID,
                        x.Title_Ar,
                        x.Title_En,
                        x.Item_Order,
                        x.AddedUser,
                        x.AddedDate,
                        x.ModifyUser,
                        x.ModifyDate,
                        x.IsDeleted,
                        x.IsActive
                    })
                    .ToList();

                return new
                {
                    Success = true,
                    Data = items
                };
            }
        }

        public object GetLevelTypes()
        {
            using (var db = new Prosto_ERP_DataClassesDataContext())
            {
                var items = db.Select_TR_Level_Types_All()
                    .Select(x => new
                    {
                        x.ID,
                        Image = "https://mohammaddaraghmeh.com/" + x.Image, // 👈 إضافة الـ Prefix هنا
                        x.Title_Ar,
                        x.Title_En,
                        x.Notes_Ar,
                        x.Notes_En,
                        x.Item_Order,
                        x.AddedUser,
                        x.AddedDate,
                        x.ModifyUser,
                        x.ModifyDate,
                        x.IsActive,
                        x.IsDeleted
                    })
                    .ToList();

                return new
                {
                    Success = true,
                    items.Count,
                    Data = items
                };
            }
        }
    }
}
