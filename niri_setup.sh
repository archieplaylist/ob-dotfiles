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


cp -rf .config/niri $CONFIG_DIR
cp -rv .config/kitty ~/.config/ 2>/dev/null || true

cp -rv .config/fuzzel ~/.config/ 2>/dev/null || true
cp -rv .config/.gtkrc-2.0 ~/ 2>/dev/null || true
cp -rv .config/gtk-3.0 ~/.config/ 2>/dev/null || true
cp -rv .config/gtk-4.0 ~/.config/ 2>/dev/null || true
cp -rv .config/wallpaper ~/.config/ 2>/dev/null || true
cp -rv .config/waybar ~/.config/ 2>/dev/null || true

mkdir -p ~/.local/share/themes
mkdir -p ~/.themes

tar -xf ./Gruvbox-BL-LB-dark.tar.xz -C ~/.local/share/themes/
tar -xf ./Gruvbox-BL-LB-dark.tar.xz -C ~/.themes/

gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-BL-LB-Dark'
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