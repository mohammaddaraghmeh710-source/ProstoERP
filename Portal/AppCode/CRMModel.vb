Public NotInheritable Class CRMModel
Public Shared ReadOnly Entities As New Dictionary(Of String, CRMDefinition) From {
{"Account_Types",New CRMDefinition("أنواع العملاء",New CRMField(){New CRMField("Name_AR","الاسم","text",200),New CRMField("Name_EN","الاسم الإنجليزي","text",200),New CRMField("Notes","ملاحظات","memo",2000)})},
{"Contract_Types",New CRMDefinition("أنواع العقود",New CRMField(){New CRMField("Name_AR","الاسم","text",200),New CRMField("Name_EN","الاسم الإنجليزي","text",200),New CRMField("Notes","ملاحظات","memo",2000)})},
{"Payment_Methods",New CRMDefinition("طرق الدفع",New CRMField(){New CRMField("Name_AR","الاسم","text",200),New CRMField("Name_EN","الاسم الإنجليزي","text",200),New CRMField("Notes","ملاحظات","memo",2000)})},
{"WorkGuide_Items",New CRMDefinition("دليل العمل",New CRMField(){})},
{"Accounts",New CRMDefinition("العملاء",New CRMField(){New CRMField("Name_AR","اسم العميل","text",200),New CRMField("Name_EN","الاسم الإنجليزي","text",200),New CRMField("Account_Type_ID","نوع العميل","Account_Types",40),New CRMField("Brand_ID","العلامة التجارية","Brands",40),New CRMField("Branch_ID","الفرع","Branches",40),New CRMField("Owner_ID","مسؤول العميل","Users",40),New CRMField("Phone","هاتف الشركة","text",50),New CRMField("Email","بريد الشركة","email",254),New CRMField("Address","العنوان","memo",500),New CRMField("Country","البلد","text",100),New CRMField("Website","الموقع الإلكتروني","url",500),New CRMField("Registration_Number","رقم تسجيل الشركة","text",100),New CRMField("Notes","ملاحظات","memo",2000)})},
{"Contacts",New CRMDefinition("جهات الاتصال",New CRMField(){New CRMField("Account_ID","العميل","Accounts",40),New CRMField("Name_AR","الاسم بالعربية","text",200),New CRMField("Name_EN","الاسم بالإنجليزية","text",200),New CRMField("Job_Title","المسمى الوظيفي بالعربية","text",200),New CRMField("Job_Title_EN","المسمى الوظيفي بالإنجليزية","text",200),New CRMField("Phone","الهاتف","text",50),New CRMField("Email","البريد الإلكتروني","email",254),New CRMField("Gender","الجنس","gender",20),New CRMField("Notes","ملاحظات","memo",2000)})}
}
    ' The inline account editor owns multi-brand/multi-branch membership separately.
    ' Keep scalar definitions for compatibility with existing legacy form submissions.
    Public Shared Function InlineFields(entityName As String) As IEnumerable(Of CRMField)
        Dim fields As New List(Of CRMField)
        For Each field In Entities(entityName).Fields
            If entityName = "Accounts" AndAlso (field.Name = "Brand_ID" OrElse field.Name = "Branch_ID") Then Continue For
            fields.Add(field)
        Next
        Return fields
    End Function
End Class
