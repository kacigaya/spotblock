#!/bin/bash

# SpotBlock - Spotify Ad Blocker Script
# This script modifies the hosts file to block Spotify advertisements

SPOTBLOCK_SOURCE_URL="${SPOTBLOCK_SOURCE_URL:-https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.sh}"
SPOTBLOCK_RUN_AFTER_INSTALL="${SPOTBLOCK_RUN_AFTER_INSTALL:-1}"

# Error handling
set -e
set -o pipefail
trap 'echo "Error occurred. Exiting..." >&2' ERR

# Platform detection
IsWindows() {
  [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]
}

NeedCommand() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: '$1' is required but was not found." >&2
    exit 1
  fi
}

SelectInstallDir() {
  if [ -n "${SPOTBLOCK_INSTALL_DIR:-}" ]; then
    echo "$SPOTBLOCK_INSTALL_DIR"
    return
  fi

  if IsWindows; then
    if [ -w "/usr/local/bin" ]; then
      echo "/usr/local/bin"
    else
      echo "$HOME/bin"
    fi
    return
  fi

  echo "/usr/local/bin"
}

InstallSpotBlock() {
  NeedCommand curl
  NeedCommand mktemp

  local install_dir
  install_dir="$(SelectInstallDir)"
  local install_path="$install_dir/spotblock"
  local temp_file

  temp_file="$(mktemp)"
  trap 'rm -f "$temp_file"' EXIT

  echo "Downloading SpotBlock..."
  curl -fsSL "$SPOTBLOCK_SOURCE_URL" -o "$temp_file"

  echo "Installing SpotBlock to $install_path..."

  if [ -d "$install_dir" ] && [ -w "$install_dir" ]; then
    cp "$temp_file" "$install_path"
    chmod +x "$install_path"
  elif IsWindows; then
    mkdir -p "$install_dir"
    echo "Error: $install_dir is not writable. Run Git Bash as administrator or set SPOTBLOCK_INSTALL_DIR." >&2
    exit 1
  else
    sudo mkdir -p "$install_dir"
    sudo cp "$temp_file" "$install_path"
    sudo chmod +x "$install_path"
  fi

  echo "SpotBlock installed successfully."

  if [ "$SPOTBLOCK_RUN_AFTER_INSTALL" = "0" ]; then
    echo "Skipping automatic block run because SPOTBLOCK_RUN_AFTER_INSTALL=0."
    return
  fi

  echo "Running SpotBlock..."
  if IsWindows; then
    "$install_path" block
  else
    sudo "$install_path" block
  fi

  echo "Done. Use 'spotblock status' to check ad blocking status."
}

ShowUsage() {
  echo "Usage: $0 [install|block|restore|status|clear-cache]" >&2
  echo "  install     - Install SpotBlock as a system command and run the blocker" >&2
  echo "  block       - Block Spotify ads by modifying hosts file" >&2
  echo "  restore     - Restore hosts file from backup" >&2
  echo "  status      - Show current Spotify and ad blocking status" >&2
  echo "  clear-cache - Clear Spotify cache directory" >&2
}

ShouldInstallFromPipe() {
  [ -z "$1" ] && [[ "$(basename "$0")" == "bash" || "$(basename "$0")" == "sh" ]]
}

# Function to get hosts file location
GetHostsFile() {
  if IsWindows; then
    echo "/c/Windows/System32/drivers/etc/hosts"
  else
    echo "/etc/hosts"
  fi
}

# Function to check if Spotify is running
IsSpotifyRunning() {
  if IsWindows; then
    tasklist | grep -i "Spotify.exe" >/dev/null
  else
    pgrep -x "Spotify" >/dev/null
  fi
}

BlockSpotifyAds() {
  local hosts_file
  hosts_file=$(GetHostsFile)

  local spotify_prefs
  if IsWindows; then
    spotify_prefs="$APPDATA/Spotify/prefs"
  else
    spotify_prefs="$HOME/Library/Application Support/Spotify/prefs"
  fi

  # hosts entries match exact names only; wildcards have no effect.
  local ad_domains=(
    # Core Ad Services
    "pagead2.googlesyndication.com"
    "gads.pubmatic.com"
    "securepubads.g.doubleclick.net"

    # Spotify Specific Ad Services
    "spotify-heads-ak.akamaized.net"
    "heads-fab.spotify.com"
    "heads4-ak.spotify.com"
    "heads4-fa.spotify.com"
    "heads-cf.spotify.com"
  )

  local spotify_prefs_entries=(
    "app.browser.smoothscroll=false"
    "ui.show_ads=false"
    "app.player.autoplay=false"
    "browser.integration.show_download_button=false"
    "ui.promo_enabled=false"
    "audio.play_bitrate_enumeration=0"
    "ui.track_notifications_enabled=false"
    "audio.normalize_v2=false"
    "audio.gapless_playback=false"
    "ui.animated_artwork=false"
    "ui.show_friend_feed=false"
  )

  # Fail before any change if hosts cannot be opened for writing.
  if ! : 2>/dev/null >>"$hosts_file"; then
    if IsWindows; then
      echo "Error: cannot write $hosts_file. Run Git Bash as administrator." >&2
    else
      echo "Error: cannot write $hosts_file." >&2
    fi
    exit 1
  fi

  # Spotify rewrites prefs on exit, which would drop entries added while it runs.
  if [ -f "$spotify_prefs" ] && IsSpotifyRunning; then
    echo "Spotify is running; skipping prefs changes. Close Spotify and run block again to apply them." >&2
  elif [ -f "$spotify_prefs" ]; then
    echo "Applying advanced blocking configurations..."
    for entry in "${spotify_prefs_entries[@]}"; do
      grep -Fq "$entry" "$spotify_prefs" || echo "$entry" >>"$spotify_prefs"
    done
  fi

  local backup_dir
  backup_dir="$HOME/.spotify_adblock_backups"
  local backup_file="$backup_dir/hosts_backup_$(date +%Y%m%d_%H%M%S)"

  # Create backup directory if it doesn't exist
  mkdir -p "$backup_dir"

  # Backup the hosts file with timestamp
  echo "Creating backup of hosts file at $backup_file"
  cp "$hosts_file" "$backup_file"

  # Add header to identify our modifications
  echo -e "\n# Spotify Ad Blocking (Added $(date))" >>"$hosts_file"

  # Add ad domains to the hosts file
  for domain in "${ad_domains[@]}"; do
    if ! grep -Fq "$domain" "$hosts_file"; then
      echo "127.0.0.1 $domain" >>"$hosts_file"
      echo "Blocking: $domain"
    fi
  done

  echo -e "\nSpotify ad blocking has been applied."
  echo "Please restart Spotify for changes to take effect."
  echo "Backup saved at: $backup_file"
}

# Function to restore the hosts file
RestoreHostsFile() {
  local backup_dir="$HOME/.spotify_adblock_backups"

  if [ ! -d "$backup_dir" ]; then
    echo "No backups found." >&2
    exit 1
  fi

  local latest_backup
  latest_backup=$(ls -t "$backup_dir"/hosts_backup_* 2>/dev/null | head -n1 || true)

  if [ -z "$latest_backup" ]; then
    echo "No backup files found in $backup_dir" >&2
    exit 1
  fi

  if [ ! -f "$latest_backup" ]; then
    echo "Error: Backup file is not a regular file" >&2
    exit 1
  fi

  if [ ! -r "$latest_backup" ]; then
    echo "Error: Backup file is not readable" >&2
    exit 1
  fi

  local backup_realpath
  backup_realpath=$(realpath "$latest_backup")
  local backup_dir_realpath
  backup_dir_realpath=$(realpath "$backup_dir")

  if [[ "$backup_realpath" != "$backup_dir_realpath"/* ]]; then
    echo "Error: Backup file is outside expected directory (possible path traversal)" >&2
    exit 1
  fi

  echo "Restoring from backup: $latest_backup"
  cp "$latest_backup" "$(GetHostsFile)"
  echo "Hosts file has been restored."
}

# Function to show current status
ShowStatus() {
  local hosts_file
  hosts_file=$(GetHostsFile)

  if IsSpotifyRunning; then
    echo "Spotify is currently running."
  else
    echo "Spotify is not running."
  fi

  # Check if any ad domains are currently blocked
  if grep -Fq "# Spotify Ad Blocking" "$hosts_file"; then
    echo "Ad blocking is currently active."
    echo "Number of blocked domains: $(grep -c "spotify" "$hosts_file")"
  else
    echo "Ad blocking is not active."
  fi
}

# Function to clear Spotify cache
ClearSpotifyCache() {
  local cache_dir
  if IsWindows; then
    cache_dir="$APPDATA/Spotify/Data"
  else
    cache_dir="$HOME/Library/Application Support/Spotify/PersistentCache"
  fi

  if [ -z "$cache_dir" ] || [[ "$cache_dir" == *..* ]]; then
    echo "Error: Invalid cache directory path" >&2
    exit 1
  fi

  if [ -d "$cache_dir" ]; then
    if [[ "$cache_dir" != "$HOME/"* && "$cache_dir" != "$APPDATA"* ]]; then
      echo "Error: Cache directory path is outside expected location" >&2
      exit 1
    fi
    echo "Clearing Spotify cache at: $cache_dir"
    rm -rf "$cache_dir"
    mkdir -p "$cache_dir"
    echo "Cache cleared successfully."
  else
    echo "Spotify cache directory not found."
  fi
}

# Main script logic

# Input validation
if ShouldInstallFromPipe "$1"; then
  InstallSpotBlock
  exit 0
fi

if [ -n "$1" ] && [[ ! "$1" =~ ^(install|block|restore|status|clear-cache)$ ]]; then
  echo "Error: Invalid argument '$1'" >&2
  ShowUsage
  exit 1
fi

if [ -z "$1" ]; then
  ShowUsage
  exit 1
fi

if [[ "$1" =~ ^(block|restore|status|clear-cache)$ ]] && ! IsWindows && [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)" >&2
  exit 1
fi

case "$1" in
"install")
  InstallSpotBlock
  ;;
"block")
  BlockSpotifyAds
  ;;
"restore")
  RestoreHostsFile
  ;;
"status")
  ShowStatus
  ;;
"clear-cache")
  ClearSpotifyCache
  ;;
esac

exit 0
