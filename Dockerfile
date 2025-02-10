FROM mcr.microsoft.com/devcontainers/rust:latest

# Install dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    curl \
    wget \
    build-essential \
    musl-tools \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV BIN_NAME=chaos-lambda-extension
ENV TARGET_DIR=/app/target/lambda/extensions

# Create working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git .

# Install Rust components
RUN rustup component add llvm-tools-preview
RUN cargo install cargo-audit cargo-lambda

# Build the release binary
RUN cargo build --release --locked --target x86_64-unknown-linux-gnu

# Strip the binary for smaller size
RUN strip ./target/x86_64-unknown-linux-gnu/release/$BIN_NAME

# Move binary to target directory
RUN mkdir -p $TARGET_DIR && mv ./target/x86_64-unknown-linux-gnu/release/$BIN_NAME $TARGET_DIR/

# Set entrypoint
CMD ["/app/target/lambda/extensions/chaos-lambda-extension"]
