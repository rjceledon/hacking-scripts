while ($true) {
    # Perform DNS request for A record and get only one IP address
    $dnsResult = (Resolve-DnsName -Name "google.com" -Type A | Select-Object -First 1 -ExpandProperty IPAddress)

    # Perform a single ping and get the response time
    $pingResult = Test-Connection -ComputerName "google.com" -Count 1
    $pingTime = $pingResult.ResponseTime

    # Perform a simple HTTP request to google.com and get the status code and body length
    $httpResponse = Invoke-WebRequest -Uri "http://google.com"
    $statusCode = $httpResponse.StatusCode
    $bodyLength = $httpResponse.Content.Length

    # Get the current IP address of the user on the interface called 'Ethernet adapter Ethernet 5'
    $currentIp = (Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq 'Ethernet 5' -and $_.AddressFamily -eq 'IPv4'} | Select-Object -ExpandProperty IPAddress | Select-Object -First 1)

    # Print the summary
    Write-Output "DNS IP: $($dnsResult), Ping Time: $($pingTime) ms, HTTP Status Code: $($statusCode), Body Length: $($bodyLength), Current IP: $($currentIp)"
}
