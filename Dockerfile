# Use Rust latest as the base image
FROM rust:latest AS builder

# Install required dependencies
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Clone your application repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Set Rust environment
ENV PATH="/root/.cargo/bin:$PATH"

# Add musl target for fully static compilation
RUN rustup target add x86_64-unknown-linux-musl

# ✅ Ensure the `.cargo` directory exists before writing to config.toml
RUN mkdir -p /root/.cargo && \
    echo '[target.x86_64-unknown-linux-musl]\nrustflags = ["-C", "target-feature=+crt-static"]' > /root/.cargo/config.toml

# ✅ Build the Rust application as a **fully static binary**
RUN cargo build --release --target x86_64-unknown-linux-musl

# Use a minimal Alpine image for deployment
FROM alpine:latest
WORKDIR /opt
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/chaos-lambda-extension .

# Ensure the binary is executable
RUN chmod +x /opt/chaos-lambda-extension

# Set the command to execute the Lambda extension
CMD ["/opt/chaos-lambda-extension"]
