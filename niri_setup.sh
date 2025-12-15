#!/bin/bash
set -e

# ==========================================
# Niri
# OS: Fedora
# ==========================================

TARGET_USER=${SUDO_USER:-$(id -un)}
USER_HOME=$(eval echo "~$TARGET_USER")
CONFIG_DIR="$USER_HOME/.config"

echo ">>> Target user: $TARGET_USER"

# ==========================================
# 1. Install Dependencies
# ==========================================
echo ">>> Installing Core Dependencies & LightDM..."
# System utils and dependencies for Niri and the desktop environment
sudo dnf install -y alacritty wget kitty curl git unzip xorg-x11-server-Xwayland pipewire wireplumber \
    xauth xorg-x11-server-Xorg brightnessctl \
    lightdm lightdm-gtk \
    nautilus nautilus-extensions copyq \
    xdg-desktop-portal-gtk xdg-desktop-portal-gnome mate-polkit xdg-user-dirs gnome-keyring \
    adwaita-gtk2-theme gtk2-engines adwaita-cursor-theme papirus-icon-theme adw-gtk3-theme kvantum fontawesome-6-free-fonts \
    libxkbcommon libinput libdisplay-info libseat glib2 \
    swaybg jetbrains-mono-fonts qt6-qt5compat


# ==========================================
# 2. Enable COPR Repositories & Install Software
# ==========================================
echo ">>> Enabling COPR repositories..."
for repo in "yalter/niri" "ulysg/xwayland-satellite" "errornointernet/quickshell"; do
    repo_file="_copr:copr.fedorainfracloud.org:$(echo "$repo" | tr '/' ':').repo"
    if [ ! -f "/etc/yum.repos.d/$repo_file" ]; then
        echo "Enabling copr repo $repo..."
        sudo dnf copr enable -y "$repo"
    else
        echo "Copr repo $repo already enabled, skipping."
    fi
done

echo ">>> Installing Niri, XWayland-Satellite, and Quickshell..."
sudo dnf install -y niri xwayland-satellite waybar


# ==========================================
# 3. Configure and Enable LightDM
# ==========================================
echo ">>> Enabling LightDM Display Manager..."
# Set the default graphical target and enable the LightDM service
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm.service

# ==========================================
# 4. Configuration
# ==========================================

# NIRI & Quickshell config
# mkdir -p "$CONFIG_DIR/quickshell"
# cp -rv .config/quickshell/* $CONFIG_DIR/quickshell/
cp -rf .config/niri $CONFIG_DIR
# cp -rv .config/kitty ~/.config/ 2>/dev/null || true

cp -rv .config/fuzzel ~/.config/ 2>/dev/null || true
# cp -rv .config/.gtkrc-2.0 ~/ 2>/dev/null || true
# cp -rv .config/gtk-3.0 ~/.config/ 2>/dev/null || true
# cp -rv .config/gtk-4.0 ~/.config/ 2>/dev/null || true
# cp -rv .config/wallpaper ~/.config/ 2>/dev/null || true
cp -rv .config/waybar ~/.config/ 2>/dev/null || true

# gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Kvantum theme
mkdir -p ~/.config/Kvantum
touch ~/.config/Kvantum/kvantum.kvconfig
sed -i '/^\[General\]$/,/^\[.*\]$/ s/^theme=.*/theme=KvGnomeDark/' ~/.config/Kvantum/kvantum.kvconfig

# Fix ownership
sudo chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config" "$USER_HOME/Pictures"

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