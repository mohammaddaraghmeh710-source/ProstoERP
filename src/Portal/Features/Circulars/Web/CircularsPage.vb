

Public Class CircularsPage
    Inherits InformationPagesPage

    Protected ReadOnly Property AdminMode As Boolean
        Get
            Return _
                IsAdministrator AndAlso
                (Request.QueryString("admin") = "1" OrElse
                 (PageID = 0 AndAlso Request.Path.EndsWith("/View.aspx", StringComparison.OrdinalIgnoreCase)))
        End Get
    End Property

    Protected ReadOnly Property CsrfToken As String
        Get
            If Session("CircularCsrf") Is Nothing Then Session("CircularCsrf") = Guid.NewGuid().ToString("N")
            Return CStr(Session("CircularCsrf"))
        End Get
    End Property

    Protected Function H(value As Object) As String
        Return Server.HtmlEncode(Convert.ToString(value))
    End Function

    Protected Function Stamp(value As Object) As String
        Return InformationPagesData.LocalDate(value)
    End Function

    Protected Function NameOfState(value As Object) As String
        Return CircularsPresentation.Label(value)
    End Function

    Protected Sub Failure(target As Literal, ex As Exception)
        target.Text = "<div class='alert alert-danger' role='alert'>" & H(CircularsPresentation.ErrorText(ex)) & "</div>"
    End Sub
End Class


