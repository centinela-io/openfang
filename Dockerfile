# syntax=docker/dockerfile:1
FROM rust:1-slim-bookworm AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y pkg-config libssl-dev perl make && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates
COPY xtask ./xtask
COPY agents ./agents
COPY packages ./packages
ARG LTO=true
ARG CODEGEN_UNITS=1
ENV CARGO_PROFILE_RELEASE_LTO=${LTO} \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=${CODEGEN_UNITS}
RUN cargo build --release --bin openfang

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    nodejs \
    npm \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/openfang /usr/local/bin/
COPY --from=builder /build/agents /opt/openfang/agents
COPY config.railway.toml /opt/openfang/config.railway.toml
COPY bindings.default.toml /opt/openfang/bindings.default.toml
COPY start-railway.sh /opt/openfang/start-railway.sh
RUN chmod +x /opt/openfang/start-railway.sh

EXPOSE 4200
ENV OPENFANG_HOME=/data
ENTRYPOINT ["/opt/openfang/start-railway.sh"]
