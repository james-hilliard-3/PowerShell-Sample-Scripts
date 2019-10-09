<#
Script to ping and report on computers.
Data reported: ComputerName, IPAddress, MACAddress, DateBuilt, OSVersion, Model, and LastBootTime
Requires list of computers in text file
Sam Boutros - 10/31/2014 - v1.0
#>
$ComputerList = ".\computerlist.txt"
$CSVFile = ".\Ping-Report-$(Get-Date -format yyyyMMdd_hhmmsstt).csv"
$LogFile = ".\Ping-Report-$(Get-Date -format yyyyMMdd_hhmmsstt).txt"
# End Data Entry

function Log {
<# 
 .Synopsis
  Function to log input string to file and display it to screen

 .Description
  Function to log input string to file and display it to screen. Log entries in the log file are time stamped. Function allows for displaying text to screen in different colors.

 .Parameter String
  The string to be displayed to the screen and saved to the log file

 .Parameter Color
  The color in which to display the input string on the screen
  Default is White
  Valid options are
    Black
    Blue
    Cyan
    DarkBlue
    DarkCyan
    DarkGray
    DarkGreen
    DarkMagenta
    DarkRed
    DarkYellow
    Gray
    Green
    Magenta
    Red
    White
    Yellow

 .Parameter LogFile
  Path to the file where the input string should be saved.
  Example: c:\log.txt
  If absent, the input string will be displayed to the screen only and not saved to log file

 .Example
  Log -String "Hello World" -Color Yellow -LogFile c:\log.txt
  This example displays the "Hello World" string to the console in yellow, and adds it as a new line to the file c:\log.txt
  If c:\log.txt does not exist it will be created.
  Log entries in the log file are time stamped. Sample output:
    2014.08.06 06:52:17 AM: Hello World

 .Example
  Log "$((Get-Location).Path)" Cyan
  This example displays current path in Cyan, and does not log the displayed text to log file.

 .Example 
  "Java process ID is $((Get-Process -Name java).id )" | log -color Yellow
  Sample output of this example:
    "Java process ID is 4492" in yellow

 .Example
  "Drive 'd' on VM 'CM01' is on VHDX file '$((Get-SBVHD CM01 d).VHDPath)'" | log -color Green -LogFile D:\Sandbox\Serverlog.txt
  Sample output of this example:
    Drive 'd' on VM 'CM01' is on VHDX file 'D:\VMs\Virtual Hard Disks\CM01_D1.VHDX'
  and the same is logged to file D:\Sandbox\Serverlog.txt as in:
    2014.08.06 07:28:59 AM: Drive 'd' on VM 'CM01' is on VHDX file 'D:\VMs\Virtual Hard Disks\CM01_D1.VHDX'

 .Link
  https://superwidgets.wordpress.com/category/powershell/

 .Notes
  Function by Sam Boutros
  v1.0 - 08/06/2014

#>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [String]$String, 
        [Parameter(Mandatory=$false,
                   Position=1)]
            [ValidateSet("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
            [String]$Color = "White", 
        [Parameter(Mandatory=$false,
                   Position=2)]
            [String]$LogFile
    )

    write-host $String -foregroundcolor $Color 
    if ($LogFile.Length -gt 2) {
        ((Get-Date -format "yyyy.MM.dd hh:mm:ss tt") + ": " + $String) | out-file -Filepath $Logfile -append
    } else {
        Write-Verbose "Log: Missing -LogFile parameter. Will not save input string to log file.."
    }
}

$PCData = @()
if (Test-Path -Path $ComputerList) {
    foreach ($PC in (Get-Content -Path $ComputerList)) {
        try {
            Test-Connection -ComputerName $PC -Count 2 -ErrorAction Stop | Out-Null
            log "Computer $PC is online" Green $LogFile
            foreach ($IPAddress in ((Get-WmiObject -ComputerName $PC -Class "Win32_NetworkAdapterConfiguration" | 
                Where { $_.IpEnabled -Match "True" }).IPAddress | where { $_ -match "\." })) {
                $Props = [ordered]@{
                    ComputerName = $PC;
                    IPAddress = $IPAddress;
                    MACAddress = (Get-WmiObject -ComputerName $PC -Class "Win32_NetworkAdapterConfiguration" | 
                        Where { $_.IPAddress -eq $IPAddress }).MACAddress;
                    DateBuilt = ([WMI]'').ConvertToDateTime((Get-WmiObject -ComputerName $PC -Class Win32_OperatingSystem).InstallDate);
                    OSVersion = (Get-CimInstance -ComputerName $PC -Class Win32_OperatingSystem).Version;
                    Model = (Get-WmiObject -ComputerName $PC -Class Win32_Computersystem).model;
                    LastBootTime = (Get-CimInstance -ComputerName $PC -ClassName win32_operatingsystem).LastBootUpTime
                }
                $PCData += New-Object -TypeName psobject -Property $Props
            }
        } catch {
            log "Computer $PC is offline or cannot be contacted" Yellow $LogFile
        }
    }
} else {
    log "File $ComputerList not found" Yellow $LogFile
}

$PCData | Sort ComputerName | FT -AutoSize
$PCData | Sort ComputerName | Out-GridView
$PCData | Sort ComputerName | Export-Csv -Path $CSVFile -NoTypeInformation