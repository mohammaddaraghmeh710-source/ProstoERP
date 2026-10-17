using ProstoERP.Application.Training;
using System.Linq;
using System.Web.Http;
using System.Net;
using Prosto_ERP_API.Authentication;
using System;

namespace Prosto_ERP_API.Controllers
{
    public class ERPController : ApiController
    {
        private readonly TrainingCatalogService catalog = new TrainingCatalogService();

        [HttpPost]
        [Route("api/ERPController/GetVideosStatus")]
        [Authentication]
        public IHttpActionResult GetVideosStatus()
        {
            try
            {
                return Ok(catalog.GetVideosStatus());
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading videos status list."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetLevelsStatus")]
        [Authentication]
        public IHttpActionResult GetLevelsStatus()
        {
            try
            {
                return Ok(catalog.GetLevelsStatus());
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading levels status list."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetLevelTypes")]
        [Authentication]
        public IHttpActionResult GetLevelTypes()
        {
            try
            {
                return Ok(catalog.GetLevelTypes());
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading level types."
                });
            }
        }




        [HttpPost]
        [Route("api/ERPController/GetLevelsByUserIDAndUserTypeAndLevelType")]
        [Authentication]
        public IHttpActionResult GetLevelsByUserIDAndUserTypeAndLevelType([FromBody] GetLevelsRequest model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.UserType <= 0 || model.LevelTypeID <= 0)
                {
                    return BadRequest("Invalid request parameters.");
                }

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var rows = db.Select_TR_Training_Levels_WithStats_ByUserType_And_LevelType(
                                    model.UserID, model.UserType, model.LevelTypeID)
                                 .ToList();

                    // Header معلومات المستخدم + نوع المستوى (موجودة بنفس كل Row)
                    var first = rows.FirstOrDefault();

                    var data = rows.Select(x => new
                    {
                        // Level
                        x.ID,
                        Level_Image = "https://mohammaddaraghmeh.com/" + x.Level_Image,
                        x.Title_Ar,
                        x.Title_En,
                        x.Summary_Ar,
                        x.Summary_En,
                        x.Notes_Ar,
                        x.Notes_En,
                        x.Item_Order,
                        x.BrandID,
                        x.IsActive,
                        x.IsDeleted,
                        x.AddedUser,
                        x.AddedDate,
                        x.ModifyUser,
                        x.ModifyDate,

                        // Progress
                        x.StartDate,
                        x.EndDate,
                        x.LevelStatusID,
                        x.CompletionPercent,

                        // Status (حسب الـ SP)
                        x.StatusID,
                        x.StatusTitle_Ar,
                        x.StatusTitle_En,

                        // Videos Stats
                        x.VideosCount,
                        x.TotalDurationSeconds,
                        x.TotalDurationHours,
                        x.TotalDuration_HHMMSS
                    }).ToList();

                    return Ok(new
                    {
                        Success = true,
                        User = first == null ? null : new
                        {
                            first.UserID,
                            first.UserDisplayName
                        },
                        LevelType = first == null ? null : new
                        {
                            first.LevelTypeID,
                            first.LevelTypeTitle_Ar,
                            first.LevelTypeTitle_En
                        },
                        Count = data.Count,
                        Data = data
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading levels."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/InsertLevelProgress")]
        [Authentication]
        public IHttpActionResult InsertLevelProgress([FromBody] InsertLevelProgressModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.LevelID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Insert_TR_User_Level_Progress(
                                    model.UserID,     // UserID
                                    model.LevelID,    // LevelID
                                    DateTime.Now,     // StartDate
                                    null,             // EndDate
                                    1,                // Status
                                    0,                // CompletionPercent
                                    model.UserID      // AddedUser = UserID
                                 )
                                 .FirstOrDefault();

                    var newId = result != null ? result.NewID : 0;
                    return Ok(new
                    {
                        Success = true,
                        NewID = newId
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while inserting level progress."
                });
            }
        }




        [HttpPost]
        [Route("api/ERPController/GetVideosByLevelID")]
        [Authentication]
        public IHttpActionResult GetVideosByLevelID([FromBody] GetVideosByLevelIdRequest model)
        {
            try
            {
                if (model == null || model.LevelID <= 0)
                    return BadRequest("Invalid LevelID.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var rows = db.Select_TR_Training_Videos_ByLevelID(model.LevelID).ToList();
                    var first = rows.FirstOrDefault();

                    var data = rows.Select(x => new
                    {
                        // Video
                        x.VideoID,
                        Video_Image = "https://mohammaddaraghmeh.com/" + (x.Video_Image ?? ""),
                        x.VideoTitle_Ar,
                        x.VideoTitle_En,
                        x.Summary_Ar,
                        x.Summary_En,
                        VideoUrl_Ar = "https://mohammaddaraghmeh.com/" + (x.VideoUrl_Ar ?? ""),
                        VideoUrl_En = "https://mohammaddaraghmeh.com/" + (x.VideoUrl_En ?? ""),
                        x.Item_Order,
                        x.DurationSeconds,

                        // Progress (كما يطلع من الـ SP)
                        x.UserID,
                        x.StartDate,
                        x.EndDate,
                        x.LastPositionSeconds,
                        x.CompletionPercent,
                        x.Status,
                        x.IsCompleted
                    }).ToList();

                    return Ok(new
                    {
                        Success = true,
                        Level = first == null ? null : new
                        {
                            first.LevelID,
                            first.LevelTitle_Ar,
                            first.LevelTitle_En
                        },
                        Count = data.Count,
                        Data = data
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading videos."
                });
            }
        }




        [HttpPost]
        [Route("api/ERPController/InsertVideoProgress")]
        [Authentication]
        public IHttpActionResult InsertUserVideoProgress([FromBody] InsertVideoProgress model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.VideoID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Insert_TR_User_Video_Progress(
                                    model.UserID,     // UserID
                                    model.VideoID,    // VideoID
                                    DateTime.Now,     // StartDate
                                    null,             // EndDate
                                    0,                // LastPositionSeconds
                                    0,                // CompletionPercent
                                    1,                // Status
                                    false,            // IsCompleted
                                    model.UserID      // AddedUser = UserID
                                 )
                                 .FirstOrDefault();
                    return Ok(new
                    {
                        Success = true,
                        NewID = result != null ? result.NewID : 0
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while inserting user video progress."
                });
            }
        }


        [HttpPost]
        [Route("api/ERPController/UpdateVideoLastPositionSeconds")]
        [Authentication]
        public IHttpActionResult UpdateVideoLastPositionSeconds([FromBody] UpdateVideoLastPositionSecondsModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.VideoID <= 0 || model.LastPositionSeconds < 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Update_TR_User_Video_Progress_LastPositionSeconds_ByUserID_And_VideoID(
                                    model.UserID,
                                    model.VideoID,
                                    model.LastPositionSeconds,
                                    model.UserID // ModifyUser = UserID
                                 )
                                 .FirstOrDefault();

                    int affected = result != null ? result.AffectedRows : 0;
                    return Ok(new
                    {
                        Success = affected > 0,
                        AffectedRows = affected,
                        Message = affected > 0 ? "Updated successfully." : "No rows updated (record not found)."
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while updating last position."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/UpdateVideoCompletionPercent")]
        [Authentication]
        public IHttpActionResult UpdateVideoCompletionPercent([FromBody] UpdateVideoCompletionPercentModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.VideoID <= 0)
                    return BadRequest("Invalid request parameters.");

                if (model.CompletionPercent < 0) model.CompletionPercent = 0;
                if (model.CompletionPercent > 100) model.CompletionPercent = 100;

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Update_TR_User_Video_Progress_CompletionPercent_ByUserID_And_VideoID(
                                    model.UserID,
                                    model.VideoID,
                                    model.CompletionPercent,
                                    model.UserID // ModifyUser = UserID
                                 )
                                 .FirstOrDefault();

                    int affected = result != null ? result.AffectedRows : 0;
                    return Ok(new
                    {
                        Success = affected > 0,
                        AffectedRows = affected,
                        Message = affected > 0 ? "Updated successfully." : "No rows updated (record not found)."
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while updating completion percent."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/UpdateVideoProgressIsCompleted")]
        [Authentication]
        public IHttpActionResult UpdateVideoProgressIsCompleted([FromBody] UpdateVideoProgressIsCompletedModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.VideoID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Update_TR_User_Video_Progress_IsCompleted_ByUserID_And_VideoID(
                                    model.UserID,
                                    model.VideoID
                                 )
                                 .FirstOrDefault();

                    int affected = result != null ? result.AffectedRows : 0;
                    return Ok(new
                    {
                        Success = affected > 0,
                        AffectedRows = affected,
                        Message = affected > 0 ? "Video marked as completed." : "No rows updated (record not found)."
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while completing the video."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetNextVideoID")]
        [Authentication]
        public IHttpActionResult GetNextVideoID([FromBody] GetNextVideoIdModel model)
        {
            try
            {
                if (model == null || model.LevelID <= 0 || model.CurrentVideoID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Select_TR_Training_Videos_NextVideoID_ByLevelID_And_CurrentVideoID(
                                    model.LevelID,
                                    model.CurrentVideoID
                                 )
                                 .FirstOrDefault();

                    // غالباً result يحتوي NextVideoID
                    int? nextVideoId = result != null ? (int?)result.NextVideoID : null;

                    return Ok(new
                    {
                        Success = true,
                        NextVideoID = nextVideoId
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while getting next video id."
                });
            }
        }

        [HttpPost]
        [Route("api/ERPController/UpdateLevelProgressIsComplet")]
        [Authentication]
        public IHttpActionResult UpdateLevelProgressIsComplet([FromBody] UpdateLevelProgressIsCompletModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.LevelID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Update_TR_User_Level_Progress_IsComplet_ByUserID_And_LevelID(
                                    model.UserID,        // UserID
                                    model.LevelID,       // LevelID
                                    DateTime.Now,        // EndDate
                                    2,                   // Status = Completed
                                    100,                 // CompletionPercent
                                    model.UserID         // ModifyUser = UserID
                                 )
                                 .FirstOrDefault();

                    int affected = result != null ? result.AffectedRows : 0;
                    return Ok(new
                    {
                        Success = affected > 0,
                        AffectedRows = affected,
                        Message = affected > 0
                            ? "Level marked as completed."
                            : "No rows updated (record not found)."
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while completing the level."
                });
            }
        }




        [HttpPost]
        [Route("api/ERPController/UpdateLevelProgressCompletionPercent")]
        [Authentication]
        public IHttpActionResult UpdateLevelProgressCompletionPercent([FromBody] UpdateLevelProgressCompletionPercentModel model)
        {
            try
            {
                if (model == null || model.UserID <= 0 || model.LevelID <= 0)
                    return BadRequest("Invalid request parameters.");

                // حماية النسبة
                int percent = model.CompletionPercent;
                if (percent < 0) percent = 0;
                if (percent > 100) percent = 100;

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var result = db.Update_TR_User_Level_Progress_CompletionPercent_ByUserID_And_LevelID(
                                    model.UserID,
                                    model.LevelID,
                                    percent,
                                    model.UserID     // ModifyUser = UserID
                                 )
                                 .FirstOrDefault();

                    int affected = result != null ? result.AffectedRows : 0;
                    return Ok(new
                    {
                        Success = affected > 0,
                        AffectedRows = affected,
                        Message = affected > 0
                            ? "Level completion percent updated."
                            : "No rows updated (record not found)."
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while updating level completion percent."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetNews")]
        [Authentication]
        public IHttpActionResult GetNews()
        {
            try
            {
                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var items = db.Select_News_All()
                                  .Select(n => new
                                  {
                                      n.PID,
                                      n.Title_AR,
                                      n.Title_En,
                                      n.Brief_Ar,
                                      n.Brief_En,
                                      n.Details,
                                      Image = "https://mohammaddaraghmeh.com/" + (n.Image ?? ""),   // 👈 Prefix
                              n.Date,
                                      n.Item_Order,
                                      n.AddedUser,
                                      n.AddedDate,
                                      n.ModifyUser,
                                      n.ModifyDate,
                                      n.IsDeleted,
                                      n.IsActive
                                  })
                                  .ToList();

                    return Ok(new
                    {
                        Success = true,
                        Count = items.Count,
                        Data = items
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading news."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetNewsByID")]
        [Authentication]
        public IHttpActionResult GetNewsByID([FromBody] GetNewsByIdModel model)
        {
            try
            {
                if (model == null || model.PID <= 0)
                    return BadRequest("Invalid PID.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var news = db.Select_News_ByID(model.PID)
                                 .Select(n => new
                                 {
                                     n.PID,
                                     n.Title_AR,
                                     n.Title_En,
                                     n.Brief_Ar,
                                     n.Brief_En,
                                     n.Details,
                                     Image = "https://mohammaddaraghmeh.com/" + (n.Image ?? ""), // Prefix مثل GetNews
                                     n.Date,
                                     n.Item_Order,
                                     n.AddedUser,
                                     n.AddedDate,
                                     n.ModifyUser,
                                     n.ModifyDate,
                                     n.IsDeleted,
                                     n.IsActive
                                 })
                                 .FirstOrDefault();

                    if (news == null)
                    {
                        return Content(System.Net.HttpStatusCode.NotFound, new
                        {
                            Success = false,
                            Message = "News not found."
                        });
                    }

                    return Ok(new
                    {
                        Success = true,
                        Data = news
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while retrieving news details."
                });
            }
        }



        [HttpPost]
        [Route("api/ERPController/GetVideosByLevelIDandUserID")]
        [Authentication]
        public IHttpActionResult GetVideosByLevelIDandUserID([FromBody] GetVideosByLevelIdAndUserIdModel model)
        {
            try
            {
                if (model == null || model.LevelID <= 0 || model.UserID <= 0)
                    return BadRequest("Invalid request parameters.");

                using (var db = new Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext())
                {
                    var rows = db.Select_TR_Training_Videos_ByLevelID_AndUserID(model.LevelID, model.UserID).ToList();
                    var first = rows.FirstOrDefault();

                    var data = rows.Select(x => new
                    {
                        // Video
                        x.VideoID,
                        Video_Image = "https://mohammaddaraghmeh.com/" + (x.Video_Image ?? ""),
                        x.VideoTitle_Ar,
                        x.VideoTitle_En,
                        x.Summary_Ar,
                        x.Summary_En,
                        VideoUrl_Ar = "https://mohammaddaraghmeh.com/" + (x.VideoUrl_Ar ?? ""),
                        VideoUrl_En = "https://mohammaddaraghmeh.com/" + (x.VideoUrl_En ?? ""),
                        x.Item_Order,
                        x.DurationSeconds,

                        // Progress (للمستخدم المحدد)
                        x.UserID,
                        x.StartDate,
                        x.EndDate,
                        x.LastPositionSeconds,
                        x.CompletionPercent,
                        x.Status,
                        x.IsCompleted
                    }).ToList();

                    return Ok(new
                    {
                        Success = true,
                        Level = first == null ? null : new
                        {
                            first.LevelID,
                            first.LevelTitle_Ar,
                            first.LevelTitle_En
                        },
                        Count = data.Count,
                        Data = data
                    });
                }
            }
            catch
            {
                return Content(System.Net.HttpStatusCode.InternalServerError, new
                {
                    Success = false,
                    Message = "An error occurred while loading videos."
                });
            }
        }





    }

}
