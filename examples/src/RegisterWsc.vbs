'Script for RegisterWsc.wsf

Option Explicit
Dim sh : Set sh = CreateObject( "WScript.Shell" )
Dim fso : Set fso = CreateObject( "Scripting.FileSystemObject" )
Dim format : Set format = New StringFormatter
Dim flags : flags = ""
Dim uninstalling : uninstalling = False
Dim i 'integer
Dim item 'command-line argument
Dim file 'filespec

With WScript.Arguments
    If 0 = .Count Then
        Err.Raise 449,, "Command-line argument expected: the .wsc file to register."
    End If
    For i = 0 To .Count - 1
        'the command-line argument may be /u or a filespec
        If "/u" = LCase(.item(i)) Then
            uninstalling = True
            flags = "/u /n"
        Else
            item = Resolve(Expand(.item(i)))
            If fso.FileExists(item) Then
                file = item
            End If
        End If
    Next
    If IsEmpty(file) Then Err.Raise 450,, "None of the command line arguments specify an existing file."
End With

Dim args : args = format(Array("/c " & _
    "%SystemRoot%\System32\regsvr32.exe %s /s /i:""%s"" scrobj.dll & " & _
    "%SystemRoot%\SysWow64\regsvr32.exe %s /s /i:""%s"" scrobj.dll", _
    flags, file, flags, file _
  ))

With CreateObject( "Shell.Application" )
    .ShellExecute "cmd", args,, "runas"
End With

Set fso = Nothing
Set sh = Nothing
Set format = Nothing

Function Expand(path)
    Expand = sh.ExpandEnvironmentStrings(path)
End Function

Function Resolve(relativePath)
    Resolve = fso.GetAbsolutePathName(relativePath)
    If Not fso.FileExists(Resolve) Then
        Err.Raise 505,, "File doesn't exist: " & Resolve
    ElseIf Not "wsc" = LCase(fso.GetExtensionName(Resolve)) Then
        Err.Raise 5,, "Expected .wsc file. Actual file: " & Resolve
    End If
End Function