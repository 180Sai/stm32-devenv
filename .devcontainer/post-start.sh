#!/usr/bin/env bash
set -euo pipefail

# Post-start connectivity check — catches WSLg / Docker socket disruptions.

# Verify Docker socket is still reachable.
if [ ! -S /var/run/docker.sock ]; then
  echo "WARNING: Docker socket not found at /var/run/docker.sock."
  echo "Docker Desktop's WSL integration may have been disrupted."
  echo "Run 'wsl --shutdown' from PowerShell and reopen VS Code."
fi

# Verify USB devices are still accessible.
if command -v lsusb &>/dev/null; then
  USB_COUNT=$(lsusb 2>/dev/null | wc -l)
  echo "USB devices visible: ${USB_COUNT}"
  if [ "${USB_COUNT}" -eq 0 ]; then
    echo "WARNING: No USB devices visible. Attach probes with usbipd-win and 'usbipd attach --wsl --busid <BUSID>'."
  fi
fi

# Verify display forwarding for WSLg.
if [ -n "${DISPLAY:-}" ] && [ -S "/tmp/.X11-unix/0" ]; then
  echo "WSLg display socket active."
elif [ -n "${DISPLAY:-}" ]; then
  echo "WARNING: DISPLAY is set (${DISPLAY}) but X11 socket is not available."
  echo "WSLg may have been disrupted. Run 'wsl --shutdown' and reopen VS Code."
else
  echo "DISPLAY not set — WSLg forwarding is not active. GUI tools will not work."
fi

echo "STM32 devcontainer post-start check complete."
