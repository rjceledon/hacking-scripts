Write-Output "[+] Getting Boot-Up Time and Current Date"
$BootUpTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CurrentDate = Get-Date
Write-Output "[+] Computing Uptime"
$Uptime = $CurrentDate - $BootUpTime
Write-Output "[+] Computer Raw Uptime --> $($Uptime)"
Write-Output "[+] Computer Uptime --> Days: $($Uptime.days), Hours: $($Uptime.Hours), Minutes:$($Uptime.Minutes)"


$MoreThan7DaysUp = ($Uptime.days -ge 7)
if ($MoreThan7DaysUp)
{
    Write-Output "[!] Uptime greater than 7 days"
    Write-Output "[+] Preparing webhook request"
    $RequestUri = 'https://XXXXXXX.XXXXXX.logic.azure.com:443/workflows/...'
    $Body = @{
    computer = "$($env:ComputerName)"
    company = "$TenantName" # Immybot Parameter
    uptime = "$($Uptime.days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes."
    }
    Write-Output "[!] Sleeping 60 seconds to allow MS Flow to run"
    Start-Sleep -Seconds 60
    Write-Output "[+] Sending information in JSON format..."
    Invoke-WebRequest -UseBasicParsing -Uri $RequestUri -Method Post -ContentType 'application/json' -Body ($Body|ConvertTo-Json)
}

