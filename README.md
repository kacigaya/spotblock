<p align="center">
  <img src="spotblock-logo.svg" alt="Logo" width="200">
</p>

<h1 align="center">SpotBlock</h1>

<p align="center">
   <strong>Spotify Ad Blocker</strong><br>
   <em>A cross-platform Bash script that blocks Spotify ads by modifying your system's `hosts` file.</em>
</p>

## Installation  

### Prerequisites
- macOS: no additional requirements
- Windows: install [Git Bash](https://git-scm.com/download/win)

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

Run `sudo spotblock <command>` on macOS. On Windows, run Git Bash as administrator and use `spotblock <command>`.

| Command | Description |
| --- | --- |
| `block` | Block Spotify ads |
| `restore` | Restore the original hosts file |
| `status` | Check ad blocking status |
| `clear-cache` | Clear Spotify cache |

Before installing, use `sudo ./spotblock.sh <command>` on macOS or `./spotblock.sh <command>` on Windows.

## How it works

SpotBlock modifies the system's hosts file:
- macOS: `/etc/hosts`
- Windows: `C:\Windows\System32\drivers\etc\hosts`

This prevents ads from loading while you enjoy your music.

## Important notes

Automatic backup: the script creates a backup of the `hosts` file before making changes.
Restart required: restart Spotify after blocking ads so the hosts changes take effect.
Cache clearing: if ads persist, try clearing the cache with the `clear-cache` command.
Updates needed: Spotify may change its ad domains, so the blocklist may need periodic updates.

## Disclaimer  

This script is provided for educational purposes only. Modifying system files may have unintended consequences. Use it at your own risk.
Spotify may update its system to bypass this method, so effectiveness may vary over time.

## License  

MIT License. Open-source project, free to use and modify.
