#!/usr/bin/env bash
# Connectivity menu (rofi). Wi-Fi (nmcli) + Bluetooth (bluetoothctl).
# Click the network module in waybar to open. Arg "bt" opens the Bluetooth submenu.
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t /run/user/"$(id -u)"/hypr 2>/dev/null | head -1)}"

THEME="$HOME/.config/rofi/wifi.rasi"
MODE="${1:-wifi}"

menu()   { rofi -dmenu -i -p "$1" -theme "$THEME"; }
askpw()  { rofi -dmenu -password -p "Password" -theme "$THEME" </dev/null; }
notify() { notify-send -a "Connectivity" "$1" "$2" 2>/dev/null; }

# ===================== BLUETOOTH =====================
if [ "$MODE" = "bt" ]; then
    powered=$(bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo yes)

    {
        if [ "$powered" = "yes" ]; then
            echo "Turn Bluetooth OFF"
            echo "Scan (5s)"
            # connected MACs
            conn=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')
            # all known + discovered devices  (Device MAC Name...)
            bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
                [ -z "$mac" ] && continue
                if printf '%s\n' "$conn" | grep -Fxq "$mac"; then mark="* "; else mark="  "; fi
                printf "%s%s — %s\n" "$mark" "${name:-$mac}" "$mac"
            done
        else
            echo "Turn Bluetooth ON"
        fi
        echo "« Back to Wi-Fi"
    } > /tmp/.conn-menu-list

    sel=$(menu "Bluetooth" < /tmp/.conn-menu-list)
    [ -z "$sel" ] && exit 0

    case "$sel" in
        "Turn Bluetooth OFF") bluetoothctl power off >/dev/null; notify "Bluetooth" "Off"; exit 0 ;;
        "Turn Bluetooth ON")  bluetoothctl power on  >/dev/null; notify "Bluetooth" "On";  exec "$0" bt ;;
        "Scan (5s)")          bluetoothctl --timeout 5 scan on >/dev/null 2>&1; exec "$0" bt ;;
        "« Back to Wi-Fi")    exec "$0" wifi ;;
    esac

    # a device row was picked
    mac="${sel##* — }"          # MAC after last " — "
    [ -z "$mac" ] && exit 0
    if [ "${sel:0:1}" = "*" ]; then
        bluetoothctl disconnect "$mac" >/dev/null && notify "Bluetooth" "Disconnected"
    else
        notify "Bluetooth" "Connecting…"
        bluetoothctl pair "$mac"  >/dev/null 2>&1
        bluetoothctl trust "$mac" >/dev/null 2>&1
        if bluetoothctl connect "$mac" >/dev/null 2>&1; then
            notify "Bluetooth" "Connected"
        else
            notify "Bluetooth" "Failed to connect"
        fi
    fi
    exit 0
fi

# ===================== WI-FI =====================
IFACE=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')
radio=$(nmcli radio wifi)
cur=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')

{
    if [ "$radio" = "enabled" ]; then
        echo "Turn Wi-Fi OFF"
        echo "Rescan"
        [ -n "$cur" ] && echo "Disconnect ($cur)"
        # networks: in-use / signal / security / ssid  (dedup, sort by signal desc)
        nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null \
        | awk -F: 'length($4){print}' \
        | sort -t: -k2 -nr \
        | awk -F: -v cur="$cur" '!seen[$4]++{
            mark=($4==cur)?"* ":"  ";
            sec=($3=="")?"open":$3;
            printf "%s%s — %s%% — %s\n", mark, $4, $2, sec
        }'
    else
        echo "Turn Wi-Fi ON"
    fi
    echo "Bluetooth »"
} > /tmp/.conn-menu-list

sel=$(menu "Wi-Fi" < /tmp/.conn-menu-list)
[ -z "$sel" ] && exit 0

case "$sel" in
    "Turn Wi-Fi OFF") nmcli radio wifi off; notify "Wi-Fi" "Disabled"; exit 0 ;;
    "Turn Wi-Fi ON")  nmcli radio wifi on;  notify "Wi-Fi" "Enabled";  exit 0 ;;
    "Rescan")         nmcli device wifi rescan 2>/dev/null; exec "$0" wifi ;;
    "Disconnect ("*)  nmcli device disconnect "$IFACE"; notify "Wi-Fi" "Disconnected"; exit 0 ;;
    "Bluetooth »")    exec "$0" bt ;;
esac

# ---- a network was picked ----
name="${sel:2}"            # strip "* " / "  " marker
ssid="${name%% — *}"       # strip " — 72% — WPA2" suffix
[ -z "$ssid" ] && exit 0

# known saved connection? bring it up
if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$ssid"; then
    nmcli connection up id "$ssid" && notify "Wi-Fi" "Connected to $ssid" || notify "Wi-Fi" "Failed: $ssid"
    exit 0
fi

# new network — check if secured
sec=$(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | awk -F: -v s="$ssid" '$1==s{print $2; exit}')

if [ -n "$sec" ]; then
    pw=$(askpw)
    [ -z "$pw" ] && exit 0
    nmcli device wifi connect "$ssid" password "$pw" && notify "Wi-Fi" "Connected to $ssid" || notify "Wi-Fi" "Failed: wrong password?"
else
    nmcli device wifi connect "$ssid" && notify "Wi-Fi" "Connected to $ssid" || notify "Wi-Fi" "Failed: $ssid"
fi
