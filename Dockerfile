# Use Rust official image
FROM rust:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    musl-tools \
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

# Add musl target for static linking
RUN rustup target add x86_64-unknown-linux-musl

# Build the Rust application as a fully static binary
RUN cargo build --release --target x86_64-unknown-linux-musl

# Copy the compiled binary into a clean minimal image
FROM alpine:latest
WORKDIR /opt
COPY --from=0 /app/target/x86_64-unknown-linux-musl/release/chaos-lambda-extension .

# Ensure the binary is executable
RUN chmod +x /opt/chaos-lambda-extension

# Set the command to execute the Lambda extension
CMD ["/opt/chaos-lambda-extension"]
