# SpotBlock - Spotify Ad Blocker  

A **cross-platform Bash script** that **blocks Spotify ads** by modifying your system's `hosts` file. Works on both macOS and Windows!

# ![Spotify Logo](https://upload.wikimedia.org/wikipedia/commons/2/26/Spotify_logo_with_text.svg)  
## Installation  

### Prerequisites
- **macOS**: No additional requirements
- **Windows**: Install [Git Bash](https://git-scm.com/download/win)

### Steps
1 - **Clone the repository** 📂  
2 - **Make the script executable**:  
   ```bash
   chmod +x spotblock.sh
   ```

## Usage

### On macOS:
```bash
# Block Spotify ads
sudo ./spotblock.sh block  

# Restore the original hosts file
sudo ./spotblock.sh restore  

# Check status
sudo ./spotblock.sh status  

# Clear Spotify cache
sudo ./spotblock.sh clear-cache
```

### On Windows:
1. Right-click on Git Bash and select "Run as administrator"
2. Navigate to the script directory
3. Run the same commands as above (without sudo):
```bash
# Block Spotify ads
./spotblock.sh block  

# Restore the original hosts file
./spotblock.sh restore  

# Check status
./spotblock.sh status  

# Clear Spotify cache
./spotblock.sh clear-cache
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
