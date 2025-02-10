# Use Rust official image with musl support for static linking
FROM rust:latest AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    musl-tools \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git . 

# Set Rust target to musl
RUN rustup target add x86_64-unknown-linux-musl

# Build the project in release mode with musl target
RUN cargo build --release --target x86_64-unknown-linux-musl

# Create minimal runtime image
FROM alpine:latest

# Install necessary runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy compiled binary from the builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/chaos-lambda-extension /opt/chaos-lambda-extension

# Set executable permissions
RUN chmod +x /opt/chaos-lambda-extension

# Set entrypoint
ENTRYPOINT ["/opt/chaos-lambda-extension"]
