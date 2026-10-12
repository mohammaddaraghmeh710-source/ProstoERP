Imports System.Data
Imports System.Linq
Imports System.Threading.Tasks

Public Class AttendanceHistory
    Inherits PageBase
    Private ReadOnly Property Actor As Integer
        Get
            Return SessionManager.GetInstance.Users.UserID
        End Get
    End Property
    Private ReadOnly Property IsAdmin As Boolean
        Get
            Return SessionManager.GetInstance.Users.UserType = 1
        End Get
    End Property
    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If SessionManager.GetInstance.Users Is Nothing Then Response.Redirect("~/Login.aspx") : Return
        ViewStateUserKey = Session.SessionID
        Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache) : Response.Cache.SetNoStore()
    End Sub
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        pnlBrand.Visible = IsAdmin : txtEmployee.ReadOnly = Not IsAdmin
        If Not IsPostBack Then
            txtFrom.Text = AttendanceData.Today() : txtTo.Text = txtFrom.Text
            If IsAdmin Then
                Using db As New Prosto_ERP_ClassLibrary.Prosto_ERP_DataClassesDataContext()
                    ddlBrand.DataSource = db.Select_Brands_All().Where(Function(b) b.IsActive.GetValueOrDefault() AndAlso Not b.IsDeleted.GetValueOrDefault()).OrderBy(Function(b) b.Title_Ar).ToList()
                    ddlBrand.DataValueField = "ID" : ddlBrand.DataTextField = "Title_Ar" : ddlBrand.DataBind()
                End Using
                ddlBrand.Items.Insert(0, New ListItem("اختر العلامة التجارية", "0"))
            End If
            Dim id As Integer
            Integer.TryParse(Request.QueryString("EmployeeID"), id)
            If Not IsAdmin Then
                If id > 0 AndAlso id <> Actor Then Throw New System.Web.HttpException(403, "غير مسموح بعرض سجل هذا الموظف.")
                id = Actor
            End If
            If id > 0 Then
                Try
                    Dim employee = AttendanceData.Employee(Actor, id)
                    txtEmployee.Text = Convert.ToString(employee("Employee_Number"))
                    If IsAdmin Then ddlBrand.SelectedValue = Convert.ToString(employee("Brand_ID"))
                    RegisterAsyncTask(New PageAsyncTask(AddressOf LoadAttendance))
                Catch ex As Exception
                    Message(AttendanceData.ErrorText(ex))
                End Try
            End If
        End If
    End Sub
    Protected Sub Search(sender As Object, e As EventArgs)
        RegisterAsyncTask(New PageAsyncTask(AddressOf LoadAttendance))
    End Sub
    Private Async Function LoadAttendance() As Task
        rptAttendance.DataSource = Nothing : rptAttendance.DataBind() : litEmployee.Text = "" : litCount.Text = "" : lblEmpty.Visible = False : litMessage.Text = ""
        Try
            If Not AttendanceData.ValidDates(txtFrom.Text, txtTo.Text) Then Message("أدخل فترة صحيحة بحيث لا يتجاوز تاريخ البداية تاريخ النهاية.") : Return
            Dim employee As DataRow
            If IsAdmin Then
                If ddlBrand.SelectedValue = "0" OrElse String.IsNullOrWhiteSpace(txtEmployee.Text) Then Message("اختر العلامة التجارية وأدخل الرقم الوظيفي.") : Return
                employee = AttendanceData.Employee(Actor, 0, txtEmployee.Text.Trim(), CInt(ddlBrand.SelectedValue))
            Else
                employee = AttendanceData.Employee(Actor, Actor)
                txtEmployee.Text = Convert.ToString(employee("Employee_Number"))
            End If
            Dim data = Await AttendanceData.Transactions(Actor, employee, txtFrom.Text, txtTo.Text)
            litEmployee.Text = "<p class='text-muted'>" & Server.HtmlEncode(Convert.ToString(employee("FullName_Ar")) & " · " & Convert.ToString(employee("BrandName")) & " · الرقم الوظيفي " & Convert.ToString(employee("Employee_Number"))) & "</p>"
            litCount.Text = "<p>عدد الحركات: " & data.Rows.Count.ToString() & "</p>"
            rptAttendance.DataSource = data : rptAttendance.DataBind() : lblEmpty.Visible = data.Rows.Count = 0
        Catch ex As Exception
            Message(AttendanceData.ErrorText(ex))
        End Try
    End Function
    Private Sub Message(value As String)
        litMessage.Text = "<div role='alert' class='alert alert-danger'>" & Server.HtmlEncode(value) & "</div>"
    End Sub
End Class
