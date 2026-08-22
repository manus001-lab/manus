#!/usr/bin/env bash
set -Eeuo pipefail

PARTS_DIR="${1:?usage: restore.sh PARTS_DIR [IMAGE_NAME]}"
IMAGE_NAME="${2:-restored/gui-runner:latest}"
PASSPHRASE="${BACKUP_PASSPHRASE:?BACKUP_PASSPHRASE is required}"

(cd "$PARTS_DIR" && sha256sum -c SHA256SUMS)
loaded=$(cat "$PARTS_DIR"/image.tar.enc.part-* | openssl enc -d -aes-256-cbc -pbkdf2 -iter 300000 -pass "pass:$PASSPHRASE" | docker load)
printf '%s\n' "$loaded"
source_image=$(printf '%s\n' "$loaded" | sed -n 's/^Loaded image: //p' | tail -n1)
if [[ -z "$source_image" ]]; then
  echo 'docker load did not report a loaded image' >&2
  exit 1
fi
docker tag "$source_image" "$IMAGE_NAME"
echo "Encrypted image restored as $IMAGE_NAME"
