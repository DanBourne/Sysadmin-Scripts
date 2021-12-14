function New-MerakiRADIUSADUser {
    <#
.SYNOPSIS
This is intended for use with the Meraki MAC-Based RADIUS authentication process.
https://documentation.meraki.com/MS/Access_Control/Configuring_Microsoft_NPS_for_MAC-Based_RADIUS_-_MS_Switches

It will create one or more user accounts using MAC Addresses and add them to your domain. 
A PSO will be required in order to perform this, as a MAC address is used as the password for these
account outlined in the documentation, and this should go against your password policy.

Before using this, please make sure you have;
PSO applied to a group used ONLY for these accounts. 
OU for containing only these accounts.

You can feed multiple MAC addresses in from a CSV file, see examples.

.PARAMETER MACAddress
Provide a MAC Address, with or without seperating ':' or '-'. The function will remove them if they are present.

.PARAMETER Name
Name of the device that you wish to add to identify it in AD.

.PARAMETER EmailSuffix
Provide an email suffix, without the @. e.g. gmail.com

Using this depends on whether your domain requires it or not. I have left it non-mandatory.

.PARAMETER Path
Path to the OU used for RADIUS clients. Provide this within "" e.g. ""

.INPUTS
Import-CSV

.EXAMPLE
New-MerakiRADIUSADUser -Name TestDevice -MACAddress 00:00:00:00:00:00:00:00 -EmailSuffix test.com -Path "OU=Test,DC=Company,DC=pri" -Group RADIUS

.EXAMPLE
Import-CSV C:\Temp\MAC.csv | New-MerakiRADIUSADUser -Verbose

.LINK
https://documentation.meraki.com/MS/Access_Control/Configuring_Microsoft_NPS_for_MAC-Based_RADIUS_-_MS_Switches
#>
[CMDLetBinding()]
param
(
    [parameter(Mandatory = $True, 
                ValueFromPipelineByPropertyName = $True)]
    [string]$MACAddress,

    [parameter(Mandatory = $True,
                ValueFromPipelineByPropertyName = $True)]
    [string]$Name,

    [parameter(ValueFromPipelineByPropertyName = $True)]
    [string]$EmailSuffix,

    [parameter(Mandatory = $True, 
                ValueFromPipelineByPropertyName = $True)]
    [string]$Path,

    [parameter(ValueFromPipelineByPropertyName = $True)]
    [string]$Group
        
)#param
#Initialise array for later use to build custom object
Begin {$MACUserResult = @()}

Process {

    Foreach ($MAC in $MACAddress) {
        #Generate a random password that will conform most enterprise domains password policies (20 char length,at least 5 non-alphanumeric characters).
        Add-Type -Assembly System.Web
        $PasswordString = [Web.Security.Membership]::GeneratePassword(20, 5)
        [SecureString]$PasswordStringSecure = ConvertTo-SecureString $PasswordString -AsPlainText -force

        #Remove any instances of ':' or '-' in MAC Address
        $TrimmedMACAddress = $MACAddress.Replace(':', '').Replace('-', '')

        $userProps = @{
            Name              = $Name
            GivenName         = $Name
            SamAccountName    = $TrimmedMACAddress
            UserPrincipalName = ($TrimmedMACAddress + '@' + $EmailSuffix)
            AccountPassword   = $PasswordStringSecure
        }#$userProps = @{
        Write-Verbose "Creating user $TrimmedMACAddress"
        
        #Handle preexisting users or fall to catch all for any other exceptions
        try {
            New-ADUser @userprops -Path $Path -Enabled $True -Verbose -ErrorAction Stop
        }#try
        catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
            Write-Warning "User $TrimmedMACAddress already exists"
            break
        }#catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] 
        catch {
            $Error[0]
            break
        }#catch all

        #Add user to group with PSO applied
        Add-ADGroupMember -Identity $Group -Members $TrimmedMACAddress
        #Apply MAC address as password
        $Password = $TrimmedMACAddress | ConvertTo-SecureString -AsPlainText -Force -Verbose
        
        #Check the user exists before attempting to apply the password. 
        #Subsequent command errored sporadically so this gives it a second to recognise the user in AD. 
        do {
            $UserCheck = Get-ADUser -SearchBase $Path -Filter "Name -eq '$Name'"
            Start-Sleep 1
        }#do 
        until ($null -ne $UserCheck)
        Write-Verbose "Setting new password"
        Get-ADUser $TrimmedMACAddress | Set-ADAccountPassword -Reset -NewPassword $Password -Verbose
        
        #Add Result to custom object for visual output
        $MACUserResult += New-Object -TypeName psobject -Property @{
            Name           = $UserCheck.Name
            SamAccountName = $UserCheck.SamAccountName
            MemberOf       = $Group
        }#$MACUserResult += New-Object
    }#Foreach ($MAC in $MACAddress)
}#Process
  

END { Write-Output $MACUserResult }
}#function New-MerakiRADIUSADUser