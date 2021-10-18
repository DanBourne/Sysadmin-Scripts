function Get-ExchangeOnlineMobileDevices{
    param
    (
        


Connect-ExchangeOnline
#Variables
$CSV = "C:\temp\MobileDevices.csv"
$Result = @()
$UserMailbox = Get-Mailbox -Resultsize unlimited
$MobileDevice = @()

#Loop through each user mailbox
foreach($User in $UserMailbox)
{
$UPN = $User.UserPrincipalName
$DisplayName = $User.DisplayName
#Get Mobiles of users
$MobileDevices = Get-MobileDevice -Mailbox $UPN
      #Loop through each users mobile devices
      foreach($MobileDevice in $MobileDevices)
      {
          Write-Output "Getting info about a device for $displayName"
          $Properties = @{
          Name = $User.name
          UPN = $UPN
          DisplayName = $DisplayName
          FriendlyName = $MobileDevice.FriendlyName
          ClientType = $MobileDevice.ClientType
          ClientVersion = $MobileDevice.ClientVersion
          DeviceId = $MobileDevice.DeviceId
          DeviceMobileOperator = $MobileDevice.DeviceMobileOperator
          DeviceModel = $MobileDevice.DeviceModel
          DeviceOS = $MobileDevice.DeviceOS
          DeviceTelephoneNumber = $MobileDevice.DeviceTelephoneNumber
          DeviceType = $MobileDevice.DeviceType
          FirstSyncTime = $MobileDevice.FirstSyncTime
          UserDisplayName = $MobileDevice.UserDisplayName
          }
          $Result += New-Object PSObject -Property $Properties
      }#foreach($MobileDevice in $MobileDevices) close
}#foreach($User in $UserMailbox) close
 
$Result | Select-Object Name,UPN,FriendlyName,DisplayName,ClientType,ClientVersion,DeviceId,DeviceMobileOperator,DeviceModel,DeviceOS,DeviceType | Export-Csv -NoTypeInformation -Path $csv

}#function close
Disconnect-ExchangeOnline