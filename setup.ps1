# Prompt for email
$email = Read-Host "Enter the email to use for SSH and Git configuration"

if ((Read-Host "Configure global Git settings? (y/n)").Trim().ToLower() -eq 'y') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
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
        "Microsoft.VisualStudioCode",
        "AgileBits.1Password",
        "SlackTechnologies.Slack",
        "Vivaldi.Vivaldi",
        "Microsoft.VisualStudio.2022.Professional",
        "Docker.DockerDesktop",
        "Microsoft.WSL",
        "Canonical.Ubuntu",
        "Microsoft.Powershell",
        "TidalMusicAs.Tidal"
    )

    foreach ($app in $apps) {
        Write-Output "Installing $app..."
        winget install --id=$app --silent --accept-package-agreements --accept-source-agreements
    }
    Write-Output "All apps installed!"
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
}

if ((Read-Host "Install PowerShell modules and fonts? (y/n)").Trim().ToLower() -eq 'y') {
    Install-Module posh-git -Scope CurrentUser -Force
    Install-Module Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
    Install-Module PSReadLine -AllowPrerelease -Scope CurrentUser -Force
    oh-my-posh font install FiraMono
}

if ((Read-Host "Setup PowerShell profile and clone theme? (y/n)").Trim().ToLower() -eq 'y') {
    $storageOption = Read-Host "Store aliases/profile in (1) OneDrive Work or (2) Local Documents? [1/2]"
    if ($storageOption -eq '1') {
        $profileRoot = "$env:OneDriveCommercial\Documents\PowerShell"
    } else {
        $profileRoot = "$env:USERPROFILE\Documents\PowerShell"
    }

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

`$env:POSH_GIT_ENABLED` = `$true`

. `$PSScriptRoot\Aliases.ps1`
"@

    if (-not (Test-Path "$tempPath\.git")) {
        git clone https://github.com/tobiasbalzano/Setup.git "$tempPath"
    }
    Copy-Item "$tempPath\BalzanosM365Princess.omp.json" "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\" -Force
    Copy-Item "$tempPath\Aliases.ps1" "$profilePath" -Force
}

if ((Read-Host "Apply FiraMono font to Windows Terminal profile? (y/n)").Trim().ToLower() -eq 'y') {
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettingsPath) {
        $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
        foreach ($profile in $settings.profiles.list) {
            if ($profile.name -match "PowerShell") {
                $profile.font = @{ face = "FiraMono Nerd Font" }
            }
        }
        $settings | ConvertTo-Json -Depth 32 | Set-Content $wtSettingsPath -Force
    }
}

if ((Read-Host "Configure global Git settings? (y/n)").Trim().ToLower() -eq 'y') {
    git config --global push.autoSetupRemote always
    git config --global core.editor "code"
    git config --global user.email $email
    git config --global user.name "Tobias Balzano"
}

Remove-Item $tempPath -Recurse -Force

Write-Output "Setup complete. Restart terminal to apply changes."
