#!/usr/bin/env bash
set -Eeuo pipefail

DESKTOP_DIR="/home/ubuntuuser/Desktop"
APP_DIR="/home/ubuntuuser/.local/share/applications"
mkdir -p "$DESKTOP_DIR" "$APP_DIR"

cat > "$APP_DIR/firefox.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Web Browser
Exec=firefox %u
Icon=firefox
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
Icon=microsoft-edge
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
Icon=utilities-terminal
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
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF

for item in firefox microsoft-edge xfce4-terminal thunar; do
  cp "$APP_DIR/$item.desktop" "$DESKTOP_DIR/$item.desktop"
  chmod +x "$DESKTOP_DIR/$item.desktop"
done
chown -R ubuntuuser:ubuntuuser /home/ubuntuuser/Desktop /home/ubuntuuser/.local
