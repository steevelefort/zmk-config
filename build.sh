#!/usr/bin/env bash

# ZMK Local Build Script with Docker
# Builds firmware for Cradio (Ferris Sweep) keyboard

set -e

SIDE="${1:-left}"
BOARD="nice_nano"
SHIELD="cradio_${SIDE}"
BUILD_DIR="build"
WORKSPACE_DIR="zmk-workspace"
DOCKER_IMAGE="zmkfirmware/zmk-build-arm:3.5"

if [ "$SIDE" != "left" ] && [ "$SIDE" != "right" ]; then
  echo "Usage: $0 [left|right]"
  exit 1
fi

echo "Building ZMK firmware for $BOARD with shield $SHIELD"

# Create directories if they don't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$WORKSPACE_DIR"

# Copy config to workspace directory so it's accessible inside Docker
cp -r config "$WORKSPACE_DIR/" 2>/dev/null || true
cp -r boards "$WORKSPACE_DIR/" 2>/dev/null || true

# Pull latest Docker image
echo "Pulling Docker image..."
docker pull "$DOCKER_IMAGE"

# Run the build in Docker
echo "Starting build..."
docker run --rm -it \
  -v "$(pwd)/$WORKSPACE_DIR:/workspace" \
  -v "$(pwd)/$BUILD_DIR:/workspace/artifacts" \
  "$DOCKER_IMAGE" \
  sh -c "
    set -e
    cd /workspace

    # Initialize west workspace if needed
    if [ ! -d .west ]; then
      echo 'Initializing west workspace...'
      west init -l config
      echo 'Updating dependencies (this may take a while on first run)...'
      west update
    fi

    # Always run zephyr-export to ensure CMake can find Zephyr
    echo 'Exporting Zephyr CMake package...'
    west zephyr-export

    # Clean previous build for this shield
    rm -rf build/$SHIELD

    # Build firmware
    west build -s zmk/app -b $BOARD -d build/$SHIELD -- \
      -DZMK_CONFIG=/workspace/config \
      -DSHIELD=$SHIELD

    # Copy artifacts to build directory
    if [ -f build/$SHIELD/zephyr/zmk.uf2 ]; then
      cp build/$SHIELD/zephyr/zmk.uf2 /workspace/artifacts/${SHIELD}.uf2
      echo ''
      echo 'Build successful!'
      echo \"Firmware: build/${SHIELD}.uf2\"
    else
      echo 'Build failed: UF2 file not found'
      exit 1
    fi
  "

echo ""
echo "========================================="
echo "Build complete!"
echo "Firmware location: $BUILD_DIR/${SHIELD}.uf2"
echo "========================================="
echo ""
echo "To flash:"
echo "1. Put your Nice!Nano in bootloader mode (double-press reset)"
echo "2. Copy the UF2 file to the mounted drive"
