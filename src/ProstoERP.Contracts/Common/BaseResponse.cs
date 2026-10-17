namespace ProstoERP.Contracts.Common
{
    public class BaseResponse
    {
        public bool Success { get; set; }
        public ApiError Error { get; set; }

        public static BaseResponse Ok()
        {
            return new BaseResponse { Success = true };
        }

        public static BaseResponse Fail(string code, string message)
        {
            return new BaseResponse
            {
                Success = false,
                Error = new ApiError { Code = code, Message = message }
            };
        }
    }
}
