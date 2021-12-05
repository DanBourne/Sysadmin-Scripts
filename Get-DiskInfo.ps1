#TOADD

function Get-DCDiskInfo
{

    $ADForest = (Get-ADForest).Domains
    
     foreach ($Domain in ((Get-ADForest).Domains)){

        $Hosts = Get-ADDomainController -Filter * -Server $Domain | Sort-Object -Property Hostname

            foreach($DCHost in $Hosts){

                try
                {
                    $CS = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $DCHost -ErrorAction Stop
                    
                    $Properties = @{'ComputerName' = $DCHost
                    'DomainController' = $DCHost
                    'Manufacturer' = $CS.Manufacturer
                    'Model' = $CS.Model
                    'TotalPhysicalMemory(GB)' = $CS.TotalPhysicalMemory /1GB}

                    New-Object -Type PSObject -Property $Properties
                }#try
                catch [Microsoft.Management.Infrastructure.CimException]
                {
                    Write-Warning "Failed to resolve $DCHost on $ADForest - CIMException"
                }#catch [Microsoft.Management.Infrastructure.CimException]

                catch
                {
                    $Error[0].Exception
                }#catch all
    
    New-Object -TypeName psobject -Property $Properties
            }#foreach($Host in $Hosts)
     }#foreach ($Domain in (Get-ADForest.Domains))
}#function Get-DCDiskInfo