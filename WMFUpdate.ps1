Function WMFUpdate {
    <#
    .SYNOPSIS
    This function is used to upgrade Windows Management Framework 5.1.
    
    .DESCRIPTION
    This function is used to download, extract and upgrade Windows Management Framework and PS 5.1.
    Both KB3191566 and KB2872035 are installed with KB3191566.

    .PARAMETER Key
    NotMandatory - credentials to authentificate against some source to be able to download.
    .PARAMETER Restart
    NotMandatory - reboot is neccessery for update to apply so switch is optional if you plan to reboot later.
    
    .EXAMPLES
    WMFUpdate -Restart
    WMFUpdate -Key $Key
   
    .NOTES
    v1
    https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/overview?view=powershell-7.1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [switch]$Restart
    )
    BEGIN {
        Start-Transcript -Path "$env:TEMP\WMF_Transcript.txt"
        $WMF5 = Get-HotFix -Id KB3191566 -ErrorAction SilentlyContinue -Verbose
        Write-Host "PS update check has started..."
    }
    PROCESS {
        if (!$WMF5) {
            Write-Host "WMF KB3191566 is missing, installing..."
            New-Item -Path $env:TEMP -Name WMF -ItemType Directory -Force -Verbose
            $WMF_url = 'https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip'
            Invoke-WebRequest -Uri $WMF_url -OutFile "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.zip"
            Write-Host "WMF KB3191566 is downloading..."
            Expand-Archive -Path "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.zip" -DestinationPath "$env:TEMP\WMF" -Force -Verbose
            $KB_path = Test-Path -Path "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.msu" -Verbose
            if ($KB_path) {
                Write-Host "WMF KB3191566 downloaded and extracted."
                while ((Get-Service -Name wuauserv).StartType -ne "Manual") {
                    Set-Service -Name wuauserv -StartupType Manual -Verbose
                    try {
                        Write-Host "Installation of KB3191566 update has started!"
                        Start-Process -FilePath "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.msu" -Verbose -ArgumentList '/quiet /norestart' -Wait -WindowStyle Hidden
                    }
                    catch {
                        Write-Host "Installation of KB3191566 update has failed!"
                        return $false 
                    }
                }
            }
            else {
                Write-Host "Error in download and/or extract of WMF files!"
                return $false
            }
        }
        else {
            Write-Host "KB3191566 is already installed."
            return $true
        }
    }
    END {
        if (Get-HotFix -Id KB3191566 -ErrorAction SilentlyContinue -Verbose) {
            Write-Host "WMF PowerShell 5.1 has installed/present."
            return $true
        }
        else {
            Write-Host "WMF PowerShell 5.1 installation has failed!"
            return $false
        }
        Stop-Transcript
        Move-Item -Path "$env:TEMP\WMF_Transcript.txt" -Destination "$env:TEMP\WMF\WMF_Transcript.txt" -Verbose -Force
        if ($Restart) {
            Write-Host "Restarting computer."
            Restart-Computer -Force
        }
    }
}