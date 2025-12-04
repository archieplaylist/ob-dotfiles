#!/bin/bash
# This script installs Openbox and some essential components on Debian-based systems.

set -e

# Update package lists
sudo apt-get update

# Install Openbox, Polybar, a file manager, a terminal, and theming tools
sudo apt-get install -y openbox curl wget unzip neovim fastfetch htop polybar dunst feh git lightdm lightdm-gtk-greeter-settings lightdm-settings pcmanfm xfce4-terminal xfce4-clipman lxappearance lxappearance-obconf network-manager-gnome picom mate-polkit obconf xdg-user-dirs xdg-desktop-portal-gtk pavucontrol pipewire pipewire-pulse pipewire-alsa wireplumber firefox-esr gtk2-engines-murrine sassc papirus-icon-theme rofi fontconfig libglib2.0-bin

# LightDM Conf
sudo systemctl enable lightdm
sudo sed -i '/^#\?greeter-hide-users/ { s/.*greeter-hide-users=.*/greeter-hide-users=false/; t }; /^\[Seat:\*\]/a greeter-hide-users=false' /etc/lightdm/lightdm.conf

xdg-user-dirs-update

# Download and install Font Awesome
wget https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip
unzip fontawesome-free-6.7.2-desktop.zip
mkdir -p ~/.fonts
cp -v fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.fonts/
rm -rf fontawesome-free-6.7.2-desktop fontawesome-free-6.7.2-desktop.zip
fc-cache -f -v

# Create configuration directories
mkdir -p ~/.config/openbox
mkdir -p ~/.config/picom
mkdir -p ~/.config/polybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/wallpaper
mkdir -p ~/.local/share/themes

# Copy Picom config
cp -v .config/picom/*.conf ~/.config/picom/ 2>/dev/null || true

# Copy bundled Rofi theme and config into user config
cp -v .config/rofi/*.rasi ~/.config/rofi/ 2>/dev/null || true

# Copy bundled Polybar launch script and make it executable
cp -v .config/polybar/launch.sh ~/.config/polybar/ 2>/dev/null || true
chmod +x ~/.config/polybar/launch.sh 2>/dev/null || true

# GTK Theme
tar -xvf ./Gruvbox-BL-LB-dark.tar.xz -C ~/.local/share/themes/

# Create Gruvbox Openbox theme
mkdir -p ~/.local/share/themes/Gruvbox-BL-LB-Dark/openbox-3
cat << 'EOF' > ~/.local/share/themes/Gruvbox-BL-LB-Dark/openbox-3/themerc
# Gruvbox Openbox Theme based on rofi/gruvbox_colors.rasi

# General settings
border.width: 1
padding.width: 1
padding.height: 1
font.sans-serif: size=9

# Window title text
window.label.text.color: #ebdbb2

# Active window
window.active.title.bg.color: #458588
window.active.label.text.color: #282828
# border.color: #458588
border.color: #ebdbb2
window.active.button.unpressed.image.color: #ebdbb2
window.active.button.pressed.image.color: #282828
window.active.button.toggled.image.color: #98971a
window.active.client.color: #ebdbb2

# Inactive window
window.inactive.title.bg.color: #3c3836
window.inactive.label.text.color: #ebdbb2
window.inactive.button.unpressed.image.color: #ebdbb2
border.inactive.color: #3c3836
window.inactive.client.color: #ebdbb2

# Menu
menu.title.bg.color: #282828
menu.title.text.color: #ebdbb2
menu.items.bg.color: #282828
menu.items.text.color: #ebdbb2
menu.items.active.bg.color: #458588
menu.items.active.text.color: #282828

# OSD
osd.bg.color: #282828
osd.text.color: #ebdbb2
osd.border.color: #458588
osd.border.width: 1
EOF

# Copy wallpaper files
cp -r .config/wallpaper/* ~/.config/wallpaper/

# Ensure GTK2 apps use the Gruvbox theme
# Write a GTK2 rc file so legacy GTK2 apps pick up the theme
cat > ~/.gtkrc-2.0 <<'GTKRC'
gtk-theme-name="Gruvbox-BL-LB-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Sans 9"
GTKRC

# Write GTK3 settings file so GTK3 apps pick up the theme
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini <<'GTK3'
[Settings]
gtk-theme-name = Gruvbox-BL-LB-Dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Sans 9
GTK3

# Write GTK4 settings file (some GTK4 apps respect this)
mkdir -p ~/.config/gtk-4.0
cat > ~/.config/gtk-4.0/settings.ini <<'GTK4'
[Settings]
gtk-theme-name = Gruvbox-BL-LB-Dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Sans 9
GTK4

# Simple: download Bibata v2.0.7, extract to ~/.icons and set as default cursor
tmpdir=$(mktemp -d)
echo "Downloading Bibata cursor theme to $tmpdir"
url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz"
if command -v wget >/dev/null 2>&1; then
    wget -qO "$tmpdir/bibata.tar.xz" "$url" || true
elif command -v curl >/dev/null 2>&1; then
    curl -sL -o "$tmpdir/bibata.tar.xz" "$url" || true
fi
if [ -f "$tmpdir/bibata.tar.xz" ]; then
    mkdir -p "$HOME/.icons"
    tar -xJf "$tmpdir/bibata.tar.xz" -C "$tmpdir" || true
    # copy any extracted Bibata* directories into ~/.icons
    find "$tmpdir" -maxdepth 1 -type d -name 'Bibata*' -exec cp -r {} "$HOME/.icons/" \; 2>/dev/null || true

    cursor_name="Bibata-Modern-Classic"
    if [ ! -d "$HOME/.icons/$cursor_name" ]; then
        cursor_name=$(ls -1 "$HOME/.icons" 2>/dev/null | head -n1 || echo "$cursor_name")
    fi

    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" <<IDX
[Icon Theme]
Inherits=$cursor_name
IDX

    # Set cursor theme for GTK2 (~/.gtkrc-2.0)
    if [ -f "$HOME/.gtkrc-2.0" ]; then
        if ! grep -q '^gtk-cursor-theme-name' "$HOME/.gtkrc-2.0" 2>/dev/null; then
            printf "\ngtk-cursor-theme-name=\"%s\"\n" "$cursor_name" >> "$HOME/.gtkrc-2.0"
        fi
    else
        printf "gtk-theme-name=\"Gruvbox-BL-LB-Dark\"\n" > "$HOME/.gtkrc-2.0"
        printf "gtk-icon-theme-name=\"Papirus-Dark\"\n" >> "$HOME/.gtkrc-2.0"
        printf "gtk-font-name=\"Sans 9\"\n" >> "$HOME/.gtkrc-2.0"
        printf "gtk-cursor-theme-name=\"%s\"\n" "$cursor_name" >> "$HOME/.gtkrc-2.0"
    fi

    # Set cursor theme for GTK3/GTK4 settings files
    for gtkfile in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        mkdir -p "$(dirname "$gtkfile")"
        if [ -f "$gtkfile" ]; then
            if ! grep -q '^gtk-cursor-theme-name' "$gtkfile" 2>/dev/null; then
                printf "\ngtk-cursor-theme-name = %s\n" "$cursor_name" >> "$gtkfile"
            fi
        else
            cat > "$gtkfile" <<GTKSET
[Settings]
gtk-theme-name = Gruvbox-BL-LB-Dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Sans 9
gtk-cursor-theme-name = $cursor_name
GTKSET
        fi
    done

    rm -rf "$tmpdir"
fi
 

# Create a simple dark Polybar config
cat << 'EOF' > ~/.config/polybar/config.ini
[colors]
background = #282828
background-alt = #3c3836
foreground = #ebdbb2
primary = #458588
secondary = #98971a
alert = #cc241d

[bar/main]
width = 100%
height = 24pt
radius = 6

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 3pt

border-size = 4pt
border-color = #00000000

padding-left = 2
padding-right = 2

module-margin = 2

font-0 = fixed:pixelsize=10;1
font-1 = unifont:fontformat=truetype:size=8:antialias=false;0
font-2 = "Font Awesome 6 Free:style=Solid:pixelsize=10;1"
font-3 = "Font Awesome 6 Brands:style=Regular:pixelsize=10;1"

modules-left = launcher xworkspace
modules-right = tray cpu memory network pulseaudio date powermenu

cursor-click = pointer
cursor-scroll = ns-resize

[module/tray]
type = internal/tray
format-margin = 4pt
tray-spacing = 5pt
; background = ${colors.background}

[module/xworkspace]
type = internal/xworkspaces
enable-click = true
label-active = %name%
label-active-padding = 1
label-occupied = %name%
label-occupied-padding = 1
label-urgent = %name%
label-urgent-padding = 1
label-empty = %name%
label-empty-foreground = ${colors.disabled}
label-empty-background = ${colors.background-alt}
label-empty-padding = 1


[module/cpu]
type = internal/cpu
interval = 2
format = <label>
format-prefix = " "
format-prefix-foreground = ${colors.secondary}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format = <label>
format-prefix = " "
format-prefix-foreground = ${colors.secondary}
label = %gb_used%

[module/network]
type = custom/script
exec = ~/.config/polybar/network.sh
interval = 3
format = <label>
label = %output%
click-right = nm-connection-editor

[module/pulseaudio]
type = internal/pulseaudio
use-ui-max = false
format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
label-muted =  Muted
ramp-volume-0 = 
ramp-volume-1 = 
ramp-volume-2 = 
click-right = pavucontrol

[module/date]
type = internal/date
click-right = ~/.config/rofi/powermenu.sh
interval = 1

date = %H:%M
date-alt = %d-%m-%Y %H:%M:%S

label = %date%
label-foreground = ${colors.foreground}

[module/powermenu]
type = custom/script
exec = echo ""
interval = 3600
click-left = $HOME/.config/rofi/powermenu.sh
format = <label>
label = ""
label-foreground = ${colors.alert}

[module/launcher]
type = custom/script
exec = echo ""
interval = 3600
click-left = $HOME/.config/rofi/launcher.sh
format = <label>
label = ""
label-foreground = ${colors.primary}

[settings]
screen-change-reload = true
pseudo-transparency = true
EOF

# Create a robust network helper script for Polybar.
# Uses nmcli (preferred) or iw as fallback to detect wired vs wireless
# Prints only an icon and the IP address. When disconnected, prints icon only.
cat << 'NW' > ~/.config/polybar/network.sh
#!/usr/bin/env bash

# Icons (Font Awesome glyphs expected)
WIFI_ICON=""
WIRED_ICON=""
DISCONNECTED_ICON=""
LIMITED_ICON=""

get_nmcli() {
    # Find first connected device and its type
    # Output: device|type|ip|ssid|conn
    devinfo=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$3=="connected"{print $1"|"$2; exit}')
    if [ -n "$devinfo" ]; then
        dev=${devinfo%%|*}
        type=${devinfo##*|}
        ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -n1 | cut -d'/' -f1)
        ssid=""
        if [ "$type" = "wifi" ]; then
            ssid=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: -v d="$dev" '$2==d{print $1; exit}')
        fi
        conn=$(nmcli networking connectivity 2>/dev/null || echo "")
        echo "$dev|$type|$ip|$ssid|$conn"
        return 0
    fi
    return 1
}

get_iw() {
    # Check wireless interfaces reported by iw
    for w in $(iw dev 2>/dev/null | awk '/Interface/{print $2}'); do
        if iw dev "$w" link 2>/dev/null | grep -q 'Connected'; then
            ip=$(ip -4 -o addr show dev "$w" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1 | head -n1)
            ssid=$(iw dev "$w" link 2>/dev/null | awk -F': ' '/SSID/{print $2; exit}')
            # Best-effort connectivity check
            conn=$(nmcli networking connectivity 2>/dev/null || echo "")
            echo "$w|wifi|$ip|$ssid|$conn"
            return 0
        fi
    done
    return 1
}

get_route() {
    # Fallback: use ip route to infer the device and source IP
    read -r dev src <<< $(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){dev=$(i+1)}; if($i=="src"){src=$(i+1)}}} END{print dev,src}')
    if [ -n "$dev" ]; then
        # If iw knows about this dev, mark as wifi
        if command -v iw >/dev/null 2>&1 && iw dev 2>/dev/null | grep -qw "$dev"; then
            type=wifi
        else
            type=ethernet
        fi
        # connectivity fallback: ping once
        if ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
            conn=full
        else
            conn=limited
        fi
        echo "$dev|$type|$src||$conn"
        return 0
    fi
    return 1
}

result=""
if command -v nmcli >/dev/null 2>&1; then
    result=$(get_nmcli) || true
fi
if [ -z "$result" ] && command -v iw >/dev/null 2>&1; then
    result=$(get_iw) || true
fi
if [ -z "$result" ]; then
    result=$(get_route) || true
fi

if [ -z "$result" ]; then
    # no connection; show icon only
    printf "%s" "$DISCONNECTED_ICON"
    exit 0
fi

IFS='|' read -r iface type ipaddr ssid conn <<< "$result"

# Determine icon
if [ "$type" = "wifi" ] || [[ "$iface" == wl* ]]; then
    icon="$WIFI_ICON"
else
    icon="$WIRED_ICON"
fi

# Determine connectivity indicator (use nmcli connectivity when available)
indicator=""
if [ -n "$conn" ] && [ "$conn" != "full" ]; then
    indicator=" $LIMITED_ICON"
fi

# Build output: for wifi show SSID (and IP if available), for wired show IP
if [ "$type" = "wifi" ]; then
    if [ -n "$ssid" ]; then
        if [ -n "$ipaddr" ]; then
            printf "%s %s %s%s" "$icon" "$ssid" "$ipaddr" "$indicator"
        else
            printf "%s %s%s" "$icon" "$ssid" "$indicator"
        fi
    else
        if [ -n "$ipaddr" ]; then
            printf "%s %s%s" "$icon" "$ipaddr" "$indicator"
        else
            printf "%s%s" "$icon" "$indicator"
        fi
    fi
else
    if [ -n "$ipaddr" ]; then
        printf "%s %s%s" "$icon" "$ipaddr" "$indicator"
    else
        printf "%s%s" "$icon" "$indicator"
    fi
fi

NW

chmod +x ~/.config/polybar/network.sh

# Create powermenu script for Rofi
cat << 'EOF' > ~/.config/rofi/powermenu.sh
#!/bin/bash

options="Shutdown\nReboot\nLock\nSuspend\nLogout"

# Use the gruvbox theme explicitly to ensure consistent colors
chosen=$(echo -e "$options" | rofi -theme gruvbox-dark -dmenu -p "Power Menu")

case "$chosen" in
    "Shutdown") systemctl poweroff ;;
    "Reboot") systemctl reboot ;;
    "Lock") light-locker-command -l ;;
    "Suspend") systemctl suspend ;;
    "Logout") openbox --exit ;;
esac
EOF

# Make powermenu script executable
chmod +x ~/.config/rofi/powermenu.sh

# Create a simple rofi launcher script
cat << 'EOF' > ~/.config/rofi/launcher.sh
#!/bin/bash

# Launch the application launcher (drun)
rofi -show drun -theme gruvbox-dark

EOF

# Make launcher script executable
chmod +x ~/.config/rofi/launcher.sh

# Create Openbox autostart script
cat << 'EOF' > ~/.config/openbox/autostart
/usr/libexec/polkit-mate-authentication-agent-1 &
picom --config ~/.config/picom/picom.conf &
xfce4-clipman &
dunst &
nm-applet &

# Set wallpaper
feh --bg-scale ~/.config/wallpaper/7.jpg &

# Start Polybar
polybar -r &

# Set dark theme
xsettingsd &
EOF

echo "Installation complete. Please log out and select Openbox as your session."
echo "You may need to run lxappearance to select the theme manually if the gsettings command fails."
