Imports System.Data.SqlClient
Imports System.Globalization
Imports Prosto_ERP_ClassLibrary

Public Class UsersTypesPageBase
    Inherits HRTypePageBase

    Protected Function ReadTypeValues(arabic As TextBox, english As TextBox, sortOrder As TextBox,
                                      message As Literal, ByRef order As Integer?) As Boolean
        arabic.Text = arabic.Text.Trim()
        english.Text = english.Text.Trim()
        If String.IsNullOrWhiteSpace(arabic.Text) OrElse String.IsNullOrWhiteSpace(english.Text) Then
            ShowMessage(message, "يرجى إدخال الاسم بالعربية والإنجليزية.")
            Return False
        End If
        order = Nothing
        If Not String.IsNullOrWhiteSpace(sortOrder.Text) Then
            Dim normalized As String =
                    String.Concat(
                        sortOrder.Text.Trim().Select(
                            Function(c) _
                                                        If _
                                                        (CharUnicodeInfo.GetDecimalDigitValue(c) >= 0,
                                                         CharUnicodeInfo.GetDecimalDigitValue(c).ToString(
                                                             CultureInfo.InvariantCulture), c.ToString())))
            Dim value As Integer
            If Not Integer.TryParse(normalized, NumberStyles.None, CultureInfo.InvariantCulture, value) Then
                ShowMessage(message, "الترتيب اختياري؛ أدخل عددًا صحيحًا من صفر إلى 2147483647.")
                Return False
            End If
            order = value
        End If
        Return True
    End Function

    Protected Sub ReportError(message As Literal, ex As SqlException)
        Diagnostics.Trace.TraceError("Users types: {0}", ex.ToString())
        ShowMessage(message, "تعذّر تنفيذ العملية. يرجى المحاولة مرة أخرى.")
    End Sub

    ' Call inside the caller's transaction. Existing update procedures do not exclude deleted rows.
    Protected Function LockExistingType(db As Prosto_ERP_DataClassesDataContext, id As Integer) As Boolean
        Return _
            db.ExecuteQuery (Of Integer)(
                "SELECT ID FROM dbo.Users_Types WITH (UPDLOCK, HOLDLOCK) WHERE ID = {0} AND ISNULL(IsDeleted, 0) = 0",
                id).Any()
    End Function

    Protected Function HasReferences(db As Prosto_ERP_DataClassesDataContext, id As Integer) As Boolean
        ' Include historical assignments to keep their type names available.
        Return db.ExecuteQuery (Of Integer)(
            "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.UsersMembers WHERE [Type] = {0}) " &
            "OR EXISTS (SELECT 1 FROM dbo.Checklist_Employee WHERE Users_TypesID = {0}) " &
            "OR EXISTS (SELECT 1 FROM dbo.TR_Training_Level_UserTypes WHERE UserType = {0}) " &
            "THEN 1 ELSE 0 END", id).Single() = 1
    End Function

    Protected Shared Function IsActiveValue(value As Object) As Boolean
        Return value IsNot Nothing AndAlso value IsNot DBNull.Value AndAlso Convert.ToBoolean(value)
    End Function
End Class


