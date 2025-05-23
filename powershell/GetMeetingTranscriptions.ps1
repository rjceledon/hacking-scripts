#Obtain Access Token
$LoginUrl = "https://login.microsoftonline.com/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/oauth2/v2.0/token"
$ClientID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$ClientSecret = "xxxxx~xxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$FirstUrl = 'https://graph.microsoft.com/v1.0/users/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/onlineMeetings/getAllTranscripts?$filter=MeetingOrganizer/User/Id eq ''xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'''

$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Content-Type", "application/x-www-form-urlencoded")
$Body = "client_id=$($ClientID)&client_secret=$($ClientSecret)&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&grant_type=client_credentials"

$Response = Invoke-RestMethod $LoginUrl -Method 'POST' -Headers $Headers -Body $Body
$JsonResponse = $Response | ConvertTo-Json | ConvertFrom-Json

$AccessToken = $JsonResponse.access_token

$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Authorization", "Bearer $($AccessToken)")

$Response = Invoke-RestMethod $FirstUrl -Method 'GET' -Headers $Headers
$JsonResponse = $Response | ConvertTo-Json | ConvertFrom-Json

$NextLink = $JsonResponse.'@odata.nextLink'

While ($NextLink -ne "") {
    ForEach ($value in $JsonResponse.value) {
        $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $Headers.Add("Accept", "text/vtt")
        $Headers.Add("Authorization", "Bearer $($AccessToken)")
       
        $Response = Invoke-RestMethod $value.transcriptContentUrl -Method 'GET' -Headers $Headers -ErrorAction SilentlyContinue
        If ($Response.StatusCode -eq 404) {
            Write-Output "Error: The server responded with a 404 Not Found."
        } else {
            #Write-Output $NextLink
            $extractedPart = (($value.transcriptContentUrl -split '/onlineMeetings/')[1] -split '/transcripts')[0]
            # Decode the extracted part
            $decodedBytes = [System.Convert]::FromBase64String($extractedPart)
            $decodedString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            
            $secondPart = ($decodedString -split '19:')[1]
            $MeetingName = "19:$($secondPart)" -Replace "@", "_" -Replace ":", "_"
            Write-Output $MeetingName
            
            $OutputFile = "C:\Temp\$($MeetingName).vtt"
            Write-Output $Response
            $Response | Out-File -FilePath $OutputFile
        }



    }
    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("Authorization", "Bearer $($AccessToken)")

    $Response = Invoke-RestMethod $NextLink -Method 'GET' -Headers $Headers
    $JsonResponse = $Response | ConvertTo-Json | ConvertFrom-Json

    $NextLink = $JsonResponse.'@odata.nextLink'
}
