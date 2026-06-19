#!/usr/bin/env bash
# F7 (XF86Display) display switcher — mirror / extend / single output.
# Detects the external monitor dynamically (anything that isn't the internal panel).
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/"$(id -u)"/hypr 2>/dev/null | head -1)}"

INT="eDP-1"
THEME="$HOME/.config/rofi/display.rasi"

# external = first monitor whose name isn't the internal panel
EXT=$(hyprctl monitors all -j | jq -r ".[] | select(.name != \"$INT\") | .name" | head -1)

menu() { rofi -dmenu -i -p "Display" -theme "$THEME"; }

if [ -z "$EXT" ]; then
    sel=$(printf 'Internal only\nReload config' | menu)
    case "$sel" in
        "Internal only") hyprctl keyword monitor "$INT,preferred,0x0,1" ;;
        "Reload config") hyprctl reload ;;
    esac
    exit 0
fi

sel=$(printf 'Mirror\nExtend right\nExtend left\nExternal only\nInternal only' | menu)

case "$sel" in
    "Mirror")
        hyprctl keyword monitor "$INT,preferred,0x0,1"
        hyprctl keyword monitor "$EXT,preferred,0x0,1,mirror,$INT"
        ;;
    "Extend right")
        hyprctl keyword monitor "$INT,preferred,0x0,1"
        hyprctl keyword monitor "$EXT,preferred,auto-right,1"
        ;;
    "Extend left")
        hyprctl keyword monitor "$EXT,preferred,0x0,1"
        hyprctl keyword monitor "$INT,preferred,auto-right,1"
        ;;
    "External only")
        hyprctl keyword monitor "$EXT,preferred,0x0,1"
        hyprctl keyword monitor "$INT,disable"
        ;;
    "Internal only")
        hyprctl keyword monitor "$INT,preferred,0x0,1"
        hyprctl keyword monitor "$EXT,disable"
        ;;
esac
