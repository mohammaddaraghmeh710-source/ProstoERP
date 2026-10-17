Public NotInheritable Class CRMModel
    Public Shared ReadOnly Entities As New Dictionary(Of String, CRMDefinition) From {
        {"Account_Types",
        New CRMDefinition("أنواع العملاء",
                          New CRMField() _
                             {New CRMField("Name_AR", "الاسم", "text", 200),
                              New CRMField("Name_EN", "الاسم الإنجليزي", "text", 200),
                              New CRMField("Notes", "ملاحظات", "memo", 2000)})},
        {"Contract_Types",
        New CRMDefinition("أنواع العقود",
                          New CRMField() _
                             {New CRMField("Name_AR", "الاسم", "text", 200),
                              New CRMField("Name_EN", "الاسم الإنجليزي", "text", 200),
                              New CRMField("Notes", "ملاحظات", "memo", 2000)})},
        {"Payment_Methods",
        New CRMDefinition("طرق الدفع",
                          New CRMField() _
                             {New CRMField("Name_AR", "الاسم", "text", 200),
                              New CRMField("Name_EN", "الاسم الإنجليزي", "text", 200),
                              New CRMField("Notes", "ملاحظات", "memo", 2000)})},
        {"Accounts",
        New CRMDefinition("العملاء",
                          New CRMField() _
                             {New CRMField("Name_AR", "اسم العميل", "text", 200),
                              New CRMField("Name_EN", "الاسم الإنجليزي", "text", 200),
                              New CRMField("Account_Type_ID", "نوع العميل", "Account_Types", 40),
                              New CRMField("Owner_ID", "مسؤول العميل", "Users", 40),
                              New CRMField("Phone", "هاتف الشركة", "text", 50),
                              New CRMField("Email", "بريد الشركة", "email", 254),
                              New CRMField("Address", "العنوان", "memo", 500),
                              New CRMField("Country", "البلد", "text", 100),
                              New CRMField("Website", "الموقع الإلكتروني", "url", 500),
                              New CRMField("Registration_Number", "رقم تسجيل الشركة", "text", 100),
                              New CRMField("Notes", "ملاحظات", "memo", 2000)})},
        {"Contacts",
        New CRMDefinition("جهات الاتصال",
                          New CRMField() _
                             {New CRMField("Account_ID", "العميل", "Accounts", 40),
                              New CRMField("Name_AR", "الاسم", "text", 200),
                              New CRMField("Job_Title", "المسمى الوظيفي", "text", 200),
                              New CRMField("Phone", "الهاتف", "text", 50),
                              New CRMField("Email", "البريد الإلكتروني", "email", 254),
                              New CRMField("Gender", "الجنس", "gender", 20),
                              New CRMField("Notes", "ملاحظات", "memo", 2000)})}
        }
End Class


