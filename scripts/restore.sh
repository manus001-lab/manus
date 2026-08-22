#!/usr/bin/env bash
set -Eeuo pipefail

PARTS_DIR="${1:?usage: restore.sh PARTS_DIR [IMAGE_NAME]}"
IMAGE_NAME="${2:-restored/gui-runner:latest}"
PASSPHRASE="${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE is required}"

(cd "$PARTS_DIR" && sha256sum -c SHA256SUMS)
cat "$PARTS_DIR"/image.tar.enc.part-* | openssl enc -d -aes-256-cbc -pbkdf2 -iter 300000 -pass "pass:$PASSPHRASE" | docker load
if [[ "$IMAGE_NAME" != restored/gui-runner:latest ]]; then
  docker tag "$(docker images --format '{{.Repository}}:{{.Tag}}' | head -n1)" "$IMAGE_NAME" || true
fi
echo "Encrypted image restored"
