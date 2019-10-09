$wshell = New-Object -ComObject Wscript.Shell

$wshell.Popup("If you see this then the Bypass works",0,"Test Pop-up",0x1)