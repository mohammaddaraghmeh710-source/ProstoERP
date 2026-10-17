namespace Prosto_ERP_API.Controllers
{
    // Simple model for POST body



    public class GetNewsByIdModel
    {
        public int PID { get; set; }
    }

    public class GetLevelsRequest
    {
        public int UserID { get; set; }
        public int UserType { get; set; }
        public int LevelTypeID { get; set; }
    }

    public class GetVideosByLevelIdRequest
    {
        public int LevelID { get; set; }
    }

    public class GetVideosByLevelIdAndUserIdModel
    {
        public int LevelID { get; set; }
        public int UserID { get; set; }
    }


    public class InsertVideoProgress
    {
        public int UserID { get; set; }
        public int VideoID { get; set; }
    }

    public class UpdateVideoLastPositionSecondsModel
    {
        public int UserID { get; set; }
        public int VideoID { get; set; }
        public int LastPositionSeconds { get; set; }
    }

    public class UpdateVideoCompletionPercentModel
    {
        public int UserID { get; set; }
        public int VideoID { get; set; }
        public int CompletionPercent { get; set; }  // 0..100
    }

    public class UpdateVideoProgressIsCompletedModel
    {
        public int UserID { get; set; }
        public int VideoID { get; set; }
    }

    public class GetNextVideoIdModel
    {
        public int LevelID { get; set; }
        public int CurrentVideoID { get; set; }
    }


    public class InsertLevelProgressModel
    {
        public int UserID { get; set; }
        public int LevelID { get; set; }
    }


    public class UpdateLevelProgressIsCompletModel
    {
        public int UserID { get; set; }
        public int LevelID { get; set; }
    }

    public class UpdateLevelProgressCompletionPercentModel
    {
        public int UserID { get; set; }
        public int LevelID { get; set; }
        public int CompletionPercent { get; set; }   // 0 .. 100
    }


}
