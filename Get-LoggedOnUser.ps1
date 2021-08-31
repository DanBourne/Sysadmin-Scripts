function Get-LoggedOnUser {
    <#

    .SYNOPSIS
    Return the currently logged in user for a remote or local machine.

    .PARAMETER ComputerName
    Provide a remote computer name. 
    
    
    .EXAMPLE
    Get-LoggedOnUser

    .EXAMPLE
    Get-LoggedonUser -Computername Server1

    #>
    param (
    [parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]$ComputerName
    )


    If ($ComputerName -eq $Null) {

        $LoggedOnUser = (Get-Process -Name explorer -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -ne $null } | Sort-Object UserName -Unique)

}#If ($ComputerName -eq $Null) close
    else {

        $LoggedOnUser = (Invoke-Command -ComputerName $ComputerName -ScriptBlock { Get-Process -Name explorer -IncludeUserName | Select-Object UserName,SessionId | Where-Object { $_.UserName -ne $null } | Sort-Object UserName -Unique})
      
}#else close

    return $LoggedOnUser
}#Get-LoggedOnUser close