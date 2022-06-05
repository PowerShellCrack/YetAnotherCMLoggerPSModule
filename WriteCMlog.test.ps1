Import-Module .\YetAnotherCMLogger\YetAnotherCMLogger.psm1 -Force
Restore-YaCMLogFileName
Set-YaCMLogFileName
Get-YaCMLogFileName

Function Test-output{
    ${CmdletName} = $MyInvocation.InvocationName
    Write-YaCMLogEntry -Message ('this is a new message from [{0}]' -f $MyInvocation.InvocationName) -Source ${CmdletName} -Severity 0 -Passthru
}


Test-output
