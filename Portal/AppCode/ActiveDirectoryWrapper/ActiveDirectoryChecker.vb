

Imports System.DirectoryServices

Public Class ActiveDirectoryChecker

    Public Shared Function CheckDomainUser(ByVal username As String, ByVal password As String) As Boolean
        Dim isValid As Boolean = False

        Dim ADPath As String = ConfigurationManager.ConnectionStrings("ADconnectionString").ConnectionString
        Dim entry As DirectoryEntry = New DirectoryEntry(ADPath, username, password)

        Try
            Dim obj As Object = entry.NativeObject
            Dim search As DirectorySearcher = New DirectorySearcher(entry)

            search.Filter = "(&(objectClass=user)(SAMAccountName=" & username & "))"

            Dim result As SearchResult = search.FindOne()
            If (result Is Nothing) Then
                Return False
            Else
                Return True
            End If
        Catch
            Return False
        End Try

        Return isValid
    End Function

End Class
