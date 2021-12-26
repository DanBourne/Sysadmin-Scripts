Function Get-Permission{
    [CmdletBinding()]        
       
    # Params
    param
    (
        [Parameter(Position=0, Mandatory = $True, HelpMessage="Provide server names", ValueFromPipeline = $true)] 
        $Servers,
    
        [Parameter(Position=1, Mandatory = $False, HelpMessage="Provide path, for example c:\users", ValueFromPipeline = $true)]
        $Path
    ) 
  
    $Array = @()
    #$Cred = Get-Credential $env:Username
 
    If(!$Path)
    {
        Write-Warning "Exiting - No path provided"
    }
    Else
    {
    
        ForEach($Server in $Servers)
        {
            Try
            {
                #$ACLs = Invoke-Command $Server -ErrorAction Stop -ScriptBlock{param($Path)Get-Acl $Path | Select -ExpandProperty Access | Where-Object {$_.PropagationFlags -match "InheritOnly"}} -ArgumentList $path #-Credential $cred
                $ACLs = Invoke-Command $Server -ErrorAction Stop -ScriptBlock{param($Path)Get-Acl $Path | Select -ExpandProperty Access } -ArgumentList $path #-Credential $cred
            }
            Catch
            {
                $_.Exception.Message
                Continue
            }
     
                If($ACLs)
                {
                    # Loop each ACL
                    $ACLs | ForEach-Object {
     
                        # Define current loop to variable
                        $item = $_
     
                        Switch ($item.FileSystemRights)
                        {
                            "2032127"     { $Val = "FullControl" }
                            "1179785"     { $Val = "Read" }
                            "1180063"     { $Val = "Read, Write" }
                            "1179817"     { $Val = "ReadAndExecute" }
                            "-1610612736" { $Val = "ReadAndExecuteExtended" }
                            "1245631"     { $Val = "ReadAndExecute, Modify, Write" }
                            "1180095"     { $Val = "ReadAndExecute, Write" }
                            "268435456"   { $Val = "FullControl (Sub Only)" }
                        }
 
                        $Object = New-Object PSObject -Property @{ 
   
                            Servername             = $Server
                            Path                   = $Path
                            FileSystemRights       = $val     
                            Access                 = $Item.AccessControlType
                            Identity               = $Item.IdentityReference           
                            IsInherited            = $Item.IsInherited
                            PropagationFlags       = $item.PropagationFlags                    
   
                        }
                
                        # Add custom object to our array
                        $Array += $Object
                    }
                }
        }
    }
 
    If($Array)
    {
        Write-Host "`nPermissions for $Path" -ForegroundColor Green
        $Array | Select-Object Servername,Path,Access,FileSystemRights,Identity,IsInherited,PropagationFlags | Format-Table -AutoSize
 
        # Results in pop-up window
        $Array | Select-Object Servername,Path,Access,FileSystemRights,Identity,IsInherited,PropagationFlags | Out-GridView -Title "Permissions for $Path"
    }
}