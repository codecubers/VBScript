'
'Provides string formatting functions
'
'Usage example
'' With CreateObject("includer")
''     ExecuteGlobal(.read("StringFormatter"))
'' End With
'' Dim fm : Set fm = New StringFormatter
'' 
'' WScript.Echo fm.format(Array("MsgBox ""%s: "" & %s", "Result", -5.1)) 'MsgBox "Result: " & -5.1
'' 
'' WScript.Echo fm.pluralize(3, "dog") '3 dogs
'' WScript.Echo fm.pluralize(1, "dog") '1 dog
'' WScript.Echo fm.pluralize(0, "dog") '0 dogs
'' fm.SetZeroSingular
'' WScript.Echo fm.pluralize(0, "dog") '0 dog
'' WScript.Echo fm.pluralize(1, Split("person people")) '1 person
'' WScript.Echo fm.pluralize(2, Split("person people")) '2 people
'' WScript.Echo fm.pluralize(12, "egg") '12 eggs
'
Class StringFormatter

    Private zero, singular, plural
    Private scriptName

    Sub Class_Initialize
        singular = "singular"
        plural = "plural"
        SetZeroPlural
        On Error Resume Next
            scriptName = WScript.ScriptName
        On Error Goto 0
    End Sub

    'Function Format
    'Parameter: array
    'Returns a string
    'Remark: Returns a formatted string. The parameter is an array whose first element contains the pattern of the returned string. The first %s in the pattern is replaced by the next element in the array. The second %s in the pattern is replaced by the next element in the array, and so on. Variant subtypes tested OK with %s include string, integer, and single. Format is the default property for the class, so the property name is optional. If there are too many or too few %s instances, then an error will be raised.

    Public Default Function Format(array_)
        Const strSurrogate = "%s"
        Const startPosition = 1
        Const replacemtCount = 1
        Dim arr : arr = array_
        Dim i, pattern : pattern = arr(0)
        For i = 1 To UBound(arr)
            If Not CBool(InStr(pattern, strSurrogate)) Then Err.Raise 1, scriptName, "There are too few instances of " & strSurrogate & vbLf & "Pattern: " & arr(0)
            pattern = Replace(pattern, strSurrogate, arr(i), startPosition, replacemtCount)
        Next
        If InStr(pattern, strSurrogate) Then Err.Raise 1, scriptName, "There are too many instances of " & strSurrogate & vbLf & "Pattern: " & arr(0)
        Format = pattern
    End Function

    'Property Pluralize
    'Parameters: count, noun
    'Returns a string
    'Remark: Returns a string that may or may not be pluralized, depending on the specified count. If the noun has irregular pluralization, pass in a two-element array: <code> Split("person people")</code>. Otherwise, you may pass in either a singular noun as a string, <code> red herring</code>, or else a two-element array, <code> Split("red herring | red herrings", "|")</code>.

    Property Get Pluralize(count, noun_)
        Dim s : s = count & " "
        Dim noun : noun = noun_
        If vbString = VarType(noun) Then
            'convert string to two-element array
            noun = Array("", "")
            noun(0) = Trim(noun_)
            noun(1) = Trim(noun_) & "s"
        End If
        If count > 1 Or (count = 0 And zero = plural) Then
            s = s & Trim(noun(1)) 'plural
        Else
            s = s & Trim(noun(0)) 'singular
        End If
        Pluralize = s
    End Property

    'Method SetZeroSingular
    'Remark: Optional. Changes the default behavior of considering a count of zero to be plural.
    Sub SetZeroSingular : zero = singular : End Sub

    'Method SetZeroPlural
    'Remark: Optional. Restores the default behavior of considering a count of zero to be plural.
    Sub SetZeroPlural : zero = plural : End Sub
End Class