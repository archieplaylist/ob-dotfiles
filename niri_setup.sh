#!/bin/bash
set -e

# ==========================================
# Niri + Quickshell (Bar/Launcher/Notify)
# OS: Debian 13 (Trixie)
# Theme: Dark with Blur (Semi-Transparent)
# ==========================================

USER_HOME=$(eval echo ~$SUDO_USER)
CONFIG_DIR="$USER_HOME/.config"
SRC_DIR="$USER_HOME/src"

echo ">>> Updating apt..."
sudo apt update

echo ">>> Installing Core Dependencies..."
# Niri & System Utils
sudo apt install -y wget curl git unzip xwayland pipewire wireplumber \
    xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    libxkbcommon0 libinput10 libdisplay-info1 libseat1 libglib2.0-bin \
    swaybg alacritty fonts-jetbrains-mono

echo ">>> Installing Quickshell Build Dependencies (Qt6)..."
# Debian Trixie has Qt6
sudo apt install -y \
    build-essential cmake ninja-build \
    qt6-base-dev qt6-declarative-dev qt6-wayland-dev \
    libwayland-dev libxkbcommon-dev libqt6svg6 \
    qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qt-labs-platform \
    qt6-quick-controls2-dev

# ==========================================
# 1. Install xwayland-satellite & Niri
# ==========================================
sudo mkdir -p /usr/local/bin

echo ">>> Installing xwayland-satellite..."
SAT_URL=$(curl -s https://api.github.com/repos/Supreeeme/xwayland-satellite/releases/latest | grep "browser_download_url" | grep "x86_64-unknown-linux-musl" | cut -d '"' -f 4)
wget -O xwayland-satellite.tar.gz "$SAT_URL"
tar -xzf xwayland-satellite.tar.gz
chmod +x xwayland-satellite
sudo mv xwayland-satellite /usr/local/bin/
rm xwayland-satellite.tar.gz

echo ">>> Installing Niri..."
NIRI_JSON=$(curl -s https://api.github.com/repos/YaLTeR/niri/releases/latest)
NIRI_URL=$(echo "$NIRI_JSON" | grep "browser_download_url" | grep "niri-x86_64-unknown-linux-gnu" | cut -d '"' -f 4 | head -n 1)
wget -O niri "$NIRI_URL"
chmod +x niri
sudo mv niri /usr/local/bin/

# Session Entry
sudo mkdir -p /usr/share/wayland-sessions
sudo bash -c 'cat > /usr/share/wayland-sessions/niri.desktop <<EOF
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/local/bin/niri session
Type=Application
DesktopNames=niri
EOF'

# ==========================================
# 2. Build & Install Quickshell
# ==========================================
echo ">>> Building Quickshell from source..."

mkdir -p "$SRC_DIR"
if [ -d "$SRC_DIR/quickshell" ]; then
    rm -rf "$SRC_DIR/quickshell"
fi

git clone https://git.outfoxxed.me/outfoxxed/quickshell "$SRC_DIR/quickshell"
cd "$SRC_DIR/quickshell"

# Configure and Build
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Install
sudo cmake --install build

echo ">>> Quickshell installed successfully."

# ==========================================
# 3. Create Quickshell Configuration (QML)
# ==========================================
# This QML implements a Bar, a Launcher Menu, and Notifications.

mkdir -p "$CONFIG_DIR/quickshell"
cat > "$CONFIG_DIR/quickshell/shell.qml" <<EOF
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications

ShellRoot {
    // --- 1. Notification Server (Replaces Mako) ---
    // This listens for system notifications and displays a popup
    NotificationServer {
        id: notifServer
        running: true
    }

    // A list of active notifications to display
    ColumnLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        anchors.topMargin: 50 // Below bar
        spacing: 10
        width: 300
        z: 9999 // Always on top

        Repeater {
            model: notifServer.notifications
            delegate: Rectangle {
                width: 300
                height: 80
                color: "#cc1a1a1a" // Dark Transparent
                radius: 8
                border.color: "#333"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Image {
                        source: model.icon || "qrc:/qt-project.org/imports/QtQuick/Controls/Basic/images/check.png"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        fillMode: Image.PreserveAspectFit
                    }
                    ColumnLayout {
                        Text { 
                            text: model.summary 
                            color: "white"
                            font.bold: true
                        }
                        Text { 
                            text: model.body 
                            color: "#ccc"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                
                // Auto dismiss after 5 seconds (Simple logic)
                Timer {
                    interval: 5000; running: true; repeat: false
                    onTriggered: model.dismiss()
                }
            }
        }
    }

    // --- 2. Top Bar (Replaces Waybar) ---
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        height: 40
        color: "#cc141414" // Dark with transparency (Blur simulation)

        // Make sure it reserves space
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            // -- Start / Launcher Button --
            Button {
                text: "   Menu "
                background: Rectangle { color: "transparent" }
                contentItem: Text { 
                    text: parent.text
                    color: "white"
                    font.pixelSize: 14 
                    font.bold: true
                }
                onClicked: launcherPopup.visible = !launcherPopup.visible
            }

            Item { Layout.fillWidth: true } // Spacer

            // -- Clock --
            Text {
                property var date: new Date()
                text: Qt.formatDateTime(date, "ddd MMM d  hh:mm")
                color: "white"
                font.pixelSize: 14
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: parent.date = new Date()
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // -- System Tray --
            Row {
                spacing: 8
                Repeater {
                    model: SystemTray.items
                    delegate: Image {
                        source: model.icon
                        width: 20; height: 20
                        MouseArea {
                            anchors.fill: parent
                            onClicked: model.activate()
                        }
                    }
                }
            }
        }
    }

    // --- 3. Launcher Popup (Replaces Fuzzel) ---
    // A simple grid of favorites. 
    // (Note: Full app list parsing requires C++ or complex JS parsing of .desktop files)
    PopupWindow {
        id: launcherPopup
        visible: false
        width: 400
        height: 300
        anchor.window: parent
        // anchor.rect not fully supported in all compositors, centering manually often safer
        // Simple centering simulation or top-left offset
        
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: 400; height: 300
            color: "#dd1a1a1a"
            radius: 12
            border.color: "#444"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                
                Text { text: "Applications"; color: "white"; font.pixelSize: 18; font.bold: true }
                
                GridLayout {
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    // Helper Component for App Buttons
                    component AppBtn: Button {
                        property string cmd
                        property string label
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 80
                        background: Rectangle { 
                            color: parent.hovered ? "#33ffffff" : "#11ffffff" 
                            radius: 6
                        }
                        contentItem: Column {
                            anchors.centerIn: parent
                            Text { text: ""; color: "white"; font.pixelSize: 24; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: parent.label; color: "white"; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        onClicked: {
                            Quickshell.process(cmd).spawn()
                            launcherPopup.visible = false
                        }
                    }

                    AppBtn { label: "Terminal"; cmd: "alacritty" }
                    AppBtn { label: "Browser"; cmd: "firefox" }
                    AppBtn { label: "Files"; cmd: "nautilus" }
                    AppBtn { label: "Editor"; cmd: "gedit" }
                }
            }
        }
    }
}
EOF

# ==========================================
# 4. Final Niri Config
# ==========================================
mkdir -p "$CONFIG_DIR/niri"
NIRI_CONFIG="$CONFIG_DIR/niri/config.kdl"

# Download default config if missing
if [ ! -f "$NIRI_CONFIG" ]; then
    curl -s https://raw.githubusercontent.com/YaLTeR/niri/master/resources/default-config.kdl -o "$NIRI_CONFIG"
fi

# Ensure Wallpaper directory exists
mkdir -p "$USER_HOME/Pictures/Wallpapers"
wget -nc -O "$USER_HOME/Pictures/Wallpapers/dark.jpg" "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=2074&auto=format&fit=crop"

# Add Autostart items to Niri
# We check if they are already there
if ! grep -q "spawn-at-startup \"quickshell\"" "$NIRI_CONFIG"; then
    cat >> "$NIRI_CONFIG" <<EOF

// --- Quickshell & System Setup ---

spawn-at-startup "xwayland-satellite"
spawn-at-startup "swaybg" "-m" "fill" "-i" "$USER_HOME/Pictures/Wallpapers/dark.jpg"

// Launch Quickshell (Handles Bar, Launcher, Notifications)
spawn-at-startup "quickshell"

// Keybind to toggle the Launcher (We invoke it via a dummy CLI command or rely on the clickable bar button)
// Since Quickshell is running as a daemon, we can't easily "toggle" a window from outside without IPC.
// For this setup, click the "Menu" button on the top bar.

// Terminal bind
binds {
    Mod+Return { spawn "alacritty"; }
}

layout {
    focus-ring {
        width 2
        active-color "#ffffff"
        inactive-color "#505050"
    }
    border {
        off
    }
}
EOF
fi

# Fix ownership
sudo chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.config" "$USER_HOME/Pictures" "$USER_HOME/src"

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