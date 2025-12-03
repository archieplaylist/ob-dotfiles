#!/bin/bash

# This script installs Openbox and some essential components on Debian-based systems.

set -e

# Update package lists
sudo apt-get update

# Install Openbox, Polybar, a file manager, a terminal, and theming tools
sudo apt-get install -y openbox curl wget neovim polybar dunst feh git lightdm lightdm-gtk-greeter-settings lightdm-settings pcmanfm xfce4-terminal lxappearance lxappearance-obconf network-manager-gnome picom mate-polkit obconf xdg-user-dirs xdg-desktop-portal-gtk pavucontrol pipewire pipewire-pulse pipewire-alsa wireplumber firefox-esr gtk2-engines-murrine sassc papirus-icon-theme rofi fontconfig

# Download and install Font Awesome
wget https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip
unzip fontawesome-free-6.7.2-desktop.zip
mkdir -p ~/.fonts
cp -v fontawesome-free-6.7.2-desktop/otfs/*.otf ~/.fonts/
rm -rf fontawesome-free-6.7.2-desktop fontawesome-free-6.7.2-desktop.zip
fc-cache -f -v

# Create configuration directories
mkdir -p ~/.config/openbox
mkdir -p ~/.config/polybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/wallpaper
mkdir -p ~/.local/share/themes

# Copy bundled Rofi theme and config into user config
cp -v .config/rofi/*.rasi ~/.config/rofi/ 2>/dev/null || true

# Copy bundled Polybar launch script and make it executable
cp -v .config/polybar/launch.sh ~/.config/polybar/ 2>/dev/null || true
chmod +x ~/.config/polybar/launch.sh 2>/dev/null || true

tar -xvf ./Gruvbox-BL-LB-dark.tar.xz -C ~/.local/share/themes/

# Copy wallpaper files
cp -r .config/wallpaper/* ~/.config/wallpaper/

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

padding-left = 0
padding-right = 1

module-margin = 1

font-0 = fixed:pixelsize=10;1
font-1 = unifont:fontformat=truetype:size=8:antialias=false;0
font-2 = "Font Awesome 6 Free:style=Solid:pixelsize=10;1"
font-3 = "Font Awesome 6 Brands:style=Regular:pixelsize=10;1"

modules-left = xwindow
modules-right = power date

cursor-click = pointer
cursor-scroll = ns-resize

tray-position = right
tray-padding = 2

[module/xwindow]
type = internal/xwindow
label = %title:0:60:...%

[module/date]
type = internal/date
interval = 1

date = %H:%M
date-alt = %Y-%m-%d %H:%M:%S

label = %date%
label-foreground = ${colors.foreground}

[module/power]
type = custom/script
exec = ~/.config/rofi/powermenu.sh
click-left = ~/.config/rofi/powermenu.sh
format = <label>
label = "pwr"
label-foreground = ${colors.alert}

[settings]
screen-change-reload = true
pseudo-transparency = true
EOF

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

# Create Openbox autostart script
cat << 'EOF' > ~/.config/openbox/autostart
# Notif
dunst &

# Set wallpaper
feh --bg-scale ~/.config/wallpaper/current &

# Start Polybar
polybar &

# Set dark theme
xsettingsd &
lxappearance
EOF

echo "Installation complete. Please log out and select Openbox as your session."
echo "You may need to run lxappearance to select the Materia-dark theme manually if the gsettings command fails."
