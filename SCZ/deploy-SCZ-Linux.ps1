
<#
.SYNOPSIS 
    This Automation runbook deploys the SCZ activation for some Linux flavors
    
.DESCRIPTION
    

.PARAMETER WebhookData
    Optional. The information about the .
  
.PARAMETER ChannelURL
    Optional. The Microsoft Teams Channel webhook URL that information will get sent.

.NOTES
    AUTHORs: Microsoft Automation Team, A.H.Ullings
    LASTEDIT: 18/10/2019 
#>

param (
        [Parameter(Mandatory=$true)]
        [string] 
        $VMResourceGroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        $VMName
    )

#
function Get-SCZScriptPath([string]$rgname, [string]$vmname)
{
#
$remoteCommand =
@'
#/bin/sh
cat /etc/os-release
'@
    Set-Content -Path .\remote.sh -Value $remoteCommand
    $output = Invoke-AzVMRunCommand -ResourceGroupName $rgname -Name $vmname -CommandId 'RunShellScript' -ScriptPath '.\remote.sh'
    $r = $output.Value[0].Message -match 'ID="(.+)"'
    $ID=$Matches[1]
    $r = $output.Value[0].Message -match 'VERSION_ID="(.+)"'
    $VERSION_ID=$Matches[1]
    '.\SCZ'+'_'+$ID+'_'+$VERSION_ID+'.sh'
}

#
function VMPackages-SCZ-Linux([string]$rgname, [string]$vmname)
{
    #
    # determine the OS version and .sh script PATH
    $PATH = Get-SCZScriptPath $rgname $vmname
    # Write-Output $PATH
    #
    # grab the encoded secret
    $secret = Get-AzKeyVaultSecret -VaultName 'azure-play-vault' -Name 'SCZ-secret'

    # grab the right installation script directory
    $context = Get-AzContext
    $res = Set-AzContext -Subscription 'SURFcumulus Amsterdam UMC CloudBolt Development'
    $res = Set-AzCurrentStorageAccount -ResourceGroupName 'cloudbolt-dev-rg' -StorageAccountName 'cloudboltdevsa01'
    $res = Get-AzStorageFileContent -Force -ShareName 'cloudbolt-dev-scripts' -Path $PATH
    #
    $res = Set-AzContext -Context $context
    $res = Invoke-AzVMRunCommand -ResourceGroupName $rgname -Name $vmname -CommandId 'RunShellScript' `
       -ScriptPath $PATH -Parameter @{param1 = "SCZAdmin@research-cloud.nl";param2 = $secret.SecretValueText}
    #
    # Write-Output "VMPackages-SCZ-Linux done"
    return 'ok'
}

return VMPackages-SCZ-Linux $VMResourceGroupName $VMName

