Update-Module -Name ExchangeOnlineManagement
Connect-IPPSSession
$Search=New-ComplianceSearch -Name "RecurrentMeeting" -ExchangeLocation All -ContentMatchQuery '(kind:meetings) AND (From:user@contoso.com) AND (Subject:"Meeting Subject")'
Start-ComplianceSearch -Identity "RecurrentMeeting"
Get-ComplianceSearch -Identity "RecurrentMeeting"
New-ComplianceSearchAction -SearchName "RecurrentMeeting" -Purge -PurgeType SoftDelete
Get-ComplianceSearchAction -Identity "RecurrentMeeting_Purge"

Remove-CalendarEvents -Identity user@contoso.com -CancelOrganizedMeetings -PreviewOnly -QueryWindowInDays 365
