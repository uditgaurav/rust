#!/bin/bash
# chaos-lambda-extension/scripts/build.sh

set -e

echo "Building shared library..."
docker run --rm -v ${PWD}:/code \
  -w /code \
  amazonlinux:2 \
  /bin/bash -c "yum install -y gcc openssl-devel && \
  rustup target add x86_64-unknown-linux-musl && \
  cargo build --release --target x86_64-unknown-linux-musl"

echo "Building extension..."
docker run --rm -v ${PWD}:/code \
  -w /code/extension \
  amazonlinux:2 \
  /bin/bash -c "yum install -y gcc openssl-devel && \
  rustup target add x86_64-unknown-linux-musl && \
  cargo build --release --target x86_64-unknown-linux-musl"

echo "Creating layer package..."
mkdir -p layer/{extensions,lib}
cp target/x86_64-unknown-linux-musl/release/libchaos_network.so layer/lib/
cp extension/target/x86_64-unknown-linux-musl/release/chaos-extension layer/extensions/

chmod +x layer/extensions/chaos-extension

cd layer && zip -r ../chaos-layer.zip *