$Password = $env:password
$FileContent = $env:childCertificateAsBase64

$FileContentEncoded = $FileContent
$FileContentDecoded = [System.Convert]::FromBase64String($FileContentEncoded)
if (!(Test-Path 'C:\Temp' -PathType Container)) {
    New-Item -ItemType Directory -Force -Path 'C:\Temp'
}
$ExportPath = 'C:\Temp\P2SChildCert.pfx'
$FileContentDecoded | Set-Content -Path $ExportPath -Encoding Byte
$pwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
Import-PfxCertificate -FilePath $ExportPath -CertStoreLocation 'Cert:\CurrentUser\My' -Exportable -Password $pwd
Remove-Item -Path $ExportPath -Force
