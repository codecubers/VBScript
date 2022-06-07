'Test the RegistryUtility object
'intended to be run with standard or elevated privileges

Option Explicit
Dim r 'the RegistryUtility object under test
Dim incl 'VBScripting.Includer object
Dim sh 'WScript.Shell object
Dim fso 'Scripting.FileSystemObject
Dim valueName, valueName2, value, value2 'strings
Dim key 'string
Dim rootKey 'integer
Dim rootKeyName 'string
Dim subKey 'string

Set incl = CreateObject( "VBScripting.Includer" )
Execute incl.Read( "PrivilegeChecker" )

Execute incl.Read( "TestingFramework" )
With New TestingFramework

    .Describe "RegistryUtility class"
        Set r = incl.LoadObject( "RegistryUtility" )

    'setup

        'build the test key strings, value names, and values,
        'one for REG_SZ and one for REG_EXPAND_SZ

        If New PrivilegeChecker Then
            'privileges are elevated
            rootKey = r.HKCR
            rootKeyName = "HKCR"
            subKey = "AA_RegistryUtility.spec.vbs_Test_Delete_Me"
        Else
            'privileges are not elevated
            rootKey = r.HKCU
            rootKeyName = "HKCU"
            subKey = "Software\VBScripting\AA_RegistryUtility.spec.vbs_Test_Delete_Me"
        End If
        Set sh = CreateObject( "WScript.Shell" )
        Set fso = CreateObject( "Scripting.FileSystemObject" )
        valueName = "" 'an empty string specifies the key's "default value"
        valueName2 = fso.GetTempName
        value = fso.GetTempName
        value2 = fso.GetTempName
        key = rootKeyName & "\" & subKey & "\" 'registry key format used by WScript.Shell RegRead, RegWrite, & RegDelete; this format is not used by the class under test

        'delete the test key, in case a previous erring test prevented its deletion

        On Error Resume Next
            sh.RegDelete key
        On Error Goto 0

        'create the base test key

        sh.RegWrite key, 1, "REG_DWORD"

    .it "should write a registry string (REG_SZ) value"

        r.SetStringValue rootKey, subKey, valueName, value

        .AssertEqual sh.RegRead(key), value

    .it "should enumerate a key with just one value (the default value)"

        Dim aNames, aTypes
        r.EnumValues rootKey, subKey, aNames, aTypes

        .AssertEqual CInt(aNames(0) & aTypes(0)), 1 'the name of a default key is an empty string; REG_SZ type constant is 1

    .it "should write a registry string (REG_EXPAND_SZ) value"

        r.SetExpandedStringValue rootKey, subKey, valueName2, value2

        .AssertEqual sh.RegRead(key & valueName2), value2

    .it "should read a registry string (REG_SZ) value"

        .AssertEqual r.GetStringValue(rootKey, subKey, valueName), value

    .it "should read a registry string (REG_EXPAND_SZ) value"

        .AssertEqual r.GetExpandedStringValue(rootKey, subKey, valueName2), value2

    .it "should access a registry by computer name"

        With CreateObject( "WScript.Network" )
            r.SetPC .ComputerName
        End With

        .AssertEqual r.GetStringValue(rootKey, subKey, valueName), value

    .it "should return an integer showing a REG_SZ type"

        .AssertEqual r.GetRegValueType(rootKey, subKey, valueName), r.REG_SZ

    .it "should return an integer showing a REG_EXPAND_SZ type"

        .AssertEqual r.GetRegValueType(rootKey, subKey, valueName2), r.REG_EXPAND_SZ

    .it "should return a string showing a reg value type REG_SZ"

        .AssertEqual r.GetRegValueTypeString(rootKey, subKey, valueName), "REG_SZ"

    .it "should return a string showing a reg value type REG_EXPAND_SZ"

        .AssertEqual r.GetRegValueTypeString(rootKey, subKey, valueName2), "REG_EXPAND_SZ"

End With

'delete the test key

sh.RegDelete key
