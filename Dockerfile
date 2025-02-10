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

# Install Rust via rustup (ensure it installs in the correct home directory)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && echo 'source $HOME/.cargo/env' >> /root/.bashrc

# Explicitly set Rust environment variables for non-interactive shell
ENV PATH="/root/.cargo/bin:$PATH"

# Verify Rust installation (use bash to source environment)
RUN /bin/bash -c "source /root/.cargo/env && rustc --version && cargo --version && rustup --version"

# Set Rust target for AWS Lambda compatibility
RUN /bin/bash -c "source /root/.cargo/env && rustup target add x86_64-unknown-linux-gnu"

# Clone your repository
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension.git /app

# Build the Rust project
RUN /bin/bash -c "source /root/.cargo/env && cargo build --release --target x86_64-unknown-linux-gnu"

# Expose binary location
CMD ["ls", "-lh", "/app/target/x86_64-unknown-linux-gnu/release/"]
