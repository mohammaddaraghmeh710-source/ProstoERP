namespace ProstoERP.Contracts.Common
{
    public class BaseResponse<T> : BaseResponse
    {
        public T Data { get; set; }

        public bool ShouldSerializeData()
        {
            return Success;
        }

        public static BaseResponse<T> Ok(T data)
        {
            return new BaseResponse<T> { Success = true, Data = data };
        }

        public new static BaseResponse<T> Fail(string code, string message)
        {
            return new BaseResponse<T>
            {
                Success = false,
                Error = new ApiError { Code = code, Message = message }
            };
        }
    }
}
