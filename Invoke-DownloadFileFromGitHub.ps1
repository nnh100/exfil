function Invoke-DownloadFileFromGitHub
{

<#
.SYNOPSIS
Use this script to download files from GitHub (had to write this to download 64-bit executable files)

.Example

Download executable

Invoke-DownloadFileFromGitHub -GHUser nnh100 -GHRepo uploads -GHFilePath "tools/" -GHFileName "Autoruns64.exe" -LocalFilePath "c:\temp\"

.Example

Download file from specific branch

Invoke-DownloadFileFromGitHub -GHUser nnh100 -GHRepo exfil -GHFilePath "testfolder/" -GHFileName "test.txt" -LocalFilePath "c:\temp\" -Branch "2.0"

.Example

Download file and rename

Invoke-DownloadFileFromGitHub -GHUser nnh100 -GHRepo uploads -GHFilePath "tools/" -GHFileName "Autoruns64.exe" -LocalFilePath "c:\temp\" -AltFileName "autoruns64.exe"


#>


    [CmdletBinding()] Param(

    [Parameter(Position = 0, Mandatory = $True)]
    [String]
    $GHUser,


    [Parameter(Position = 1, Mandatory = $True)]
    [String]
    $GHRepo,


    [Parameter(Position =2, Mandatory = $True)]
    [String]
    $GHFilePath,

    [Parameter(Position = 3, Mandatory = $True)]
    [String]
    $GHFileName,

    [Parameter(Position = 4, Mandatory=$True)]
    [String]
    $LocalFilePath,

    [Parameter(Position = 5, Mandatory=$False)]
    [String]
    $Branch = "master",

    [Parameter(Position = 6, Mandatory=$False)]
    [String]
    $AltFileName


    )


    # Construct the api of the file to download
    $GHAPI = "https://api.github.com/repos/" + $GHUser + "/" + $GHRepo + "/contents/" + $GHFilePath + $GHFileName

    $Body = @{
        path = $GHFilePath + $GHFileName;
        ref = $Branch;
    }


    Try {
        # Don't actually need the header
        $content = Invoke-RestMethod -Uri $GHAPI -Body $Body -Method Get -ErrorAction SilentlyContinue
        
        $fileBytes = [System.Convert]::FromBase64String(($content.content))


       #if ($Fuzz -eq $True){
        #    Write-Host "fuzzing"
         #   $fileBytes = $fileBytes + (New-Object Random).NextBytes((New-Object Byte[] (1024*100)))
       #}



        if ($AltFileName) {
            $outFile = $LocalFilePath + $AltFileName
        }
        else {
            $outFile = $LocalFilePath + $GHFileName
        }

		[System.IO.File]::WriteAllBytes($outFile, $fileBytes)
			
        
    }
    Catch {        
        $ErrorMessage = "Trying to get file contents: " + $_.Exception.Message;
        Write-Error $ErrorMessage; 
    }


}
