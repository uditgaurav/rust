# Use Rust latest as the base image
FROM rust:latest

# Install required dependencies
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
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Clone your application repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Set Rust environment
ENV PATH="/root/.cargo/bin:$PATH"

# Add AWS Lambda-compatible Rust target
RUN rustup target add x86_64-unknown-linux-gnu

# Build the Rust application
RUN cargo build --release --target x86_64-unknown-linux-gnu

# Set the command to run your application
CMD ["./target/x86_64-unknown-linux-gnu/release/chaos-lambda-extension"]
