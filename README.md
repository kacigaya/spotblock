<p align="center">
  <img src="spotblock-logo.svg" alt="SpotBlock logo" width="140">
</p>

<h1 align="center">SpotBlock</h1>

<p align="center">
   <strong>Spotify ad blocker for macOS and Windows.</strong><br>
   <em>A single Bash script that blocks ad domains through your system's <code>hosts</code> file.</em>
</p>

<p align="center">
  <a href="https://www.gnu.org/software/bash/"><img alt="Bash" src="https://shieldcn.dev/badge/Bash-script-4eaa25.svg?variant=secondary&amp;logo=gnubash"></a>
  <a href="https://www.spotify.com/download"><img alt="Spotify desktop" src="https://shieldcn.dev/badge/Spotify-desktop-1db954.svg?variant=secondary&amp;logo=spotify"></a>
  <img alt="macOS supported" src="https://shieldcn.dev/badge/macOS-supported-171717.svg?variant=secondary&amp;logo=apple">
  <a href="https://git-scm.com/download/win"><img alt="Windows via Git Bash" src="https://shieldcn.dev/badge/Windows-Git_Bash-0078d4.svg?variant=secondary&amp;logo=windows"></a>
  <a href="https://github.com/kacigaya/spotblock/blob/main/LICENSE"><img alt="MIT License" src="https://shieldcn.dev/github/license/kacigaya/spotblock.svg?variant=secondary"></a>
</p>

## Features

- Blocks Spotify ad and tracking domains through the `hosts` file
- Disables promo and ad settings in Spotify's `prefs` file when present
- Backs up the `hosts` file before every change and restores it in one command
- Clears the Spotify cache when old ads persist
- Installs as a `spotblock` command with a single `curl` line
- No dependencies beyond Bash and `curl`

## Installation

### Prerequisites

| Platform | Requirement |
| --- | --- |
| macOS | None |
| Windows | [Git Bash](https://git-scm.com/download/win), run as administrator |

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

### Install options

| Variable | Default | Effect |
| --- | --- | --- |
| `SPOTBLOCK_INSTALL_DIR` | `/usr/local/bin` | Where the `spotblock` command is installed. On Windows, falls back to `~/bin` when `/usr/local/bin` is not writable. |
| `SPOTBLOCK_RUN_AFTER_INSTALL` | `1` | Set to `0` to install without running the blocker. |

## Usage

On macOS, run `sudo spotblock <command>`. On Windows, open Git Bash as administrator and run `spotblock <command>`.

| Command | Description |
| --- | --- |
| `block` | Block Spotify ads |
| `restore` | Restore the most recent `hosts` backup |
| `status` | Check whether Spotify is running and ad blocking is active |
| `clear-cache` | Clear the Spotify cache |

Before installing, use `sudo ./spotblock.sh <command>` on macOS or `./spotblock.sh <command>` on Windows.

## How it works

`block` points known ad domains to `127.0.0.1` in the system `hosts` file, so Spotify cannot load them:

| Platform | Hosts file |
| --- | --- |
| macOS | `/etc/hosts` |
| Windows | `C:\Windows\System32\drivers\etc\hosts` |

Each run saves a timestamped copy of the `hosts` file to `~/.spotify_adblock_backups/` first. `restore` copies the newest backup back.

> [!NOTE]
> Restart Spotify after blocking so the `hosts` changes take effect. If ads persist, run `clear-cache` and restart again.

> [!WARNING]
> Spotify may change its ad domains at any time, so the blocklist can need updates and results may vary.

## Disclaimer

This script is provided for educational purposes only. Modifying system files may have unintended consequences. Use it at your own risk.

## License

[MIT](LICENSE)
