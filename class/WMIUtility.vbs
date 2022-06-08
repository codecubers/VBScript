'Examples of the Windows Management Instrumentation object.
'
' See <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/computer-system-hardware-classes > Computer System Hardware Classes</a>.
'
Class WMIUtility

    'Function TerminateProcessById
    'Parameter: process id
    'Returns a boolean
    'Remark: Terminates any Windows&reg; process with the specified id. Returns True if the process was found, False if not.
    Function TerminateProcessById(id)
        Dim scrubId : scrubId = Scrub(id)
        Dim process
        For Each process in GetProcessesWhere("ProcessID = '" & scrubId & "'")
            process.Terminate()
            TerminateProcessById = True
            Exit Function
        Next
        TerminateProcessById = False
    End Function

    'Function TerminateProcessByIdAndName
    'Parameters: id, name
    'Returns a boolean
    'Remark: Terminates a process with the specified id and name. Returns True if the process was found, False if not.
    Function TerminateProcessByIdAndName(id, name)
        Dim scrubId : scrubId = Scrub(id)
        Dim scrubName : scrubName = Scrub(name)
        Dim process
        For Each process in GetProcessesWhere("ProcessID = '" & scrubId & "' and Name = '" & scrubName & "'")
            process.Terminate()
            TerminateProcessByIdAndName = True
            Exit Function
        Next
        TerminateProcessByIdAndName = False
    End Function

    'Method TerminateProcessByIdAndNameDelayed
    'Parameters: id, name, milliseconds
    'Remark: Terminates a process with the specified id (integer), name (string, e.g. notepad.exe), and delay (integer: milliseconds), asynchronously.
    Sub TerminateProcessByIdAndNameDelayed(id, name, milliseconds)
        'create and run a .vbs script to end the process
        With CreateObject( "VBScripting.Includer" )
            Execute .Read( "TextStreamer" )
            Execute .Read( "StringFormatter" )
        End With
        Dim ts : Set ts = New TextStreamer
        ts.SetFolder "%Temp%"
        ts.SetFileName ts.GetFileName & ".vbs"
        Dim format : Set format = New StringFormatter
        Dim stream : Set stream = ts.Open
        stream.WriteLine "'automatically generated script"
        stream.WriteLine "With CreateObject(""VBScripting.Includer"")"
        stream.WriteLine "    Execute .Read(""WMIUtility"")"
        stream.WriteLine "End With"
        stream.WriteLine "Dim fso : Set fso = CreateObject(""Scripting.FileSystemObject"")"
        stream.WriteLine "Dim wmi : Set wmi = New WMIUtility"
        stream.WriteLine "WScript.Sleep " & milliseconds
        stream.WriteLine format(Array("wmi.TerminateProcessByIdAndName %s, ""%s""", id, name))
        stream.WriteLine "fso.DeleteFile WScript.ScriptFullName" 'file deletes itself
        stream.WriteLine "Set fso = Nothing"
        stream.Close
        Set stream = Nothing
        ts.Run 'the Run method is asynchronous by default: program execution will not halt
    End Sub

    'Function GetProcessIDsByName
    'Parameter a process name
    'Returns a boolean
    'Remark: Returns an array of the process ids of all processes that have the specified name. The process name is what would appear in the Task Manager's Details tab. <br /> E.g. <code> notepad.exe</code>.
    Function GetProcessIDsByName(pName)
        Dim s : s = ""
        Dim scrubName : scrubName = Scrub(pName)
        Dim process
        For Each process in GetProcessesWhere("Name = '" & scrubName & "'")
            s = s & " " & process.ProcessID
        Next
        GetProcessIDsByName = split(Trim(s))
    End Function

    'Function GetProcessesWithNamesLike
    'Parameter: a string like jav%
    'Returns an array of process names
    Function GetProcessesWithNamesLike(string_)
        Dim s : s = ""
        Dim scrubString : scrubString = Scrub(string_)
        Dim process
        For Each process in GetProcessesWhere("Name like '" & scrubString & "'")
            s = s & " " & process.Name
        Next
        GetProcessesWithNamesLike = split(Trim(s))
    End Function

    'Function IsRunning
    'Parameter: a process name
    'Returns a boolean
    'Remark: Returns a boolean indicating whether at least one instance of the specified process is running. <br /> E.g. <code> wmi.IsRunning( "notepad.exe" ) 'True or False</code>.
    Function IsRunning(name)
        IsRunning = -1 < UBound(GetProcessIDsByName(name))
    End Function

    'Scrub parameters before query
    Private Property Get Scrub(param)
        Dim s : s = param
        Dim removes : removes = Array("=", " ", ";", "'", "\", "/", ":", "*", "?", """", "<", ">", "|", "%20")

        For i = 0 To UBound(removes)
            s = Replace( s, removes(i), "" )
        Next
        Scrub = s
    End Property

    Private Function GetProcessesWhere(condition)
        Set GetProcessesWhere = GetResults(select_ & all & from & Win32_Process & where & condition)
    End Function

    Property Get Win32_Process : Win32_Process = "Win32_Process" : End Property

    Private Function GetResults(query)
        Set GetResults = GetObject(GetWmiToken).ExecQuery(query)
    End Function

    Private Property Get wmiToken1 : wmiToken1 = "winmgmts:\\" : End Property
    Private Property Get wmiToken2 : wmiToken2 = "winmgmts:{impersonationLevel=impersonate}!\\" : End Property
    Property Get GetWmiToken : GetWmiToken = wmiToken1 & computer & "\root\cimv2" : End Property

    'Function partitions
    'Returns a collection
    'Remarks: Returns a collection of <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-diskpartition> Win32_DiskPartition</a> objects, each having these properties, among others: Caption, Name, DiskIndex, Index, PrimaryPartition, Bootable, BootPartition, Description, Type, Size, StartingOffset, BlockSize, DeviceID, Access, Availability, ErrorMethodology, HiddenSectors, Purpose, Status.
    Function partitions
        Set partitions = GetResults(select_ & all & from & Win32_DiskPartition)
    End Function
    Property Get Win32_DiskPartition : Win32_DiskPartition = "Win32_DiskPartition" : End Property

    'Function disks
    'Returns a collection
    'Remark: Returns a collection of <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-logicaldisk> Win32_LogicalDisk</a> objects, each having these properties, among others: FileSystem, DeviceID.
    Function disks
        Set disks = GetResults(select_ & all & from & Win32_LogicalDisk)
    End Function
    Property Get Win32_LogicalDisk : Win32_LogicalDisk = "Win32_LogicalDisk" : End Property

    'Function cpu
    'Returns an object
    'Remark: Returns a <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor> Win32_Processor</a> object that has these properties, among others: Architecture, Description.
    Function cpu
        Dim processor, q
        q = select_ & all & from & Win32_Processor
        For Each processor in GetResults(q)
            Set cpu = processor : Exit For
        Next
    End Function
    'Function CPUs
    'Returns a collection
    'Remark: Returns a collection of <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor> Win32_Processor</a> objects, each of which has these properties, among others: Architecture, Description
    Function CPUs
        Set CPUs = GetResults(select_ & all & from & Win32_Processor)
    End Function
    Property Get Win32_Processor : Win32_Processor = "Win32_Processor" : End Property

    'Function os
    'Returns an object
    'Remark: Returns a <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingsystem> Win32_OperatingSystem</a> object having these properties, among others: Name, Version, Manufacturer, WindowsDirectory, Locale, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory, SizeStoredInPagingFiles.
    Function os
        Dim process
        For Each process in GetResults(select_ & all & from & Win32_OperatingSystem)
            Set os = process : Exit For
        Next
    End Function
    Property Get Win32_OperatingSystem : Win32_OperatingSystem = "Win32_OperatingSystem" : End Property

    'Function pc
    'Returns an object
    'Remark: Returns a <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem> Win32_ComputerSystem</a> object which has these properties, among others: Name, Manufacturer, Model, CurrentTimeZone, TotalPhysicalMemory.
    Function pc
        Dim process
        For Each process in GetResults(select_ & all & from & Win32_ComputerSystem)
            Set pc = process : Exit For
        Next
    End Function
    Property Get Win32_ComputerSystem : Win32_ComputerSystem = "Win32_ComputerSystem" : End Property

    'Function Bios
    'Returns an object
    'Remark: Returns a <a href=https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-bios> Win32_BIOS</a> object which has a Version property, among others.
    Function Bios
        Dim process
        For Each process in GetResults(select_ & all & from & Win32_Bios)
            Set Bios = process : Exit For
        Next
    End Function
    Property Get Win32_Bios : Win32_Bios = "Win32_Bios" : End Property

    'Function Battery
    'Returns an object
    'Remark: Returns a <a target="_blank" href="https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-battery"> Win32_Battery</a> object, which has these properties, among others: BatteryStatus, EstimatedChargeRemaining.
    Function Battery
        Dim bat
        For Each bat in GetResults(select_ & all & from & Win32_Battery)
            Set Battery = bat : Exit For
        Next
    End Function
    Property Get Win32_Battery : Win32_Battery = "Win32_Battery" : End Property

    Sub SetPC(newPC) : computer = newPC : End Sub
    Private Property Get localPC : localPC = "." : End Property

    Private computer, select_, all, from, where

    Sub Class_Initialize
         SetPC(localPC)
         select_ = "Select "
         all = " * "
         from = " from "
         where = " where "
    End Sub
End Class
