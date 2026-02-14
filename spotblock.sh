#!/bin/bash

# SpotBlock - Spotify Ad Blocker Script
# This script modifies the hosts file to block Spotify advertisements

# Spotify app bundle identifier
SPOTIFY_BUNDLE_ID="com.spotify.client"

# Error handling
set -e
set -o pipefail
trap 'echo "Error occurred. Exiting..." >&2' ERR

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)" >&2
  exit 1
fi

# Platform detection
IsWindows() {
  [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]
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

# Function to skip audio ads
SkipAudioAds() {
  # Add more aggressive audio ad domains
  local audio_ad_domains=(
    "audio-ak-spotify-com.akamaized.net"
    "audio-fa.spotifycdn.com"
    "audio-ak.spotify.com.edgesuite.net"
    "heads-ak.spotify.com"
    "audio-sp-*.pscdn.co"
    "audio-sp-*.spotifycdn.net"
    "audio-sp-*.spotify.map.fastly.net"
    "audio-sp-*.spotify.com.edgesuite.net"
    "audio-sp.spotify.com.akamaized.net"
    "audio-fa.scdn.co"
    "audio-sp.scdn.co"
    "audio-akp.scdn.co"
    "pubads.g.doubleclick.net"
    "googleads.g.doubleclick.net"
    "ads.spotify.com"
    "audio-sp-*.spotify.com"
    "audio-fa.spotify.com"
    "heads-fa.spotify.com"
    "heads4.spotify.com"
    "media-match.com"
    "omaze.com"
    "analytics.spotify.com"
    "log.spotify.com"
    "pixel.spotify.com"
    "pixel-static.spotify.com"
    "crashdump.spotify.com"
    "audio-ak.spotify.com"
    "audio-akp-*.spotify.com"
    "audio-cf.spotify.com"
    "audio-gc.scdn.co"
    "promoted.spotify.com"
    "ad.spotify.com"
    "adstudio.spotify.com"

  )

  # Additional blocking for audio ads
  if IsWindows; then
    local spotify_prefs="$APPDATA/Spotify/prefs"
  else
    local spotify_prefs="$HOME/Library/Application Support/Spotify/prefs"
  fi

  # Enhanced Spotify preferences modifications
  if [ -f "$spotify_prefs" ]; then
    echo "Optimizing Spotify preferences..."
    echo "audio.play_bitrate_enumeration=0" >>"$spotify_prefs"
    echo "ui.track_notifications_enabled=false" >>"$spotify_prefs"
    echo "audio.normalize_v2=false" >>"$spotify_prefs"
    echo "audio.gapless_playback=false" >>"$spotify_prefs"
    echo "ui.animated_artwork=false" >>"$spotify_prefs"
    echo "ui.show_friend_feed=false" >>"$spotify_prefs"
  fi
}

# Function to modify Spotify binary
ModifySpotifyBinary() {
  local spotify_path
  if IsWindows; then
    spotify_path="$APPDATA/Spotify/Spotify.exe"
  else
    spotify_path="/Applications/Spotify.app/Contents/MacOS/Spotify"
  fi

  if [ -f "$spotify_path" ]; then
    echo "Creating backup of Spotify binary..."
    cp "$spotify_path" "${spotify_path}.backup"

    if [[ "$OSTYPE" == "darwin"* ]]; then
      # Add SpotBlock signature
      perl -pi -e 's/Spotify/SpotBlock by Gaya KACI/g' "$spotify_path"

      # Enhanced binary modifications
      perl -pi -e 's/audio-sp-.+?\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/audio-.+?\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/heads-.+?\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/audio-.+?\.scdn\.co/localhost/g' "$spotify_path"
      perl -pi -e 's/\.spotify\.com:443/localhost:1/g' "$spotify_path"
      perl -pi -e 's/\.spotifycdn\.net:443/localhost:1/g' "$spotify_path"
      perl -pi -e 's/\.spotify\.com:4070/localhost:1/g' "$spotify_path"
      perl -pi -e 's/spotify\.map\.fastly\.net/localhost/g' "$spotify_path"
      perl -pi -e 's/spclient\.wg\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/upgrade\.spotify\.com/localhost/g' "$spotify_path"

      # Advanced ad blocking patterns
      perl -pi -e 's/spotify:ad:[0-9a-zA-Z]+/spotify:track:blocked/g' "$spotify_path"
      perl -pi -e 's/com\.spotify\.ads/com.spotify.blocked/g' "$spotify_path"
      perl -pi -e 's/ad-logic\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/adclick\.g\.doubleclick\.net/localhost/g' "$spotify_path"
      perl -pi -e 's/adeventtracker\.spotify\.com/localhost/g' "$spotify_path"

      # Premium feature unlocking
      perl -pi -e 's/premium-www\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/\.spotify\.com\/premium/localhost\/blocked/g' "$spotify_path"
      perl -pi -e 's/spotify:app:premium/spotify:app:free/g' "$spotify_path"

      # Disable tracking and analytics
      perl -pi -e 's/analytics\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/log\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/pixel\.spotify\.com/localhost/g' "$spotify_path"
      perl -pi -e 's/metric\.spotify\.com/localhost/g' "$spotify_path"

      echo "Advanced binary modifications applied successfully."
    fi
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

  # Add new advanced blocking domains
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

    # Binary Patterns
    "*.spotify.map.fastly.net"
    "*.spotify.com.edgesuite.net"
    "*.spotify.com.akamaized.net"
    "*.spotifycdn.map.fastly.net"
    "*.audio-ak-spotify-com.akamaized.net"

    # Rest of existing domains...
  )

  # Enhanced Spotify preferences
  if [ -f "$spotify_prefs" ]; then
    echo "Applying advanced blocking configurations..."
    echo "app.browser.smoothscroll=false" >>"$spotify_prefs"
    echo "ui.show_ads=false" >>"$spotify_prefs"
    echo "app.player.autoplay=false" >>"$spotify_prefs"
    echo "browser.integration.show_download_button=false" >>"$spotify_prefs"
    echo "ui.promo_enabled=false" >>"$spotify_prefs"
    echo "audio.play_bitrate_enumeration=0" >>"$spotify_prefs"
    echo "ui.track_notifications_enabled=false" >>"$spotify_prefs"
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
    if ! grep -q "$domain" "$hosts_file"; then
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

  # Get the most recent backup
  local latest_backup
  latest_backup=$(find "$backup_dir" -maxdepth 1 -name 'hosts_backup_*' -type f -printf '%T@ %p\n' 2>/dev/null | sort -t' ' -k1 -n | tail -n1 | cut -d' ' -f2-)

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
  cp "$latest_backup" "/etc/hosts"
  echo "Hosts file has been restored."
}

# Function to show current status
ShowStatus() {
  if IsSpotifyRunning; then
    echo "Spotify is currently running."
  else
    echo "Spotify is not running."
  fi

  # Check if any ad domains are currently blocked
  if grep -q "# Spotify Ad Blocking" "/etc/hosts"; then
    echo "Ad blocking is currently active."
    echo "Number of blocked domains: $(grep -c "spotify" "/etc/hosts")"
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
if [ -n "$1" ] && [[ ! "$1" =~ ^(block|restore|status|clear-cache)$ ]]; then
  echo "Error: Invalid argument '$1'" >&2
  echo "Usage: $0 [block|restore|status|clear-cache]" >&2
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 [block|restore|status|clear-cache]" >&2
  echo "  block       - Block Spotify ads by modifying hosts file" >&2
  echo "  restore     - Restore hosts file from backup" >&2
  echo "  status      - Show current Spotify and ad blocking status" >&2
  echo "  clear-cache - Clear Spotify cache directory" >&2
  exit 1
fi

case "$1" in
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
