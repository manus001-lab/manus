#!/usr/bin/env bash
set -Eeuo pipefail

DESKTOP_DIR="/home/ubuntuuser/Desktop"
APP_DIR="/home/ubuntuuser/.local/share/applications"
ICON_DIR="/usr/share/icons/manus"
mkdir -p "$DESKTOP_DIR" "$APP_DIR" "$ICON_DIR"
cp /opt/gui-icons/firefox.svg "$ICON_DIR/firefox.svg"
cp /opt/gui-icons/edge.svg "$ICON_DIR/edge.svg"
cp /opt/gui-icons/terminal.svg "$ICON_DIR/terminal.svg"
cp /opt/gui-icons/file-manager.svg "$ICON_DIR/file-manager.svg"
chmod 644 "$ICON_DIR"/*.svg

cat > "$APP_DIR/firefox.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Web Browser
Exec=firefox %u
Icon=/usr/share/icons/manus/firefox.svg
Terminal=false
Categories=Network;WebBrowser;
EOF

cat > "$APP_DIR/microsoft-edge.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Microsoft Edge
Comment=Web Browser
Exec=microsoft-edge %u
Icon=/usr/share/icons/manus/edge.svg
Terminal=false
Categories=Network;WebBrowser;
EOF

cat > "$APP_DIR/xfce4-terminal.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Command Line
Exec=xfce4-terminal
Icon=/usr/share/icons/manus/terminal.svg
Terminal=false
Categories=System;TerminalEmulator;
EOF

cat > "$APP_DIR/thunar.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Comment=Manage files and folders
Exec=thunar %U
Icon=/usr/share/icons/manus/file-manager.svg
Terminal=false
Categories=System;FileManager;
EOF

for item in firefox microsoft-edge xfce4-terminal thunar; do
  cp "$APP_DIR/$item.desktop" "$DESKTOP_DIR/$item.desktop"
  chmod +x "$DESKTOP_DIR/$item.desktop"
done
chown -R ubuntuuser:ubuntuuser /home/ubuntuuser/Desktop /home/ubuntuuser/.local
if command -v xfconf-query >/dev/null 2>&1; then
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u ubuntuuser)/bus}"
  su -s /bin/bash ubuntuuser -c 'xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 2 || true'
  su -s /bin/bash ubuntuuser -c 'xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show -n -t bool -s true || true'
fi
