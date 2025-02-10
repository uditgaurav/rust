# Use the base image
FROM linuxserver/rustdesk:latest

# Set the working directory
WORKDIR /app

# Install necessary dependencies
RUN apt update && apt install -y \
    git \
    curl \
    build-essential \
    clang \
    gcc \
    g++ \
    make \
    perl \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust via rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Set Rust target for AWS Lambda compatibility
RUN rustup target add x86_64-unknown-linux-gnu

# Clone your repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Build the Rust project
RUN cargo build --release --target x86_64-unknown-linux-gnu

# Expose binary location
CMD ["ls", "-lh", "/app/target/x86_64-unknown-linux-gnu/release/"]
