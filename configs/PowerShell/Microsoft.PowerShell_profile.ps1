# Custom Variables
Set-Alias au '~/Projects/Personal/chocolatey-packages/update_all.ps1' #[Windows]
Set-Alias aphro '~/Projects/Personal/Aphrodite/Aphrodite/bin/Release/netcoreapp2.2/win10-x64/Aphrodite.exe' #[Windows]
Set-Alias config '~/Projects/Personal/stalas/config.ps1'
$config = '~/Projects/Personal/stalas/config.sh' #[macOS]

# Custom Commands
Remove-Item Alias:ls #[Windows]
function ls { Get-ChildItem | Format-Wide -AutoSize -Property 'Name' } #[Windows]
function git_drop {
    git reset --hard
    git clean -fd
}
function git_prune {
    $branches = git branch -l |
        ForEach-Object { $_.Trim() } |
        Where-Object { -Not $_.StartsWith('*') } |
        Where-Object { $_ -ne 'master' }
    if ($branches.Length -eq 0) {
        Write-Host 'No branch is going to be deleted.'
        return
    }
    Write-Host 'Going to ' -NoNewline
    Write-Host 'delete' -ForegroundColor 'Red' -NoNewline
    Write-Host ' these branches:'
    Write-Host $branches
    $choice = Read-Host '[Y]es or [N]o?'
    if ($choice -eq 'y') {
        foreach ($branch in $branches) {
            git branch -D $branch
        }
    }
}
function git_push {
    $first_try = & git push 2>&1
    Write-Host $first_try
    if ($first_try[3] -Match '^\s*(git push --set-upstream origin \S+)$') {
        Write-Host "The push is recoverable, going to retry..."
        Invoke-Expression $Matches[1]
    }
}
function Flatten-Files {
    Get-ChildItem -Recurse -File | ForEach-Object {
        if ((Test-Path -LiteralPath $_.Name) -and ($_.Directory.FullName -ne $PWD)) {
            Move-Item -LiteralPath $_.FullName -Destination "$PWD/$($_.Directory.Name) - $($_.Name)"
        } else {
            Move-Item -LiteralPath $_.FullName -Destination "$PWD/$($_.Name)"
        }
    }
    Get-ChildItem -Directory | ForEach-Object {
        Remove-Item $_.Name -Recurse
    }
}
function Compress-Images([switch] $Recurse) {
    if ($Recurse) {
        Get-ChildItem -Directory | ForEach-Object {
            Set-Location -LiteralPath $_.Name
            Compress-Images -Recurse
            Convert-Images
            Set-Location ..
        }
    }
    magick mogrify -monitor -strip -quality 85% *.jpg
    Convert-Images
}
function Convert-Images {
    magick mogrify -monitor -format jpg *.png
    Remove-Item *.png
}

# Modules
if (!$global:GitPromptSettings) { Import-Module 'posh-git' }
$global:GitPromptSettings.BeforeText = ' ['
$global:GitPromptSettings.AfterText  = '] '

$DirectoryBackgroundColor = [ConsoleColor]::Blue
$UserBackgroundColor      = [ConsoleColor]::Green
$HostBackgroundColor      = [ConsoleColor]::Magenta

$GitBackgroundColor = [ConsoleColor]::DarkBlue
$global:GitPromptSettings.BeforeBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.DelimBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.AfterBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.LocalDefaultStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.LocalWorkingStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.LocalStagedStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchGoneStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchIdenticalStatusToBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchAheadStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchBehindStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BranchBehindAndAheadStatusBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BeforeIndexBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.IndexBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.WorkingBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.BeforeStashBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.AfterStashBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.StashBackgroundColor = $GitBackgroundColor
$global:GitPromptSettings.ErrorBackgroundColor = $GitBackgroundColor

$global:GitPromptSettings.LocalDefaultStatusForegroundColor = [ConsoleColor]::Green
$global:GitPromptSettings.LocalWorkingStatusForegroundColor = [ConsoleColor]::Red
$global:GitPromptSettings.BeforeIndexForegroundColor = [ConsoleColor]::Green
$global:GitPromptSettings.IndexForegroundColor = [ConsoleColor]::Green
$global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Red

Set-PSReadLineOption -Colors @{
    'Default' = [ConsoleColor]::Black #[macOS]
    'Number' = [ConsoleColor]::Green
    'Member' = [ConsoleColor]::Magenta
    'Type' = [ConsoleColor]::DarkYellow
    'ContinuationPrompt' = [ConsoleColor]::DarkMagenta
}

$Env:PATH = "$($Env:PATH):/Applications/Visual Studio Code.app/Contents/Resources/app/bin" #[macOS]
if (-not $Env:PATH.Contains('/usr/local/bin')) { #[macOS]
    $Env:PATH = "/usr/local/bin:$Env:PATH" #[macOS]
} #[macOS]
# For GnuPG and Pinentry's password prompt. #[macOS]
# Reference: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html #[macOS]
$Env:GPG_TTY = $(tty) #[macOS]

$Env:JAVA_HOME = /usr/libexec/java_home -v 1.8 #[macOS]

if ((Get-Service ssh-agent).Status -ne 'Running') { #[Windows]
    ssh-agent #[Windows]
} #[Windows]

function IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function IsRoot { return $(id -un) -eq 'root' }

function prompt {

    # Git
    Write-VcsStatus
    if (Get-GitDirectory) {
        Write-Host '' -ForegroundColor $GitBackgroundColor -BackgroundColor $DirectoryBackgroundColor -NoNewline
    }

    # Path
    $path = " $($PWD.Path -replace ($HOME -replace '\\', '\\'), '~' -replace '\\', '/') "
    Write-Host $path -ForegroundColor 'White' -BackgroundColor $DirectoryBackgroundColor -NoNewline
    Write-Host '' -ForegroundColor $DirectoryBackgroundColor

    # User
    $user = " $Env:USERNAME@$((Get-Culture).TextInfo.ToTitleCase($env:USERDOMAIN.ToLower())) " #[Windows]
    $user = " $Env:USER@$(hostname) " #[macOS]
    Write-Host $user -ForegroundColor 'White' -BackgroundColor $UserBackgroundColor -NoNewline
    Write-Host '' -ForegroundColor $UserBackgroundColor -BackgroundColor $HostBackgroundColor -NoNewline

    # Host symbol
    $symbol = if (IsAdmin) { '#' } else { '$' } #[Windows]
    $symbol = if (IsRoot) { '#' } else { '$' } #[macOS]
    Write-Host " $symbol " -ForegroundColor 'White' -BackgroundColor $HostBackgroundColor -NoNewline
    Write-Host '' -ForegroundColor $HostBackgroundColor -NoNewline

    return ' '
}
# This has to be after prompt function because zLocation alters prompt to work. #[Windows]
Import-Module -Name 'zLocation' #[Windows]
