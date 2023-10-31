$Company = $env:company
$Year = $env:year
$Password = $env:password
$params = @{
    Type = 'Custom'
    Subject = 'CN=P2S' + $Company + $Year + 'RootCert'
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyUsage = 'CertSign'
    KeyUsageProperty = 'Sign'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
}
$rootcert = New-SelfSignedCertificate @params
if (!(Test-Path 'C:\Temp' -PathType Container)) {
    New-Item -ItemType Directory -Force -Path 'C:\Temp'
}
$ExportPath = 'C:\Temp\P2S' + $Company + $Year + 'RootCert.cer'
Export-Certificate -Cert $rootcert -FilePath $ExportPath -Type CERT
$OpenSSLDir = 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe'
$OpenSSLArguments = 'x509 -inform der -in ' + $ExportPath + ' -out ' + $ExportPath
if (!(Test-Path -Path $OpenSSLDir)) {
    $OpenSSLInstaller = 'C:\Temp\Win64OpenSSL_Light-3_1_3.exe'
    Invoke-WebRequest -Uri 'https://slproweb.com/download/Win64OpenSSL_Light-3_1_3.exe' -OutFile $OpenSSLInstaller
    Start-Process -FilePath $OpenSSLInstaller -Wait
    Remove-Item -Path $OpenSSLInstaller -Force
}
Start-Process -FilePath $OpenSSLDir -ArgumentList $OpenSSLArguments -Wait
$content = Get-Content $ExportPath
$content = $content[1..($content.Length - 2)]
$content = $content -join ""
$content | Out-File ($ExportPath + '.txt')
Remove-Item -Path $ExportPath -Force
Write-Host ("`n`n[+] Root certificate exported in one-line Base64 encoded text:`n`n" + $content + "`n`n")
$params = @{
    Type = 'Custom'
    Subject = 'CN=P2S' + $Company + $Year + 'ChildCert'
    DnsName = 'P2S' + $Company + $Year + 'ChildCert'
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(18)
    CertStoreLocation = 'Cert:\CurrentUser\My'
    Signer = $rootcert
    TextExtension = @(
    '2.5.29.37={text}1.3.6.1.5.5.7.3.2')
}
$childcert = New-SelfSignedCertificate @params
$ExportPath = 'C:\Temp\P2S' + $Company + $Year + 'ChildCert.pfx'
$pwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $childcert -FilePath $ExportPath -Password $pwd -ChainOption BuildChain
$Password | Set-Content -Path 'C:\Temp\Cert pass.txt'

$FileContent = Get-Content -Path $ExportPath -Encoding Byte -Raw
$fileContentEncoded = [System.Convert]::ToBase64String($FileContent)
$fileContentEncoded | Set-Content -Path ($ExportPath + '.b64')
Write-Host ("`n`n[+] Child certificate exported as Base64 binary:`n`n" + $fileContentEncoded)
