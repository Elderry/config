$consoleRegPath = 'HKCU:\Console'
$cmdPath        = Join-Path $consoleRegPath '%SystemRoot%_System32_cmd.exe'
$poshPath       = Join-Path $consoleRegPath '%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe'
$posh32Path     = Join-Path $consoleRegPath '%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe'
$poshNativePath = Join-Path $consoleRegPath '%SystemRoot%_sysnative_WindowsPowerShell_v1.0_powershell.exe'

$colorTable = (
    "Black",    "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray",
    "DarkGray",     "Blue",     "Green",     "Cyan",     "Red",     "Magenta",     "Yellow", "White"
)

$config = @{}
((Get-Content '.\Settings - Windows Console.json') -Replace '\/\/.*' | ConvertFrom-Json)[1].PSObject.Properties |
ForEach-Object {
    $name = $_.Name
    $value = $_.Value
    switch ($name) {
        { $colorTable.Contains($name) } {
            $config.Add('ColorTable' + ('{0:D2}' -f $colorTable.IndexOf($name)), '0X' + $value -as [int])
        }
        'CursorSize' { $config.Add($name, $(switch ($value) { 'small' { 25 } 'medium' { 50 } 'large' { 100 } })) }
        'FontSize' { $config.FontSize = $value * 65536 }
        'ScreenBufferSize.Lines'   { $config.ScreenBufferSize += $value * 65536 }
        'ScreenBufferSize.Columns' { $config.ScreenBufferSize += $value }
        'ScreenColors.Background' { $config.ScreenColors += $value * 16 }
        'ScreenColors.Foreground' { $config.ScreenColors += $value }
        'WindowAlpha' { $config.WindowAlpha = $value * 2.55 -as [int] }
        'WindowPosition.LeftMargin' { $config.WindowPosition += $value * 65536 }
        'WindowPosition.TopMargin'  { $config.WindowPosition += $value }
        'WindowSize.Height' { $config.WindowSize += $value * 65536 }
        'WindowSize.Width'  { $config.WindowSize += $value }
        default { $config.Add($name, $value) }
    }
}

function Remove-RegistryValue([string] $path, [string] $name) {
    $exists = Get-ItemProperty $path -Name $name -ErrorAction SilentlyContinue
    if ($exists -ne $null) { Remove-ItemProperty -Path $path -Name $name | Out-Null }
}

foreach($i in $config.GetEnumerator()) {
    switch ($i) {
        { $_ -is [int] -or $_ -is [bool] } { $type = 'DWORD' }
        { $_ -is [string]                } { $type = 'SZ'    }
    }
    New-ItemProperty -Path $consoleRegPath -Name $i.Name -Value $i.Value -PropertyType $type -Force | Out-Null
    if ($i.Name -ne 'CodePage') {
        Remove-RegistryValue $cmdPath        $i.Name
        Remove-RegistryValue $poshPath       $i.Name
        Remove-RegistryValue $posh32Path     $i.Name
        Remove-RegistryValue $poshNativePath $i.Name
    } else {
        New-ItemProperty -Path $cmdPath        -Name $i.Name -Value $i.Value -PropertyType $type -Force | Out-Null
        New-ItemProperty -Path $poshPath       -Name $i.Name -Value $i.Value -PropertyType $type -Force | Out-Null
        New-ItemProperty -Path $posh32Path     -Name $i.Name -Value $i.Value -PropertyType $type -Force | Out-Null
        New-ItemProperty -Path $poshNativePath -Name $i.Name -Value $i.Value -PropertyType $type -Force | Out-Null
    }
}
