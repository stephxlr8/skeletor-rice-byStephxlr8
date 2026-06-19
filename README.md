# Skeletor Rice

A skeletor goth/dark rice made by me — a gothic metallic-glass desktop for
**Hyprland** on Arch Linux: frosted-glass Quickshell widgets, a glossy Waybar,
and wallpaper-tinted rofi menus for Wi-Fi, Bluetooth and display switching.

Tested on an ASUS laptop (AMD GPU, eDP-1 @ 1920x1200, Hyprland 0.55).
Srry for some bugs lol.(if u find a lot of it, tell me pls)

<img width="1400" height="700" alt="image" src="https://github.com/user-attachments/assets/8bac9bb6-f08c-4054-8f5b-70c11d1ceb6d" />


## What's inside

| Path | What it is |
|------|------------|
| `.config/hypr/` | Hyprland config, hyprpaper, and the `wifi-menu` / `display-menu` scripts |
| `.config/waybar/` | Glossy glass bottom bar (`config.jsonc` + `style.css`) |
| `.config/quickshell/` | Floating gothic widgets (clock, folders, media player) |
| `.config/rofi/` | Wallpaper-tinted glass themes for the menus |
| `wallpaper/` | The wallpaper |

## Dependencies

```
hyprland hyprpaper waybar quickshell rofi
networkmanager bluez bluez-utils         # nmcli + bluetoothctl menus
wireplumber pavucontrol playerctl        # audio + media widget
brightnessctl jq libnotify               # backlight, scripts, notifications
kitty dolphin htop                       # terminal, file manager, sysmenu
noto-fonts ttf-nerd-fonts-symbols-mono   # text + glyph fonts
```

Enable the services once: `systemctl enable --now NetworkManager bluetooth`.

## Install

```bash
git clone https://github.com/stephxlr8/skeletor-rice-byStephxlr8.git
cd skeletor-rice-byStephxlr8

# 1. copy the configs
cp -r .config/* ~/.config/

# 2. make the scripts executable
chmod +x ~/.config/hypr/scripts/*.sh

# 3. place the wallpaper where the configs expect it
mkdir -p ~/Pictures
cp wallpaper/skeletor-wallpaper.png ~/Pictures/
```

> **Note on paths:** the wallpaper is referenced by an absolute path in
> `.config/hypr/hyprland.conf` and `.config/hypr/hyprpaper.conf`
> (`/home/stephxlr8/Pictures/3c3b1105-...png`). If your username isn't
> `stephxlr8`, or you renamed the file, edit those two files to point at your
> own wallpaper path.

Then log into Hyprland (or `hyprctl reload`).

## Usage

- **Waybar (bottom):** workspaces left; system tray, network, audio, battery,
  backlight, temperature, clock and a power button on the right.
- **Click the network icon** → glass menu: Wi-Fi (toggle / scan / connect, asks
  for a password when needed) plus a Bluetooth submenu (toggle / scan / connect).
- **F7** (or `Super+O`) → display switcher: mirror / extend / single output.
- **Temperature icon** → floating `htop` mini-menu.
- Function keys: volume, mic-mute, screen + keyboard backlight.

## License

MIT — do whatever you want.


## *Others distros*

i made this on arch but a want it to migrate to NixOS because the vulnerabilitys so if u find this rn, u can wait some wekes for the NixOS version 


