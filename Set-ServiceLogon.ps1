function Set-ServiceLogon {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ServiceName,
        [securestring]$NewPassword,
        [string]$NewUser,
        [string]$Computername,
        [string]$ErrorLogFilePath
    )

    Invoke-Command -ComputerName $Computername -ScriptBlock {Set-CimInstance Win32_Service }



foreach ($Computer in $ComputerName){
    $Option = New-CimSessionOption -Protocol Wsman
    $Session = New-CimSession -SessionOption $option -ComputerName $Computer

    if ($PSBoundParameters.ContainsKey('NewUser')){
        $args = @{'StartName'=$NewUser;
                    'StartPassword'=$NewPassword}
    else {
        $args = @{'StartPassword'=$NewPassword}
    }
    Invoke-CimMethod -ComputerName $ComputerName -MethodName Change -Query "SELECT * FROM Win32_Service WHERE Name = $ServiceName" -Arguments $args |
        Select-Object -Property @{n='ComputerName';e={$Computer}},
                                @{n='Result';e='$_.ReturnValue'}}

    $Session | Remove-CimSession

    }#foreach
}#function