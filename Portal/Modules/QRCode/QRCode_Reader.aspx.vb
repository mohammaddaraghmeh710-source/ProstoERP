Imports System
Imports System.Web.Services

Public Class QRCode_Reader
        Inherits PageBase

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If SessionManager.GetInstance.Users Is Nothing Then
            Response.Redirect("/login.aspx")
            Return
        End If
    End Sub

    <WebMethod()>
    Public Shared Function ResolveCrmQr(ByVal tokenStr As String) As Object
        Try
            ' ✅ تحقق من الـ GUID
            Dim token As Guid
            If String.IsNullOrWhiteSpace(tokenStr) OrElse Not Guid.TryParse(tokenStr, token) Then
                Return New With {.ok = False, .msg = "QR غير صالح"}
            End If

            ' ✅ (اختياري) تحقق من صلاحيات المستخدم (مثلاً مفتش)
            ' ملاحظة: WebMethod لا يرى SessionManager مباشرة دائماً حسب تطبيقك،
            ' إذا تحتاج صلاحيات هنا: الأفضل تعمل HttpHandler/ASMX أو PageMethod مع Session enabled.
            ' حالياً سنكتفي بأن الصفحة نفسها تتطلب Login من Page_Load.

            Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext

                Dim row = db.QR_GetByToken(token).FirstOrDefault()
                Dim ShiftId As Integer = GetCurrentShiftId()

                If row Is Nothing Then
                    Return New With {.ok = False, .msg = "QR غير معتمد داخل النظام"}
                End If

                Dim url As String = ""
                Select Case (row.EntityType & "").ToLower()
                    Case "brands"
                        url = "/modules/Branches_Dashboards/Branches_Dashboards.aspx?BrandID=" & row.EntityID
                    Case "branches"
                        url = "/Modules/Branch_Shift_Manager/Branch_Shift_Manager_Dashboard.aspx?BranchID=" & row.EntityID.ToString() + "&ShiftID=" + ShiftId.ToString()
                    Case "departments"
                        url = "/Modules/QRCode/Departments_Viewer_QRCode.aspx?Departmentid=" & row.EntityID.ToString()
                    Case "jobtitles"
                        url = "/modules/qrCode/JobTitle_Viewer_QRCode.aspx?JobTitle=" & row.EntityID
                    Case "jobitem"
                        url = "/Modules/QRCode/Tools_Viewer_QRCode.aspx?JobTitle_ItemsID=" & row.EntityID
                    Case "employees"
                        url = "/modules/Employees/Employee_Evaluation.aspx?EmployeeID=" & row.EntityID
                    Case Else
                        Return New With {.ok = False, .msg = "نوع QR غير مدعوم"}
                End Select

                Return New With {.ok = True, .url = url}

            End Using

        Catch ex As Exception
            Return New With {.ok = False, .msg = "حدث خطأ أثناء معالجة QR"}
        End Try
    End Function
    Private Shared Function GetCurrentShiftId() As Integer
        Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext


            Dim nowTime As TimeSpan = DateTime.Now.TimeOfDay

            Dim shifts = (From s In db.Select_Shift_All()
                          Where (s.IsDeleted = False OrElse s.IsDeleted Is Nothing) _
                            AndAlso (s.IsActive = True OrElse s.IsActive Is Nothing)
                          Select s).ToList()

            For Each s In shifts
                If Not s.Start_Time.HasValue OrElse Not s.End_Time.HasValue Then
                    Continue For
                End If

                Dim startT As TimeSpan = s.Start_Time.Value
                Dim endT As TimeSpan = s.End_Time.Value

                Dim isMatch As Boolean

                If startT <= endT Then
                    ' وردية عادية داخل نفس اليوم
                    isMatch = (nowTime >= startT AndAlso nowTime <= endT)
                Else
                    ' وردية تمتد بعد منتصف الليل
                    isMatch = (nowTime >= startT OrElse nowTime <= endT)
                End If

                If isMatch Then
                    Return s.ID
                End If
            Next

            Return 0
        End Using
    End Function


    Protected Sub btnback_Click(sender As Object, e As EventArgs)
        'Dim ref = Request.UrlReferrer
        'If ref IsNot Nothing Then
        '    Response.Redirect(ref.ToString())
        'Else
        '    Response.Redirect("/Default.aspx")
        'End If
    End Sub
End Class

