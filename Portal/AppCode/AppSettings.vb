
Public Class AppSettings

    Public Enum UserType As Integer
        Admin = 1
        Dewan = 2
        System = 3
    End Enum

    Public Enum SystemType As Integer
        Inbound = 1
        Outbound = 2
        Memo = 3
    End Enum

    Public Enum SystemModules
        Inbound = 1
        outbound = 2
        Archive = 3
        Reports = 4
        Search = 5
        FollowUp = 6
        Update = 7
        ListOfAction = 8
        CloseTransactions = 9
        MySearch = 10
        MyArchive = 11
        Delegation = 12
        SeeAllComments = 13
        ArchivedAnnouncment = 14
        Eservices = 15
        ShowDepartmentMemo = 16
    End Enum

#Region "Inbound related enumerations"

    Public Enum InboundAction As Integer
        Redirect = 1
        Archived = 2
        ForAll = 3
    End Enum
    Public Enum InboundStatus As Integer
        Active = 1
        Archived = 2
        Finished = 3
        NearExpire = 4
        Late = 5
    End Enum

#End Region

    Public Enum ExportableLists As Integer
        SearchArchivedInbound = 1
        SearchArchivedOutbound = 2
        SearchExpandedInbound = 3
        SearchExpandedOutbound = 4
    End Enum

End Class
