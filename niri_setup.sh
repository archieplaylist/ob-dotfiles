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
echo ">>> Installing Core Dependencies & Ly Build Tools..."
# System utils and dependencies required for building Ly from source
sudo dnf install -y wget curl git unzip xorg-x11-server-Xwayland pipewire wireplumber \
    zig xauth xorg-x11-server-Xorg brightnessctl \
    pam-devel \
    xdg-desktop-portal-gtk \
    libxkbcommon libinput libdisplay-info libseat glib2 \
    swaybg alacritty jetbrains-mono-fonts

# Install Development Tools group for C compiler needed by Ly/Zig
sudo dnf group install -y "development-tools"


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
# 3. Build & Install Ly Display Manager
# ==========================================
echo ">>> Building Ly from source..."
if [ -d "$SRC_DIR/ly" ]; then
    echo ">>> Removing existing ly source directory..."
    rm -rf "$SRC_DIR/ly"
fi
echo ">>> Cloning ly from codeberg.org into $SRC_DIR/ly"
sudo -u "$TARGET_USER" -H git clone --recurse-submodules https://codeberg.org/fairyglade/ly.git "$SRC_DIR/ly"

echo ">>> Building and installing Ly with Zig..."
(cd "$SRC_DIR/ly" && zig build && sudo zig build installexe -Dinit_system=systemd)

echo ">>> Configuring and enabling Ly service..."
# Disable getty on tty2 to prevent conflict with Ly
sudo systemctl disable getty@tty2.service
sudo systemctl enable ly.service


# ==========================================
# 4. Configuration
# ==========================================

# Create Quickshell config and write QML
mkdir -p "$CONFIG_DIR/quickshell"
cat > "$CONFIG_DIR/quickshell/shell.qml" <<'EOF'
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

# Final Niri Config
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