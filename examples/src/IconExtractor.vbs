'Script for ..\IconExtractor.hta

Option Explicit

'project objects
Dim extractor 'VBScripting.IconExtractor object
Dim format 'VBScripting.StringFormatter object
Dim rf 'RegExFunctions object
Dim includer 'VBScripting.Includer object
Dim browser 'VBScripting.FolderChooser object
Dim log 'VBSLogger object
Dim admin 'VBScripting.Admin object
Dim pbar 'VBScripting.ProgressBar

'Windows native objects
Dim sh 'WScript.Shell object
Dim fso 'Scripting.FileSystemObject
Dim regex 'RegExp object
Dim fileDict 'Scripting.Dictionary object for storing filespecs
Dim application 'HTML application element (HTA application)

'other
Dim timeoutId 'saved integer for cancelling a setTimeout instance
Dim fileKeys 'array of filespecs
Dim iconIndex 'index of an icon within a .dll or .exe file
Dim fileIndex 'array index for the fileKeys array
Dim targetFolder 'string: a folder path
Dim ms 'integer: milliseconds; for setTimeout 
Dim iconsExtracted 'integer: number of icons extracted
Dim CheckingMsg 'string: partial progress message
Dim eStop 'boolean: flag for stopping the extration
Dim iconCount 'integer: the supposed number of icons in a file
Dim configFile 'string: filespec of configuration file

Const F1 = 112 'window.event.KeyCode
Const F6 = 117
Const F7 = 118
Const F8 = 119
Const F9 = 120
Const Esc = 27
Const Enter = 13
Const ForWriting = 2, CreateNew = True 'for OpenTextFile
Const ListingFiles = "Listing filles"
Const ExtractingFiles = "Extracting files"
Const ShowingResults = "Showing results"
Const WordPad = "%ProgramFiles%\Windows NT\Accessories\wordpad.exe"

Sub Window_OnLoad
    Dim sourceFileValue
    Dim sourceDirValue
    Dim targetDirValue
    Dim configStream
    InitializeObjects

    'populate fields from the config file,
    'and/or create the config file
    
    configFile = format(Array( _
        "%s\VBScripting\%s.configure", _
        Expand("%AppData%"), _
        fso.GetBaseName(document.location.href)))
    On Error Resume Next
        Execute fso.OpenTextFile(configFile).ReadAll
        If Err Then
            Set configStream = fso.OpenTextFile(configFile, ForWriting, CreateNew)
            configStream.WriteLine "sourceDirValue = ""%SystemRoot%\System32"""
            configStream.WriteLine "sourceFileValue = ""*.dll | *.exe"""
            configStream.WriteLine "targetDirValue = format(Array(""%UserProfile%\Desktop\extracted-icons\%s-%s-%s-%s-%s"", Month(Now), Day(Now), Hour(Now), Minute(Now), Second(Now)))"
            configStream.Close
        End If
    Err.Clear
        Execute fso.OpenTextFile(configFile).ReadAll
        If Err Then
            Feedback format( Array( _
                "Error reading the config file. <br />" & _
                "File: %s <br />" & _
                "Error description: %s", _
                configFile, Err.Description _
            ))
        End If
    On Error Goto 0

    If admin.PrivilegesAreElevated Then
        Disable elevateBtn
    End If
    sourceDirTxtBox.value = sourceDirValue
    sourceFileTxtBox.value = sourceFileValue
    targetDirTxtBox.value = targetDirValue
    CheckIconChoices
    CheckingMsg = "Checking for icons in<br />"
    Disable stopBtn
    ms = 0 'milliseconds; for setTimeout
End Sub

Sub InitializeObjects
    Set sh = CreateObject( "WScript.Shell" )
    Set fso = CreateObject( "Scripting.FileSystemObject" )
    Set format = CreateObject( "VBScripting.StringFormatter" )
    Set extractor = CreateObject( "VBScripting.IconExtractor" )
    Set application = document.getElementsByTagName( "application" )(0)
    document.Title = application.applicationName
    Set regex = New RegExp
    regex.IgnoreCase = True
    Set includer = CreateObject( "VBScripting.Includer" )
    Execute includer.Read( "RegExFunctions" )
    Set rf = New RegExFunctions
    Execute includer.Read( "VBSLogger" )
    Set log = New VBSLogger
    Set browser = CreateObject( "VBScripting.FolderChooser" )
    Set admin = CreateObject( "VBScripting.Admin" )
    Set fileDict = CreateObject( "Scripting.Dictionary" )
    Set pbar = CreateObject( "VBScripting.ProgressBar" )
    pbar.SetIconByDllFile "%SystemRoot%\System32\msctfui.dll", 0
    pbar.FormLocationByPercentage 100, 100
    pbar.FormSize 500, 100
    pbar.PBarSize 400, 30
    pbar.PBarLocation 50, 40
    pbar.Caption = "Extracting icons..."
    pbar.Minimum = 0
    pbar.Style = 1 'continuous style = 1
End Sub

Sub extractIconsBtn_OnClick
    InProgressMsg "Getting the file list..."
    window.setTimeout "PrepStatesFor ListingFiles", ms, "VBScript"
End Sub

Function PrepStatesFor(status)
    Select Case status

    Case ListingFiles
    ClearFeedback
    Disable extractIconsBtn
    inProgressDiv.style.display = "block"
    fileDict.RemoveAll
    iconsExtracted = 0
    eStop = False
    Disable subfoldersChkBox
    Disable sourceDirTxtBox
    Disable sourceBrowserBtn
    Disable sourceFileTxtBox
    Disable targetDirTxtBox
    Disable targetBrowserBtn
    Disable largeIconsChkBox
    Disable smallIconsChkBox
    Disable zeroIndexesOnlyChkBox
    Disable stopBtn
    Disable elevateBtn
    window.setTimeout "ListFiles", ms, "VBScript"

    Case ExtractingFiles
    fileKeys = fileDict.Keys
    If -1 = UBound(fileKeys) Then
        Feedback "No files found"
        PrepStatesFor = False
        PrepStatesFor ShowingResults
        Exit Function
    End If
    iconIndex = 0
    fileIndex = 0
    InProgressMsg CheckingMsg & fileKeys(0)
    targetFolder = Expand(targetDirTxtBox.value)
    Enable stopBtn
    stopBtn.focus
    Disable extractIconsBtn

    Case ShowingResults
    inProgressDiv.innerHTML = ""
    inProgressDiv.style.display = "none"
    pbar.Visible = False
    Enable extractIconsBtn
    Enable stopBtn
    Enable subfoldersChkBox
    Enable sourceDirTxtBox
    Enable sourceBrowserBtn
    Enable sourceFileTxtBox
    Enable targetDirTxtBox
    Enable targetBrowserBtn
    Enable largeIconsChkBox
    Enable smallIconsChkBox
    Enable zeroIndexesOnlyChkBox
    Disable stopBtn
    Enable elevateBtn
    End Select

    PrepStatesFor = True
End Function

Sub Disable(element)
    element.disabled = True
End Sub
Sub Enable(element)
    element.disabled = False
End Sub

'Compile a list of the file(s) to extract; then start extracting
Sub ListFiles
    Dim dir
    dir = Expand(targetDirTxtBox.value)
    If largeIconsChkBox.checked Then
        CreateFolder format(Array("%s\lg", dir))
    End If
    If smallIconsChkBox.checked Then
        CreateFolder format(Array("%s\sm", dir))
    End If
    If subfoldersChkBox.checked Then
        ListFilesBySubfolder sourceDirTxtBox.value
    ElseIf InStr( sourceFileTxtBox.value, "*" ) _
    Or InStr( sourceFileTxtBox.value, "?" ) _
    Or InStr( sourceFileTxtBox.value, "|" ) Then
        ListFilesByWildcard sourceDirTxtBox.value
    Else
        ListFile sourceDirTxtBox.value, sourceFileTxtBox.value
    End If
    If Not PrepStatesFor(ExtractingFiles) Then
        Exit Sub
    End If
    pbar.Maximum = UBound(fileKeys) + 1
    On Error Resume Next 'prevents an error if the progress bar was previously closed by the user
        pbar.Visible = True
    On Error Goto 0
    window.setTimeout "ExtractTheNextIcon", ms, "VBScript"
End Sub

Sub ClearEStop
    eStop = False
End Sub

Sub ListFilesBySubfolder(folder)
    Dim subfolder
    For Each subfolder In fso.GetFolder(Expand(folder)).SubFolders
        ListFilesBySubfolder subfolder 'recurse
    Next
    ListFilesByWildcard folder
End Sub

Sub ListFilesByWildcard(sourceDir)
    Dim file
    regex.Pattern = rf.Pattern(sourceFileTxtBox.value)
    For Each file In fso.GetFolder(Expand(sourceDir)).Files
        If regex.Test(file.Name) Then
            ListFile sourceDir, file.Name
        End If
    Next
End Sub

'Add a file to the dictionary object. Just the key is used, not the value.
Sub ListFile(sourceDir, sourceFile)
    fileDict.Add format(Array("%s\%s", sourceDir, sourceFile)), ""
End Sub

Sub ExtractTheNextIcon
    Dim file 'filespec of the current file
    Dim base 'base name of the current file
    Dim ext 'extension name of the current file
    Dim largeTarget 'generated filespec for saving a large icon
    Dim smallTarget 'generated filespec for saving a small icon
    Dim suspect 'flespec of potentially-zero-size icon file
    Dim msg 'string: partial progress message
    If eStop Or fileIndex > UBound(fileKeys) Then
        ShowResults
        Exit Sub
    End If
    pbar.Value = fileIndex
    file = fileKeys(fileIndex)
    If iconIndex = 0 Then
        iconCount = extractor.IconCount(file)
    End If
    If (zeroIndexesOnlyChkBox.checked And iconIndex > 0) _
    Or iconIndex >= iconCount Then
        iconIndex = 0
        fileIndex = fileIndex + 1
        window.setTimeout "ExtractTheNextIcon", ms, "VBScript"
        Exit Sub
    End If
    base = fso.GetBaseName(file)
    ext = fso.GetExtensionName(file)
    largeTarget = format(Array( _
        "%s\lg\%s_%s_%s_Lg.ico", _
        targetFolder, base, ext, iconIndex))
    smallTarget = format(Array( _
        "%s\sm\%s_%s_%s_Sm.ico", _
        targetFolder, base, ext, iconIndex))
    If largeIconsChkBox.checked Then
        On Error Resume Next
            extractor.Save file, iconIndex, largeTarget, True
        On Error Goto 0
    End If
    If smallIconsChkBox.checked Then
        On Error Resume Next
            extractor.Save file, iconIndex, smallTarget, False
        On Error Goto 0
    End If
    For Each suspect In Array(largeTarget, smallTarget)
        RemoveIfZeroSize suspect
    Next
    If iconIndex = 0 Then
        msg = CheckingMsg
    Else msg = format(Array("Extracting icon %s from<br />", iconIndex))
    End If
    InProgressMsg msg & fileKeys(fileIndex)
    If fileIndex > UBound(fileKeys) Then
        ShowResults
        Exit Sub
    Else iconIndex = iconIndex + 1
    End If
    window.setTimeout "ExtractTheNextIcon", ms, "VBScript"
End Sub

Sub ShowResults
    PrepStatesFor ShowingResults
    Feedback "Icons extracted: " & iconsExtracted
    Feedback "Files processed: " & fileIndex
    window.setTimeout "ClearEStop", ms + 200, "VBScript"
End Sub

Sub RemoveIfZeroSize(filespec)
    If Not fso.FileExists(filespec) Then
        Exit Sub
    End If
    If fso.GetFile(filespec).Size > 0 Then
        iconsExtracted = iconsExtracted + 1
        Exit Sub
    End If
    On Error Resume Next
        fso.DeleteFile filespec
    On Error Goto 0
End Sub

Sub sourceBrowserBtn_OnClick
    Dim folder
    browser.Title = "Choose the icon source folder"
    browser.InitialDirectory = "%ProgramFiles%"
    folder = browser.FolderName
    If Not "" = folder Then
        sourceDirTxtBox.value = folder
    End If
End Sub

Sub targetBrowserBtn_OnClick
    Dim folder
    browser.Title = "Create and/or choose a destination folder for the icons that will be extracted"
    browser.InitialDirectory = "%UserProfile%\Desktop"
    folder = browser.FolderName
    If Not "" = folder Then
        targetDirTxtBox.value = folder
    End If
End Sub

Sub stopBtn_OnClick
    eStop = True
    Disable stopBtn
End Sub

Sub elevateBtn_OnClick
    With CreateObject( "Shell.Application" )
        .ShellExecute "mshta", application.CommandLine,, "runas"
    End With
    Self.Close
End Sub

Sub Document_OnKeyUp
    If F6 = window.event.keyCode Then
        sh.Run format(Array( _
            """%s"" %s", _
            Expand(WordPad), _
            application.commandLine ))
    ElseIf F9 = window.event.keyCode Then
        sh.Run "notepad """ & configFile & """"
    ElseIf Enter = window.event.keyCode _
    And Not eStop _
    And Not extractIconsBtn.disabled Then
        window.setTimeout _
            "extractIconsBtn_OnClick", ms, "VBScript"
    ElseIf Esc = window.event.keyCode Then
        Self.Close
    End If
End Sub

Sub smallIconsChkBox_OnClick
    CheckIconChoices
End Sub
Sub largeIconsChkBox_OnClick
    CheckIconChoices
End Sub

Sub CheckIconChoices
    If Not smallIconsChkBox.checked _
    And Not largeIconsChkBox.checked Then
        Disable extractIconsBtn
    Else Enable extractIconsBtn
    End If
End Sub

Sub CreateFolder(newDir)
    Dim parentDir
    parentDir = fso.GetParentFolderName(newDir)
    If Not fso.FolderExists(parentDir) Then
        CreateFolder parentDir
    End If
    If Not fso.FolderExists(newDir) Then
        fso.CreateFolder newDir
    End If
End Sub

Function Expand(str)
    Expand = sh.ExpandEnvironmentStrings(str)
End Function

Sub InProgressMsg(msg)
    inProgressDiv.innerHTML = msg
End Sub

Sub Feedback(msg)
    feedbackDiv.innerHTML = msg & "<br />" & feedbackDiv.innerHTML
    window.clearTimeout timeoutId
    timeoutId = window.setTimeout("ClearFeedback", 20000, "VBScript")
End Sub

Sub ClearFeedback
    feedbackDiv.innerHTML = ""
End Sub

Sub ReleaseObjects
    Set sh = Nothing
    Set fso = Nothing
    Set format = Nothing
    Set extractor = Nothing
    Set application = Nothing
    Set regex = Nothing
    Set includer = Nothing
    Set rf = Nothing
    Set log = Nothing
    Set browser = Nothing
    Set admin = Nothing
    Set fileDict = Nothing
End Sub

Sub Window_OnUnload
    ReleaseObjects
End Sub
