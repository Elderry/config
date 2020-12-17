Import-Module powershell-yaml

$desktop = "$Home/OneDrive/Collections/AppBackup/Desktop"
$pwshShortcut = 'PS.lnk'
$pwshAdminShortcut = 'PSA.lnk'
$pwshNativeShortcut = 'PN.lnk'
$pwshNativeAdminShortcut = 'PNA.lnk'
$cmdShortcut = 'CD.lnk'
$cmdAdminShortcut = 'CDA.lnk'

$colorTable = (
    "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue",
    "Green", "Cyan", "Red", "Magenta", "Yellow", "White"
)

$config = @{}
(Get-Content "$PSScriptRoot/settings.yml" -Raw | ConvertFrom-Yaml).GetEnumerator() | ForEach-Object {
    $name = $_.Name
    $value = $_.Value
    switch ($name) {
        { $colorTable.Contains($name) } {
            $config.Add('ColorTable' + ('{0:D2}' -f $colorTable.IndexOf($name)), '0X' + $value -as [int])
        }
        'CursorSize' { $config.Add($name, $(switch ($value) { 'small' { 25 } 'medium' { 50 } 'large' { 100 } })) }
        'FontFamily.Family' { $config.FontFamily += $(switch ($value) {
            'dontCare' { 0 } 'roman' { 0x10 } 'swiss' { 0x20 } 'modern' { 0x30 } 'script' { 0x40 } 'decorative' { 0x50 }
        })}
        'FontFamily.Pitch' { if ($value) { $config.FontFamily += 1 }}
        'FontFamily.Vector' { if ($value) { $config.FontFamily += 2 }}
        'FontFamily.TrueType' { if ($value) { $config.FontFamily += 4 }}
        'FontFamily.Device' { if ($value) { $config.FontFamily += 8 }}
        'FontSize' { $config.FontSize = $value * 65536 }
        'ScreenBufferSize.Lines' { $config.ScreenBufferSize += $value * 65536 }
        'ScreenBufferSize.Columns' { $config.ScreenBufferSize += $value }
        'ScreenColors.Background' { $config.ScreenColors += $value * 16 }
        'ScreenColors.Foreground' { $config.ScreenColors += $value }
        'WindowAlpha' { $config.WindowAlpha = $value * 2.55 -as [int] }
        'WindowPosition.LeftMargin' { $config.WindowPosition += $value }
        'WindowPosition.TopMargin' { $config.WindowPosition += $value * 65536 }
        'WindowSize.Height' { $config.WindowSize += $value * 65536 }
        'WindowSize.Width' { $config.WindowSize += $value }
        default { $config.Add($name, $value) }
    }
}

function Set-Registry([string] $path, [string] $name, $value, [string] $type) {
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force -ErrorAction 'SilentlyContinue' |
        Out-Null
}

function Remove-Registry([string] $path, [string] $name) {
    $exists = Get-ItemProperty $path -Name $name -ErrorAction 'SilentlyContinue'
    if ($exists) { Remove-ItemProperty -Path $path -Name $name | Out-Null }
}

function Remove-Registry([String] $path) {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse }
}

# Clean specific configuration for each console exe.
$consolePath = 'HKCU:/Console'
Get-ChildItem $consolePath | ForEach-Object {
    $path = $_.Name -replace 'HKEY_CURRENT_USER', 'HKCU:'
    Remove-Item -LiteralPath $path -Recurse
}

$config.GetEnumerator() | ForEach-Object {

    $name = $_.Name
    $value = $_.Value
    switch ($value) {
        { $_ -is [int] -or $_ -is [bool] } { $type = 'Dword' }
        { $_ -is [string] } { $type = 'String' }
    }
    Set-Registry $consolePath $name $value $type
}

function Set-Shortcut([string] $Path, [string] $Target, [switch] $RequireAdmin) {

    $shortcut = $(New-Object -ComObject 'WScript.Shell').CreateShortcut($Path)
    $shortcut.TargetPath = $Target
    $shortcut.WorkingDirectory = $Home
    # Icon location has to be specifically determined because otherwise PowerShell Core will fail to display it.
    $shortcut.IconLocation = "$Target, 0"
    $shortcut.Save()

    if ($RequireAdmin) {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $bytes[0x15] = $bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes($Path, $bytes)
    }
}

$pwshPath = "$PSHOME/pwsh.exe"
$pwshNativePath = "$Env:SystemRoot/System32/WindowsPowerShell/v1.0/powershell.exe"
$cmdPath = "$Env:SystemRoot/System32/cmd.exe"

function Update-Shortcut([string] $Path) {
    $shortcut = $(New-Object -ComObject 'WScript.Shell').CreateShortcut($Path)
    $target = $pwshPath
    if ($shortcut.TargetPath -eq $target) { return }
    $shortcut.TargetPath = $target
    $shortcut.Save()
}

Set-Shortcut "$desktop/$pwshShortcut" $pwshPath
Set-Shortcut "$desktop/$pwshAdminShortcut" $pwshPath -RequireAdmin
Set-Shortcut "$desktop/$pwshNativeShortcut" $pwshNativePath
Set-Shortcut "$desktop/$pwshNativeAdminShortcut" $pwshNativePath -RequireAdmin
Set-Shortcut "$desktop/$cmdShortcut" $cmdPath
Set-Shortcut "$desktop/$cmdAdminShortcut" $cmdPath -RequireAdmin
