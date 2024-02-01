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

foreach ($subscription in $subscriptions) {
    # Set context to the subscription
    Set-AzContext -SubscriptionId $subscription.Id

    $dnsZones = Get-AzPrivateDnsZone

    foreach ($zone in $dnsZones) {
        $links = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName
        $records = Get-AzPrivateDnsRecordSet -ZoneName $zone.Name -ResourceGroupName $zone.ResourceGroupName

        foreach ($link in $links) {
            $vnetId = $link.VirtualNetworkId
            $vnet = Get-AzVirtualNetwork -Name $vnetId.Split('/')[-1] # Splitting to get the name

            foreach ($record in $records) {
                # Initialize an empty string to hold record data
                $recordDataString = ""

                switch ($record.RecordType) {
                    'A' {
                        $recordDataString = ($record.Records.Ipv4Address -join ", ")
                    }
                    'AAAA' {
                        $recordDataString = ($record.Records.Ipv6Address -join ", ")
                    }
                    'MX' {
                        $recordDataString = ($record.Records | ForEach-Object { "$($_.Preference) $($_.Exchange)" }) -join ", "
                    }
                    'TXT' {
                        $recordDataString = ($record.Records.Text -join ", ")
                    }
                    Default {
                        $recordDataString = "Unsupported record type"
                    }
                }

                $zoneWithVnetsAndRecords += [PSCustomObject]@{
                    SubscriptionId     = $subscription.Id
                    SubscriptionName   = $subscription.Name
                    ZoneName           = $zone.Name
                    ZoneId             = $zone.ResourceId
                    RecordSetName      = $record.Name
                    RecordType         = $record.RecordType
                    RecordData         = $recordDataString
                    LinkedVNetId       = $vnetId
                    VNetName           = $vnet.Name
                    VNetAddressSpace   = ($vnet.AddressSpace.AddressPrefixes -join ", ")
                }
            }
        }
    }
}

if ($zoneWithVnetsAndRecords.Count -eq 0) {
    Write-Host "No DNS Zones with linked Virtual Networks and records found across all subscriptions."
} else {
    $zoneWithVnetsAndRecords | Format-Table
    $zoneWithVnetsAndRecords | Export-Csv -Path "ZoneWithVnetsAndRecords.csv" -NoTypeInformation
}
