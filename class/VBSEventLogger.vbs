
'Logs messages to the Application event log.
'
'Wraps the LogEvent method of the WScript.Shell object.
'
'To see a log entry, type EventVwr at the command prompt to open the Event Viewer, expand Windows Logs, and select Application. The log Source will be WSH. Or you can use the CreateCustomView method to create an entry in the Event Viewer's Custom Views section.
'
'Usage example:
' <pre>  With CreateObject( "VBScripting.Includer" ) <br />      Execute .Read( "VBSEventLogger" ) <br />  End With <br />   <br />  Dim logger : Set logger = New VBSEventLogger <br />  logger.log logger.INFORMATION, "message 1" <br />  logger logger.INFORMATION, "message 2" <br />  logger 4, "message 3" <br />  logger 1, "error message" <br />   <br />  logger.CreateCustomView 'create a custom view in the Event Viewer <br />  logger.OpenViewer 'open EventVwr.msc </pre>
'
Class VBSEventLogger

    Private fs 'file system utilities
    Private sh, fso, sa
    Private viewsFolder, VBScriptLibraryPath
    Private customViewFile, configFolder, logFile, logFolder

    Sub Class_Initialize

        'assign defaults in case VBSEventLogger.config is absent
        customViewFile = "VBSEventLoggerCustomView.xml" 'custom view xml
        configFolder = "%ProgramData%\Microsoft\Event Viewer" 'eventvwr.msc config folder
        logFile = "Application.evtx" 'event log file with WSH events
        logFolder = "%SystemRoot%\System32\Winevt\Logs" 'event logs location

        With CreateObject( "VBScripting.Includer" )
            Execute .Read( "VBSFileSystem" )
            On Error Resume Next
                Execute .Read( "VBSEventLogger.config" )
            On Error Goto 0
            VBScriptLibraryPath = .LibraryPath
        End With
        Set fs = New VBSFileSystem
        Set sh = CreateObject( "WScript.Shell" )
        Set fso = CreateObject( "Scripting.FileSystemObject" )
        Set sa = CreateObject( "Shell.Application" )

        customViewFile = fs.ResolveTo(customViewFile, VBScriptLibraryPath) 'get the absolute path
        viewsFolder = fs.Expand( configFolder & "\Views" )
    End Sub

    'Method Log
    'Parameters: eventType, message
    'Remark: Adds an event entry to a log file with the specified message. This is the default method, so the method name is optional.
    Public Default Sub Log(eventType, message)
        sh.LogEvent eventType, message
    End Sub

    'Method CreateCustomView
    'Remark: Creates a Custom View in the Event Viewer, eventvwr.msc, named WSH Logs. The User Account Control dialog will open, in order to confirm elevation of privileges. Based on VBSEventLoggerCustomView.xml.
    Sub CreateCustomView
        If Not fso.FileExists(customViewFile) Then Err.Raise 505,, "Can't find source file, " & customViewFile
        If Not fso.FolderExists(viewsFolder) Then Err.Raise 505,, "Can't find target folder, " & viewsFolder
        sa.ShellExecute "cmd.exe", "/c copy /y """ & customViewFile & """ """ & viewsFolder & """",, "runas"
    End Sub

    'Method OpenViewer
    'Remark: Opens the Windows&reg; Event Viewer, eventvwr.msc
    Sub OpenViewer
        sh.Run "eventvwr.msc"
    End Sub

    'Property SUCCESS
    'Returns 0
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get SUCCESS : SUCCESS = 0 : End Property

    'Property ERROR
    'Returns 1
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get ERROR : ERROR = 1 : End Property

    'Property WARNING
    'Returns 2
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get WARNING : WARNING = 2 : End Property

    'Property INFORMATION
    'Returns 4
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get INFORMATION : INFORMATION = 4 : End Property

    'Property AUDIT_SUCCESS
    'Returns 8
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get AUDIT_SUCCESS : AUDIT_SUCCESS = 8 : End Property

    'Property AUDIT_FAILURE
    'Returns 16
    'Remark: Returns a value for use as an "eventType" parameter
    Property Get AUDIT_FAILURE : AUDIT_FAILURE = 16 : End Property

    'Method OpenConfigFolder
    'Remark: Opens the Event Viewer configuration folder, by default "%ProgramData%\Microsoft\Event Viewer". The Views subfolder contains the .xml files defining the custom views.
    Sub OpenConfigFolder
        sh.Run "explorer " & configFolder
    End Sub

    'Method OpenLogFolder
    'Remark: Opens the folder with the .evtx files that contain the event logs, by default "%SystemRoot%\System32\Winevt\Logs". Application.evtx holds the WSH data.
    Sub OpenLogFolder
        sh.Run "explorer " & logFolder
    End Sub

    Sub Class_Terminate
        Set sh = Nothing
        Set sa = Nothing
        Set fso = Nothing
    End Sub
End Class
