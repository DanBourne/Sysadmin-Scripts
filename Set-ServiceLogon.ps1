function Set-ServiceLogon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$ServiceName,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]$NewPassword,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [string]$NewUser,

        [Parameter(Mandatory = $True, 
            ValueFromPipeline = $True)]
        [string]$Computername,

        [string]$ErrorLogFilePath
    )

    foreach ($Computer in $ComputerName) {

        $Option = New-CimSessionOption -Protocol Wsman
        $Session = New-CimSession -SessionOption $option -ComputerName $Computer

        if ($PSBoundParameters.ContainsKey('NewUser')) {
            $serviceargs = @{
                'StartName'     = $NewUser;
                'StartPassword' = $NewPassword
            }#args
        }#if ($PSBoundParameters.ContainsKey('NewUser'))
        else {
            $serviceargs = @{'StartPassword' = $NewPassword }
        }#else

        $params = @{'CimSession' = $Session
            'Methodname'         = 'Change'
            'Query'              = "SELECT * FROM Win32_Service WHERE Name = '$ServiceName'"
            'Arguments'          = $serviceargs
        }#$params

        $Return = Invoke-CimMethod @params

        switch ($Return.ReturnValue) {
            0 { $Status = "Success" }
            22 { $Status = "Invalid Account Name" }
            Default { $Status = "Failed: $($Return.ReturnValue)" }
        }#switch

        $props = @{
            'ComputerName' = $Computer
            'Status'       = $Status
        }#$props
        $ServiceResult = New-Object -TypeName psobject -Property $props

        Write-Output $ServiceResult

        $Session | Remove-CimSession

    }
}#foreach
#function
