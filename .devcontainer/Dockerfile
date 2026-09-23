FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-arm-none-eabi \
        binutils-arm-none-eabi \
        gdb-multiarch \
        cmake \
        ninja-build \
        make \
        git \
        openocd \
        stlink-tools \
        python3 \
        python3-pip \
        usbutils \
        libusb-1.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Optional: probe-rs (modern flashing/debugging alternative)
RUN curl -fsSL https://raw.githubusercontent.com/probe-rs/probe-rs/master/install.sh | sh \
    && mv ~/.cargo/bin/probe-rs /usr/local/bin/ || true
