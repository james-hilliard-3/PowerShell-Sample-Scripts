#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                # 
#                                                                           #
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

# Authenticate if needed
# Connect-AzAccount -Environment AzureUSGovernment

# Retrieve all subscriptions
$subscriptions = Get-AzSubscription

if ($subscriptions -eq $null -or $subscriptions.Count -eq 0) {
    Write-Host "No subscriptions found."
    exit
}

$zoneWithVnetsAndRecords = @()

foreach ($subscription in $subscriptions) {
    # Set context to the subscription
    Set-AzContext -SubscriptionId $subscription.Id

    $dnsZones = Get-AzPrivateDnsZone

    foreach ($zone in $dnsZones) {
        $links = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName
        # Retrieve DNS records for the zone
        $records = Get-AzPrivateDnsRecordSet -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName

        foreach ($link in $links) {
            $vnetId = $link.VirtualNetworkId
            # Retrieve detailed VNET info
            $vnet = Get-AzVirtualNetwork -Name $vnetId

            # Process each record in the zone
            foreach ($record in $records) {
                $zoneWithVnetsAndRecords += [PSCustomObject]@{
                    SubscriptionId     = $subscription.Id
                    SubscriptionName   = $subscription.Name
                    ZoneName           = $zone.Name
                    ZoneId             = $zone.ResourceId
                    RecordSetName      = $record.Name
                    RecordType         = $record.RecordType
                    RecordData         = ($record.Records | ConvertTo-Json -Compress)
                    LinkedVNetId       = $vnetId
                    VNetName           = $vnet.Name
                    VNetAddressSpace   = $vnet.AddressSpace.AddressPrefixes -join ", "
                }
            }
        }
    }
}

if ($zoneWithVnetsAndRecords.Count -eq 0) {
    Write-Host "No DNS Zones with linked Virtual Networks and records found across all subscriptions."
} else {
    # Example: Output to console
    $zoneWithVnetsAndRecords | Format-Table

    # Example: Export to CSV
    $zoneWithVnetsAndRecords | Export-Csv -Path "ZoneWithVnetsAndRecords.csv" -NoTypeInformation
}
