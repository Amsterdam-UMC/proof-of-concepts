<#
.SYNOPSIS 
    This Automation runbook dispatches the VMPackage requests
    
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
        $VMPackage,
        
        [Parameter(Mandatory=$true)]
        [string] 
        $VMResourceGroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        $VMName
    )


#
function VMPackages-Dispatch([string]$package, [string]$rgname, [string]$vmname)
{
    #
    # grab the right installation script directory
    Write-Output $package
    switch ($package)
	{
   	    "SCZ:Linux"         { $result = ./deploy-SCZ-Linux.ps1 -VMName $vmname -VMResourceGroupName $rgname; break }
   	    "R:Windows"         { $result = ./deploy-R-Windows.ps1 -VMPath './R_windows.ps1' -VMName $vmname -VMResourceGroupName $rgname; break }
        "Rstudio:Windows"   { $result = ./deploy-R-Windows.ps1 -VMPath './Rstudio_windows.ps1' -VMName $vmname -VMResourceGroupName $rgname; break }
   	    default             { $result = 'fail'; break }
	}
    return $result
}

#
return VMPackages-Dispatch $VMPackage $VMResourceGroupName $VMName