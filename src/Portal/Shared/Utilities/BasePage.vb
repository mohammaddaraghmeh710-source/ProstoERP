Imports System.Net
Imports Newtonsoft.Json

Public Class BasePage
    Public Shared Function postData(ByVal params As Object, ByVal url As String) As String
        Try
            Dim webClient As WebClient = New WebClient()
            webClient.Headers("content-type") = "application/json"
            Dim reqString = Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(params, Formatting.Indented))
            Dim resByte As Byte() = webClient.UploadData(url, "post", reqString)
            Dim resString1 = Encoding.[Default].GetString(resByte)
            webClient.Dispose()
            Return resString1
        Catch ex As Exception
            Return Nothing
        End Try
    End Function



End Class
