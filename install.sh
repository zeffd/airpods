#!/bin/sh
# Install the airpods tool. Usage: ./install.sh [destination-dir]
set -e

DEST="${1:-$HOME/.local/bin}"
SRC="$(cd "$(dirname "$0")" && pwd)/airpods"

command -v python3 >/dev/null 2>&1 || { echo "error: python3 not found" >&2; exit 1; }
command -v bluetoothctl >/dev/null 2>&1 || echo "warning: bluetoothctl not found (install bluez-utils)" >&2
command -v busctl >/dev/null 2>&1 || echo "warning: busctl not found (part of systemd)" >&2

mkdir -p "$DEST"
install -m 755 "$SRC" "$DEST/airpods"
echo "installed $DEST/airpods"

case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "note: $DEST is not on your PATH" >&2 ;;
esac
