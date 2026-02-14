#!/usr/bin/env bash

# Build all halves of Cradio (Ferris Sweep) firmware

set -e

echo "Building both Cradio halves..."
echo ""

# Build left half
echo "=== Building left half ==="
./build.sh left

echo ""
echo "=== Building right half ==="
./build.sh right

echo ""
echo "========================================="
echo "All builds complete!"
echo "========================================="
echo ""
ls -lh build/*.uf2
