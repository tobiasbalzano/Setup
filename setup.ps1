# Prompt for email
$email = Read-Host "Enter the email to use for SSH and Git configuration"

if ((Read-Host "Set ExecutionPolicy for this process? (y/n)").Trim().ToLower() -eq 'y') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
}

if ((Read-Host "Set Timezone? (y/n)").Trim().ToLower() -eq 'y') {
    Set-TimeZone -Name "W. Europe Standard Time"
}

$tempPath = "C:\fresh-install"
mkdir $tempPath -Force

$codePath = "C:\code"
mkdir $codePath -Force

if ((Read-Host "Install applications with winget? (y/n)").Trim().ToLower() -eq 'y') {
    $apps = @(
        "Git.Git",
        "GitHub.cli",
        "JanDeDobbeleer.OhMyPosh",
        "7zip.7zip",
        "Microsoft.VisualStudioCode",
        "AgileBits.1Password",
        "SlackTechnologies.Slack",
        "Vivaldi.Vivaldi",
        "Docker.DockerDesktop",
        "Microsoft.WSL",
        "Microsoft.Powershell",
        "TidalMusicAs.Tidal"
    )

    foreach ($app in $apps) {
        if (-not [string]::IsNullOrWhiteSpace($app)) {
            if ((Read-Host ("Install {0}? (y/n)" -f $app)).Trim().ToLower() -eq 'y') {
                Write-Output "Installing $app..."
                winget install --id=$app --silent --accept-package-agreements --accept-source-agreements
            } else {
                Write-Output "Skipping $app."
            }
        }
    }

    Write-Output "All apps installed!"



    if ((Read-Host "Install Visual Studio 2022 with workloads? (y/n)").Trim().ToLower() -eq 'y') {
        $vsEdition = Read-Host "Choose edition: (1) Professional or (2) Community [1/2]"
        $vsId = if ($vsEdition -eq '2') { 'Microsoft.VisualStudio.2022.Community' } else { 'Microsoft.VisualStudio.2022.Professional' }

        winget install --id $vsId --accept-package-agreements --accept-source-agreements --override "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.NetCore.Component.SDK --includeRecommended --quiet --wait"
    }

    if ((Read-Host "Install .NET SDKs? (y/n)").Trim().ToLower() -eq 'y') {
        $startVersion = Read-Host "Enter the starting .NET major version to install (e.g., 6, 7, 8)"
        $version = [int]$startVersion

        while ($true) {
            $sdkId = "Microsoft.DotNet.SDK.$version"
            Write-Output "Attempting to install $sdkId..."
            $result = winget install --id $sdkId --silent --accept-package-agreements --accept-source-agreements -e 2>&1

            if ($result -match 'No package found') {
                Write-Output "No SDK found for version $version. Stopping."
                break
            }

            Write-Output "Installed .NET SDK version $version"
            $version++
        }
    }
    
    if ((Read-Host "Install JetBrains ReSharper? (y/n)").Trim().ToLower() -eq 'y') {
        Write-Output "Installing JetBrains.ReSharper..."
        winget install --id JetBrains.ReSharper --silent --accept-package-agreements --accept-source-agreements
    }
}

if ((Read-Host "Install WSL with Ubuntu? (y/n)").Trim().ToLower() -eq 'y') {
    wsl --install -d Ubuntu
}

if ((Read-Host "Generate SSH key and start ssh-agent? (y/n)").Trim().ToLower() -eq 'y') {
    $sshPath = "$HOME\.ssh"
    if (-not (Test-Path $sshPath)) {
        mkdir $sshPath
    }
    ssh-keygen -t ed25519 -C $email -f "$sshPath\id_ed25519" -N "" -q
    Get-Service -Name ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    ssh-add "$sshPath\id_ed25519"
    notepad "$sshPath\id_ed25519.pub"
}

if ((Read-Host "Install PowerShell modules and fonts? (y/n)").Trim().ToLower() -eq 'y') {
    Install-Module posh-git -Scope CurrentUser -Force
    Install-Module Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
    Install-Module PSReadLine -AllowPrerelease -Scope CurrentUser -Force
    oh-my-posh font install FiraMono
}

if ((Read-Host "Setup PowerShell profile and clone theme? (y/n)").Trim().ToLower() -eq 'y') {
    $storageOption = Read-Host "Store aliases/profile in (1) OneDrive Work or (2) Local Documents? [1/2]"
    $profileRoot = if ($storageOption -eq '1') { "$env:OneDriveCommercial\Documents\PowerShell" } else { "$env:USERPROFILE\Documents\PowerShell" }

    if (-not (Test-Path $profileRoot)) {
        New-Item -Path $profileRoot -ItemType Directory -Force
    }

    $profilePath = Join-Path $profileRoot 'aliases.ps1'

    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force
    }

    Add-Content $PROFILE @"
Import-Module posh-git
Import-Module -Name Terminal-Icons
oh-my-posh prompt init pwsh --config `"$env:LOCALAPPDATA\Programs\oh-my-posh\themes\BalzanosM365Princess.omp.json`" | Invoke-Expression

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

`$env:POSH_GIT_ENABLED = `$true

. `$profilePath
"@

    if (-not (Test-Path "$tempPath\.git")) {
        git clone https://github.com/tobiasbalzano/Setup.git "$tempPath"
    }
    Copy-Item "$tempPath\BalzanosM365Princess.omp.json" "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\" -Force
    Copy-Item "$tempPath\Aliases.ps1" "$profilePath" -Force
}

if ((Read-Host "Apply defaults to Windows Terminal? (y/n)").Trim().ToLower() -eq 'y') {
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettingsPath) {
        $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
        foreach ($profile in $settings.profiles.list) {
            if ($profile.name -match "PowerShell") {
                $profile | Add-Member -MemberType NoteProperty -Name fontFace -Value "FiraMono Nerd Font" -Force
            }
        }

        $pwshProfile = $settings.profiles.list | Where-Object { $_.commandline -like "*pwsh.exe" }
        if ($pwshProfile) {
            $settings.defaultProfile = $pwshProfile.guid
        }

        $settings | ConvertTo-Json -Depth 32 | Set-Content $wtSettingsPath -Force
    }
}

if ((Read-Host "Configure global Git settings? (y/n)").Trim().ToLower() -eq 'y') {
    git config --global push.autoSetupRemote true
    git config --global core.editor "code"
    git config --global user.email $email
    git config --global user.name "Tobias Balzano"
}

Remove-Item $tempPath -Recurse -Force

Write-Output "Setup complete. Restart terminal to apply changes."
