#!/usr/bin/env bash
set -euo pipefail

# Verify the toolchain is present and working.
arm-none-eabi-gcc --version | head -n1
cmake --version | head -n1
ninja --version
openocd --version 2>&1 | head -n1
st-info --version || true
probe-rs --version || true

# Verify USB device access (ST-Link / J-Link)
if lsusb 2>/dev/null | grep -qi "stlink\|jlink"; then
  echo "USB debug probe detected."
else
  echo "No USB debug probe detected. Use usbipd-win on Windows WSL2 to attach probes."
fi

# Verify WSLg display forwarding (if GUI tools are needed)
if [ -n "${DISPLAY:-}" ]; then
  echo "WSLg display forwarding active (DISPLAY=$DISPLAY)."
else
  echo "WSLg display forwarding not active. GUI tools (CubeMX, GDB GUI) will not work."
  echo "Run 'wsl --shutdown' and reopen VS Code if this is unexpected."
fi

echo "STM32 devcontainer ready."
