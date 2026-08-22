#!/usr/bin/env bash
set -Eeuo pipefail

export DISPLAY="${DISPLAY:-:99}"
export SCREEN_WIDTH="${SCREEN_WIDTH:-1440}"
export SCREEN_HEIGHT="${SCREEN_HEIGHT:-900}"
export SCREEN_DEPTH="${SCREEN_DEPTH:-24}"

mkdir -p /workspace/screenshots /workspace/backup
chmod 700 /workspace/screenshots /workspace/backup
if [[ -z "${NOVNC_PASSWORD:-}" || ${#NOVNC_PASSWORD} -lt 12 ]]; then
  echo "NOVNC_PASSWORD must be at least 12 characters" >&2
  exit 1
fi
x11vnc -storepasswd "$NOVNC_PASSWORD" /tmp/vnc.pass >/dev/null
chmod 600 /tmp/vnc.pass
unset NOVNC_PASSWORD

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/gui.conf
