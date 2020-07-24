
<#
.SYNOPSIS 
    This Automation runbook deploys R/R studio to Windows platform using a Powershell script
    
.DESCRIPTION

.PARAMETER VMResourceGroupName
    Mandatory.
  
.PARAMETER VMName
    Mandatory.

.NOTES
    AUTHORs:  A.H.Ullings
    LASTEDIT: 18/10/2019 
#>

param (
        [Parameter(Mandatory=$true)]
        [string] 
        $VMPath,
        
        [Parameter(Mandatory=$true)]
        [string] 
        $VMResourceGroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        $VMName
    )



#
function VMPackages-Windows([string]$path, [string]$rgname, [string]$vmname)
{
    #
    # grab the right installation script directory
    $context = Get-AzContext
    $res = Set-AzContext -Subscription 'SURFcumulus Amsterdam UMC CloudBolt Development'
    $res = Set-AzCurrentStorageAccount -ResourceGroupName 'cloudbolt-dev-rg' -StorageAccountName 'cloudboltdevsa01'
    $res = Get-AzStorageFileContent -Force -ShareName 'cloudbolt-dev-scripts' -Path $path
    #
    Set-AzContext -Context $context
    Invoke-AzVMRunCommand -ResourceGroupName $rgname -Name $vmname -CommandId 'RunPowerShellScript' -ScriptPath $path
    #
    Write-Output "VMPackages done"
    return 'ok'
}

#
return VMPackages-Windows $VMPath $VMResourceGroupName $VMName
# return 'debug'