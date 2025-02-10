FROM rustembedded/cross:x86_64-unknown-linux-gnu-0.2.1 AS builder

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Rust tools
RUN rustup component add llvm-tools-preview && \
    pip3 install cargo-lambda

# Clone your fork (replace with specific branch/tag if needed)
RUN git clone https://github.com/uditgaurav/chaos-lambda-extension /app
WORKDIR /app

# Build for Lambda execution environment
RUN cargo lambda build --release --target x86_64-unknown-linux-gnu

# Final stage with Amazon Linux 2 runtime
FROM public.ecr.aws/lambda/provided:al2

# Copy the stripped binary
COPY --from=builder \
    /app/target/lambda/extensions/chaos-lambda-extension \
    /opt/

# Lambda extension entrypoint
ENTRYPOINT [ "/opt/chaos-lambda-extension" ]
