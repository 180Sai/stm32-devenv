# STM32 Devcontainer

VS Code devcontainer for STM32 embedded development.

## Contents

- `.devcontainer/devcontainer.json` — container config, VS Code extensions (C/C++, Cortex-Debug, CMake Tools), USB passthrough, WSL mitigations
- `.devcontainer/Dockerfile` — Ubuntu 24.04 + `gcc-arm-none-eabi`, `gdb-multiarch`, CMake/Ninja, OpenOCD, `stlink-tools`, probe-rs
- `.devcontainer/post-create.sh` — toolchain sanity check on container build
- `.devcontainer/post-start.sh` — runtime connectivity check (catches WSLg / Docker socket disruptions)

## Usage

1. Open this folder in VS Code → **Reopen in Container**.
2. Build firmware with CMake Tools or `cmake -G Ninja -B build && cmake --build build`.
3. Flash/debug via Cortex-Debug (OpenOCD or probe-rs).

## Prerequisites

### Docker Desktop on Windows (WSL2 backend)

Docker Desktop must be configured to use the **WSL2 backend** (not Hyper-V or the legacy Windows container engine):

1. Docker Desktop → Settings → **General** → ✅ *Use the WSL 2 based engine*
2. Docker Desktop → Settings → **Resources** → **WSL Integration** → ✅ Enable integration with your WSL2 distribution (e.g. `Ubuntu-24.04`)
3. Restart Docker Desktop and your WSL2 distribution after changing these settings

### USB Passthrough for ST-Link / J-Link (Windows + WSL2)

USB devices are **not** automatically visible inside Docker containers on WSL2. The standard solution is [`usbipd-win`](https://github.com/dorssel/usbipd-win):

```powershell
# Install usbipd-win (one-time)
winget install usbipd

# List attached ST-Link / J-Link probes
usbipd list

# Bind the probe to WSL2 (replace <BUSID> with the bus ID from the list above)
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>

# Verify the device appears inside the WSL2 distribution
lsusb
# Should show your ST-Link/J-Link with vendor/product ID
```

Once the device is attached to WSL2, the devcontainer's `--device-cgroup-rule` and `plugdev`/`dialout` group membership make it accessible inside the container without `--privileged`.

### WSLg (GUI Forwarding)

WSLg provides X11/Wayland forwarding from WSL2 to Windows. It is required if you use GUI tools inside the container (e.g., STM32CubeMX, GDB GUI frontends). Known issues:

- **WSLg can break after Windows feature updates** — if display forwarding stops working, restart WSL (`wsl --shutdown` from PowerShell) and reopen VS Code.
- **`DISPLAY` / `WAYLAND_DISPLAY` may not propagate** into the container — the devcontainer.json explicitly forwards these env vars via `runArgs` and `remoteEnv`.
- **X11 socket permission errors** — the `ro` (read-only) mount of `/tmp/.X11-unix` prevents the container from writing to the socket, which is the correct behavior for forwarding-only.

If you experience a broken connection to the container after a Windows update or WSL restart:
1. Close all VS Code windows
2. Run `wsl --shutdown` in PowerShell
3. Reopen VS Code and reconnect to the container

This sequence resolves the vast majority of WSLg-related devcontainer disconnections.

## WSL-Specific Notes

- **File system performance**: Bind mounts from WSL2 to Docker containers traverse the 9P filesystem bridge, which is slower than native ext4. For large CMake builds with thousands of small object files, expect 2–5× slower incremental builds compared to native Linux. The `consistency=cached` mount option reduces this by caching metadata on the Windows side.
- **Docker socket path**: In WSL2, Docker Desktop mounts the socket at `/var/run/docker.sock` inside the WSL distribution. The devcontainer uses this by default (no extra configuration needed).
- **WSL distribution suspension**: Windows may suspend idle WSL2 distributions to save memory. When you reopen VS Code after a suspension, the container may need to be rebuilt. This is normal and not a configuration error.
- **Network**: WSL2 uses a virtual network adapter; containers can reach the host via `host.docker.internal` (not `localhost`). This matters if your firmware has a network stack or you use a remote GDB server.

## Notes

- `runArgs` uses granular permissions (`--group-add plugdev/dialout`, `--device-cgroup-rule`) instead of `--privileged` for security.
- `gdb-multiarch` is used instead of `arm-none-eabi-gdb` (same functionality, packaged for Ubuntu 24.04).
- STM32Cube library paths are set as environment variables (`STM32_CUBE_*_PATH`) — the libraries themselves are not bundled in the image. See the project's CMake toolchain file for how they are discovered (FetchContent or local install).
- For CI (GitHub Actions), use the Docker image directly without devcontainer — see the project's `.github/workflows/` for an example.
