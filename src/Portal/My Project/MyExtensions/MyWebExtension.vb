Imports System.ComponentModel.Design
Imports System.Diagnostics.CodeAnalysis
Imports Microsoft.VisualBasic.ApplicationServices
Imports Microsoft.VisualBasic.Devices
Imports Microsoft.VisualBasic.Logging

#If _MyType <> "Empty" Then

Namespace My
    ''' <summary>
    '''     Module used to define the properties that are available in the My Namespace for Web projects.
    ''' </summary>
    ''' <remarks></remarks>
    <HideModuleName>
    Module MyWebExtension
        Private ReadOnly s_Computer As New ThreadSafeObjectProvider(Of ServerComputer)
        Private ReadOnly s_User As New ThreadSafeObjectProvider(Of WebUser)
        Private ReadOnly s_Log As New ThreadSafeObjectProvider(Of AspLog)

        ''' <summary>
        '''     Returns information about the host computer.
        ''' </summary>
        <
            SuppressMessage _
                ("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")>
        Friend ReadOnly Property Computer As ServerComputer
            Get
                Return s_Computer.GetInstance()
            End Get
        End Property

        ''' <summary>
        '''     Returns information for the current Web user.
        ''' </summary>
        <
            SuppressMessage _
                ("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")>
        Friend ReadOnly Property User As WebUser
            Get
                Return s_User.GetInstance()
            End Get
        End Property

        ''' <summary>
        '''     Returns Request object.
        ''' </summary>
        <
            SuppressMessage _
                ("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")> _
        <HelpKeyword("My.Request")>
        Friend ReadOnly Property Request As HttpRequest
            <DebuggerHidden>
            Get
                Dim CurrentContext As HttpContext = HttpContext.Current
                If CurrentContext IsNot Nothing Then
                    Return CurrentContext.Request
                End If
                Return Nothing
            End Get
        End Property

        ''' <summary>
        '''     Returns Response object.
        ''' </summary>
        <
            SuppressMessage _
                ("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")> _
        <HelpKeyword("My.Response")>
        Friend ReadOnly Property Response As HttpResponse
            <DebuggerHidden>
            Get
                Dim CurrentContext As HttpContext = HttpContext.Current
                If CurrentContext IsNot Nothing Then
                    Return CurrentContext.Response
                End If
                Return Nothing
            End Get
        End Property

        ''' <summary>
        '''     Returns the Asp log object.
        ''' </summary>
        <
            SuppressMessage _
                ("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")>
        Friend ReadOnly Property Log As AspLog
            Get
                Return s_Log.GetInstance()
            End Get
        End Property
    End Module
End Namespace

#End If

