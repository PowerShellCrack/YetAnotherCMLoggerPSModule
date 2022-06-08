

#region FUNCTION: Check if running in ISE
Function Test-IsISE {
    # trycatch accounts for:
    # Set-StrictMode -Version latest
    try {
        return ($null -ne $psISE);
    }
    catch {
        return $false;
    }
}
#endregion

#region FUNCTION: Check if running in Visual Studio Code
Function Test-VSCode{
    if($env:TERM_PROGRAM -eq 'vscode') {
        return $true;
    }
    Else{
        return $false;
    }
}
#endregion

#region FUNCTION: Find script path for either ISE or console
Function Get-ScriptPath {
    <#
        .SYNOPSIS
            Finds the current script path even in ISE or VSC
        .LINK
            Test-VSCode
            Test-IsISE
    #>
    param(
        [switch]$Parent
    )

    Begin{}
    Process{
        Try{
            if ($PSScriptRoot -eq "")
            {
                if (Test-IsISE)
                {
                    $ScriptPath = $psISE.CurrentFile.FullPath
                }
                elseif(Test-VSCode){
                    $context = $psEditor.GetEditorContext()
                    $ScriptPath = $context.CurrentFile.Path
                }Else{
                    $ScriptPath = (Get-location).Path
                }
            }
            else
            {
                $ScriptPath = $PSCommandPath
            }
        }
        Catch{
            $ScriptPath = '.'
        }
    }
    End{

        If($Parent){
            Split-Path $ScriptPath -Parent
        }Else{
            $ScriptPath
        }
    }

}
#endregion


Function Restore-YaCMLogFileName {
    <#
    .SYNOPSIS
        Gets current log path
    .DESCRIPTION
       Gets current log path from global variable: $Global:LogFilePath
    #>
    # Use function to get paths because Powershell ISE & other editors have differnt results
    $scriptPath = Get-ScriptPath
    [string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
    #specify path of log
    $Global:LogFilePath = "$env:Windir\Logs\$($scriptName)_$(Get-Date -Format 'yyyy-MM-dd_Thh-mm-ss-tt').log"
    Return $Global:LogFilePath
}


Function Set-YaCMLogFileName {
    <#
    .SYNOPSIS
       Sets a log file path and name

    .DESCRIPTION
       Sets a log file path and name for Write-YaCMLogEntry to use
       Sets a global variable: $Global:LogFilePath

    .PARAMETER ParentPath
        Defaults to the $env:Windir\Logs

    .PARAMETER CallerName
        Overwrites the script name as caller. Useful when Intune generates file using a random caller file name.

    .PARAMETER Appendix
        Defaults to the (Get-Date -Format 'yyyy-MM-dd_Thh-mm-ss-tt')

    .PARAMETER Passthru
        Output new log path. This DOES NOT update Write-YaCMLogEntry OutputLogFile location

    .EXAMPLE
        Set-YaCMLogFileName

    .EXAMPLE
        Set-YaCMLogFileName -ParentPath c:\Logs

    .EXAMPLE
        Set-YaCMLogFileName -ParentPath c:\Windows\Logs -CallerName 'MyPoshScript' -Appendix ''

    .EXAMPLE
        Set-YaCMLogFileName -ParentPath c:\Logs -Appendix ''

    .EXAMPLE
        Set-YaCMLogFileName -Passthru
    #>
    Param(
        [Parameter(Mandatory=$false)]
        [string]$ParentPath = "$env:Windir\Logs",

        [Parameter(Mandatory=$false)]
        [string]$CallerName,

        [Parameter(Mandatory=$false)]
        [string]$Appendix = (Get-Date -Format 'yyyy-MM-dd_Thh-mm-ss-tt'),

        [switch]$Passthru
    )

    #Overwrite name with specified caller name
    If($CallerName){
        [string]$scriptName = $CallerName
    }
    Else{
        # Attempt to get path from PScommandpath (only works when called within script)
        $scriptPath = Try{Split-Path $MyInvocation.PSCommandPath -Leaf}Catch{Get-ScriptPath}
        [string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
    }

    #tes path of parent location
    If(Test-Path $ParentPath)
    {
        #build path
        If($Appendix){$AddAppendix= "_$($Appendix).log"}Else{$AddAppendix= ".log"}
        $NewLogFilePath = Join-Path $ParentPath -ChildPath ($scriptName + $AddAppendix)

        If($Passthru){
            Return $NewLogFilePath
        }
        Else{
            $Global:LogFilePath = $NewLogFilePath
        }
    }
    Else{
        Write-Error ("Path does not exist [{0}]. Create path or specify a new one!" -f $ParentPath)
    }
}

Function Get-YaCMLogFileName{
    <#
    .SYNOPSIS
        Gets current log path
    .DESCRIPTION
       Gets current log path from global variable: $Global:LogFilePath
    #>
    Return $Global:LogFilePath
}

Function Write-YaCMLogEntry{
    <#
    .SYNOPSIS
        Creates a log file

    .DESCRIPTION
       Creates a log file format for cmtrace log reader

    .NOTES
        Allows to view log using cmtrace while being written to

    .PARAMETER Message
        Write message to log file

    .PARAMETER Source
        Defaults to the script running or another function that calls this function.
        Used to specify a different source if specified

    .PARAMETER Severity
        Ranges 1-5. CMtrace will highlight severity 2 as yellow and 3 as red.
        If Passthru parameter used will change host output:
        0 = Green
        1 = Gray
        2 = Yellow
        3 = Red
        4 = Verbose Output
        5 = Debug output

    .PARAMETER OutputLogFile
        Defaults to $Global:LogFilePath. Specify location of log file.

    .PARAMETER Passthru
        Output message to host as well. Great when replacing Write-Host with Write-YaCMLogEntry

    .EXAMPLE
        #build global log fullpath
        $Global:LogFilePath = "$env:Windir\Logs\$($scriptName)_$(Get-Date -Format 'yyyy-MM-dd_Thh-mm-ss-tt').log"
        Write-YaCMLogEntry -Message 'this is a new message' -Severity 1 -Passthru

    .EXAMPLE
        Function Test-output{
            ${CmdletName} = $MyInvocation.InvocationName
            Write-YaCMLogEntry -Message ('this is a new message from [{0}]' -f $MyInvocation.InvocationName) -Source ${CmdletName} -Severity 0 -Passthru
        }
        Test-output

        OUTPUT is in green:
        [21:07:50.476-300] [Test-output] :: this is a new message from [Test-output]

    .EXAMPLE
        Create entry in log with warning message and output to host in yellow
        Write-YaCMLogEntry -Message 'this is a log entry from an error' -Severity 2 -Passthru

    .EXAMPLE
        Create entry in log with error and output to host in red
        Write-YaCMLogEntry -Message 'this is a log entry from an error' -Severity 3 -Passthru

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory=$false,Position=2)]
		[string]$Source,

        [parameter(Mandatory=$false,Position=3)]
        [ValidateSet(0,1,2,3,4,5)]
        [int16]$Severity,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$OutputLogFile = $Global:LogFilePath,

        [parameter(Mandatory=$false)]
        [switch]$Passthru
    )
    Begin{
        #get BIAS time
        [string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
        [string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
        [int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
        [string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias

        #  Get the file name of the source script
        If($Source){
            [string]$ScriptSource = $Source
        }
        Else{
            Try {
                If($MyInvocation.InvocationName){
                    [string]$ScriptSource = $MyInvocation.InvocationName
                }
                ElseIf ($script:MyInvocation.Value.ScriptName) {
                    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
                }
                Else {
                    [string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
                }
            }
            Catch {
                [string]$ScriptSource = ''
            }
        }

        #if -Verbose or -Debug is used, set appropriate log severity and prefix log, then reset preference.
        If( ($Severity -eq 4) -or $VerbosePreference){$Message='VERBOSE: ' + $Message;$VerbosePreference = 'Continue'}
        If( ($Severity -eq 5) -or $DebugPreference){$Message='DEBUG: ' + $Message;$DebugPreference = 'Continue'}
    }
    Process{
        #generate CMTrace log format
        $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="{7}">'
        $LineFormat = $Message, $LogTimePlusBias, $LogDate, $ScriptSource, $([Security.Principal.WindowsIdentity]::GetCurrent().Name),$Severity,$PID,$ScriptSource
        $LogFormat = $Line -f $LineFormat

        #when using pipeline, verbose mode output is not a string; the output needs to be encoded into utf8 then decoded into a string
        #eg. Get-Childitem $_ -Verbose 4>&1 | Write-YaCMLogEntry -Passthru
        $enc = [System.Text.Encoding]::UTF8
        $LogFormatEncoded = $enc.GetBytes($LogFormat)
        $LogFormatDecoded = [System.Text.Encoding]::UTF8.GetString($LogFormatEncoded)

        try {
            $LogFormatDecoded | Out-File -Append -NoClobber -Encoding UTF8 -FilePath $OutputLogFile -ErrorAction Stop
        }
        catch {
            Write-Error ("[{0}] [{1}] :: Unable to append log entry to [{2}], error: {3}" -f $LogTimePlusBias,$ScriptSource,$OutputLogFile,$_.Exception.ErrorMessage)
        }

        #output the message to host
        If($Passthru)
        {
            If($Source){
                $OutputMsg = ("[{0}] [{1}] :: {2}" -f $LogTimePlusBias,$Source,$Message)
            }
            Else{
                $OutputMsg = ("[{0}] [{1}] :: {2}" -f $LogTimePlusBias,$ScriptSource,$Message)
            }

            Switch($Severity){
                0       {Write-Host $OutputMsg -ForegroundColor Green}
                1       {Write-Host $OutputMsg -ForegroundColor White}
                2       {Write-Host $OutputMsg -ForegroundColor Yellow}
                3       {Write-Host $OutputMsg -ForegroundColor Red}
                4       {Write-Host $OutputMsg -ForegroundColor Yellow}
                5       {Write-Host $OutputMsg -ForegroundColor Yellow}
                default {Write-Host $OutputMsg}
            }
        }
    }
}

Restore-YaCMLogFileName

$exportModuleMemberParams = @{
    Function = @(
        'Get-YaCMLogFileName',
        'Set-YaCMLogFileName',
        'Restore-YaCMLogFileName',
        'Write-YaCMLogEntry'
    )
}

Export-ModuleMember @exportModuleMemberParams
