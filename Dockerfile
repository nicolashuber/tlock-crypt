FROM rust:1.74-slim-bookworm AS builder
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone https://github.com/thibmeu/drand-rs.git .
RUN cargo build --release --package dee

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/release/dee /usr/local/bin/dee
COPY tlock.sh /usr/local/bin/tlock
RUN chmod +x /usr/local/bin/tlock
RUN mkdir -p /root/.config/dee
WORKDIR /data

RUN dee remote add quicknet https://drand.cloudflare.com/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971
RUN dee remote add quicknet-pl https://api.drand.sh/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971 || true
RUN dee remote add mainnet-cloudflare https://drand.cloudflare.com || true

ENTRYPOINT ["tlock"]
CMD ["--help"]