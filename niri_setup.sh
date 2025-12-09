#!/bin/bash
set -e

# ==========================================
# Niri + Quickshell (Bar/Launcher/Notify)
# OS: Fedora
# Theme: Dark with Blur (Semi-Transparent)
# ==========================================

TARGET_USER=${SUDO_USER:-$(id -un)}
USER_HOME=$(eval echo "~$TARGET_USER")
CONFIG_DIR="$USER_HOME/.config"
SRC_DIR="$USER_HOME/src"

echo ">>> Target user: $TARGET_USER"

# ==========================================
# 1. Install Dependencies
# ==========================================
echo ">>> Installing Core Dependencies & LightDM..."
# System utils and dependencies for Niri and the desktop environment
sudo dnf install -y wget kitty curl git unzip xorg-x11-server-Xwayland pipewire wireplumber \
    xauth xorg-x11-server-Xorg brightnessctl \
    lightdm lightdm-gtk \
    xdg-desktop-portal-gtk \
    libxkbcommon libinput libdisplay-info libseat glib2 \
    swaybg alacritty jetbrains-mono-fonts qt6-qt5compat


# ==========================================
# 2. Enable COPR Repositories & Install Software
# ==========================================
echo ">>> Enabling COPR repositories..."
sudo dnf copr enable -y yalter/niri
sudo dnf copr enable -y ulysg/xwayland-satellite
sudo dnf copr enable -y errornointernet/quickshell

echo ">>> Installing Niri, XWayland-Satellite, and Quickshell..."
sudo dnf install -y niri xwayland-satellite quickshell


# ==========================================
# 3. Configure and Enable LightDM
# ==========================================
echo ">>> Enabling LightDM Display Manager..."
# Set the default graphical target and enable the LightDM service
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm.service
sudo systemctl disable gdm.service || true

# ==========================================
# 4. Configuration
# ==========================================

# NIRI & Quickshell config
mkdir -p "$CONFIG_DIR/quickshell"
cp -rv .config/quickshell/* $CONFIG_DIR/quickshell/
cp -rf .config/niri $CONFIG_DIR

# Ensure Wallpaper directory exists
mkdir -p "$USER_HOME/Pictures/Wallpapers"
wget -nc -O "$USER_HOME/Pictures/Wallpapers/dark.jpg" "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=2074&auto=format&fit=crop"


# Fix ownership
sudo chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/Pictures" "$USER_HOME/src"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo "1. Log out."
echo "2. Select 'Niri' session."
echo "3. Quickshell will load a Top Bar."
echo "4. Click 'Menu' on the bar to see the Launcher."
echo "5. Notifications will appear as Popups."
echo ""
echo "To edit the shell: nano ~/.config/quickshell/shell.qml"