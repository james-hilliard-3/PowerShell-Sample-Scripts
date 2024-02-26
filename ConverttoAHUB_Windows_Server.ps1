#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                # 
#   Version 1.1                                                             #
#                                                                           #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#############################################################################

<# This PowerShell Workflow changes the LicenseType Property on Azure VM's to "Windows_Server"
   which converts the machine to leverage Azure Hybrid Use Benefits (AHUB) at
   a cost savings of up to 40%. You MUST bring your own license or have an EA
   with Microsoft in order to be compliant.
#>

# Authenticate if needed
# Connect-AzAccount -Environment AzureUSGovernment

# Get all VMs in the selected subscription
$VMs = Get-AzVM

# Initialize an array to hold custom output objects
$output = @()

# Process each VM to apply AHUB where applicable
foreach ($VM in $VMs) {
    if ($VM.StorageProfile.OsDisk.OsType -eq "Windows" -and $VM.LicenseType -ne "Windows_Server") {
        try {
            # Setting the LicenseType to Windows_Server to enable AHUB
            $VM.LicenseType = "Windows_Server"
            # Suppress the less informative output by redirecting it to $null
            Update-AzVM -ResourceGroupName $VM.ResourceGroupName -VM $VM | Out-Null
            $status = "AHUB Conversion Completed"
        }
        catch {
            $status = "Conversion Failed: $_"
        }
    }
    else {
        $status = "Skipped: Not a Windows VM or already converted."
    }

    # Create a custom object for each VM processed and add it to the output array
    $output += [PSCustomObject]@{
        VMName            = $VM.Name
        ResourceGroupName = $VM.ResourceGroupName
        LicenseType       = $VM.LicenseType
        Status            = $status
    }
}

# Display the results in a formatted table
$output | Format-Table -AutoSize
