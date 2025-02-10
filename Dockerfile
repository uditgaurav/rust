# =====================================
# Stage 1: Build Rust App (Static Binary)
# =====================================
FROM mcr.microsoft.com/devcontainers/rust:latest AS builder

# Install required dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    musl-tools \
    build-essential \
    clang \
    gcc \
    g++ \
    make \
    perl \
    pkg-config \
    libssl-dev \
    git \
    wget \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Zig (required for cargo-lambda)
RUN wget -q https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz \
    && tar -xf zig-linux-x86_64-0.11.0.tar.xz \
    && mv zig-linux-x86_64-0.11.0 /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig

# Set the working directory
WORKDIR /app

# Clone your application repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Set Rust environment
ENV PATH="/root/.cargo/bin:$PATH"

# Add musl target for fully static compilation
RUN rustup target add x86_64-unknown-linux-musl

# Ensure the `.cargo` directory exists before modifying config
RUN mkdir -p /root/.cargo && \
    echo '[target.x86_64-unknown-linux-musl]\nrustflags = ["-C", "target-feature=+crt-static"]' > /root/.cargo/config.toml

# Install additional Rust tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
RUN wget https://github.com/mozilla/grcov/releases/download/v0.8.18/grcov-x86_64-unknown-linux-gnu.tar.bz2 && tar -xvjf grcov-x86_64-unknown-linux-gnu.tar.bz2 -C /usr/local/bin
RUN rustup component add llvm-tools-preview
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
RUN cargo install cargo-audit && cargo binstall -y cargo-lambda

# ✅ Build the Rust application as a fully static binary
RUN cargo lambda build --release --target x86_64-unknown-linux-musl

# =====================================
# Stage 2: Create Minimal Runtime Image
# =====================================
FROM alpine:latest
WORKDIR /opt

# Copy the compiled binary from the builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/chaos-lambda-extension .

# Ensure the binary is executable
RUN chmod +x /opt/chaos-lambda-extension

# Set the command to execute the Lambda extension
CMD ["/opt/chaos-lambda-extension"]
