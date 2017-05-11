


Function Get-ReleaseURL()
{
$ReleaseURL=$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI + $env:SYSTEM_TEAMPROJECT + "/_apps/hub/ms.vss-releaseManagement-web.hub-explorer?definitionId="+ $env:RELEASE_DEFINITIONID +"&amp;releaseId=" + $env:RELEASE_RELEASEID  +"&amp;_a=release-summary" +"&releaseId=" + $env:RELEASE_RELEASEID  +"&_a=release-summary"
return $ReleaseURL
}




Function RecordDeployment($BaseURL, $appID, $apiKey)
{

$URI="$BaseURL/applications/$appID/deployments.json"
write-host "Sending the Deployment details to New Relic: $URI" 
$r=Invoke-RestMethod -Uri $URI -Method POST -Headers @{'X-Api-Key'=$apiKey} -ContentType 'application/json' -TimeoutSec 300 -Body @"
{
    "deployment": {
    "revision": "$revision",
    "changelog": "$changelog",
    "description": "$description",
    "user": "$user"
}
}
"@ 

if ( $r.StatusCode -eq 200)
{
    write-host "Deployment event of $AppName was recorded successfully to NewRelic server" 
    write-host  $r 
}

 }


# Output logo.
Function PrintLogo {
 write-host "" 
 write-host "" 
 write-host "=================================================================================================" 
 write-host "New Relic record deployment task" 
 write-host "Written by Shmulik Ahituv. All rights reserved.`n" 
 write-host "=================================================================================================" 
 write-host "" 
 write-host "" 
}

# Output  parameters.
Function PrintArguments {
  write-host "=================================================================================================" 
  write-host "Executing task with the following arguments:" 
  write-host "=================================================================================================" 
  write-host "*************** Application:          $application" 
  write-host "*************** Revision:             $revision" 
  write-host "*************** Changelog:            $changelog" 
  write-host "*************** Description:          $description" 
  write-host "#################################################################################################" 
  write-host "Finish Printing task's arguments" 
  write-host "#################################################################################################" 
}




#Main
write-host "Importing module: VstsTaskSdk" 
Import-Module $PSScriptRoot\ps_modules\VstsTaskSdk\VstsTaskSdk.psd1 -ArgumentList @{ NonInteractive = $true } -Verbose:$false

PrintLogo


#Get arguments 
$application=Get-VstsInput -name application
if ([string]::IsNullOrEmpty($application))
{
Write-Error "You must specify an Application name is empty" 
Exit 1
}

$revision=Get-VstsInput -name revision
if ([string]::IsNullOrEmpty($revision))
{
write-host "Revision is empty, trying to use default" 
$revision=$env:BUILD_SOURCEVERSION
if ([string]::IsNullOrEmpty($revision))
{
Write-Error "deafult BUILD_SOURCEVERSION is empty, revision cannot be null or empty" 
Exit 1
}
}

$Changelog=Get-VstsInput -name Changelog
if ([string]::IsNullOrEmpty($Changelog))
{
write-host "Changelog is empty, using default" 
$changelog=Get-ReleaseURL
}

$description=Get-VstsInput -name description
if ([string]::IsNullOrEmpty($description))
{
write-host "Description is empty, using default" 
$description=$env:RELEASE_RELEASEDESCRIPTION
}

$user=Get-VstsInput -name user
if ([string]::IsNullOrEmpty($user))
{
write-host "User is empty, using default" 
$user=$env:RELEASE_REQUESTEDFOR

}

PrintArguments
#Get Endpoint details
$serviceNameInput= Get-VstsInput -name NewRelicService
write-host "Endpoint id: $serviceNameInput" 
$endpoint=Get-VstsEndpoint -name $serviceNameInput
write-host "Endpoint details: $endpoint" 


#Get AppID
$BaseURL=$endpoint.URL
$url=$BaseURL+"/applications.json"
$apiKey=$endpoint.Auth[0].parameters[0].apitoken
write-host "Getting the App_id from the given application name" 
write-host "URL is: $url, application is: $application, token is : $apiKey" 

$r=Invoke-RestMethod -Method Post -Uri $url -Body "filter[name]=$application" -Header @{"X-Api-Key"=$apiKey}
$appID= $r.applications.id | Select-Object -first 1
write-host "AppID is $appID" 


RecordDeployment $BaseURL $appID $apiKey



