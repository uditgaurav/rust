# Use Rust latest as the base image
FROM rust:latest

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    gcc \
    g++ \
    make \
    perl \
    pkg-config \
    libssl-dev \
    git \
    musl-tools \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Clone your application repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Set Rust environment
ENV PATH="/root/.cargo/bin:$PATH"

# Add the musl target to Rust (static linking)
RUN rustup target add x86_64-unknown-linux-musl

# Build the Rust application using musl
RUN cargo build --release --target x86_64-unknown-linux-musl

# Set the command to run your application
CMD ["./target/x86_64-unknown-linux-musl/release/chaos-lambda-extension"]
