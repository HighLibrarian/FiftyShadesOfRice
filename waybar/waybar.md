# Waybar Setup Reference

Purpose: quick memory aid for what I installed and what I configured.

## Files in use

- `config.jsonc`
- `style.css`
- `colors/gruvbox-material.css`
- `scripts/launch.sh`

## What I installed/used

- `waybar`: this bar
- `hyprland`: desktop environment
- `swaync` and `swaync-client`: notification service
- `pavucontrol`: volumecontrol screen
- `adwaita-network`: wifi manager
- `rofi` (power menu script at `~/.config/rofi/powermenu/power-menu.sh`)
- `libnotify` (`notify-send`)
- Nerd Font for icons

## Bar layout configured

- Layer: `top`
- Width: `1000`
- Height: `15`

Modules configured:

- Left: `clock`, `pulseaudio`
- Center: `hyprland/workspaces`
- Right: `battery`, `network`, `custom/notification`, `custom/power`

## Module settings I configured

### clock

- Format: `{:%H:%M}`
- Alt format: `{:%A, %d %B %Y [W%V]}`
- Click action: `waybar -m clock toggle-format`

### pulseaudio

- Format: icon + volume
- Bluetooth format enabled
- Muted format set
- Scroll step: `1`
- Click action: `pavucontrol`
- Ignored sink: `Easy Effects Sink`

### hyprland/workspaces

- Format: `{icon}`
- Click action: `activate`
- Workspace icons: `1` to `5`
- Persistent workspaces: `5` per monitor (`"*": 5`)

### battery

- Interval: `60`
- Format: icon + capacity
- Custom icon ramps for default and charging states

### network

- Wi-Fi format: icon + signal percent
- Wi-Fi tooltip shows ESSID, signal, and IP
- Ethernet format: connected icon/text
- Disconnected format: offline warning
- Click action: `adwaita-network`

### custom/notification

- Return type: `json`
- Run only if available: `which swaync-client`
- Exec: `swaync-client -swb`
- Left click: `swaync-client -t -sw`
- Right click: `swaync-client -d -sw`
- Uses icon map for notification/DND/inhibited states

### custom/power

- Format: power icon
- Click action: `~/.config/rofi/powermenu/power-menu.sh;`

## Style choices configured

- Imports `colors/gruvbox-material.css`
- Global reset: `all: unset`
- Font family: `monospace`
- Waybar background: `@bg0`
- Waybar text color: `@fg`
- Rounded bottom corners on bar and tooltips
- Workspace container uses pill shape
- Workspace buttons use `@bg4` and hidden text (`transparent`)
- Active workspace uses `@blue`
- Left module margin: `15px`
- Right module margin: `30px`
- Extra left spacing for power + notification modules

## Color palette configured

- Backgrounds: `bg0`, `bg1`, `bg2`, `bg3`, `bg4`
- Foreground: `fg`
- Accents: `red`, `orange`, `yellow`, `green`, `aqua`, `blue`, `purple`
- Grays: `grey0`, `greyl`, `grey2`

## Launch script currently configured

```bash
#!/bin/bash
pkill waybar
pkill swaync
waybar &
swaync &
swaync-client -t -sw &
notify-send "Your momma" "Is a nice lady" &
```

## Run command

```bash
chmod +x scripts/launch.sh
./scripts/launch.sh
```
