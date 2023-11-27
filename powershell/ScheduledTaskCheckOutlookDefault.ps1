$Powershell_Code = {
    If (!(Test-Path 'C:\Temp' -PathType Container)) {
        New-Item -ItemType Directory -Force -Path 'C:\Temp'
    }
    Write-Host '[ ] Downloading SetUserFTA.zip package'
    Invoke-WebRequest -Uri 'https://kolbi.cz/SetUserFTA.zip' -OutFile 'C:\Temp\SetUserFTA.zip'
    Expand-Archive -Path 'C:\Temp\SetUserFTA.zip' -DestinationPath 'C:\Temp' -Force
    Remove-Item  'C:\Temp\SetUserFTA.zip' -Force
    Write-Host '[ ] Getting MAILTO association'
    $Result = cmd.exe /c 'C:\Temp\SetUserFTA\SetUserFTA.exe get | findstr mailto'
    Write-Host "[+] Current association is: $Result"
    If (!($Result -ilike '*outlook*')) {
        Write-Host '[ ] Checking if Outlook is installed'
        If (Get-ItemProperty HKLM:\SOFTWARE\Classes\Outlook.Application -ErrorAction SilentlyContinue) {
            Write-Host "[+] Outlook is installed, chaging association" -ForegroundColor Green
            Start-Process -Wait -WindowStyle Hidden -FilePath 'C:\Temp\SetUserFTA\SetUserFTA.exe' -ArgumentList 'mailto Outlook.URL.mailto.15'
        }
        Else {
            Write-Host '[!] Outlook is NOT installed, exiting' -ForegroundColor Red
        }
    }
    $Result = cmd.exe /c 'C:\Temp\SetUserFTA\SetUserFTA.exe get | findstr mailto'
    Write-Host "`n[=] Final association is: $Result"
    Remove-Item 'C:\Temp\SetUserFTA\*' -Recurse -Force
}
$EncodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Powershell_Code.ToString()))
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -EncodedCommand $EncodedCommand"
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskName = 'CheckOutlookAssociation'
$TaskPrincipal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Limited
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$Task = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Settings $TaskSettings -Trigger $TaskTrigger -Description 'Check and apply Outlook as MAILTO launcher' 
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -InputObject $Task -TaskPath '\'
