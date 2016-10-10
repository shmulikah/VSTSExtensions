


Function Get-ReleaseURL()
{
$ReleaseURL=$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI + $env:SYSTEM_TEAMPROJECT + "/_apps/hub/ms.vss-releaseManagement-web.hub-explorer?definitionId="+ $env:RELEASE_DEFINITIONID + "&amp;_a=release-summary&amp;releaseId=" + $env:RELEASE_RELEASEID + "&amp;_a=release-summary&amp;releaseId=" + $env:RELEASE_RELEASEID
return $ReleaseURL
}




Function RecordDeployment($BaseURL, $appID, $apiKey)
{

  $BodyData = @{ "deployment"=
  @{
    revision= $Revision
    changelog= $Changelog
    description= $description
    user= $user
    }
}
Write-Verbose "Sending the Deployment details to new relic" -Verbose
$r=Invoke-RestMethod -Uri $BaseURL/applications/$appID/deployments.json -Method POST -Headers @{'X-Api-Key'=$apiKey} -ContentType 'application/json' -Body $BodyData -TimeoutSec 300

if ( $r.StatusCode -eq 200)
{
    write-verbose "Deployment event of $AppName was recorded successfully to NewRelic server" -Verbose
    write-verbose  $r -Verbose
}

 }


# Output logo.
Function PrintLogo {
 write-verbose "" -Verbose
 write-verbose "" -Verbose
 write-verbose "=================================================================================================" -Verbose
 write-verbose "New Relic record deployment task" -Verbose
 write-verbose "Written by Shmulik Ahituv. All rights reserved.`n" -Verbose
 write-verbose "=================================================================================================" -Verbose
 write-verbose "" -Verbose
 write-verbose "" -Verbose
}

# Output  parameters.
Function PrintArguments {
  write-verbose "=================================================================================================" -Verbose
  write-verbose "Executing task with the following arguments:" -Verbose
  write-verbose "=================================================================================================" -Verbose
  write-verbose "*************** Application:          $application" -Verbose
  write-verbose "*************** Revision:             $revision" -Verbose
  write-verbose "*************** Changelog:            $changelog" -Verbose
  write-verbose "*************** Description:          $description" -Verbose
  write-verbose "#################################################################################################" -Verbose
  write-verbose "Finish Printing task's arguments" -Verbose
  write-verbose "#################################################################################################" -Verbose
}




#Main
Write-Verbose "Importing module: VstsTaskSdk" -Verbose
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
Write-Verbose "Revision is empty, using default" -Verbose
$revision=$env:BUILD_SOURCEVERSION
}

$Changelog=Get-VstsInput -name Changelog
if ([string]::IsNullOrEmpty($Changelog))
{
Write-Verbose "Changelog is empty, using default" -Verbose
$changelog=Get-ReleaseURL
}

$description=Get-VstsInput -name description
if ([string]::IsNullOrEmpty($description))
{
Write-Verbose "Description is empty, using default" -Verbose
$description=$env:RELEASE_RELEASEDESCRIPTION
}

$user=Get-VstsInput -name user
if ([string]::IsNullOrEmpty($user))
{
Write-Verbose "User is empty, using default" -Verbose
$user=$env:RELEASE_REQUESTEDFOR
}

PrintArguments
#Get Endpoint details
$serviceNameInput= Get-VstsInput -name NewRelicService
write-Verbose "Endpoint id: $serviceNameInput" -Verbose
$endpoint=Get-VstsEndpoint -name $serviceNameInput
write-Verbose "Endpoint details: $endpoint" -Verbose


#Get AppID
$BaseURL=$endpoint.URL
$url=$BaseURL+"/applications.json"
$apiKey=$endpoint.Auth[0].parameters[0].apitoken
Write-Verbose "Getting the App_id from the given application name" -Verbose
Write-Verbose "URL is: $url, application is: $application, token is : $apiKey" -Verbose

$r=Invoke-RestMethod -Method Post -Uri $url -Body "filter[name]=$application" -Header @{"X-Api-Key"=$apiKey}
$appID= $r.applications.id | Select-Object -first 1
Write-Verbose "AppID is $appID" -Verbose


RecordDeployment $BaseURL $apiKey $appID




