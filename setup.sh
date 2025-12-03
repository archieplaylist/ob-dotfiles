#!/bin/bash

# This script installs Openbox and some essential components on Debian-based systems.

# Update package lists
sudo apt-get update

# Install Openbox, Polybar, a file manager, a terminal, and theming tools
sudo apt-get install -y openbox curl wget neovim polybar dunst feh git lightdm lightdm-gtk-greeter-settings lightdm-settings pcmanfm xfce4-terminal lxappearance-obconf network-manager-gnome picom mate-polkit obconf xdg-user-dirs xdg-desktop-portal-gtk pavucontrol pipewire pipewire-pulse pipewire-alsa wireplumber firefox-esr materia-gtk-theme rofi

# Create configuration directories
mkdir -p ~/.config/openbox
mkdir -p ~/.config/polybar
mkdir -p ~/.config/rofi
mkdir -p ~/.config/wallpaper

# Copy wallpaper files
cp -r .config/wallpaper/* ~/.config/wallpaper/

# Create a simple dark Polybar config
cat << 'EOF' > ~/.config/polybar/config.ini
[colors]
background = #2e3440
background-alt = #4c566a
foreground = #d8dee9
primary = #88c0d0
secondary = #81a1c1
alert = #bf616a

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
label = ""
label-foreground = ${colors.alert}

[settings]
screen-change-reload = true
pseudo-transparency = true
EOF

# Create powermenu script for Rofi
cat << 'EOF' > ~/.config/rofi/powermenu.sh
#!/bin/bash

options="Shutdown\nReboot\nLock\nSuspend\nLogout"

chosen=$(echo -e "$options" | rofi -dmenu -p "Power Menu")

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
# Set wallpaper
feh --bg-scale ~/.config/wallpaper/current &

# Start Polybar
polybar -r &

# Set dark theme
xsettingsd &
lxappearance &
EOF

# Set the GTK theme to Materia-dark
gsettings set org.gnome.desktop.interface gtk-theme "Materia-dark"
gsettings set org.gnome.desktop.interface icon-theme "Materia-dark"

echo "Installation complete. Please log out and select Openbox as your session."
echo "You may need to run lxappearance to select the Materia-dark theme manually if the gsettings command fails."
