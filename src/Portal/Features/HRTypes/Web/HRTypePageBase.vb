Imports System.Data.SqlClient
Imports System.Globalization

Public Class HRTypePageBase
    Inherits PageBase

    Protected Overrides Sub OnInit(e As EventArgs)
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("~/login.aspx")
            Return
        End If
        If SessionManager.GetInstance.Users.UserType <> 1 Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        ViewStateUserKey = Session.SessionID
        MyBase.OnInit(e)
    End Sub

    Protected Sub ShowMessage(target As Literal, message As String, Optional success As Boolean = False)
        target.Text = "<div role='alert' class='alert alert-" & If(success, "success", "danger") & "'>" &
                      HttpUtility.HtmlEncode(message) & "</div>"
    End Sub

    Protected Sub ShowDatabaseError(target As Literal, ex As SqlException)
        Diagnostics.Trace.TraceError("HR types: {0}", ex.ToString())
        If ex.Number = 2601 OrElse ex.Number = 2627 Then
            ShowMessage(target, "رقم النوع في النظام الأساسي مستخدم مسبقًا، وقد يكون مسجلًا ضمن العناصر المحذوفة.")
        Else
            ShowMessage(target, "تعذّر تنفيذ العملية. يرجى المحاولة مرة أخرى.")
        End If
    End Sub

    Private Shared Function NormalizeNumber(value As String) As String
        Dim result As New StringBuilder()
        For Each character As Char In value.Trim()
            Dim digit As Integer = CharUnicodeInfo.GetDecimalDigitValue(character)
            If digit >= 0 Then
                result.Append(digit.ToString(CultureInfo.InvariantCulture))
            ElseIf character = ChrW(&H66B) Then
                result.Append("."c)
            Else
                result.Append(character)
            End If
        Next
        Return result.ToString()
    End Function

    Protected Function ReadValues(core As TextBox, arabic As TextBox, english As TextBox,
                                  maximum As TextBox, fractional As Boolean, message As Literal,
                                  ByRef coreID As Integer, ByRef maxValue As Decimal) As Boolean
        If _
            Not _
            Integer.TryParse(NormalizeNumber(core.Text), NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture,
                             coreID) Then
            ShowMessage(message, "أدخل رقمًا صحيحًا صالحًا للنوع في النظام الأساسي.")
            Return False
        End If
        arabic.Text = arabic.Text.Trim()
        english.Text = english.Text.Trim()
        If _
            String.IsNullOrWhiteSpace(arabic.Text) OrElse String.IsNullOrWhiteSpace(english.Text) OrElse
            arabic.Text.Length > 200 OrElse english.Text.Length > 200 Then
            ShowMessage(message, "الاسم العربي والإنجليزي مطلوبان، وبحد أقصى 200 حرف لكل اسم.")
            Return False
        End If
        Dim number As String = NormalizeNumber(maximum.Text)
        Dim pattern As String = If(fractional, "\A[0-9]+(?:\.[0-9]{1,2})?\z", "\A[0-9]+\z")
        If Not Regex.IsMatch(number, pattern) OrElse
           Not Decimal.TryParse(number, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, maxValue) OrElse
           maxValue <= 0D OrElse maxValue > If(fractional, 9999999.99D, CDec(Integer.MaxValue)) Then
            ShowMessage(message, If(fractional,
                                    "أدخل عدد ساعات أكبر من صفر ولا يتجاوز 9999999.99، بمنزلتين عشريتين كحد أقصى (مثال: 1.50).",
                                    "أدخل عدد أيام صحيحًا أكبر من صفر ولا يتجاوز 2147483647، دون كسور."))
            Return False
        End If
        Return True
    End Function
End Class


