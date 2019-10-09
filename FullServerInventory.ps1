#     Powershell script created to gather some basic server information when I log onto a server for the first time
#     or after configuration changes are made.
#     Created by Jeremiah Berryman
#     Date 7.28.2016
#     Updated 4.12.2017
#        Added GPResult & Auditpol to the script.
#     *****
#   ->  Copy file to the server.  When you run the file the text document will be saved to the Admins desktop folder.
#   ->  Run from Admin PowerShell.  Future version will include the ability to run remotely.
#   ->  Command is '.\serverinfo2012.v1.2.ps1'
#
# If run in Powershell 2.0.  Get-Windows Feature wont run if ServerManager module is not loaded.
#  Import-Module ServerManager
  $OS = reg query "$prefix`HKLM\SOFTWARE\Microsoft\Windows nt\CurrentVersion"/v productname
  if ($OS[2] -like "*2016*"){$ServerOS = "2016"}
  if ($OS[2]-like "*2016*" -and $OS[2] -like "*R2*" ){$ServerOS = "2016R2"}#Into the future
  if ($OS[2] -like "*2012*" -and $OS[2] -notlike "*R2*"){$ServerOS = "2012"}
  if ($OS[2] -like "*2012*" -and $OS[2] -like "*R2*" ){$ServerOS = "2012R2"}
  if ($OS[2] -like "*2008*" -and $OS[2] -notlike "*R2*"){write-host -ForegroundColor Magenta  "$Servername - Unsupported OS $OS[2].";return}
  if ($OS[2] -like "*2008*" -and $OS[2] -like "*R2*" ){$ServerOS = "2008R2"}
  if ($OS[2] -like "*Windows 10*"){write-host  -ForegroundColor Magenta "$Servername - Unsupported OS `"Windows 10`"";return}
  If ($ServerOS -eq "2008R2") {import-module ServerManager}
# Change the working Directory
cd "$env:USERPROFILE\desktop"

# Variables for location and filename.
    $date = Get-Date -UFormat "%Y%m%d"
    $Outfile = ($env:COMPUTERNAME) + ".verification.$date.txt"
    $location = "$env:USERPROFILE\desktop"

# Category Title Variables to be input into script.
    $vBios = "
    ***** BIOS *****"
#   $vADLocation = "
#   ***** Active Directory Location *****"
    $vSysInfo = "
    ***** System Information *****"
    $vProcessorInfo = "
    ***** Processor Information *****"
    $vIpConfig = "
    ***** IP Configuration *****"
    $vServices = "
    ***** Services *****"
    $vSoftware = "
    ***** Installed Software *****"
    $vDrives = "
    ***** Drives *****"
    $vVolumes = "`
    ***** Volumes *****"
    $vShares = "
    ***** Shares *****"
    $vRaF = "
    ***** Installed Roles and Features *****"
    $vGPResult = "
    ***** GPResult *****"
    $vAuditpol = "
    ***** AuditPol *****
    "


# Output the file and join filename and location.
    Out-File -Append -FilePath (Join-Path $location $Outfile)

# Information to be added to the file that will be stored on the desktop of the Administrator.
# 1.  Date and Time script is run.
# 2.  Bios Info.
# 3.  Active Directory Location of Server Object
# 4.  System Information.
# 4a. Processor Information.
# 5.  IP Configuration Settings.
# 6.  Services (Current status of Services).
# 7.  Installed Applications.
# 8.  Drive Listing and Space Used/Available.
# 9.  Shares Listed
# 10.  Installed Features of the Server (What is the server used for?)
# 11.  GPResult (List of Group Policies applied to the server)
# 12.  Auditpol (Used in Remediation) 
# *****
cls
$SystemInfo =  SystemInfo
$BIOS = gwmi win32_bios
$Device =   WMIC CPU Get Caption
$DeviceID = WMIC CPU Get DeviceID
$Name = WMIC CPU Get Name
$NumberofCores = WMIC CPU Get NumberofCores
$NumberofLogicalProcessors = WMIC CPU Get NumberofLogicalProcessors
$Hostname = $Systeminfo[1]
$Hostname = $Hostname -replace ("Host Name:                 ", "")


Get-Date | Out-File "$Outfile"
"`r`n`r`nInformation for`:           $Hostname"| Out-File "$Outfile" -Append
$RegKeyTC = "HKLM:SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\"  
$RegKeyR = "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
$RegText = "DynamicSiteName"
$RegPath = test-path -path $RegKeyTC
if ($RegPath -eq $True) `
  {
    "Looking for : `"$RegText`"`r`n" | out-file -append  $OutFile
    $reg = reg query "$RegKeyR"
    $reg[1] | out-file -append  $OutFile
    for ($i = 0; $i -lt $reg.count; $i++) {if ($reg[$i] -like "*$RegText*"){$SiteName =  $reg[$i]}}
  }
$SiteName = $SiteName.Replace("    DynamicSiteName    REG_SZ    ", "")
"Site Name`:                 $SiteName"| Out-File "$Outfile" -Append

"Serial Number`:             " +  $BIOS.SerialNumber | Out-File "$Outfile"  -Append
for ($i = 1; $i -lt $Systeminfo.count; $i++){if ($Systeminfo[$i] -like  "Domain: *") {$Domain = $Systeminfo[$i] }}

$Domain = $Domain -replace ("Domain:                    ", ".")
$Systeminfo[1] + $Domain  | Out-File "$Outfile" -Append
for ($i = 1; $i -lt $Systeminfo.count; $i++){if ($Systeminfo[$i] -like "*IP address(es)*") {$Systeminfo[$i+1] | Out-File "$Outfile" -Append}}
$Systeminfo[2]  | Out-File "$Outfile" -Append  #Hostname
$Systeminfo[3]  | Out-File "$Outfile" -Append  #OS Version
$Systeminfo[5]  | Out-File "$Outfile" -Append  #OS Configuration
$Systeminfo[14] | Out-File "$Outfile" -Append  #System Type
$Systeminfo[15] | Out-File "$Outfile" -Append  #Processor(s)
"    " + $DeviceID[0] + "               " + $NumberofCores[0] + "        " + $NumberofLogicalProcessors[0] | Out-File "$Outfile" -Append
for ($i = 1; $i -lt $DeviceID.count; $i++)
{ 
    if ($DeviceID[$i] -ne "")
    {
       "    " +  $DeviceID[$i] + "               " + $NumberofCores[$i] + "        " + $NumberofLogicalProcessors[$i] | Out-File "$Outfile" -Append
    }
}
$Systeminfo[16] | Out-File "$Outfile" -Append
$Systeminfo[17] | Out-File "$Outfile" -Append  #BIOS Version
<#
$RegKeyTC = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"  
$RegKeyR = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegText = "LocalAccountTokenFilterPolicy"
$RegPath = test-path -path $RegKeyTC
if ($RegPath -eq $True) `
  {
    "Looking for : `"$RegText`"`r`n" | out-file -append  $OutFile
    $reg = reg query "$RegKeyR"
    $reg[1] | out-file -append  $OutFile
    for ($i = 0; $i -lt $reg.count; $i++) {if ($reg[$i] -like "*$RegText*"){$LATFP =  $reg[$i]}}
    "LATFP`:                 $LATFP"
  }
  #>
$Systeminfo[18] | Out-File "$Outfile" -Append  #Windows Directory
$Systeminfo[25] | Out-File "$Outfile" -Append  #Available Physical Memory
$Systeminfo[26] | Out-File "$Outfile" -Append  #Virtual Memory: Max Size:
$Systeminfo[27] | Out-File "$Outfile" -Append  #Virtual Memory: Available:
$Systeminfo[28] | Out-File "$Outfile" -Append  #Virtual Memory: In Use: 
$Systeminfo[29] | Out-File "$Outfile" -Append  #Page File Location(s): 

$myCount = 0
$Marker = $Null
for ($i = 31; $i -lt $Systeminfo.count; $i++) {if ($Systeminfo[$i] -like "*]: KB*") { $myCount++}}
$myCountRnd = ([System.Math]::Round($myCount / 2, 0)-1)
for ($i = 31; $i -lt $Systeminfo.count; $i++)`
  {
     if ($Systeminfo[$i]  -like "*]: KB*" -and $Systeminfo[$i + $myCountRnd]  -like "*]: KB*"  ) 
       {
        If ($Marker -eq $Null) {$Marker = $Systeminfo[$i + $myCountRnd]}
        If ($Marker -ne $Systeminfo[$i]) {        $Systeminfo[$i] + "       " + $Systeminfo[$i + $myCountRnd] | Out-File "$Outfile" -Append} 
        If ($Marker -eq $Systeminfo[$i]) {$i = $i + $myCountRnd -1}

      }
      elseif ($Systeminfo[$i]  -like "*]: KB*"){"                                                  " + $Systeminfo[$i] | Out-File "$Outfile" -Append }
      else {$Systeminfo[$i] | Out-File "$Outfile" -Append}
   }


$vIpConfig | Out-File "$Outfile" -Append
ipconfig /all >> "$Outfile";

$vServices | Out-File "$Outfile" -Append
get-service |sort status, displayname|ft status, displayname, name -autosize >> "$Outfile";

$vSoftware | Out-File "$Outfile" -Append
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Select-Object  Publisher, Displayname, InstallDate | 
sort publisher, Displayname |
Format-Table  -Autosize | Out-File "$Outfile" -Append

#   Drive Info
$vDrives | Out-File "$Outfile" -Append
Get-WmiObject Win32_logicaldisk -ComputerName  LocalHost `
| Format-Table DeviceID, MediaType, `
@{Name="Size(GB)";Expression={[decimal]("{0:N0}" -f($_.size/1gb))}}, `
@{Name="Free Space(GB)";Expression={[decimal]("{0:N0}" -f($_.freespace/1gb))}}, `
@{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}} `
-AutoSize | Out-File "$Outfile" -Append
$vVolumes | Out-File "$Outfile" -Append
Get-WmiObject -Class Win32_Volume | 
        Select DriveLetter,
            @{Label="FreeSpace (In GB)";Expression={$_.Freespace/1gb}},
            @{Label="Capacity (In GB)";Expression={$_.Capacity/1gb}},
            DeviceID,Label |sort-object -Property DriveLetter |
        Format-Table -AutoSize | Out-File "$Outfile" -Append



#   Gets server shares
$vShares | Out-File "$Outfile" -Append
Get-Wmiobject -class Win32_Share | Select-Object Name, Path, Description | Format-Table -Autosize >> "$Outfile";

#   Gets Windows Features and only shows Roles and Features that are installed.
#   Windows 2012 Version
$vRaF | Out-File "$Outfile" -Append

Get-WindowsFeature | Where {$_.'InstallState' -ne "Available"} >> "$Outfile"

#   Lists the Group Policies that are applied to the server.  
$vGPResult | Out-file "$Outfile" -Append
$GPR = GPResult.exe /r /scope computer
for ($i = 1; $i -lt $GPR.count; $i++) {if ($GPR[$i] -ne "" ) {$GPR[$i] >> "$Outfile" } }

#   Review current Audit policy configuration
$vAuditpol | Out-file "$Outfile" -Append
$Audit = AuditPol /get /category:* 
for ($i = 1; $i -lt $Audit.count; $i++) {if ($audit[$i] -ne "" ) {$audit[$i]>> "$Outfile" } }


"`r`n***** Local accounts on server ***** `r`n" | out-file -append  $Outfile

$ComputerName = $env:COMPUTERNAME
$Computer = $env:COMPUTERNAME
$Computer =  [ADSI]"WinNT://$Computer"
$Groups =  $Computer.psbase.Children | Where {$_.psbase.schemaClassName -eq "group"}
$AllLocalAccounts = Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" `
-Filter "LocalAccount='$True'" -ComputerName "localhost"  -ErrorAction Stop
Foreach($LocalAccount in $AllLocalAccounts)
  {
    
    "UserName = " + $LocalAccount.Name | out-file -append  $Outfile
    "     SID = " + $LocalAccount.SID | out-file -append  $Outfile
    "     PasswordExpires = " + $LocalAccount.PasswordExpires | out-file -append  $Outfile
    "     PasswordRequired = " + $LocalAccount.PasswordRequired | out-file -append  $Outfile
    "     AcctDisabled = " + $LocalAccount.Disabled | out-file -append  $Outfile
    $UserName = $LocalAccount.Name
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
    $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $ComputerName)
    $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($PrincipalContext, $UserName)
    "     PasswordLastSet = " +  $User.LastPasswordSet | out-file -append  $Outfile
    ForEach ($Group In $Groups)
      {
        $Members  = @($Group.psbase.Invoke("Members"))
        ForEach ($Member In $Members)
        {
           $Class = $Member.GetType().InvokeMember("Class", 'GetProperty', $Null, $Member, $Null)
           $Name = $Member.GetType().InvokeMember("Name", 'GetProperty', $Null, $Member, $Null)
           if ($UserName -like  "*$Name*")   {"     Group: "  + $Group.Name +   "-- Member: $Name ($Class)" | out-file -append  $Outfile}

         }

     }
" "| out-file -append  $Outfile
  }

  "***** `Members of Administrators group ***** " | out-file -append  $Outfile
$group =[ADSI]"WinNT://$env:COMPUTERNAME/Administrators" 
@($group.psbase.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) } | out-file -append  $Outfile


"`r`n***** Members of Backup Operators group (should be none) ***** " | out-file -append  $Outfile
$group =[ADSI]"WinNT://$env:COMPUTERNAME/Backup Operators" 
@($group.psbase.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }  | out-file -append  $Outfile
if (@($group.psbase.Invoke("Members"))[0] -eq $Null) {"no accounts are members of the Backup Operators group" | out-file -append  $Outfile}


"`r`n***** Members of Event Log Readers group ***** " | out-file -append  $Outfile
$group =[ADSI]"WinNT://$env:COMPUTERNAME/Event Log Readers" 
@($group.psbase.Invoke("Members")) | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) | out-file -append  $Outfile } 
if (@($group.psbase.Invoke("Members"))[0] -eq $Null) {"no accounts are members of the Event Log Readers group" | out-file -append  $Outfile}

"`r`n***** Printer status. There should be no printers installed, except XPS one ***** "| out-file -append  $Outfile
$Spooler = Get-Service Spooler
if ($Spooler.Status -eq "Stopped") {If ($Spooler.StartType -eq "Disabled") {"Spooler Service Is Disabled" | out-file -append  $Outfile}}
Else { Start-Service -name Spooler}
if ($Spooler.Status -eq "Running") {get-WmiObject -class Win32_printer | ft name, systemName, shareName | out-file -append  $Outfile}

"`r`n***** Firewall status.***** "| out-file -append  $Outfile
$NetProf = get-NetFirewallProfile 
for ($i = 0; $i -lt$NetProf.count; $i++){$msg = $Netprof[$i].name + "enabled = " + $Netprof[$i].enabled;  $msg| out-file -append  $Outfile}

"`r`n***** Activation Status, LicenseStatus of 1 means activated.***** "| out-file -append  $Outfile
Get-CimInstance SoftwareLicensingProduct -ComputerName $env:computername |where licensestatus -eq 1  |Select PSComputername, LicenseStatus|FT -AutoSize| out-file -append  $Outfile

"`r`n***** Timezone Setting***** "| out-file -append  $Outfile
TZUTIL /g | out-file -append  $Outfile

"`r`n***** IPv6 Status***** "| out-file -append  $Outfile
$IPV6 = $false
$arrInterfaces = (Get-WmiObject -class Win32_NetworkAdapterConfiguration -filter "ipenabled = TRUE").IPAddress
foreach ($i in $arrInterfaces) 
{ $IPV6 = $IPV6 -or $i.contains(":")
"$i  IPv6 =   $IPV6" | out-file -append  $Outfile
}
netsh interface ipv6 show interfaces | out-file -append  $Outfile

route print | out-file -append  $Outfile
#   End
