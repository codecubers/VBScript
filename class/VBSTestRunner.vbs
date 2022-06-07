
'Run a test or group of tests

'Usage example
' <pre>    'test-launcher.vbs <br />    'run this file from a console window; e.g. cscript //nologo test-launcher.vbs <br />   <br />     With CreateObject( "VBScripting.Includer" ) <br />         Execute .Read( "VBSTestRunner" ) <br />     End With <br />   <br />     With New VBSTestRunner <br />         .SetSpecFolder "../spec" 'location of test files relative to test-launcher.vbs <br />         .Run <br />     End With </pre>
'
'See also <a href=#testingframework> TestingFramework</a>.
'
Class VBSTestRunner

    'Method Run
    'Remark: Initiate the specified tests
    Sub Run
        ValidateSettings

        'run the test(s)
        Set regex = New RegExp
        regex.IgnoreCase = True
        regex.Pattern = specPattern
        Dim i : For i = 1 To runCount
            If Len(specFile) Then
                RunTest fs.ResolveTo(specFile, specFolder) 'a single test
            Else
                ProcessFiles fso.GetFolder(specFolder) 'multiple tests
            End If
        Next

        'write the result summary
        If GetErring Then
            Write_ formatter.pluralize( GetErring, "erring file" ) & ", "
        End If
        If GetFailing Then
            Write_ formatter.pluralize( GetFailing, "failing spec" ) & ", "
        End If
        If GetPassing Then
            Write_ formatter.pluralize( GetPassing, "passing spec" ) & "; "
        End If
        Write_ formatter.pluralize( GetSpecFiles, "test file" ) & "; "
        WriteLine "test duration: " & formatter.pluralize( stopwatch, "second" ) & " "
    End Sub

    'run all the test files whose names match the regex pattern
    Private Sub ProcessFiles(Folder)
        Dim File, Subfolder
        If searchingSubfolders Then
            For Each Subfolder in Folder.Subfolders
                ProcessFiles Subfolder 'recurse
            Next
        End If
        For Each File In Folder.Files
            'if the file is a test/spec file, then run it
            If regex.Test(File.Name) Then
                RunTest File.Path
            End If
        Next
    End Sub

    'run a single test file
    Private Sub RunTest(filespec)
        Dim Pipe : Set Pipe = sh.Exec("%ComSpec% /c cscript //nologo """ & filespec & """")
        TimedOut = False
        IncrementSpecFiles

        'wait for test to finish or time out
        If timeout > 0 Then
            WaitForTestToFinishOrTimeout(Pipe)
        End If

        'show StdOut results not already shown
        While Not Pipe.StdOut.AtEndOfStream
            WriteALineOfStdOut(Pipe)
        Wend

        'show any errors
        While Not Pipe.StdErr.AtEndOfStream
            WriteALineOfStdErr(Pipe)
        Wend

        If TimedOut Then
            Pipe.Terminate
            log fso.GetBaseName(filespec) & " timed out (> " & timeout & "s)"
        End If
    End Sub

    'Method SetSpecFolder
    'Parameter a folder
    'Remark: Optional. Specifies the folder containing the test files. Can be a relative path, relative to the calling script. Default is the parent folder of the calling script.
    Sub SetSpecFolder(newSpecFolder)
        specFolder = fs.Resolve(newSpecFolder)
    End Sub

    'Method SetSpecPattern
    'Parameter: wildcard(s)
    'Remark Optional. Specifies which file types to run. Default is *.spec.vbs. Standard wildcard notation with &#124; delimiter.
    Sub SetSpecPattern(wildcard)
        specPattern = rf.Pattern(wildcard)
    End Sub

    'Method SetSpecFile
    'Parameter: a file
    'Remark Optional. Specifies a single file to test. Include the filename extension. E.g. SomeClass.spec.vbs. A relative path is OK, relative to the spec folder. If no spec file is specified, all test files matching the specified pattern will be run. See SetSpecPattern.
    Sub SetSpecFile(newSpecFile)
        specFile = newSpecFile
    End Sub

    'Method SetSearchSubfolders
    'Parameter: a boolean
    'Remark: Optional. Specifies whether to search subfolders for test files. True or False. Default is False.
    Sub SetSearchSubfolders(newSearchingSubfolders)
        searchingSubfolders = newSearchingSubfolders
    End Sub

    'Method SetPrecision
    'Parameter: 0, 1, or 2
    'Remark: Optional. Sets the number of decimal places for reporting the elapsed time. Default is 2.
    Sub SetPrecision(newPrecision) : stopwatch.SetPrecision newPrecision : End Sub

    'Method SetRunCount
    'Parameter: an integer
    'Remark: Optional. Sets the number of times to run the test(s). Default is 1.
    Sub SetRunCount(newRunCount) : runCount = newRunCount : End Sub

    'Sets the time in seconds to wait for each test file to finish all of its specs. After this time the test file will be terminated and the other tests, if any, will be run. 0 waits indefinitely. Default is 0. Termination may not be immediate. Optional.
    Sub SetTimeout(newTimeout) : timeout = newTimeout : End Sub

    Private Sub ValidateSettings
        Dim msg
        msg = "The folder specified using SetSpecFolder must exist. A relative path is fine, relative to the calling script's folder, " & fs.SFolderName
        If Not fso.FolderExists(specFolder) Then Err.Raise 505, fs.SName, msg
        sh.CurrentDirectory = specFolder

        msg = "Wnen SetSpecFile is used to specify a single spec file, the file specified (" & specFile & ") must exist. A relative path is fine, relative to the spec folder, " & specFolder
        If Len(specFile) Then
            If Not fso.FileExists(fs.ResolveTo(specFile, specFolder)) Then Err.Raise 505, fs.SName, msg
        End If
    End Sub

    Private Sub WriteALineOfStdOut(Pipe)
        Dim Line
        If Not Pipe.StdOut.AtEndOfStream Then
            Line = Pipe.StdOut.ReadLine
            WriteLine Line
            If "pass" = LCase(Left(Line, 4)) Then IncrementPassing
            If "fail" = LCase(Left(Line, 4)) Then IncrementFailing
        End If
    End Sub

    Private Sub WriteALineOfStdErr(Pipe)
        Dim Line
        If Not Pipe.StdErr.AtEndOfStream Then
            Line = Pipe.StdErr.ReadLine
            If Len(Line) Then
                WriteLine WScript.ScriptName & ": """ & Line & """"
                IncrementErring
            End If
        End If
    End Sub

    Private Sub WaitForTestToFinishOrTimeout(Pipe)
        Dim startSplit : startSplit = stopwatch.Split
        Do
            WScript.Sleep 100 'milliseconds
            WriteALineOfStdOut(Pipe)
            If stopwatch.Split - startSplit > timeout Then Exit Do
            If TestIsFinished = Pipe.status Then Exit Sub
        Loop
        TimedOut = True
    End Sub

    'Write a line to StdOut
    Private Sub WriteLine(line)
        If Len(line) Then WScript.StdOut.WriteLine line
    End Sub

    'Write to StdOut
    Private Sub Write_(str)
        If Len(str) Then WScript.StdOut.Write str
    End Sub

    Private passing, failing, erring, foundTestFiles 'tallies
    Private regex
    Private fs, formatter, stopwatch, log, rf
    Private sh, fso
    Private specFolder, specPattern, specFile 'settings
    Private searchingSubfolders
    Private runCount
    Private timeout, TimedOut
    Private TestIsFinished, TestIsRunning

    Sub Class_Initialize
        passing = 0
        failing = 0
        erring = 0
        foundTestFiles = 0
        TestIsRunning = 0
        TestIsFinished = 1
        With CreateObject( "VBScripting.Includer" )
            Execute .Read( "VBSFileSystem" )
            Execute .Read( "StringFormatter" )
            Execute .Read( "VBSStopwatch" )
            Execute .Read( "VBSlogger" )
            Execute .Read( "RegExFunctions" )
        End With
        Set fs = New VBSFileSystem
        Set formatter = New StringFormatter
        Set stopwatch = New VBSStopwatch
        Set log = New VBSLogger
        Set rf = New RegExFunctions
        Set sh = CreateObject( "WScript.Shell" )
        Set fso = CreateObject( "Scripting.FileSystemObject" )
        specFolder = ""
        SetSpecFile ""
        SetSpecPattern "*.spec.vbs"
        SetSearchSubfolders False
        SetPrecision 2
        SetRunCount 1
        SetTimeout 0
    End Sub

    Private Property Get GetPassing : GetPassing = passing : End Property
    Private Property Get GetFailing : GetFailing = failing : End Property
    Private Property Get GetErring : GetErring = erring : End Property
    Private Property Get GetSpecFiles : GetSpecFiles = foundTestFiles : End Property
    Private Sub IncrementFailing : failing = 1 + failing : End Sub
    Private Sub IncrementPassing : passing = 1 + passing : End Sub
    Private Sub IncrementErring : erring = 1 + erring : End Sub
    Private Sub IncrementSpecFiles : foundTestFiles = 1 + foundTestFiles : End Sub

    Sub Class_Terminate
        Set sh = Nothing
        Set fso = Nothing
    End Sub
End Class
