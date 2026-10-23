Imports System.Data
Imports System.Globalization
Imports System.Collections.Generic
Imports System.Linq
Imports System.Text
Imports System.Web.UI.WebControls
Imports System.Xml.Linq

Public Class CRMOverview
    Inherits CRMModulePage
    Private activity As DataTable
    Protected IsCRMAdministrator As Boolean
    Protected Overrides ReadOnly Property EntityName As String
        Get
            Return "Activity_Logs"
        End Get
    End Property
    Protected Overrides ReadOnly Property Mode As String
        Get
            Return "Manage"
        End Get
    End Property

    Protected Overrides Sub OnInit(e As EventArgs)
        MyBase.OnInit(e)
        If Not CRMAccessAllowed Then Return
        IsCRMAdministrator = CRMIsAdmin
        Try
            activity = MyBase.LoadListData()
            activity.Columns.Add("Actor_Key", GetType(String))
            For Each row As DataRow In activity.Rows
                row("Actor_Key") = If(Not IsDBNull(row("Actor_ID")), "staff:" & Convert.ToString(row("Actor_ID")), "customer:" & Convert.ToString(row("Account_ID")))
            Next
            FillLogOptions("filterActor", "Actor_Key", "User_Name", "كل المنفّذين", True)
            FillLogOptions("filterAccount", "Account_ID", "Account_Name", "كل العملاء", False)
        Catch ex As Exception
            Field(Of Panel)("pnlBody").Visible = False
            ShowError(ex)
        End Try
    End Sub

    Private Sub FillLogOptions(controlName As String, valueColumn As String, titleColumn As String, placeholder As String, includeSource As Boolean)
        Dim list = Field(Of DropDownList)(controlName)
        list.Items.Clear() : list.Items.Add(New ListItem(placeholder, ""))
        Dim options = activity.Rows.Cast(Of DataRow)().Where(Function(r) Not IsDBNull(r(valueColumn))).GroupBy(Function(r) Convert.ToString(r(valueColumn)))
        For Each item In options.OrderBy(Function(g) Convert.ToString(g.First()(titleColumn)))
            Dim row = item.First(), title = Convert.ToString(row(titleColumn))
            If title = "" Then title = "سجل سابق #" & item.Key
            If includeSource Then title &= " — " & Convert.ToString(row("Source_Name"))
            list.Items.Add(New ListItem(title, item.Key))
        Next
    End Sub

    Protected Overrides Function LoadListData() As DataTable
        Return If(activity, MyBase.LoadListData())
    End Function

    Protected Overrides Sub PrepareListData(data As DataTable)
        Dim actor = Field(Of DropDownList)("filterActor").SelectedValue
        Dim source = Field(Of DropDownList)("filterSource").SelectedValue
        For Each row In data.Rows.Cast(Of DataRow)().ToArray()
            If (actor <> "" AndAlso Convert.ToString(row("Actor_Key")) <> actor) OrElse (source <> "" AndAlso Convert.ToString(row("Source_Name")) <> source) Then data.Rows.Remove(row)
        Next
    End Sub

    ' Only business fields are rendered; secrets, image bytes and row versions stay hidden.
    Private Shared ReadOnly SnapshotLabels As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase) From {
        {"ID", "الرقم"}, {"Account_ID", "رقم العميل"}, {"AccountID", "رقم العميل"},
        {"Name_AR", "الاسم بالعربية"}, {"Name_EN", "الاسم بالإنجليزية"},
        {"Title_Ar", "الاسم بالعربية"}, {"Title_En", "الاسم بالإنجليزية"},
        {"Details_AR", "التفاصيل بالعربية"}, {"Details_EN", "التفاصيل بالإنجليزية"}, {"Summary_AR", "الملخص بالعربية"}, {"Summary_EN", "الملخص بالإنجليزية"},
        {"Permissions", "صلاحيات التصنيفات"}, {"Category_ID", "رقم التصنيف"}, {"Category_Name", "التصنيف"}, {"Operation", "العملية"}, {"Parent_ID", "رقم التصنيف الأب"}, {"Sort_Order", "الترتيب"}, {"Categories", "التصنيفات"},
        {"File_Url", "مسار الملف"}, {"File_Name", "اسم الملف"}, {"File_Extension", "صيغة الملف"}, {"File_Size", "حجم الملف (بايت)"},
        {"Job_Title", "المسمى الوظيفي بالعربية"}, {"Job_Title_EN", "المسمى الوظيفي بالإنجليزية"},
        {"Phone", "الهاتف"}, {"Email", "البريد الإلكتروني"}, {"Address", "العنوان"}, {"Country", "الدولة"},
        {"Website", "الموقع الإلكتروني"}, {"Registration_Number", "رقم التسجيل"}, {"Gender", "الجنس"},
        {"Account_Type_ID", "رقم نوع العميل"}, {"Brand_ID", "رقم العلامة التجارية"}, {"Branch_ID", "رقم الفرع"},
        {"Supplier_Brands", "علامات التوريد"}, {"Account_Brands", "العلامات التجارية للعميل"}, {"Account_Branches", "فروع العميل"}, {"Supplier_Account_ID", "رقم حساب المورد"}, {"Tool_Number", "رقم الأداة"}, {"JobTitle_ID", "رقم المحطة التعريفية"},
        {"Owner_ID", "رقم المسؤول"}, {"Notes", "ملاحظات"}, {"Description", "الوصف"},
        {"Is_Active", "فعال"}, {"IsActive", "السماح بالدخول"}, {"Is_Deleted", "محذوف"},
        {"Username", "اسم المستخدم"}, {"PasswordChanged", "تم تغيير كلمة المرور"},
        {"Logo_Url", "مسار الشعار"}, {"HasLogo", "يوجد شعار"}, {"LogoChanged", "تم تغيير الشعار"}}

    Private Shared Function SnapshotValue(element As XElement, ParamArray names As String()) As String
        For Each name In names
            Dim child = element.Element(name)
            If child IsNot Nothing Then Return child.Value
            Dim attribute = element.Attribute(name)
            If attribute IsNot Nothing Then Return attribute.Value
        Next
        Return ""
    End Function

    Private Shared Function Snapshot(value As Object) As Dictionary(Of String, String)
        Dim fields As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        Dim xml = Convert.ToString(value)
        If String.IsNullOrWhiteSpace(xml) Then Return fields
        Try
            Dim settings As New System.Xml.XmlReaderSettings With {.DtdProcessing = System.Xml.DtdProcessing.Prohibit, .XmlResolver = Nothing, .MaxCharactersInDocument = 4194304}
            Using input As New System.IO.StringReader(xml), reader = System.Xml.XmlReader.Create(input, settings)
                For Each element As XElement In XElement.Load(reader).Elements()
                    If element.Name.LocalName = "Permissions" Then
                        fields("Permissions") = String.Join("، ", element.Elements("grant").Select(Function(g) CStr(g.Element("Name_AR")) & " (#" & CStr(g.Element("ID")) & "): " & If(CStr(g.Element("Can_View")) = "1", If(CStr(g.Element("Can_Download")) = "1", "اطلاع وتحميل", "اطلاع فقط"), "تحميل فقط")))
                    ElseIf element.Name.LocalName = "Categories" Then
                        fields("Categories") = String.Join("، ", element.Elements("category").Select(Function(c) CStr(c.Element("Name_AR")) & " / " & CStr(c.Element("Name_EN")) & " (#" & CStr(c.Element("ID")) & ")"))
                    ElseIf {"Supplier_Brands", "Account_Brands", "Account_Branches"}.Contains(element.Name.LocalName) Then
                        Dim names As New List(Of String)
                        Dim branches = element.Name.LocalName = "Account_Branches"
                        For Each relation In element.Elements(If(branches, "Branch", "Brand"))
                            Dim id = SnapshotValue(relation, If(branches, "Branch_ID", "Brand_ID"), "ID")
                            Dim name = SnapshotValue(relation, "Name_AR", If(branches, "Branch_Name", "Brand_Name")), english = SnapshotValue(relation, "Name_EN")
                            If String.IsNullOrWhiteSpace(name) Then name = english : english = ""
                            Dim label = If(String.IsNullOrWhiteSpace(name), If(branches, "فرع #", "علامة تجارية #") & id, name & If(String.IsNullOrWhiteSpace(english), "", " / " & english) & " (#" & id & ")")
                            Dim brandName = If(branches, SnapshotValue(relation, "BrandName", "Brand_Name"), "")
                            names.Add(If(String.IsNullOrWhiteSpace(brandName), label, brandName & " — " & label))
                        Next
                        fields(element.Name.LocalName) = String.Join("، ", names)
                    ElseIf Not element.HasElements AndAlso SnapshotLabels.ContainsKey(element.Name.LocalName) Then
                        fields(element.Name.LocalName) = If(element.Name.LocalName.StartsWith("Details_", StringComparison.Ordinal), CRMWorkGuideContent.PlainText(element.Value), element.Value)
                    End If
                Next
            End Using
        Catch ex As System.Xml.XmlException
            ' Never fall back to raw historical XML in the UI.
        End Try
        Return fields
    End Function

    Protected Function SnapshotDetails(value As Object, comparison As Object) As String
        Dim fields = Snapshot(value), other = Snapshot(comparison)
        If fields.Count = 0 AndAlso other.Count = 0 Then Return "<span class='text-muted small'>لا توجد بيانات مسجلة</span>"
        If String.IsNullOrWhiteSpace(Convert.ToString(value)) Then Return "<span class='text-muted small'>لا توجد بيانات مسجلة</span>"
        Dim html As New StringBuilder("<details class='crm-activity-details'><summary class='text-primary'>عرض التفاصيل</summary><dl class='mb-0 mt-2'>")
        For Each label In SnapshotLabels
            ' SQL omits NULL fields: include the opposite side to show cleared values explicitly.
            If Not fields.ContainsKey(label.Key) AndAlso Not other.ContainsKey(label.Key) Then Continue For
            Dim text = If(fields.ContainsKey(label.Key), fields(label.Key), "")
            Dim previous = If(other.ContainsKey(label.Key), other(label.Key), "")
            Dim changed = other.Count > 0 AndAlso text <> previous
            If New String() {"Is_Active", "IsActive", "Is_Deleted", "PasswordChanged", "HasLogo", "LogoChanged"}.Contains(label.Key) Then text = If(text = "1" OrElse text = "true", "نعم", If(text = "0" OrElse text = "false", "لا", text))
            If label.Key = "Gender" Then text = If(text = "M", "ذكر", If(text = "F", "أنثى", text))
            html.Append("<div class='crm-activity-field rounded p-2 mb-1 ").Append(If(changed, "bg-label-warning", "bg-light")).Append("'><dt class='small mb-1'>").Append(CRMData.H(label.Value)).Append("</dt><dd class='mb-0' dir='auto'>").Append(CRMData.H(If(text = "", "—", text))).Append("</dd></div>")
        Next
        Return html.Append("</dl></details>").ToString()
    End Function
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not CRMAccessAllowed OrElse IsPostBack Then Return
        Try
            litActivity.Text = Convert.ToInt64(CRMData.Query("dbo.CRM_Activity_Count", CRMData.P("@Actor_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID)).Rows(0)("Activity_Count")).ToString("N0", CultureInfo.InvariantCulture)
            If Not IsCRMAdministrator Then
                Dim actor = SessionManager.GetInstance.Users.UserID
                litAccounts.Text = CRMData.Rows("Accounts", actor).Rows.Count.ToString("N0", CultureInfo.InvariantCulture)
                litContacts.Text = CRMData.Rows("Contacts", actor).Rows.Count.ToString("N0", CultureInfo.InvariantCulture)
                Return
            End If
            Dim extra = CRMData.Query("dbo.CRM_Overview_Extensions", CRMData.P("@Actor_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID)).Rows(0)
            litContractTypes.Text = Convert.ToInt64(extra("Contract_Types")).ToString("N0", CultureInfo.InvariantCulture)
            litPaymentMethods.Text = Convert.ToInt64(extra("Payment_Methods")).ToString("N0", CultureInfo.InvariantCulture)
            litWorkGuide.Text = Convert.ToInt64(extra("WorkGuide_Items")).ToString("N0", CultureInfo.InvariantCulture)
            Dim row = CRMData.Query("dbo.CRM_Dashboard_Counts", CRMData.P("@Actor_ID", SqlDbType.Int, SessionManager.GetInstance.Users.UserID)).Rows(0)
            litTypes.Text = Convert.ToInt64(row("Account_Types")).ToString("N0", CultureInfo.InvariantCulture)
            litAccounts.Text = Convert.ToInt64(row("Accounts")).ToString("N0", CultureInfo.InvariantCulture)
            litContacts.Text = Convert.ToInt64(row("Contacts")).ToString("N0", CultureInfo.InvariantCulture)
        Catch ex As Exception
            litMessage.Text = "<div class=""alert alert-danger"" role=""alert"">" & CRMData.H(CRMData.ErrorMessage(ex)) & "</div>"
        End Try
    End Sub
End Class
