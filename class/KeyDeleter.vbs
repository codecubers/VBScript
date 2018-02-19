
'delete a registry key and all subkeys

Class KeyDeleter

    Public Sub DeleteKey(root, key)
        ValidateRoot root
        PrivateDeleteKey root, key, Delete
    End Sub
    
    Private Sub PrivateDeleteKey(root, key, deleting)
        Dim subkey, name, names
        ValidateKey key

        'enumerate subkeys
        reg.EnumKey root, key, names

        'if names is an array, then there are subkeys
        If IsArray(names) Then

            'for each subkey, recurse
            For Each name In names
                subkey = key & "\" & name
                ValidateSubkey key, subkey
                PrivateDeleteKey root, subkey, deleting
            Next
        End If
        
        'delete key after deleting subkeys
        If deleting Then
            result_ = reg.DeleteKey(root, key)
        Else result_ = - 1
        End If
    End Sub

    Sub ValidateRoot(rootCandidate)
        Dim root : For Each root In validRoots
            If rootCandidate = root Then Exit Sub
        Next
        Err.Raise 1, "KeyDeleter.ValidateRoot", "Expected one of " & validRootsString
    End Sub

    Sub ValidateKey(key)
        If "" = Trim(key) Or key <> Trim(key) Then Err.Raise 1, "KeyDeleter.ValidateKey", "The key value is empty, consists of whitespace, or has leading or trailing whitespace."
    End Sub
    
    Sub ValidateSubkey(key, subkey)
        savedKey_ = key
        savedSubkey_ = subkey
        ValidateBackslashCount key, subkey
    End Sub

    Sub ValidateBackslashCount(key, subkey)
        If BackslashCount(subkey) - BackslashCount(key) <> 1 Then Err.Raise 1, "KeyDelete.ValidateBackslashCount", "Expected subkey to have one more backslash than its parent key."
    End Sub

    Function BackslashCount(str)
        Dim count : count = 0
        Dim i : For i = 1 To Len(str)
            If "\" = Mid(str, i, 1) Then count = count + 1
        Next
        If count > maxCount_ Then maxCount_ = count
        BackslashCount = count
    End Function

    Property Get HKCR : HKCR = &H80000000 : End Property
    Property Get HKCU : HKCU = &H80000001 : End Property
    Property Get HKLM : HKLM = &H80000002 : End Property
    Property Get HKU : HKU = &H80000003 : End Property
    Property Get HKCC : HKCC = &H80000005 : End Property
    
    'for testability, introduce a few Public
    'Get-ters and a Let-ter
    Private maxCount_
    Public Property Get MaxCount : MaxCount = maxCount_ : End Property
    Private savedKey_
    Public Property Get SavedKey : SavedKey = savedKey_ : End Property
    Private savedSubkey_
    Public Property Get SavedSubkey : SavedSubkey = savedSubkey_ : End Property
    Private result_
    Public Property Get Result : Result = result_ : End Property
    Private delete_
    Public Property Get Delete : Delete = delete_ : End Property
    Public Property Let Delete(newValue)
        If Not "Boolean" = TypeName(newValue) Then Err.Raise 1, "KeyDeleter.Delete (Let)", "Expected a Boolean."
        delete_ = newValue
    End Property

    Private reg
    Private validRoots, validRootsStrings, validRootsString
    
    Sub Class_Initialize
        maxCount_ = -1
        Delete = True
        validRoots = Array(HKCR, HKCU, HKLM, HKU, HKCC)
        validRootsStrings = Array( _
           "-2147483648 = &H80000000 (HKCR)", _
           "-2147483647 = &H80000001 (HKCU)", _
           "-2147483646 = &H80000002 (HKLM)", _
           "-2147483645 = &H80000003 (HKU)", _
           "-2147483643 = &H80000005 (HKCC)")
        validRootsString = vbLf & _
            Join(validRootsStrings, vbLf) & vbLf
        Set reg = GetObject( _
           "winmgmts:\\.\root\default:StdRegProv")
    End Sub
End Class