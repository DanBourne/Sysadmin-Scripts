function Set-ServiceLogon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [string]$ServiceName,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [string]$NewPassword,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [string]$NewUser,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [string]$Computername,
        [string]$ErrorLogFilePath
    )

    foreach ($Computer in $ComputerName) {

        $Option = New-CimSessionOption -Protocol Wsman
        $Session = New-CimSession -SessionOption $option -ComputerName $Computer

        if ($PSBoundParameters.ContainsKey('NewUser')) {
            $args = @{'StartName' = $NewUser;
                'StartPassword'   = $NewPassword
            }
        }
        else {
            $args = @{'StartPassword' = $NewPassword }
        }

        $params = @{'CimSession' = $Session
            'Methodname'         = 'Change'
            'Query'              = "SELECT * FROM Win32_Service WHERE Name = '$ServiceName'"
            'Arguments'          = $args
        }

        $Return = Invoke-CimMethod @params

        switch ($Return.ReturnValue) {
            0 { $Status = "Success" }
            22 { $Status = "Invalid Account Name" }
            Default { $Status = "Failed: $($Return.ReturnValue)" }
        }

        $props = @{'ComputerName' = $Computer
            'Status'              = $Status
        }
        $obj = New-Object -TypeName psobject -Property $props

        Write-Output $obj

        $Session | Remove-CimSession

    }
}#foreach
#function
