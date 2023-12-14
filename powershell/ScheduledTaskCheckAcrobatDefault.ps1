$powershell_code = {
    If (!(Test-Path 'C:\Temp' -PathType Container)) {
        New-Item -ItemType Directory -Force -Path 'C:\Temp'
    }
    Write-Host '[ ] Downloading SetUserFTA.zip package'
    Invoke-WebRequest -Uri 'https://kolbi.cz/SetUserFTA.zip' -OutFile 'C:\Temp\SetUserFTA.zip'
    Expand-Archive -Path 'C:\Temp\SetUserFTA.zip' -DestinationPath 'C:\Temp' -Force
    Remove-Item  'C:\Temp\SetUserFTA.zip' -Force
    Write-Host '[ ] Getting PDF association'
    $Result = cmd.exe /c 'C:\Temp\SetUserFTA\SetUserFTA.exe get | findstr .pdf'
    Write-Host "[+] Current association is: $Result"
    If (!($Result -ilike '*acrobat*')) {
        Write-Host '[ ] Checking if Acrobat is installed'
        If (Get-Package | findstr /I Acrobat) {
            Write-Host "[+] Acrobat is installed, chaging association" -ForegroundColor Green
            Start-Process -Wait -WindowStyle Hidden -FilePath 'C:\Temp\SetUserFTA\SetUserFTA.exe' -ArgumentList '.pdf Acrobat.Document.DC'
        }
        Else {
            Write-Host '[!] Acrobat is NOT installed, exiting' -ForegroundColor Red
        }
    }
    $Result = cmd.exe /c 'C:\Temp\SetUserFTA\SetUserFTA.exe get | findstr .pdf'
    Write-Host "`n[=] Final association is: $Result"
}

$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($powershell_code.ToString()))

$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -EncodedCommand $encodedCommand"
$taskTrigger = New-ScheduledTaskTrigger -AtLogOn
$taskName = 'CheckAcrobatAssociation'
$taskPrincipal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Limited
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$task = New-ScheduledTask -Action $taskAction -Principal $taskPrincipal -Settings $taskSettings -Trigger $taskTrigger -Description 'Check and apply Acrobat as PDF launcher' 
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -InputObject $task -TaskPath '\'
