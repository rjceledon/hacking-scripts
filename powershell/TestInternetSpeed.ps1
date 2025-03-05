# Define the CSV file path
$csvFilePath = "C:\Temp\InternetSpeedResults.csv"

$maxRetries = 5
    $retryCount = 0
    $validResult = $false

    while ($retryCount -lt $maxRetries -and -not $validResult) {
        $result = C:\SpeedtestCLI\speedtest.exe --server-id 14237 --format json | ConvertFrom-Json
        $downloadSpeed = $result.download.bandwidth / 125000
        $uploadSpeed = $result.upload.bandwidth / 125000
        $ping = $result.ping.latency

        if ($downloadSpeed -gt 0 -and $uploadSpeed -gt 0) {
            $validResult = $true
            $data = [PSCustomObject]@{
                Timestamp = Get-Date
                DownloadSpeed = $downloadSpeed
                UploadSpeed = $uploadSpeed
                Ping = $ping
            }

            if (Test-Path $csvFilePath) {
                $data | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
            } else {
                $data | Export-Csv -Path $csvFilePath -NoTypeInformation
            }
        } else {
            $retryCount++
            Start-Sleep -Seconds 10  # Wait for 10 seconds before retrying
        }
    }
