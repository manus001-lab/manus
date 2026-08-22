#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="${1:?usage: backup.sh IMAGE [OUT_DIR]}"
OUT_DIR="${2:-backup-parts}"
PASSPHRASE="${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE is required}"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/image.tar.enc.part-*

docker save "$IMAGE" | openssl enc -aes-256-cbc -pbkdf2 -iter 300000 -salt -pass "pass:$PASSPHRASE" | split -b 90m -d -a 4 - "$OUT_DIR/image.tar.enc.part-"
sha256sum "$OUT_DIR"/image.tar.enc.part-* > "$OUT_DIR/SHA256SUMS"
chmod 700 "$OUT_DIR"
chmod 600 "$OUT_DIR"/image.tar.enc.part-* "$OUT_DIR/SHA256SUMS"
echo "Encrypted image parts written to $OUT_DIR"
