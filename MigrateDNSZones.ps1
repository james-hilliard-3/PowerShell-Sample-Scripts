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

# Import the CSV file
$csvData = Import-Csv -Path "$HOME/ZoneWithVnetsAndRecords.csv"

# Group by ZoneName to identify duplicates
$groupedZones = $csvData | Group-Object -Property ZoneName

foreach ($group in $groupedZones) {
    if ($group.Count -le 1) {
        continue
    }

    # Display the list of duplicate zones for user selection
    Write-Host "Duplicate zones found for: $($group.Name)"
    $index = 0
    foreach ($zone in $group.Group) {
        $resourceGroup = (Get-AzResource -ResourceId $zone.ZoneId).ResourceGroupName
        Write-Host "$($index): Zone Name: $($zone.ZoneName), Resource Group: $resourceGroup"
        $index++
    }

    # User selects the primary zone
    [int]$selectedIndex = Read-Host "Enter the index of the primary zone"
    $primaryZone = $group.Group[$selectedIndex]

    # Migrate records and VNet links from duplicate zones to the primary zone
    foreach ($zone in $group.Group) {
        # Skip the primary zone itself
        if ($zone.ZoneId -eq $primaryZone.ZoneId) {
            continue
        }

        # Set context to the subscription of the duplicate zone
        Set-AzContext -SubscriptionId $zone.SubscriptionId

        # Migrate all DNS Records
        $dnsRecords = Get-AzPrivateDnsRecordSet -ZoneName $zone.ZoneName -ResourceGroupName $resourceGroup
        foreach ($record in $dnsRecords) {
            try {
                $existingRecord = Get-AzPrivateDnsRecordSet -ZoneName $primaryZone.ZoneName -ResourceGroupName (Get-AzResource -ResourceId $primaryZone.ZoneId).ResourceGroupName -Name $record.Name -RecordType $record.RecordType -ErrorAction SilentlyContinue
                if ($existingRecord) {
                    Write-Host "Duplicate record found: $($record.Name) in zone: $($primaryZone.ZoneName). Migration paused for manual intervention."
                    break 2
                } else {
                    # Add record to target zone
                    $recordSetParams = @{
                    ZoneName       = $primaryZone.ZoneName
                    ResourceGroupName = (Get-AzResource -ResourceId $primaryZone.ZoneId).ResourceGroupName
                    Name           = $record.Name
                    RecordType     = $record.RecordType
                    Ttl            = $record.Ttl
                    DnsRecords     = $record.Records
                }

                    # Depending on the record type, handle the record data accordingly
                    switch ($record.RecordType) {
                "A" {
                     # For A records
                      $recordSetParams.Ipv4Address = ($record.Records).Ipv4Address
                    }
                "AAAA" {
                     # For AAAA records
                    $recordSetParams.Ipv6Address = ($record.Records).Ipv6Address
                    }
                "CNAME" {
                    # For CNAME records
                    $recordSetParams.Cname = ($record.Records).Cname
                    }
                "MX" {
                    # For MX records
                    $recordSetParams.Exchange = ($record.Records).Exchange
                    $recordSetParams.Preference = ($record.Records).Preference
                    }
                # Add additional cases for other record types as needed
                }

                # Create the record set in the primary zone
                    try {
                        Add-AzPrivateDnsRecordSet @recordSetParams
                        Write-Host "Record migrated: $($record.Name)"
             } catch {
                 Write-Host "Error migrating record: $($record.Name). Error: $_"
                         break 2
}

                }
            } catch {
                Write-Host "Error migrating record: $($record.Name). Error: $_"
                break 2
            }
        }

        # Migrate VNet Links
        $vnetLinks = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.ZoneName -ResourceGroupName $resourceGroup
        foreach ($link in $vnetLinks) {
            try {
                # Check if the link already exists in the primary zone
                $existingLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $primaryZone.ZoneName -ResourceGroupName (Get-AzResource -ResourceId $primaryZone.ZoneId).ResourceGroupName -Name $link.Name -ErrorAction SilentlyContinue
                if ($existingLink) {
                Write-Host "Link already exists in primary zone: $($link.Name)"
                } else {
                # Create a new link in the primary zone
                New-AzPrivateDnsVirtualNetworkLink -ZoneName $primaryZone.ZoneName -ResourceGroupName (Get-AzResource -ResourceId $primaryZone.ZoneId).ResourceGroupName -VirtualNetworkId $link.VirtualNetworkId -Name $link.Name -EnableRegistration $link.RegistrationEnabled
                Write-Host "Link migrated: $($link.Name)"
                }
        } catch {
            Write-Host "Error migrating link: $($link.Name). Error: $_"
            break 2
    }
}

    }
}

Write-Host "Migration completed."
