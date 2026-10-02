# SpotBlock - Spotify Ad Blocker Script for Windows PowerShell
# Native Windows port of spotblock.sh. Keep the domain and prefs lists in sync with it.

param(
  [string]$Command
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$SourceUrl = if ($env:SPOTBLOCK_SOURCE_URL) { $env:SPOTBLOCK_SOURCE_URL } else { 'https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.ps1' }
$HostsFile = [IO.Path]::Combine($env:SystemRoot, 'System32', 'drivers', 'etc', 'hosts')
$BackupDir = Join-Path $HOME '.spotify_adblock_backups'
$SpotifyPrefs = [IO.Path]::Combine($env:APPDATA, 'Spotify', 'prefs')
$CacheDir = [IO.Path]::Combine($env:APPDATA, 'Spotify', 'Data')
$Header = '# Spotify Ad Blocking'

# hosts entries match exact names only; wildcards have no effect.
$AdDomains = @(
  # Core Ad Services
  'pagead2.googlesyndication.com'
  'gads.pubmatic.com'
  'securepubads.g.doubleclick.net'

  # Spotify Specific Ad Services
  'spotify-heads-ak.akamaized.net'
  'heads-fab.spotify.com'
  'heads4-ak.spotify.com'
  'heads4-fa.spotify.com'
  'heads-cf.spotify.com'
)

$SpotifyPrefsEntries = @(
  'app.browser.smoothscroll=false'
  'ui.show_ads=false'
  'app.player.autoplay=false'
  'browser.integration.show_download_button=false'
  'ui.promo_enabled=false'
  'audio.play_bitrate_enumeration=0'
  'ui.track_notifications_enabled=false'
  'audio.normalize_v2=false'
  'audio.gapless_playback=false'
  'ui.animated_artwork=false'
  'ui.show_friend_feed=false'
)

function Show-Usage {
  [Console]::Error.WriteLine(@'
Usage: spotblock [install|block|restore|status|clear-cache]
  install     - Install SpotBlock as a system command and run the blocker
  block       - Block Spotify ads by modifying hosts file
  restore     - Restore hosts file from backup
  status      - Show current Spotify and ad blocking status
  clear-cache - Clear Spotify cache directory
'@)
}

function Test-SpotifyRunning {
  [bool](Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue)
}

function Assert-HostsWritable {
  try {
    [IO.File]::Open($HostsFile, 'Append', 'Write').Dispose()
  } catch {
    throw "Cannot write $HostsFile. Run PowerShell as Administrator."
  }
}

# Spotify reads prefs as UTF-8 without BOM, one key per line.
function Add-PrefsEntry {
  $content = [IO.File]::ReadAllText($SpotifyPrefs)
  $lines = $content -split '\r?\n'
  $missing = @($SpotifyPrefsEntries | Where-Object { $lines -notcontains $_ })
  if ($missing.Count -eq 0) { return }

  if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) { $content += "`n" }
  $content += ($missing -join "`n") + "`n"
  [IO.File]::WriteAllText($SpotifyPrefs, $content, (New-Object Text.UTF8Encoding $false))
}

function Get-HostsHostname {
  $names = @{}
  foreach ($line in [IO.File]::ReadAllLines($HostsFile)) {
    $fields = @(($line -replace '#.*$', '').Trim() -split '\s+' | Where-Object { $_ })
    for ($i = 1; $i -lt $fields.Count; $i++) { $names[$fields[$i].ToLowerInvariant()] = $true }
  }
  $names
}

function Invoke-Block {
  Assert-HostsWritable

  # Spotify rewrites prefs on exit, which would drop entries added while it runs.
  if ((Test-Path -LiteralPath $SpotifyPrefs -PathType Leaf) -and (Test-SpotifyRunning)) {
    [Console]::Error.WriteLine('Spotify is running; skipping prefs changes. Close Spotify and run block again to apply them.')
  } elseif (Test-Path -LiteralPath $SpotifyPrefs -PathType Leaf) {
    Write-Output 'Applying advanced blocking configurations...'
    Add-PrefsEntry
  }

  New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
  $backupFile = Join-Path $BackupDir ('hosts_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
  Write-Output "Creating backup of hosts file at $backupFile"
  Copy-Item -LiteralPath $HostsFile -Destination $backupFile -Force

  $existing = Get-HostsHostname
  $missing = @($AdDomains | Where-Object { -not $existing.ContainsKey($_) })
  if ($missing.Count -eq 0) {
    Write-Output 'All domains are already blocked.'
  } else {
    $nl = [Environment]::NewLine
    $text = $nl + "$Header (Added $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))" + $nl
    foreach ($domain in $missing) {
      $text += "127.0.0.1 $domain" + $nl
      Write-Output "Blocking: $domain"
    }
    [IO.File]::AppendAllText($HostsFile, $text, [Text.Encoding]::ASCII)
  }

  Write-Output ''
  Write-Output 'Spotify ad blocking has been applied.'
  Write-Output 'Please restart Spotify for changes to take effect.'
  Write-Output "Backup saved at: $backupFile"
}

function Invoke-Restore {
  if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) { throw 'No backups found.' }

  $latest = Get-ChildItem -LiteralPath $BackupDir -Filter 'hosts_backup_*' -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $latest) { throw "No backup files found in $BackupDir" }

  Assert-HostsWritable
  Write-Output "Restoring from backup: $($latest.FullName)"
  Copy-Item -LiteralPath $latest.FullName -Destination $HostsFile -Force
  Write-Output 'Hosts file has been restored.'
}

function Show-Status {
  if (Test-SpotifyRunning) {
    Write-Output 'Spotify is currently running.'
  } else {
    Write-Output 'Spotify is not running.'
  }

  if (Select-String -LiteralPath $HostsFile -SimpleMatch $Header -Quiet) {
    $existing = Get-HostsHostname
    $blocked = @($AdDomains | Where-Object { $existing.ContainsKey($_) })
    Write-Output 'Ad blocking is currently active.'
    Write-Output "Number of blocked domains: $($blocked.Count)"
  } else {
    Write-Output 'Ad blocking is not active.'
  }
}

function Clear-SpotifyCache {
  if (-not $env:APPDATA) { throw 'Could not determine the Spotify data directory' }
  if (-not (Test-Path -LiteralPath $CacheDir -PathType Container)) {
    Write-Output 'Spotify cache directory not found.'
    return
  }

  Write-Output "Clearing Spotify cache at: $CacheDir"
  # .NET deletes links without following them. Keep the directory itself so its owner stays the same.
  foreach ($item in Get-ChildItem -LiteralPath $CacheDir -Force) {
    if ($item.PSIsContainer -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      [IO.Directory]::Delete($item.FullName, $true)
    } else {
      $item.Delete()
    }
  }
  Write-Output 'Cache cleared successfully.'
}

# Writes the raw registry value so %VAR% entries in Path stay expandable.
function Add-InstallPath([string]$Dir) {
  try {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
  } catch [Security.SecurityException] {
    # Without Administrator rights (custom SPOTBLOCK_INSTALL_DIR), use the user Path.
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
  }
  if (-not $key) { throw 'Could not open the Path registry key.' }
  try {
    $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $entries = @($raw -split ';' | Where-Object { $_ })
    if ($entries -contains $Dir) { return }
    $key.SetValue('Path', (($entries + $Dir) -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
  } finally {
    $key.Close()
  }

  # Tell Explorer to reload the environment so new terminals see the updated Path.
  Add-Type -Namespace SpotBlock -Name Native -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
'@
  $result = [UIntPtr]::Zero
  [void][SpotBlock.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
  $env:Path = "$env:Path;$Dir"
}

function Install-SpotBlock {
  $InstallDir = if ($env:SPOTBLOCK_INSTALL_DIR) { $env:SPOTBLOCK_INSTALL_DIR } else { Join-Path $env:ProgramFiles 'SpotBlock' }
  $target = Join-Path $InstallDir 'spotblock.ps1'
  # Only the .cmd shim goes on Path. A spotblock.ps1 on Path would win in PowerShell
  # and fail under the default execution policy; the shim bypasses it for this script only.
  $binDir = Join-Path $InstallDir 'bin'
  $shim = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\spotblock.ps1`" %*`r`n"
  try {
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    [IO.File]::WriteAllText((Join-Path $binDir 'spotblock.cmd'), $shim, [Text.Encoding]::ASCII)
  } catch {
    throw "$InstallDir is not writable. Run PowerShell as Administrator or set SPOTBLOCK_INSTALL_DIR."
  }

  if ($PSCommandPath -and ([IO.Path]::GetFullPath($PSCommandPath) -eq [IO.Path]::GetFullPath($target))) {
    Write-Output "SpotBlock is already at $target."
  } elseif ($PSCommandPath) {
    Write-Output "Installing $PSCommandPath to $target..."
    Copy-Item -LiteralPath $PSCommandPath -Destination $target -Force
  } else {
    Write-Output "Downloading SpotBlock to $target..."
    Invoke-WebRequest -UseBasicParsing -Uri $SourceUrl -OutFile $target
  }
  Add-InstallPath $binDir
  Write-Output 'SpotBlock installed successfully.'

  if ($env:SPOTBLOCK_RUN_AFTER_INSTALL -eq '0') {
    Write-Output 'Skipping automatic block run because SPOTBLOCK_RUN_AFTER_INSTALL=0.'
    return
  }

  Write-Output 'Running SpotBlock...'
  Invoke-Block
  Write-Output "Done. Use 'spotblock status' to check ad blocking status."
}

# Run without a command through Invoke-Expression (irm ... | iex), the script installs itself.
if (-not $Command -and -not $PSCommandPath) { $Command = 'install' }

try {
  switch ($Command) {
    'install' { Install-SpotBlock }
    'block' { Invoke-Block }
    'restore' { Invoke-Restore }
    'status' { Show-Status }
    'clear-cache' { Clear-SpotifyCache }
    default {
      if ($Command) { [Console]::Error.WriteLine("Error: Invalid argument '$Command'") }
      Show-Usage
      if ($PSCommandPath) { exit 1 }
    }
  }
} catch {
  [Console]::Error.WriteLine("Error: $($_.Exception.Message)")
  # exit would close the window when run through Invoke-Expression.
  if ($PSCommandPath) { exit 1 }
}
