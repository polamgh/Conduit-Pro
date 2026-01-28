#!/bin/bash

REPO_USER="polamgh"
REPO_NAME="Conduit-Pro"
APP_NAME="Conduit Pro.app"
ZIP_NAME="Conduit Pro.zip"
INSTALL_DIR="/Applications"

echo "Downloading Conduit Pro..."

DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO_USER/$REPO_NAME/releases/latest" | grep "browser_download_url" | grep ".zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find the latest release URL."
    exit 1
fi

curl -L -o "/tmp/$ZIP_NAME" "$DOWNLOAD_URL"

if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo "Removing old version..."
    rm -rf "$INSTALL_DIR/$APP_NAME"
fi

echo "Installing to $INSTALL_DIR..."
unzip -q -o "/tmp/$ZIP_NAME" -d "$INSTALL_DIR"

echo "Fixing permissions (Gatekeeper)..."
xattr -cr "$INSTALL_DIR/$APP_NAME"

rm "/tmp/$ZIP_NAME"

echo "✅ Installation Complete!"
echo "You can now open Conduit from your Applications folder."
echo ""
echo "Opening Conduit..."
open "$INSTALL_DIR/$APP_NAME"