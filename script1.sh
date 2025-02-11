#!/bin/bash
set -e

# Install required system packages
sudo yum update -y
sudo yum install -y \
    gcc \
    openssl-devel \
    zip \
    glibc-static \
    libstdc++-static

# Install Rust
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Add native target
rustup target add x86_64-unknown-linux-gnu

# Build shared library with position-independent code
echo "Building shared library..."
(PERL=/usr/bin/perl cargo build --release --target x86_64-unknown-linux-gnu)

# Build extension
echo "Building extension..."
(cd extension && \
 PERL=/usr/bin/perl cargo build --release --target x86_64-unknown-linux-gnu)

# Create layer structure
echo "Creating layer package..."
OUTPUT_DIR="layer"
mkdir -p ${OUTPUT_DIR}/opt/extensions ${OUTPUT_DIR}/opt/lib

# Copy binaries
cp target/x86_64-unknown-linux-gnu/release/libchaos_network.so ${OUTPUT_DIR}/opt/lib/
cp extension/target/x86_64-unknown-linux-gnu/release/chaos-extension ${OUTPUT_DIR}/opt/extensions/

# Set permissions
chmod +x ${OUTPUT_DIR}/opt/extensions/chaos-extension

# Create ZIP package
ZIP_FILE="chaos-layer.zip"
(cd ${OUTPUT_DIR} && zip -r ../${ZIP_FILE} .)

echo "Build complete! Layer package: ${ZIP_FILE}"
