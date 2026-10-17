using System;
using System.Net;

namespace Prosto_ERP_API.Mobile
{
 public sealed class ResetException:Exception {
  public HttpStatusCode Status{get;private set;}public string Code{get;private set;}
  public ResetException(HttpStatusCode status,string code,string message):base(message){Status=status;Code=code;}
 }
}
