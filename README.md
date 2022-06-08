# YetAnotherCMLogger PowerShell module

Another module that writes a log in cmtrace format but with an output

## Prerequisites

No prerequisites are need, however having the cmtrace.exe is useful to read log output


## Cmdlets
- **Get-YaCMLogFileName** --> Grabs current log file
- **Set-YaCMLogFileName** --> Sets a log file (defaults to name of script calling the cmdlet)
- **Restore-YaCMLogFileName** --> restores to original log name and path
- **Write-YaCMLogEntry** --> Write a log entry in CMtrace compatible format

## Install

```powershell
Install-Module YetAnotherCMLogger -Force
Import-Module YetAnotherCMLogger
```

## Examples

```powershell
#build global log fullpath
$Global:LogFilePath = "$env:Windir\Logs\Mylogfile_$(Get-Date -Format 'yyyy-MM-dd').log"
#or set path by just calling (this will use the name)
Set-YaCMLogFileName
Write-YaCMLogEntry -Message 'this is a new message' -Severity 1 -Passthru


Function Test-output{
    ${CmdletName} = $MyInvocation.InvocationName
    Write-YaCMLogEntry -Message ('this is a new message from [{0}]' -f $MyInvocation.InvocationName) -Source ${CmdletName} -Severity 0 -Passthru
}
Test-output

#Create entry in log with warning message and output to host in yellow
Write-YaCMLogEntry -Message 'this is a log entry from an warning' -Severity 2 -Passthru

#Create entry in log with error and output to host in red
Write-YaCMLogEntry -Message 'this is a log entry from an error' -Severity 3 -Passthru

#restore path (eg. c:\windows\logs\YetAnotherCMLogger_2022-06-05_T02-01-47-PM.log)
Restore-YaCMLogFileName
Write-YaCMLogEntry -Message 'this is a log entry from success' -Severity 1  -Passthru

#Set path to c:\ with no appendix to log. (eg. c:\Logs\MyPoshScript.log).
Set-YaCMLogFileName -ParentPath c:\Logs -CallerName 'MyPoshScript' -Appendix ''

#Retrieve current log path
Get-YaCMLogFileName

```
