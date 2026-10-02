<p align="center">
  <img src="spotblock-logo.svg" alt="SpotBlock logo" width="140">
</p>

<h1 align="center">SpotBlock</h1>

<p align="center">
   <strong>Spotify ad blocker for macOS, Linux, and Windows.</strong><br>
   <em>A Bash script, with a PowerShell version for Windows, that blocks ad domains through your system's <code>hosts</code> file.</em>
</p>

<p align="center">
  <a href="https://www.gnu.org/software/bash/"><img alt="Bash" src="https://shieldcn.dev/badge/Bash-script-4eaa25.svg?variant=secondary&amp;logo=gnubash"></a>
  <a href="https://www.spotify.com/download"><img alt="Spotify desktop" src="https://shieldcn.dev/badge/Spotify-desktop-1db954.svg?variant=secondary&amp;logo=spotify"></a>
  <img alt="macOS supported" src="https://shieldcn.dev/badge/macOS-supported-171717.svg?variant=secondary&amp;logo=apple">
  <img alt="Linux supported" src="https://shieldcn.dev/badge/Linux-supported-171717.svg?variant=secondary&amp;logo=linux">
  <img alt="Windows supported" src="https://shieldcn.dev/badge/Windows-supported-0078d4.svg?variant=secondary&amp;logo=windows">
  <a href="https://github.com/kacigaya/spotblock/blob/main/LICENSE"><img alt="MIT License" src="https://shieldcn.dev/github/license/kacigaya/spotblock.svg?variant=secondary"></a>
</p>

## Features

- Blocks a short list of known ad domains through the `hosts` file
- Adds ad and promo entries to Spotify's `prefs` file when it exists and Spotify is closed
- Backs up the `hosts` file before every change and restores the newest backup in one command
- Clears the Spotify cache when old ads persist
- Installs as a `spotblock` command with one `curl` or PowerShell line
- Needs only Bash and standard system tools, or Windows PowerShell 5.1 or later on Windows

> [!IMPORTANT]
> Blocking is partial. Most Spotify audio ads are served from the same API hosts that deliver music, and blocking those breaks playback. SpotBlock only blocks separate ad hosts, so some ads will still play.

## Installation

### Prerequisites

| Platform | Requirement |
| --- | --- |
| macOS | None |
| Linux | None |
| Windows (PowerShell) | None. Run PowerShell as Administrator. |
| Windows (Git Bash) | [Git Bash](https://git-scm.com/download/win), run as Administrator |

### One-line install

On macOS, Linux, or Git Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.sh | bash
```

On Windows, in PowerShell run as Administrator:

```powershell
irm https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.ps1 | iex
```

Both install SpotBlock as a `spotblock` command and run `block`. The PowerShell version installs to `C:\Program Files\SpotBlock` and adds its `bin` folder to the system `Path`. Open a new terminal to use `spotblock`.

To read the script before running it:

```bash
curl -fsSLO https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.sh
less spotblock.sh
bash spotblock.sh install
```

```powershell
irm https://raw.githubusercontent.com/kacigaya/spotblock/main/spotblock.ps1 -OutFile spotblock.ps1
notepad spotblock.ps1
powershell -ExecutionPolicy Bypass -File .\spotblock.ps1 install
```

### Manual install

```bash
git clone https://github.com/kacigaya/spotblock.git
cd spotblock
chmod +x spotblock.sh
./spotblock.sh install
```

The Bash `install` downloads the script again from `main` instead of copying your local file. To run exactly the file you read without installing it, use `sudo ./spotblock.sh <command>` on macOS and Linux, or `./spotblock.sh <command>` in Git Bash. The PowerShell `install` copies the local file when run from one.

### Install options

| Variable | Default | Effect |
| --- | --- | --- |
| `SPOTBLOCK_INSTALL_DIR` | `/usr/local/bin`, or `C:\Program Files\SpotBlock` for PowerShell | Where the `spotblock` command is installed. In Git Bash, falls back to `~/bin` when `/usr/local/bin` is not writable. In PowerShell, a folder you can write without Administrator rights goes on the user `Path`. |
| `SPOTBLOCK_RUN_AFTER_INSTALL` | `1` | Set to `0` to install without running the blocker. |

In PowerShell, set a variable with `$env:SPOTBLOCK_RUN_AFTER_INSTALL = '0'` before installing.

## Usage

On macOS and Linux, run `sudo spotblock <command>`. On Windows, open PowerShell or Git Bash as Administrator and run `spotblock <command>`.

| Command | Description |
| --- | --- |
| `block` | Add the ad domains to `hosts` and the entries to `prefs` |
| `restore` | Copy the newest `hosts` backup back over `hosts` |
| `status` | Show whether Spotify is running and whether the SpotBlock header is in `hosts` |
| `clear-cache` | Delete the contents of the Spotify cache directory |

Sample output from a test run with a fake `hosts` file:

```console
$ sudo spotblock block
Applying advanced blocking configurations...
Creating backup of hosts file at /home/you/.spotify_adblock_backups/hosts_backup_20261002_143005
Blocking: pagead2.googlesyndication.com
Blocking: gads.pubmatic.com
Blocking: securepubads.g.doubleclick.net
Blocking: spotify-heads-ak.akamaized.net
Blocking: heads-fab.spotify.com
Blocking: heads4-ak.spotify.com
Blocking: heads4-fa.spotify.com
Blocking: heads-cf.spotify.com

Spotify ad blocking has been applied.
Please restart Spotify for changes to take effect.
Backup saved at: /home/you/.spotify_adblock_backups/hosts_backup_20261002_143005
$ sudo spotblock status
Spotify is not running.
Ad blocking is currently active.
Number of blocked domains: 5
```

## How it works

`block` first checks that the `hosts` file is writable and stops without changing anything if it isn't. It then saves a timestamped copy of `hosts` to `$HOME/.spotify_adblock_backups/` and appends a `# Spotify Ad Blocking` header followed by the ad domains, each pointed to `127.0.0.1`. Domains already in the file are skipped. The PowerShell version does not add the header when every domain is already there.

`$HOME` is the home directory as seen by the script. Under `sudo` it can be root's home instead of yours, depending on sudo settings. Most Linux systems use `/root`. The PowerShell version uses `%USERPROFILE%\.spotify_adblock_backups`.

| Platform | Hosts file |
| --- | --- |
| macOS, Linux | `/etc/hosts` |
| Windows | `%SystemRoot%\System32\drivers\etc\hosts`, usually `C:\Windows\System32\drivers\etc\hosts` |

The list holds three ad network hosts (`googlesyndication.com`, `pubmatic.com`, `doubleclick.net`) and five Spotify `heads` ad hosts. A `hosts` file matches exact hostnames only, so wildcards are not supported.

If a `prefs` file exists and Spotify is closed, `block` also appends entries such as `ui.show_ads=false` and `ui.promo_enabled=false`. These keys come from community lists, not from Spotify documentation, and current clients may ignore them. The list also turns off autoplay, gapless playback, and volume normalization. The `prefs` file is not backed up.

| Platform | Prefs file |
| --- | --- |
| macOS | `~/Library/Application Support/Spotify/prefs` |
| Linux | `~/.config/spotify/prefs`, or `~/.var/app/com.spotify.Client/config/spotify/prefs` for Flatpak when the first is missing |
| Windows | `%APPDATA%\Spotify\prefs` |

`clear-cache` empties the Spotify cache directory and keeps the directory itself.

| Platform | Cache directory |
| --- | --- |
| macOS | `~/Library/Application Support/Spotify/PersistentCache` |
| Linux | `~/.cache/spotify` and `~/.var/app/com.spotify.Client/cache/spotify` (Flatpak) |
| Windows | `%APPDATA%\Spotify\Data` |

On Linux, `~` in these paths is the home directory of the user who ran `sudo`, not `/root`.

> [!NOTE]
> Restart Spotify after blocking so the `hosts` changes take effect. If ads persist, run `clear-cache` and restart again.

> [!WARNING]
> Spotify may change its ad domains at any time, so the blocklist can need updates and results may vary.

## Troubleshooting

- **`prefs` changes don't stick.** Spotify rewrites `prefs` when it exits, so entries added while it runs are lost. `block` skips `prefs` while Spotify is running and says so. Quit Spotify fully, including from the tray or menu bar, then run `block` again.
- **`block` fails on Windows with `cannot write`.** Editing `hosts` needs Administrator rights. Close PowerShell or Git Bash, reopen it with **Run as administrator**, and run `block` again.
- **`running scripts is disabled on this system`.** Windows blocks `.ps1` files by default. Use the installed `spotblock` command, which runs the script with `-ExecutionPolicy Bypass`, or run `powershell -ExecutionPolicy Bypass -File .\spotblock.ps1 <command>`.
- **`spotblock` is not found after installing on Windows.** Open a new terminal so it picks up the updated `Path`.
- **Microsoft Store version of Spotify.** It keeps `prefs` under `%LOCALAPPDATA%\Packages\SpotifyAB.SpotifyMusic_*\LocalState\Spotify\prefs`, which SpotBlock does not handle. `hosts` blocking still applies.
- **Snap version of Spotify on Linux.** SpotBlock does not handle the Snap `prefs` or cache paths. A custom `XDG_CONFIG_HOME` is also ignored.
- **`status` says active but nothing changed.** `status` only checks for the `# Spotify Ad Blocking` header in `hosts`. It does not check each domain or whether Spotify uses them. In the Bash version, the domain count is the number of lines containing `spotify`, so it shows 5 when all 8 domains are blocked. The PowerShell version counts the listed domains found in `hosts`.
- **No `Spotify.exe.bak` file.** SpotBlock never patches `Spotify.exe`, so no `.bak` file is created.

## Uninstall

### macOS, Linux, and Git Bash

1. Restore `hosts`:

   ```bash
   sudo spotblock restore    # on Windows, run without sudo in an Administrator Git Bash
   ```

2. Remove the command. Use `command -v spotblock` to find it if you set `SPOTBLOCK_INSTALL_DIR`.

   ```bash
   sudo rm /usr/local/bin/spotblock    # macOS, Linux
   rm -f /usr/local/bin/spotblock ~/bin/spotblock    # Windows
   ```

3. Optionally, delete the backups. On macOS and Linux, run this through `sudo` so `$HOME` matches the one used by `block`. On Windows, run `rm -rf ~/.spotify_adblock_backups`.

   ```bash
   sudo sh -c 'rm -rf "$HOME/.spotify_adblock_backups"'
   ```

### PowerShell

Run these in PowerShell as Administrator:

```powershell
spotblock restore
Remove-Item -Recurse "$env:ProgramFiles\SpotBlock"
Remove-Item -Recurse "$HOME\.spotify_adblock_backups"    # optional
```

Then remove `C:\Program Files\SpotBlock\bin` from the system `Path` under **System Properties > Environment Variables**.

### Notes

`restore` copies the newest backup, which was taken before the last `block` run. If you ran `block` more than once, that backup already contains SpotBlock entries. Delete the lines from the first `# Spotify Ad Blocking` header to the end of `hosts`, or copy the oldest backup instead. `restore` does not touch `prefs`. Remove the added entries by hand while Spotify is closed.

## Contributing and support

- To suggest a domain, open a pull request that adds it to `ad_domains` in [`spotblock.sh`](spotblock.sh) and `$AdDomains` in [`spotblock.ps1`](spotblock.ps1), and explain how you confirmed it serves ads without breaking playback.
- Ask questions in [Discussions Q&A](https://github.com/kacigaya/spotblock/discussions/categories/q-a).
- Report bugs in [Issues](https://github.com/kacigaya/spotblock/issues).

## Disclaimer

This script is provided for educational purposes only. Modifying system files may have unintended consequences. Use it at your own risk.

Blocking ads may violate [Spotify's Terms of Use](https://www.spotify.com/legal/end-user-agreement/). You are responsible for how you use this script.

## License

[MIT](LICENSE)
