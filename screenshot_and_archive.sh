#!/bin/bash
set -e

SAMPLES_DIR="/var/jenkins_home/samples"
ARCHIVE_DIR="$SAMPLES_DIR/archive"
SCREENSHOT_FILE="$SAMPLES_DIR/jenkins_homepage_latest.png"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

mkdir -p "$SAMPLES_DIR"
mkdir -p "$ARCHIVE_DIR"

echo "Taking screenshot of http://localhost:8080..."
TEMP_SCREENSHOT_FILE="$SAMPLES_DIR/jenkins_homepage_temp.png"
xvfb-run --auto-servernum --server-args="-screen 0, 1024x768x24" wkhtmltoimage http://localhost:8080 "$TEMP_SCREENSHOT_FILE"
if [ $? -ne 0 ]; then echo "Error taking screenshot."; exit 1; fi

if [ -f "$SCREENSHOT_FILE" ]; then
  echo "Archiving old screenshot."
  ARCHIVED_FILE="$ARCHIVE_DIR/jenkins_homepage_${TIMESTAMP}.png.tar.gz"
  tar -czf "$ARCHIVED_FILE" --remove-files "$SCREENSHOT_FILE"
fi

mv "$TEMP_SCREENSHOT_FILE" "$SCREENSHOT_FILE"
echo "New screenshot saved to $SCREENSHOT_FILE"

exit 0
