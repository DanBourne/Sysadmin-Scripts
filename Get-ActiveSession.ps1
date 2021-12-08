function Get-ActiveSession {
    <#
    .SYNOPSIS
    Return the currently logged in user for a remote or local machine.
    Uses CIMSession for speed purposes on local sessions, otherwise define -RemoteSession.

    .PARAMETER ComputerName
    Provide a remote computer name. 

    .PARAMETER Name
    Same as ComputerName. Alias is being used to allow piping of (Get-ADComputer).Name property to function.

    .PARAMETER RemoteSession
    Use to specify remote RDP sessions.

    .EXAMPLE
    #Get the active session on the local host.
    Get-ActiveSession -ComputerName localhost

    .EXAMPLE
    #Get the active remote session on Server1.
    Get-ActiveSession -Computername Server1 -RemoteSession
    
    .EXAMPLE
    #Return all AD computers and pipe to retrieve all locally logged on users of these machines.
    Get-ADComputer -Filter * | Get-ActiveSession

    #>
    [CmdletBinding()]
    param (
        
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [Alias('ComputerName')]
        [string[]]$Name,

        [switch]$RemoteSession
    )

    BEGIN {
        $LoggedonUser = @()
    }

    PROCESS {
        foreach ($Computer in $Name) {
    
            if ($RemoteSession) {
                try {

                    $User = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { [System.Security.Principal.WindowsIdentity]::GetCurrent().Name }
                    $Properties = @{'ComputerName' = $Name
                                    'Username' = $User.split("\")[0]
                    }#try
                }
                catch [System.Exception] {
                    Write-Warning "No remote sessions found"
                    break
                }#catch [System.Exception]
                catch{
                    $Error[0].Exception
                }#catch all



            }#if ($RemoteSession)
            else {

                try {
                    $SessionOption = New-CimSessionOption -Protocol Wsman
                    New-CimSession -ComputerName $Computer -SessionOption $SessionOption -ErrorAction Stop | Out-Null
                }#try
                catch [Microsoft.Management.Infrastructure.CimException] {
                    $SessionOption = New-CimSessionOption -Protocol Dcom
                    New-CimSession -ComputerName $Computer -SessionOption $SessionOption -ErrorAction Stop | Out-Null
                }#catch [Microsoft.Management.Infrastructure.CimException]
                catch {
                    $Error[0].Exception
                }#catch all

                $User = Get-CimInstance -ComputerName $Computer -ClassName Win32_ComputerSystem | Select-Object Username

                #if ($null -eq $User.Username)
                #>
                if ($null -eq $User.Username -or $Computer) {
                    Write-Warning "No user found, if the user is connected via remote session try using the -Remotesession switch"

                    break

                }#if ($null -eq $User.Username -or $Computer)
            }#else



        $LoggedonUser += New-Object -TypeName psobject -Property @{'ComputerName' = $Computer;
                                                                    'DOMAIN\Username' = $User}
                                                                    
        }#foreach ($Computer in $Name)

        
            
    }#Process

    END {Write-Output $LoggedonUser}
}#function Get-ActiveSession


