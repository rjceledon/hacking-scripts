#[!] Usage: .\ExchangeBlock.ps1 -Item "user@domain.com|domain.com" -Notes "Additional notes... Ticket Number#"
#rjceledon May 2025

param (
    $Notes,
    $Item
)

$scriptFileName = Split-Path -Leaf $PSCommandPath

function Press-AnyKeyToContinue {
    Write-Host -ForegroundColor White "[=] Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

function Show-Usage {
    Write-Host -ForegroundColor Red "[!] Usage: " -NoNewline
    Write-Host -ForegroundColor Yellow ".\$scriptFileName " -NoNewline
    Write-Host -ForegroundColor DarkGray "-Item " -NoNewline
    Write-Host -ForegroundColor DarkCyan "`"user@domain.com|domain.com`" " -NoNewline
    Write-Host -ForegroundColor DarkGray "-Notes " -NoNewline
    Write-Host -ForegroundColor DarkCyan "`"T20250000.0000 - INFOSEC-00000`""
}

if ([string]::IsNullOrEmpty($Notes) -or [string]::IsNullOrEmpty($Item)) {
    Show-Usage
    Press-AnyKeyToContinue
}

If ((Get-ConnectionInformation | Select-Object -ExpandProperty State) -ne "Connected") {
	Write-Host -ForegroundColor Yellow "[!] Not connected to ExchangeOnline, connecting..."
	Connect-ExchangeOnline -SkipLoadingCmdletHelp -SkipLoadingFormatData -ShowBanner:$false
}

If ((Get-ConnectionInformation | Select-Object -ExpandProperty State) -eq "Connected") {
	Write-Host -ForegroundColor Green "[+] Connected to ExchangeOnline"
	If ($Item -like "*@*") {
		Write-Host -ForegroundColor Green "[+] Blocking email sender"
		Try {
			New-TenantAllowBlockListItems -ListType Sender -Block -Entries $Item -NoExpiration -Notes $Notes -ErrorAction Stop
			Write-Host -ForegroundColor Green "[+] Added Sender to block list"
		} Catch {
			If ($_.Exception.Message -like "*Duplicate value*") {
				Write-Host -ForegroundColor Yellow "[!] Item already exists"
				Get-TenantAllowBlockListItems -ListType Sender -Entry $Item
			} Else {
				Write-Host -ForegroundColor Red "[!] An error has occurred, exiting now"
				Press-AnyKeyToContinue
    			}
		}
		Press-AnyKeyToContinue
	} Else {
		Write-Host -ForegroundColor Green "[+] Blocking domain"
		Try {
			New-TenantAllowBlockListItems -ListType Url -Block -Entries $Item -NoExpiration -Notes $Notes -ErrorAction Stop
			Write-Host -ForegroundColor Green "[+] Added Url to block list"
		} Catch {
			If ($_.Exception.Message -like "*Duplicate value*") {
				Write-Host -ForegroundColor Yellow "[!] Item already exists"
				Get-TenantAllowBlockListItems -ListType Url -Entry $Item
			} Else {
				Write-Host -ForegroundColor Red "[!] An error has occurred, exiting now"
				Press-AnyKeyToContinue
    			}
		}
		Get-TenantAllowBlockListItems -ListType Url -Entry $Item
		Press-AnyKeyToContinue
	}
} Else {
	Write-Host -ForegroundColor Red "[!] An error has occurred, exiting now"
	Press-AnyKeyToContinue
}
