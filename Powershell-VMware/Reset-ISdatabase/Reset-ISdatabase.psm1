#Requires -Version 2
function Reset-ISdatabase {
<# 
.SYNOPSIS
Resets the vCenter Inventory Service database.
.DESCRIPTION
This is a Powershell module, so you first need to run : Import-Module \Path\To\Reset-ISdatabase.psm1.
Then, you can use the Reset-ISdatabase function just like a cmdlet.
You can also use its alias : risdb.

This script resets the vCenter Inventory Service database.
IMPORTANT : For vCenter 5.1 and 5.5 only.
IMPORTANT : It needs to be run as Administrator.
Requires Powershell 2.0 or later (built into Windows Server 2008 R2).

.PARAMETER NoPrompt
By default, the function prompts you to confirm that you understand the potential consequences of resetting the Inventory Service database.
If you want to suppress this prompt, use the -NoPrompt parameter.

.PARAMETER Verbose
By default, the function doesn't display much output on the console while running.
If you want the function to display what it's doing on the console, use the -Verbose parameter

.PARAMETER DBpath
Allows you to specify the path to the Inventory Service Database, if it's not the default path.

.PARAMETER ScriptsPath
Allows you to specify the path to the Inventory Service Scripts folder, if it's not the default path.

.PARAMETER vCenterPort
Allows you to specify the vCenter HTTPS port, if it's not the default.

.PARAMETER ISport
Allows you to specify the Inventory Service port, if it's not the default.

.PARAMETER LookupServicePort
Allows you to specify the Lookup Service port, if it's not the default.

.EXAMPLE
Reset-ISdatabase -NoPrompt

This resets vCenter Inventory Service database without prompting to confirm that you understand the potential consequences of resetting the Inventory Service database.
.EXAMPLE
Reset-ISdatabase -Verbose

This resets vCenter Inventory Service database and displays verbose output on the console.
.EXAMPLE
Reset-ISdatabase -DBpath "D:\Program Files\VMware\Infrastructure\Inventory Service\data" -ScriptsPath "D:\Program Files\VMware\Infrastructure\Inventory Service\scripts"

This resets vCenter Inventory Service database, specifying the paths to the database and the scripts folder, in case the Inventory Service was installed in the D: drive.
.EXAMPLE
Reset-ISdatabase -vCenterPort 1093 -ISport 1094 -LookupServicePort 1095

This resets vCenter Inventory Service database, specifying custom ports for the vCenter URL, the Inventory Service URL, and the Lookup Service URL.
.NOTES 
Author : Mathieu Buisson

.LINK
http://kb.vmware.com/kb/2042200
#>

[cmdletbinding()]

param(
[switch]$NoPrompt,
[string]$DBpath = 'C:\Program Files\VMware\Infrastructure\Inventory Service\data',
[string]$ScriptsPath = 'C:\Program Files\VMware\Infrastructure\Inventory Service\scripts',
[int]$vCenterPort = 443,
[int]$ISport = 10443,
[int]$LookupServicePort = 7444
)
if (!$NoPrompt) {
    $choice = read-host "As explained in http://kb.vmware.com/kb/2042200 , resetting the Inventory Service database deletes the Managed Object IDs and the vCenter tags, are you sure you want to continue ? (Y/N)"
    if ($choice -eq "Y") { 
        Write-Verbose "Stopping the Inventory Service. This can take a few moments..."
        Stop-Service -Name vimQueryService | Out-Null
        Write-Verbose "The Inventory Service is now stopped"
        
        Write-Verbose "Saving the Inventory Service database hash to the variable `$DataHash."
        $DataHash = Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap) | Select-String -Pattern '<server' -SimpleMatch
        Write-Verbose "`$DataHash is : $DataHash"
        
        Write-Verbose "deleting the content of $DBpath..."
        Remove-Item -Path (Join-Path -Path $DBpath -ChildPath *) -Recurse -Force
        
        Write-Verbose "Creating a brand new Inventory Service database, using the script createDB.bat ..."
        &(Join-Path -Path $ScriptsPath -ChildPath createDB.bat) | Out-Null
        Write-Verbose "Restoring the xdb.bootstrap header."
        
        $newDataHash = Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap) | Select-String -Pattern '<server' -SimpleMatch
        (Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap)) | ForEach-Object {$_.Replace("$newDataHash","$DataHash")} | 
        Set-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap)
        
        Write-Verbose "Starting the Inventory Service. This can take a few moments..."
        Start-Service -Name vimQueryService | Out-Null
        Write-Verbose "The Inventory Service is now started"
        $vCenterFQDN = [System.Net.Dns]::GetHostByName((hostname)).HostName
        
        Write-Verbose "Re-registering vCenter Server with the Inventory Service, using the script register-is.bat. This can take a few moments, please wait ..."
        Set-Location -Path "C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool"
        
        # Building the vCenter component URLs
        $vCenterURL = "https://" + "$vCenterFQDN" + ":" +  "$vCenterPort" + "/sdk"
        $IS_URL = "https://" + "$vCenterFQDN" + ":" + "$ISport"
        $LookupServiceURL = "https://" + "$vCenterFQDN" + ":" + "$LookupServicePort" + "/lookupservice/sdk"
        &"C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool\register-is.bat" $vCenterURL $IS_URL $LookupServiceURL | Out-Null
        Write-Verbose "Restarting the vCenter Server service. This can take a few minutes, please wait ..."
        Restart-Service -Name vpxd -force -WarningAction SilentlyContinue | Out-Null

        Write-Verbose "The vCenter Server service is now started"
        Write-Verbose "The vCenter Inventory Service database is now reset."       
    }
    Else { break }
 }
Else {
    Write-Verbose "Stopping the Inventory Service. This can take a few moments..."
    Stop-Service -Name vimQueryService | Out-Null
    Write-Verbose "The Inventory Service is now stopped"
    
    Write-Verbose "Saving the Inventory Service database hash to the variable `$DataHash."
    $DataHash = Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap) | Select-String -Pattern '<server' -SimpleMatch
    Write-Verbose "`$DataHash is : $DataHash"
    
    Write-Verbose "deleting the content of $DBpath..."
    Remove-Item -Path (Join-Path -Path $DBpath -ChildPath *) -Recurse -Force
    
    Write-Verbose "Creating a brand new Inventory Service database, using the script createDB.bat ..."
    &(Join-Path -Path $ScriptsPath -ChildPath createDB.bat) | Out-Null
    Write-Verbose "Restoring the xdb.bootstrap header."
    
    $newDataHash = Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap) | Select-String -Pattern '<server' -SimpleMatch
    (Get-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap)) | ForEach-Object {$_.Replace("$newDataHash","$DataHash")} | 
    Set-Content -Path (Join-Path -Path $DBpath -ChildPath xdb.bootstrap)
    
    Write-Verbose "Starting the Inventory Service. This can take a few moments..."
    Start-Service -Name vimQueryService | Out-Null
    Write-Verbose "The Inventory Service is now started"
    $vCenterFQDN = [System.Net.Dns]::GetHostByName((hostname)).HostName
    
    Write-Verbose "Re-registering vCenter Server with the Inventory Service, using the script register-is.bat. This can take a few moments, please wait ..."
    Set-Location -Path "C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool"
    
    # Building the vCenter component URLs
    $vCenterURL = "https://" + "$vCenterFQDN" + ":" +  "$vCenterPort" + "/sdk"
    $IS_URL = "https://" + "$vCenterFQDN" + ":" + "$ISport"
    $LookupServiceURL = "https://" + "$vCenterFQDN" + ":" + "$LookupServicePort" + "/lookupservice/sdk"
    &"C:\Program Files\VMware\Infrastructure\VirtualCenter Server\isregtool\register-is.bat" $vCenterURL $IS_URL $LookupServiceURL | Out-Null
    Write-Verbose "Restarting the vCenter Server service. This can take a few minutes, please wait ..."
    Restart-Service -Name vpxd -force -WarningAction SilentlyContinue | Out-Null

    Write-Verbose "The vCenter Server service is now started"
    Write-Verbose "The vCenter Inventory Service database is now reset."
    }
}

New-Alias -Name risdb -Value Reset-ISdatabase
Export-ModuleMember -Function *
Export-ModuleMember -Alias *
