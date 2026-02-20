#!/bin/bash
# curl -sL https://raw.githubusercontent.com/nyber-net/utopia-installer/main/install.sh | bash -s
# -y = install here; no -y = fetch that version's install.sh, run it, exit
set -e

REPO="nyber-net/utopia-installer"
INSTALL=false
VERSION=""

for arg in "$@"; do
  case "$arg" in
    -y) INSTALL=true ;;
    *)  [ -z "$VERSION" ] && VERSION="$arg" ;;
  esac
done

if [ -z "$VERSION" ]; then
  VERSION=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | grep -oP '"tag_name": "\K[^"]+')
  [ -z "$VERSION" ] && { echo "Error: No releases found."; exit 1; }
fi

if [ "$INSTALL" != "true" ]; then
  curl -sL "https://raw.githubusercontent.com/${REPO}/${VERSION}/install.sh" | bash -s -- -y "$VERSION"
  exit 0
fi

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

if ! command -v apt-get &>/dev/null; then
  echo "Error: This installer requires apt-get (Debian/Ubuntu)."
  exit 1
fi

echo ""
echo "Installing dependencies..."
$SUDO apt-get update -qq

echo ""
echo "Downloading utopia-amd64.deb ($VERSION)..."
DEB_URL="https://github.com/${REPO}/releases/download/${VERSION}/utopia-amd64.deb"
TMP_DEB=$(mktemp --suffix=.deb)
if ! curl -sLf -o "$TMP_DEB" "$DEB_URL"; then
  echo "Error: Failed to download $DEB_URL"
  rm -f "$TMP_DEB"
  exit 1
fi

echo ""
echo "Installing Utopia..."
$SUDO dpkg -i "$TMP_DEB" || true
$SUDO apt-get -f install -y

rm -f "$TMP_DEB"

echo ""
echo "=========================================="
echo "  Done! Utopia $VERSION has been installed."
echo "=========================================="
