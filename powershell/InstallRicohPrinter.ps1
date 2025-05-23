Set-Service -Name Spooler -StartupType Automatic
Set-Service -Name Spooler -Status Running

Remove-Printer -Name "RICOH Printer 1"
Remove-Printer -Name "RICOH Printer 2"

Remove-PrinterPort -Name "10.0.0.9"
Remove-PrinterPort -Name "10.0.0.8"

Set-Service -Name Spooler -Status Stopped
Set-Service -Name Spooler -Status Running

Remove-PrinterDriver -Name "RICOH Aficio MP 4002 PCL 6"

Expand-Archive -Path C:\drivers\ricoh.zip -Destinationpath C:\drivers\

pnputil.exe /a C:\drivers\ricoh\*.inf

Add-PrinterPort -Name "10.0.0.9" -PrinterHostAddress "10.0.0.9"
Add-PrinterPort -Name "10.0.0.8" -PrinterHostAddress "10.0.0.8"

Add-PrinterDriver -Name "RICOH Aficio MP 4002 PCL 6"

Add-Printer -DriverName "RICOH Aficio MP 4002 PCL 6" -Name "RICOH Printer 1" -PortName "10.0.0.9"
Add-Printer -DriverName "RICOH Aficio MP 4002 PCL 6" -Name "RICOH Printer 2" -PortName "10.0.0.8"
