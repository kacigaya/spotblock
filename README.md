<p align="center">
  <img src="spotblock-logo.svg" alt="Logo" width="200">
</p>

<h1 align="center">SpotBlock</h1>

<p align="center">
   <strong>Spotify Ad Blocker</strong><br>
   <em>A cross-platform Bash script that blocks Spotify ads by modifying your system's `hosts` file. Works on both macOS and Windows!</em>
</p>

## Installation  

### Prerequisites
- **macOS**: No additional requirements
- **Windows**: Install [Git Bash](https://git-scm.com/download/win)

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.sh | bash
```

This installs SpotBlock as a `spotblock` command and runs the blocker.

### Manual install

```bash
git clone https://github.com/kacigaya/spotblock.git
cd spotblock
chmod +x spotblock.sh
./spotblock.sh install
```

## Usage

### On macOS:
```bash
# Block Spotify ads
sudo ./spotblock.sh block  

# Or, after the one-line install
sudo spotblock block

# Restore the original hosts file
sudo ./spotblock.sh restore  

# Or, after the one-line install
sudo spotblock restore

# Check status
sudo ./spotblock.sh status  

# Or, after the one-line install
sudo spotblock status

# Clear Spotify cache
sudo ./spotblock.sh clear-cache

# Or, after the one-line install
sudo spotblock clear-cache
```

### On Windows:
1. Right-click on Git Bash and select "Run as administrator"
2. Navigate to the script directory
3. Run the same commands as above (without sudo):
```bash
# Block Spotify ads
./spotblock.sh block  

# Or, after the one-line install
spotblock block

# Restore the original hosts file
./spotblock.sh restore  

# Or, after the one-line install
spotblock restore

# Check status
./spotblock.sh status  

# Or, after the one-line install
spotblock status

# Clear Spotify cache
./spotblock.sh clear-cache

# Or, after the one-line install
spotblock clear-cache
```

## How It Works  

**SpotBlock** modifies the system's hosts file:
- **macOS**: `/etc/hosts`
- **Windows**: `C:\Windows\System32\drivers\etc\hosts`

This prevents ads from loading while you enjoy your music.  

## Important Notes  

**Automatic backup** : The script **creates a backup** of the `hosts` file before making any changes.  
**Restart required** : After blocking ads, **Spotify must be restarted** for the changes to take effect.  
**Cache clearing** : If ads persist, try clearing the cache with the `clear-cache` command.  
**Updates needed** : Spotify may change its ad domains, so periodic **updates** to the blocklist may be required.  

## Disclaimer  

**This script is provided for educational purposes only.** Modifying system files may have unintended consequences. **Use at your own risk.**  
**Spotify may update its system to bypass this method,** so effectiveness may vary over time.  

## License  

**MIT License** - Open-source project, free to use and modify.
