#!/usr/bin/env bash
#
# install_logo.sh — drop your Pzathy Tools logo into the app icon + splash.
#
# Usage:
#   ./scripts/install_logo.sh /path/to/your-logo-1024.png
#
# The source should be a square PNG (1024x1024 recommended). It is copied to:
#   - pzathy_tool/Assets.xcassets/AppIcon.appiconset/icon.png   (App icon)
#   - pzathy_tool/Assets.xcassets/AppLogo.imageset/AppLogo.png   (Splash logo)
#
# Note: App Store icons must NOT contain an alpha channel. If your PNG is
# transparent, this script flattens it onto black for the icon (requires
# ImageMagick `magick`/`convert`); the splash copy keeps any transparency.

set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "usage: $0 /path/to/logo-1024.png" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT/pzathy_tool/Assets.xcassets/AppIcon.appiconset"
LOGO_DIR="$ROOT/pzathy_tool/Assets.xcassets/AppLogo.imageset"
ICON_DST="$ICON_DIR/icon.png"
LOGO_DST="$LOGO_DIR/AppLogo.png"

mkdir -p "$ICON_DIR" "$LOGO_DIR"

# Splash logo: copy as-is (transparency is fine here).
cp "$SRC" "$LOGO_DST"
echo "✓ splash logo  → $LOGO_DST"

# App icon: flatten alpha onto black if a tool is available, else copy as-is.
if command -v magick >/dev/null 2>&1; then
  magick "$SRC" -background black -alpha remove -alpha off "$ICON_DST"
  echo "✓ app icon     → $ICON_DST (flattened)"
elif command -v convert >/dev/null 2>&1; then
  convert "$SRC" -background black -alpha remove -alpha off "$ICON_DST"
  echo "✓ app icon     → $ICON_DST (flattened)"
else
  cp "$SRC" "$ICON_DST"
  echo "✓ app icon     → $ICON_DST"
  echo "  (ImageMagick not found — if your PNG has transparency, flatten it"
  echo "   onto an opaque background before submitting to the App Store.)"
fi

echo "Done. Rebuild in Xcode to see the new icon and splash."
