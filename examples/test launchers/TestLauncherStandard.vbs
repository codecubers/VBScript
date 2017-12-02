
'Launch the test runner for standard tests

Option Explicit : Initialize

Call Main

Sub Main

    'specify the file types
    testRunner.SetSpecPattern "*.spec.vbs | *.spec.elev+std.vbs"

    'specify the folder containing the tests; path is relative to this script
    testRunner.SetSpecFolder "..\..\spec"

    'handle command-line arguments, if any
    With WScript.Arguments
        If .Count > 0 Then

            'if it is desired to run just a single test file, pass it in on the
            'command line, using a relative path, relative to the spec folder
            testRunner.SetSpecFile .item(0)

            'get the runCount from the command-line, arg #2, if specified
            If .Count > 1 Then testRunner.SetRunCount .item(1)
       End If
    End With

    'specify the time allotted for each test file to complete all of its specs, in seconds
    testRunner.SetTimeout 4 'default is 0; 0 => indefinite

    'run the tests
    testRunner.Run
End Sub

Const notElevated = False
Const elevated = True
Dim testRunner

Sub Initialize
    With CreateObject("includer")
        Execute .read("VBSTestRunner")
        Execute .read("VBSApp")
    End With
    Set testRunner = New VBSTestRunner
    Dim app : Set app = New VBSApp

    'if required, restart the script with cscript.exe
    If Not "cscript.exe" = app.GetHost Then
        app.SetUserInteractive False
        Dim privileges : privileges = notElevated
        app.RestartWith "cscript.exe", "/k", privileges
    End If
End Sub
