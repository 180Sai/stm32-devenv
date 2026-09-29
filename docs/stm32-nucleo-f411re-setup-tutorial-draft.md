# STM32 for Beginners: Two Ways to Set Up Your NUCLEO-F411RE (CubeIDE or VS Code)

*Draft v1 — 2026-09-29. All screenshots are `[SCREENSHOT: …]` placeholders; the full shot list is in Appendix A (Visual Checklist). Anything not yet verifiable is marked `[PLACEHOLDER: …]`.*

---

## Table of Contents

1. About this tutorial and how to read it
2. What you need and what gets installed (the dependency map)
   - 2.1 Hardware checklist
   - 2.2 Path A — what the CubeIDE installer brings
   - 2.3 Path B — what the VS Code extension pack brings
   - 2.4 One thing to know up front: the extension is now 3.x
   - 2.5 Network requirements (mandatory vs. optional)
   - 2.6 Accounts: ST sign-in vs. guest checkout
   - 2.7 Drivers
3. Hardware bring-up (shared, do this first)
   - 3.1 Plug in and watch the LEDs
   - 3.2 Verify the board from the OS
   - 3.3 Linux/macOS: permissions and udev
   - 3.4 What you should see: Mass Storage + virtual COM port
4. Workspace prep (shared — do this once, before either path)
   - 4.1 Folder layout and naming rules
   - 4.2 Why path names matter
   - 4.3 Version control: `git init`
   - 4.4 What those project files are
   - 4.5 Archive / export workflow
5. Path A — Bare STM32CubeIDE
   - 5.1 Download and install
   - 5.2 First launch: workspace dialog and license screen
   - 5.3 New Project wizard → Board Selector → NUCLEO-F411RE
   - 5.4 The .ioc overview
   - 5.5 Generate the project
   - 5.6 Smoke test: insert the two lines
   - 5.7 Build, flash, debug
6. Path B — VS Code + the STM32CubeIDE for VS Code extension
   - 6.1 Install VS Code and the extension pack
   - 6.2 The Bundle Manager populates the toolchain
   - 6.3 First project creation (CubeMX2)
   - 6.4 ⚠️ Compatibility preflight checkpoint (NUCLEO-F411RE)
   - 6.5 Fallback: bare CMake project mode
   - 6.6 Smoke test
   - 6.7 Debug with the ST DAP implementation
   - 6.8 Sidebar: "I'm following 2.x-era docs"
7. Troubleshooting
8. Next steps and references

**Appendix A — Visual checklist (shot table)**
**Appendix B — Smoke-test snippet and the placement rule**

---

## 1. About this tutorial and how to read it

The thesis of this tutorial is simple: **the board stays the same, the tooling is what varies.** You will use the same NUCLEO-F411RE board, generate the same blink project, and run the same smoke test — twice, once per setup path. Only the editor and the toolchain underneath it differ.

- **Path A — bare STM32CubeIDE.** ST's all-in-one Eclipse-based IDE. One installer, everything bundled. The most forgiving route for a first board.
- **Path B — VS Code + the STM32CubeIDE for Visual Studio Code extension (official ST pack).** Lighter editor, modular tooling, current ST direction.

The two paths are kept **strictly separate** so you never mix up their steps. The shared sections (§3, §4) are done once, before either path.

**Who this is for:** you own (or are about to buy) a NUCLEO-F411RE board, you use a Windows PC (Linux/macOS differences are called out in boxes where they matter), you have basic programming familiarity, and you have never set up an embedded toolchain before.

**What this tutorial is *not*:** this is not an embedded-C course. There is no HAL teaching, no code-structure explanation, and no peripheral-configuration tutorial. The only code you will see is a two-line smoke test. Likewise, **headless/CI builds are intentionally out of scope** — this document covers the interactive GUI flows only (a future tutorial may cover command-line builds).

**A note on images:** every image in this document is a placeholder describing what to capture, what to crop, and what to annotate. See the Visual Checklist in Appendix A for the complete table. The annotation philosophy throughout: **red-circle or highlight the one thing that matters, crop tight, and never paste a full cluttered window.** An un-annotated screenshot teaches nothing; a cluttered one teaches less.

---

## 2. What you need and what gets installed (the dependency map)

### 2.1 Hardware checklist

| Item | Requirement | Notes |
|---|---|---|
| NUCLEO-F411RE board | The constant in this tutorial | STM32F411RE on a NUCLEO-64 form factor; onboard ST-LINK/V2-1 programmer+debugger |
| USB cable | **Data-capable micro-USB** | The #1 beginner gotcha: charge-only cables power the board but the PC never sees it. If the PC doesn't detect anything, try another cable first. |
| PC | Windows 10/11 (this tutorial), Linux or macOS with callouts | See §3.3 for Linux/macOS permission notes |
| Internet | Mandatory for one-time downloads; see §2.5 | ST bundle/pack servers required for Path B |
| (Optional) second USB cable / breadboard | Not required for the smoke test | LD2 is onboard, on PA5 |

> **[SCREENSHOT: Labeled photo of NUCLEO-F411RE — top view, centered. Annotations: ① micro-USB connector (ST-LINK), ② LD1 COM LED, ③ LD2 user LED (green, PA5), ④ LD3 power LED, ⑤ the two ST-LINK jumpers area, ⑥ Arduino-compatible headers left/right. Crop: just the board on a neutral background. Do NOT photograph the whole desk.]**

### 2.2 Path A — what the CubeIDE installer brings

STM32CubeIDE is a single all-in-one installer. One download, one install, and you are done with tooling:

| Component | Role | From where |
|---|---|---|
| **STM32CubeIDE** (Eclipse-based) | The IDE itself | The one installer |
| **GCC Arm toolchain** (arm-none-eabi-*) | Compiler + assembler + linker | Bundled |
| **GDB debugger** | Breakpoints, stepping, watch | Bundled |
| **STM32CubeMX (project configurator)** | Pin/clock/peripheral configuration, code generation | Bundled (integrated) |
| **STM32CubeProgrammer** | Flashing utility | Bundled |
| **STM32 firmware packages** (e.g., STM32CubeF4) | HAL drivers, board support for codegen | Downloaded on demand from within CubeIDE (a few hundred MB) |

There is nothing else to install for Path A on modern Windows. On Windows 7/8-era systems you may need the ST-LINK USB driver; on Windows 10+ the virtual COM port and ST-LINK enumerate out of the box (see §2.7).

> **[SCREENSHOT: CubeIDE download page on st.com — crop to the download button area, red-circle the version dropdown or the download button. Optional second shot: the installer's component list screen (workbench + toolchain) showing everything checked.]**

### 2.3 Path B — what the VS Code extension pack brings

Path B is: **VS Code + the official ST extension pack** (`stmicroelectronics.stm32-vscode-extension`, "STM32CubeIDE for Visual Studio Code", ~369k installs, free, in the VS Code Marketplace).

The extension is a **pack**: one install pulls in several pieces. What ships inside (current 3.x):

| Component | Role | Notes |
|---|---|---|
| **Extension pack** (GUI) | Project views, board manager, serial monitor, commands | The single thing you install in §6.1 |
| **Bundle Manager** | Downloads and updates the CLI tools (compiler, GDB server, programmer, CMake, Ninja) as "bundles" | **Replaces the old all-in-one STM32CubeCLT package (see §2.4)** |
| **STM32CubeMX2** (now integrated) | Project configuration and code generation (the newer, pack-aware CubeMX) | Only generates for packs that carry STM32Cube metadata — see the §6.4 preflight |
| **CMSIS-PACK DFPs** | Device support (descriptions of the MCU, register maps, startup) | Downloaded per device family; no more waiting for a whole new CLT release to support a new chip |
| **Microsoft CMake Tools** | Drives the CMake build | Ships with the pack |
| **clangd** | C/C++ code indexing and navigation | Ships with the pack |
| **ST Debug Adapter Protocol (DAP) implementation** | Launch/attach debugging over ST-LINK (and SEGGER J-Link) probes | New in 3.x, replaces the older debug glue |
| **Build Analyzer, Peripheral Inspector, RTOS views, Serial Monitor** | Extras | Board Manager (ST-LINK firmware updates) included in the pack UI |

> **[SCREENSHOT: VS Code Extensions marketplace entry for "STM32CubeIDE for Visual Studio Code" — crop the search box + the Install button; red-circle the extension name. Do not screenshot the whole marketplace page. Optional second shot: the pack's "extension dependencies/pack" section listing CMake Tools and clangd.]**

### 2.4 One thing to know up front: the extension is now 3.x

This matters because **most existing blog posts and YouTube videos describe the previous 2.x architecture, and it no longer matches what you will see.**

What changed in 3.x (verified against the Marketplace changelog and ST's own docs, 2026-09-29):

- **STM32CubeCLT is being replaced by a bundle manager.** In 2.x you installed STM32CubeCLT (the command-line toolset: GCC Arm toolchain, GDB, STM32CubeProgrammer, CMake, Ninja) as a separate, all-in-one package. In 3.x, VS Code downloads those tools for you as *bundles* — with the Bundle Manager view to track/update them.
- **Device support is decoupled** via CMSIS-PACK DFPs, so a newly released MCU no longer requires a full CLT update.
- **STM32CubeMX is now "STM32CubeMX2"** — integrated with the pack, and it only "sees" packs that contain STM32Cube-specific metadata. Other CMSIS-PACKs can be installed, but they are invisible to CubeMX2 and unused for code generation.
- **Debugging** uses a new ST-provided DAP implementation (ST-LINK and SEGGER J-Link), simplifying launch configuration.
- **clangd** now powers C/C++ indexing (instead of the older C/C++ extension reliance).
- Update rule the docs state explicitly: **uninstall the old version before installing the new one** (see §7).

There is an official **2.x → 3.x migration page** in ST's docs (link in §8) — if you already have 2.x installed, read it before updating.

### 2.5 Network requirements (mandatory vs. optional)

These are **verified requirements** for the 3.x extension — useful for corporate/proxied networks:

| Endpoint | Purpose | Mandatory? |
|---|---|---|
| `https://developer.st.com/bundles` | Initial install + keeping CLI tool bundles updated | **Mandatory** |
| `https://developer.st.com/st-pack-server/` | Product/device description data (packs) | **Mandatory** |
| `https://stmicroelectronics.d3.sc.omtrdc.net/…` | Adobe Analytics anonymous telemetry | Optional — no functional impact if blocked |

If bundle or pack downloads fail in a locked-down environment, check that these two domains are reachable (and your proxy allows them) — this is the first thing to verify per the troubleshooting table (§7).

**Where packs live on disk** (useful for backing up or debugging pack weirdness):

- Windows: `$HOME/AppData/Local/stm32cube/packs`
- Linux: `$HOME/.local/share/stm32cube/packs`
- macOS: `$HOME/Library/Application Support/stm32cube/packs`

> **[SCREENSHOT: Bundle Manager view inside VS Code — show the list of CLI tool bundles with download/update status. Red-circle the "Check for updates"/download-toast area if visible. Optional: the packs folder in a file manager, cropped to the folder list.]**

### 2.6 Accounts: ST sign-in vs. guest checkout

Two things to know so nobody stalls on a login wall:

1. **st.com downloads work as a guest.** The download flow asks for name/email/company/country and requires accepting the EULA — but you do **not** have to register an account. A free ST account is convenient (it auto-fills those forms, keeps download history, and is needed for the ST Community forums), but it is never mandatory for installing anything in this tutorial.
2. **The VS Code extension needs no ST form at all** — you install it straight from the VS Code Marketplace with one click. This is one of the nice beginner wins of Path B: no st.com account interaction for the tooling itself (firmware packs may still prompt during project generation).

### 2.7 Drivers

- **Windows 10/11:** nothing to install. The ST-LINK/V2-1 on the NUCLEO-F411RE enumerates as a debug probe + virtual COM port using inbox drivers.
- **Older Windows (7/8):** you may need the *ST-LINK USB driver* from st.com.
- **Linux:** see §3.3 (udev rules + `dialout` group membership).
- **macOS:** generally works out of the box; if a stale ST-LINK firmware causes issues, the Board Manager in Path B can update ST-LINK firmware (see §6.7).

---

## 3. Hardware bring-up (shared, do this first)

This section is identical for both paths. Do it once, before installing anything — a working connection makes the rest of the tutorial feel less abstract.

### 3.1 Plug in and watch the LEDs

1. Connect the board to your PC with a **data-capable micro-USB cable** (see §2.1 — charge-only cables are the #1 false start).
2. Within a few seconds you should see:
   - **LD3** (power indicator) lit red;
   - **LD1** (COM/communication) lit green — this is the ST-LINK talking to the PC;
   - **LD2** (user LED, green, wired to PA5) — starts **blinking** because NUCLEO boards ship with a pre-loaded demo firmware.

> **[SCREENSHOT: Photograph of the board in place with only the three LEDs in frame (macro/crop). Annotations: LD1 COM green (arrow), LD2 user green PA5 (arrow), LD3 power (arrow). Rule: crop tight; a macro shot beats a full-board shot here.]**

The pre-loaded blink pattern is the board's own demo. **You are not expected to do anything with it** — the smoke test in §5.6/§6.6 will prove your *own* firmware was flashed by using a distinctive 500 ms blink (see §5.6 for why that specifically).

### 3.2 Verify the board from the OS

**Windows — Device Manager:**

1. Open Device Manager (Win+X → Device Manager).
2. Expand **Ports (COM & LPT)** — you should see a **virtual COM port** (named something like *STM32 STLink Virtual COM Port (COMx)*).
3. Under **Universal Serial Bus devices** you should also see the **ST-LINK** entry, and under disk drives a **USB Mass Storage** device (the board's virtual flash drive).

> **[SCREENSHOT: Device Manager cropped to show the three relevant trees (Ports, USB devices, Disk drives). Red-circle the virtual COM port entry and the ST-LINK entry. Crop tight — nothing else in frame.]**

**Linux** — `lsusb`, and the serial device:

```bash
lsusb          # look for "STMicroelectronics ST-LINK/V2.1" or similar
ls -l /dev/ttyACM*   # the virtual COM port usually appears as ttyACM0
```

**macOS** — System Information → USB, or `lsusb` via Homebrew; the VCP shows as `/dev/cu.usbmodem*`.

> **[SCREENSHOT: side-by-side comparison — left: Windows Device Manager excerpt; right: Linux `lsusb`/`ls -l /dev/ttyACM*` terminal output. Annotations: red-circle the ST-LINK/VCP lines on each side, and add a "≈ same result, two OSes" caption. Keep both panes small.]**

### 3.3 Linux/macOS: permissions and udev

**Linux** — two things commonly bite:

1. **udev rules:** most distros work out of the box, but if the board never appears, add ST's udev rule (`60-stlink.rules` or similar — shipped with ST tools / available from the ST community) and reload: `sudo udevadm control --reload-rules && sudo udevadm trigger`.
2. **User groups:** your user must be in the `dialout` group (Debian/Ubuntu family) to open the serial port: `sudo usermod -aG dialout $USER`, then log out and back in.

**macOS:** no udev equivalent; if a serial tool can't see the port, confirm the cable is data-capable (yes, again — this bites everyone at least once).

### 3.4 What you should see: Mass Storage + virtual COM port

Two interesting features of the NUCLEO-64's ST-LINK that you'll use later:

- **Mass Storage drive:** the board mounts as a tiny USB drive (named like `NODE_F411RE`). It exposes the drag-and-drop flashing mechanism — you can drop a `.bin`/`.hex` onto it if you ever need a no-IDE flash. *(Note: with ST-LINK firmware updates, this drive can become disabled and re-enabled — that's the "double-tap" recovery in §7.)*
- **Virtual COM port:** the ST-LINK bridges the target's USART2 to USB, giving you a serial console without any extra hardware. You won't use it in this tutorial (smoke test is LED-only), but its presence in Device Manager is your "board is healthy" check.

If any of these are missing, go straight to §7 (Troubleshooting) — particularly the *board not detected* row.

---

## 4. Workspace prep (shared — do this once, before either path)

Both paths generate projects that live in folders. A little discipline now saves real pain later. This section is the same for Path A and Path B.

### 4.1 Folder layout and naming rules

Adopt a scheme like this on your PC:

```
C:\dev\
  nucleo-f411re\
    path-a-cubeide\      ← Path A project folder (if you try Path A)
    path-b-vscode\       ← Path B project folder (if you try Path B)
    shared-docs\         ← notes, pinouts, datasheets
```

Rules:

- **Drive root or a shallow folder** (`C:\dev\`, `C:\projects\`) — not buried inside the user profile or Program Files.
- **No spaces, no accents, no special characters** in any path component. `my_project` not `My Project`, `blinky-f411` not `blinky F411 (final)`.
- **Lowercase + hyphen/underscore** only, for maximum cross-tool sanity (Make/CMake/Eclipse all tolerate it, terminals appreciate it).
- Keep the **NUCLEO-F411RE family name** in your folder name so a shelf of boards doesn't turn into a guessing game.

> **[SCREENSHOT: File Explorer showing the folder scheme above. Two-line annotation: "root of C:\, no spaces" with a red arrow to the path bar.]**

### 4.2 Why path names matter

Embedded toolchains are the crankiest tools on your machine when it comes to paths:

- **Spaces** break makefiles, CMake generators, and debugger working-directory parsing in ways that are infuriating to diagnose ("missing separator", "unexpected token", "launch failed: file not found").
- **Program Files** is both a space-containing path *and* a UAC-protected location — the IDE may not be able to write build artifacts there without elevation.

One sentence version: **if anything in your path has a space, stop and move the folder.** This one rule eliminates a whole class of beginner errors.

### 4.3 Version control: `git init`

Before generating your first project:

```bash
cd C:\dev\nucleo-f411re
git init
```

Then `git add` + commit after each milestone (project generated, smoke test passing, etc.). Rationale:

- The whole point of the smoke test is to prove *your* build worked; git gives you the "before" and "after" to diff.
- STM32CubeMX codegen **regenerates files** — when you change the `.ioc` later, git shows you exactly what changed and lets you revert.
- A `.gitignore` for the generated noise (CubeIDE: `Debug/`, `Release/`; both paths: `build/`, `cmake-build-*/`) is worth adding on day one.

> **[SCREENSHOT: terminal showing `git init` + first commit output. Annotations: none needed beyond a red circle on the branch/commit summary line. Keep it tiny.]**

### 4.4 What those project files are

After generation you'll see files you didn't write. Half a page of orientation, no more:

| File/dir | What it is |
|---|---|
| `.ioc` (CubeMX/CubeMX2) | The **configuration source of truth** — pins, clocks, peripherals. You edit this; the code is (re)generated from it. |
| `main.c`, `stm32f4xx_hal_*` | Generated C sources; HAL driver library. **Edit only inside the `USER CODE` sections** (see Appendix B) or your edits get overwritten on regeneration. |
| `CMakeLists.txt` / `CMakePresets.json` | The build definition (both paths now use CMake under the hood). |
| `.project`, `.cproject`, `.launch` (Path A) | Eclipse project metadata + debug launch configuration. Don't hand-edit. |
| `.vscode/` (Path B) | VS Code workspace settings, tasks, and launch configs. Don't hand-edit unless you know what you're doing. |

Rule of thumb: **treat everything generated as disposable, and the `.ioc`/source edits you actually make as the only things you own.** That mental model is what makes regeneration anxiety-free.

### 4.5 Archive / export workflow

Two workflows worth knowing before you need them:

1. **Plain folder copy/zip.** Close the IDE first (both IDEs hold file locks and caches), then zip the project folder. Exclude `Debug/`, `Release/`, `build/`, and `.metadata/` (Eclipse workspace metadata — it's machine-specific and bloats the archive). A clean zip of the sources + `.ioc` is a perfectly shareable project.
2. **CubeIDE's own export** (Path A): `File → Export → General → Archive File` gives a filtered archive from inside the IDE.

> **[SCREENSHOT: right-click project → Export dialog in CubeIDE, crop to the export wizard list with "Archive File" highlighted.]**

---

## 5. Path A — Bare STM32CubeIDE

Everything in this section happens **only** in the CubeIDE world. If you're also doing Path B later, nothing here conflicts — they are separate toolchains in separate folders.

### 5.1 Download and install

1. Go to the STM32CubeIDE page on st.com (see §8 for the link family) and download the installer for your OS.
2. Run the installer. On Windows you can choose the install location — keep the default if unsure, but remember the **no-spaces rule applies to your *project* folders, not to the IDE install location** (the official installer paths are fine).
3. The installer may offer optional components (e.g., a standalone STM32CubeProgrammer or ST-LINK driver for old Windows). All optional items can be left at their defaults for this tutorial.
4. First launch: the installer finishes by opening the IDE. The welcome screen may offer to download device support / firmware — accept it; it saves a step later. The STM32CubeF4 firmware package will be needed when the project wizard generates code for the F411RE (a few hundred MB, one-time).

> **[SCREENSHOT: installer window with checkbox list of components, red-circle the main IDE + toolchain components; caption "accept the defaults". [PLACEHOLDER: versions/release numbers of the STM32CubeIDE installer at time of writing]]**

A free **ST account is not required** for download — guest checkout works (see §2.6) — but having one makes the form-filling faster.

### 5.2 First launch: license screen and workspace dialog

Two dialogs appear the first time:

1. **License/agreement screen** — multiple license radio choices (commercial vs. community terms). All are usable for this tutorial; pick the one matching your situation and accept.
2. **Workspace dialog** — Eclipse asks where to store its workspace (settings, not your code). Point this at something shallow like `C:\dev\nucleo-f411re\cubeide-workspace`. Your projects will live *inside* this workspace folder by default — which is exactly why §4's folder scheme puts it under `C:\dev\`.

> **[SCREENSHOT: the CubeIDE workspace launcher dialog, red-circle the path field; caption: "pick a shallow, space-free path — see §4.2"].**

### 5.3 New Project wizard → Board Selector → NUCLEO-F411RE

1. `File → New → STM32 Project` (or the "Create a new STM32 project" tile on the welcome screen).
2. **Board Selector tab** → type `NUCLEO-F411RE` in the filter → select the *NUCLEO-F411RE* board entry → Next. (The MCU Selector tab is the alternative for bare-chip projects — not what we want here.)
3. Name the project (e.g., `blinky-f411`), pick a location under your workspace, accept the default toolchain (STM32CubeIDE bundled GCC) and firmware package (STM32CubeF4) → Finish.
4. Answer **Yes** to "Initialize all peripherals with their default mode?" when offered — the defaults already drive LD2.

> **[SCREENSHOT: New Project wizard → Board Selector tab with "NUCLEO-F411RE" typed in the filter, the board row selected. Red-circle the filter box and the board row; do NOT screenshot the whole wizard at full window.]**

### 5.4 The .ioc overview

The project opens showing the **`.ioc` device configuration view** (the CubeMX graphical editor, integrated):

- Left: the **pinout diagram** of the STM32F411RE — a schematic-style chip with pins color-coded by function.
- Right/center: tabs for **Clock Configuration**, **Pinout & Configuration** (peripherals), and **Project Manager**.

For this tutorial you don't *change* anything: it's enough to see that PA5 is already assigned to the user LED (`GPIO_Output`, label `LD2` — the NUCLEO board definition wires this up for you). This view is where all future configuration happens, but that's a later tutorial (remember: no peripheral-config teaching here, by design).

> **[SCREENSHOT: the .ioc pinout editor with PA5/LD2 highlighted — red-circle PA5's label (`LD2`) and the green GPIO_Output color coding; caption: "your user LED is already wired in the board definition".]**

### 5.5 Generate the project

Click **Generate Code** (the gear icon / Ctrl+S equivalent in CubeIDE). The IDE now creates the full HAL project tree: `Core/Src/main.c`, the HAL driver sources, startup files, and build configuration. When generation finishes you're looking at `main.c` with the HAL's generated `main()` — including an empty `while (1)` loop with a `USER CODE` section inside it.

> **[SCREENSHOT: Project Explorer tree of the generated project (Core/, Drivers/, .ioc file). Red-circle the `main.c` node or the `.ioc`; crop to the tree pane.]**

### 5.6 Smoke test: insert the two lines

This is the *only* code in this tutorial — and the only rule that matters is **where** it goes:

1. In `Core/Src/main.c`, find the `while (1)` loop in `main()`.
2. Inside it there is a pair of marker comments:

```c
  /* USER CODE BEGIN 3 */
  /* USER CODE END 3 */
```

3. Place the two lines **between those markers** (so they survive the next code regeneration):

```c
  /* USER CODE BEGIN 3 */
  HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);  /* LD2 green LED, PA5 */
  HAL_Delay(500);
  /* USER CODE END 3 */
```

**Why 500 ms?** The factory demo blinks at one speed; newer ST demo samples often blink at 200 ms; older ones at 1 s. A 500 ms blink is deliberately **distinguishable by eye from all of them** — so when you see it, the code you flashed is *your* build, not leftover demo firmware. That's the entire smoke test: it validates the toolchain→board path (compile, link, flash, reset) and nothing more. UART echoes, timers, and peripheral checks are deliberate future work.

Also note: **no extra loop of your own** — the template's `while (1)` is already looping; you only add the two lines inside it.

> **[SCREENSHOT: main.c showing the USER CODE BEGIN 3 / END 3 block with the two inserted lines. Red-circle the marker comments and the two lines; crop to ~15 lines of code, no chrome.]**

### 5.7 Build, flash, debug

**Build:** click the hammer icon (or `Project → Build Project`). Watch the Console for `Build Finished` with 0 errors, 0 warnings. The output artifact lands in `Debug/` as `blinky-f411.elf`.

**Flash:** click **Run** (or `Run → Debug As → STM32 Cortex-M C/C++ Application`). CubeIDE builds, launches a debug session, and flashes via the onboard ST-LINK automatically. The board resets and the LED starts blinking — **500 ms — your build is on the board.**

**Debug (the part to try next):**

1. In the code, click in the gutter next to the `HAL_Delay(500);` line to set a **breakpoint** (blue dot).
2. `Run → Debug` again. Execution halts at the breakpoint.
3. Open `Window → Show View → Variables` and add `GPIOA->ODR` or a watch on the LED state — step (F6) through the toggle and watch the register change.

That's the whole loop: **code → build → flash → debug**, all inside one tool, with zero config. This is Path A's appeal.

> **[SCREENSHOT: CubeIDE in debug perspective — editor with a breakpoint marker on the HAL_Delay line, Variables view populated in the lower right. Red-circle the breakpoint dot and one Variables row. Crop out the rest of the window.]**

**Optional GIF:** stepping over `HAL_GPIO_TogglePin` with the Variables view updating. Keep it short (<5 s) — it's a demo, not a movie.

---

## 6. Path B — VS Code + the STM32CubeIDE for VS Code extension

Everything in this section happens **only** in the VS Code world. If you did Path A first, no conflicts — separate folders, separate tooling.

### 6.1 Install VS Code and the extension pack

1. Install **VS Code** from code.visualstudio.com (stable channel).
2. Open the **Extensions** activity bar (Ctrl+Shift+X), search for `STM32`, and install **STM32CubeIDE for Visual Studio Code** — publisher *STMicroelectronics*, slug `stmicroelectronics.stm32-vscode-extension` (~369k installs, free).
3. VS Code may prompt to install the pack's dependencies (CMake Tools, clangd) — accept. The pack itself pulls in what it needs.
4. **No ST account, no st.com form** for this step — one-click Marketplace install (see §2.6).

> **[SCREENSHOT: Extensions view with "STM32" search and the STMicroelectronics pack listed, Install button visible. Red-circle the publisher name + Install button; crop the sidebar only.]**

### 6.2 The Bundle Manager populates the toolchain

With 3.x, the **Bundle Manager** downloads the CLI tools (GCC Arm toolchain, GDB, STM32CubeProgrammer, CMake, Ninja — the pieces that used to come as the monolithic STM32CubeCLT) as modular bundles:

1. Open the **Bundle Manager** view (it appears in the STM32 activity view / status bar after install).
2. Trigger a download/check-for-updates (the view offers install/update actions; first run may do this automatically).
3. Wait for the bundles to finish — they are sized in the hundreds of MB total, so the status bar shows progress. **This is the step that needs the mandatory ST servers** (§2.5).
4. When green/complete, the toolchain is ready. You can inspect which bundles are active from the same view.

If downloads fail here, jump to §7 *bundle/pack download fails* — it's almost always firewall/proxy or a charge-only-cable false alarm is not it this time, it's network.

> **[SCREENSHOT: the Bundle Manager view mid-download (progress rows) or complete. Red-circle a bundle row and the status/progress indicator. [PLACEHOLDER: exact bundle names/labels shown by the 3.x Bundle Manager view at time of writing]]**

### 6.3 First project creation (CubeMX2)

1. Open the command palette (Ctrl+Shift+P) and run the ST project creation command (e.g., `STM32: Create Project` — [PLACEHOLDER: confirm the exact 3.x command label from the Extension Commands docs page]).
2. The integrated **STM32CubeMX2** flow starts: choose project mode and target device.
3. Type `F411RE` (or `NUCLEO-F411RE`) when prompted for the part/board.

> **[SCREENSHOT: command palette with the ST create-project command selected. Red-circle the command. Optional second shot: the CubeMX2 device/board picker with "F411RE" filtering results.]**

### 6.4 ⚠️ Compatibility preflight checkpoint (NUCLEO-F411RE)

**Stop here and check this deliberately — it's the one place in this tutorial where upstream conditions could differ from what we describe.**

CubeMX2's part support depends on the **installed device-support pack (DFP) containing STM32Cube metadata for the part**. Crucially, CubeMX2 is **not** "newer-models-only": support is per-pack. The F411RE is a 2014-era, extremely popular part, so support is *expected* — but ST's pack contents change over time and we could **not verify today's exact pack contents** for the F411RE at writing time. [PLACEHOLDER: verify at time of writing whether the NUCLEO-F411RE appears in the CubeMX2 board picker with current packs; update this section if not]

**The checkpoint:** after project creation begins, does **NUCLEO-F411RE appear in the picker / does project generation complete with HAL code for the F411RE?**

- **Yes** → proceed to §6.6.
- **No** (part missing from picker, or generation errors about missing device support) → use the **fallback in §6.5**, or switch to Path A, which covers all families unconditionally (its firmware is bundled, no pack dependency).

### 6.5 Fallback: bare CMake project mode

If the F411RE is not available through CubeMX2's packs, the same extension still works via its **empty/bare CMake project mode** — you just don't get code generation:

1. Create an **Empty Project** (CMake-based) through the same ST project creation flow.
2. Wire the **STM32CubeF4 HAL** into the project manually: add the HAL source/include paths and the `stm32f4xx_hal_conf.h`/`stm32f4xx_hal.h` setup to `CMakeLists.txt` (the ST docs' CMake page — link in §8 — covers the project shape).
3. Write `main.c` yourself (or adapt a HAL blinky example from the STM32CubeF4 package) and build.

This is more work, and it's the one place where this tutorial's "no embedded-C teaching" rule means you may need to consult the ST examples. Plan B if you'd rather not: **Path A handles the F411RE unconditionally**.

> **[SCREENSHOT: the empty-project creation flow with the CMake template selected. [PLACEHOLDER: confirm the 3.x empty-project dialog labels]]**

### 6.6 Smoke test

The smoke test is **identical to Path A's** (§5.6) — same two lines, same placement rule, same 500 ms rationale:

```c
  /* USER CODE BEGIN 3 */
  HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);  /* LD2 green LED, PA5 */
  HAL_Delay(500);
  /* USER CODE END 3 */
```

If your project generated via CubeMX2, the `USER CODE BEGIN 3 / END 3` markers already exist in `main.c` — put the lines between them. In the fallback bare-mode project there are no markers; keep the two lines at the top of your `while (1)`.

Build via the **CMake Tools** status-bar button (or the CMake extension's build command), then flash and run (§6.7). **What you watch for is the same**: a solid 500 ms blink — *your* build, not the factory demo.

> **[SCREENSHOT: VS Code editor showing the same two lines inside USER CODE BEGIN 3/END 3, CMake status bar visible at the bottom. Red-circle the markers. Caption: "identical to §5.6 — the board stays the same, only the tooling differs".]**

> **[SCREENSHOT (optional, powerful): side-by-side — CubeIDE and VS Code open with the same `main.c` snippet visible in both. Caption: "same file, same two lines — this whole tutorial in one image".]**

### 6.7 Debug with the ST DAP implementation

3.x ships a new ST-provided **Debug Adapter Protocol (DAP)** implementation supporting **ST-LINK** (and SEGGER J-Link) probes — no third-party debug extension needed:

1. Open the **Run and Debug** view and create a launch configuration using the ST DAP type (the ST docs' Debug page — link in §8 — gives the exact config; a starter config is usually offered automatically for an ST project).
2. Set a breakpoint on the `HAL_GPIO_TogglePin` line; press F5.
3. The session flashes the board (via ST-LINK) and halts at the breakpoint. Step (F10) and inspect variables/registers in the Debug sidebar.

Also new in the pack: the **Board Manager** view (shows the ST-LINK serial number, can update ST-LINK firmware — handy if Mass Storage disappears after a PC-side ST-LINK driver update).

> **[SCREENSHOT: VS Code debug session at a breakpoint with ST DAP active, Debug sidebar + variable inspection visible. Red-circle the breakpoint and the debug toolbar. [PLACEHOLDER: exact 3.x launch-config labels for the ST DAP type]]**

> **[SCREENSHOT: Board Manager view showing the ST-LINK serial + firmware version, crop to the view pane.]**

### 6.8 Sidebar: "I'm following 2.x-era docs"

Most tutorials you'll find online were written against the **2.x** architecture. If a doc tells you to:

- install **STM32CubeCLT** (the all-in-one command-line toolset) as a prerequisite → in 3.x this is **replaced by the Bundle Manager** (§6.2); you can still install it, but it's not the modern path;
- rely on the older C/C++ extension for indexing → 3.x uses **clangd**;
- set up Cortex-Debug style launch configs → 3.x uses the **ST DAP** implementation (§6.7);
- update the previous extension in place → ST says **uninstall the old version first** (that rule is version-independent, actually).

ST maintains an official **2.x → 3.x migration page** (link in §8) — when a source disagrees with what you see on screen, that page and the FAQ are the tiebreakers.

---

## 7. Troubleshooting

The table you'll actually live in. Symptoms first, fixes second.

| Symptom | Fix |
|---|---|
| **Board not detected at all** | Use a **data cable, not a charge-only one** (the #1 cause). Then: ST-LINK driver on old Windows (see §2.7); on Linux check udev + groups (§3.3). If the board was working and suddenly vanished, see the mass-storage/driver-only behaviour below — some ST-LINK firmware modes disable the COM+drag&drop interface. |
| **Board seems bricked / only Mass Storage appeared and the chip won't run** | **Double-tap the board's reset button** (B1) → the ST-LINK re-enables the Mass Storage drive (drag&drop flashing mode); use it to reflash with the current firmware, then update ST-LINK firmware via the **Board Manager** view (§6.7) if it's older. This is a recovery mode, not a brick — the bootloader is in ROM and can't be killed by a bad user program. |
| **"Cannot activate the 'STM32Cube Debug Core' extension because it depends on an unknown 'STMicroelectronics.st-cube-build-cmake'"** | Known 3.x issue: **restart VS Code**. If it persists, ask on the STM32 VS Code Extension Community forum (link in §8). |
| **Bundle/pack download fails or hangs** | Check access to `https://developer.st.com/bundles` and `https://developer.st.com/st-pack-server/` (§2.5) — both are **mandatory**. Corporate proxy/firewall is the usual culprit: allow both domains, or use the Bundle Manager's retry. |
| **Extension update broke things** | Per ST: **uninstall the old version before installing the new one** (§2.4). If you jumped versions, read the 2.x→3.x migration page (§6.8). |
| **"No source available" at a breakpoint** | You're debugging a build whose source paths don't match (e.g., Release/optimized build, or the file was regenerated after the debug session started). Debug with the **Debug build configuration** (not Release), rebuild, and re-flash; if optimization is on, disable it in the build settings — optimized code reorders lines so breakpoints land on "no source". |
| **Linux: no serial port / can't open it** | udev rules missing or not reloaded, or your user isn't in the `dialout` group — see §3.3. Re-login after `usermod`. |
| **VS Code missing a CubeIDE feature** | Feature-gap note, by design: **live-variable view is not in the initial 3.x release** (ST says efforts are ongoing), and there's no "reset perspective" equivalent. For register-level live inspection use the **Embedded Peripheral Inspector** (ships with the pack); for classic live variables, CubeIDE (Path A) is the tool. |

One meta-tip: **change one variable at a time.** The most frustrating debugging sessions are the ones where the cable, the firmware, the group, and the build config all changed at once.

---

## 8. Next steps and references

**Natural next steps (each is a future tutorial, not this one):**

1. Serial output via the virtual COM port (USART2 on the NUCLEO-64) — now that §3.4 taught you where the port is.
2. A first real peripheral config via the `.ioc`/CubeMX2 (a timer, then an interrupt) — now that §5.4/§6.3 showed you the editor.
3. Version control habits for generated code (git + `.gitignore` for `Debug/`, `build/`) — §4.3 gives the seed.
4. Headless/CLI builds — intentionally out of scope here; the CMake page + UM3088 below are the entry points when you want it.

**References (all verified live 2026-09-29):**

| # | Resource | URL |
|---|---|---|
| 1 | STM32CubeIDE for VS Code — Marketplace listing (pack contents, breaking changes) | https://marketplace.visualstudio.com/items?itemName=stmicroelectronics.stm32-vscode-extension |
| 2 | Official FAQ — 3.x differences, live-variable gap, servers, pack locations | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/troubleshooting/faq.html |
| 3 | Installation guide (extension + cherry-picking sub-extensions) | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/getting_started/installation.html |
| 4 | CMake concepts page | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/basic_concepts/cmake.html |
| 5 | Bundles concept page | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/basic_concepts/bundles.html |
| 6 | Packs concept page | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/basic_concepts/packs.html |
| 7 | First project creation guide | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/getting_started/first_project_creation.html |
| 8 | STM32CubeCLT page (+ UM3088 quick-start PDF) | https://www.st.com/en/development-tools/stm32cubeclt.html |
| 9 | ST Community: CMake integration in CubeMX + VS Code extension | https://community.st.com/stm32-mcus-60/cmake-integration-in-stm32cubemx-and-usage-in-stm32cubeide-for-visual-studio-code-158397 |
| 10 | Community reference: STM32 + VS Code + CMake tutorial (MaJerle) | https://github.com/MaJerle/stm32-cube-cmake-vscode |
| 11 | **2.x → 3.x migration page** (tiebreaker when sources disagree) | https://dev.st.com/stm32cube-docs/stm32cubeide-vscode/latest/en/docs/markup/tutorials/migration.html |

---

## Appendix A — Visual checklist

Every `[SCREENSHOT: …]` placeholder in the document, tabulated. Capture rule for all: **crop tight, red-circle/highlight one element, no full-window clutter.**

| Shot # | Section | What it shows | Annotation |
|---|---|---|---|
| V1 | §2.1 | Labeled photo of NUCLEO-F411RE (top view) | ① micro-USB connector ② LD1 COM ③ LD2 user LED (PA5) ④ LD3 power ⑤ ST-LINK jumpers ⑥ Arduino headers |
| V2 | §2.2 | CubeIDE download page on st.com | Red-circle download button / version selector |
| V3 | §2.2 (alt) | CubeIDE installer component list | All components checked; caption "accept defaults" |
| V4 | §2.3 | VS Code Marketplace listing of the ST pack | Red-circle pack name + Install; show dependency section if possible |
| V5 | §2.5 | Bundle Manager view in VS Code (bundles + status) | Red-circle a bundle row + update/status control |
| V6 | §3.1 | Macro photo of the three LEDs lit | Arrows: LD1 COM, LD2 user, LD3 power |
| V7 | §3.2 | Windows Device Manager (Ports + USB + Disk) | Red-circle virtual COM port + ST-LINK entries |
| V8 | §3.2 | Side-by-side: Device Manager vs. Linux `lsusb`/`ls -l /dev/ttyACM*` | Red-circle matching entries both sides; "same result, two OSes" caption |
| V9 | §4.1 | File Explorer with the `C:\dev\nucleo-f411re` scheme | Arrow to path bar; caption "no spaces, shallow root" |
| V10 | §4.3 | Terminal: `git init` + first commit | Red-circle commit summary line |
| V11 | §4.5 | CubeIDE Export → Archive File dialog | Red-circle "Archive File" in the export wizard list |
| V12 | §5.1 | CubeIDE installer component checklist | Red-circle the IDE + toolchain components; caption "accept the defaults"; [PLACEHOLDER: installer version numbers] |
| V13 | §5.2 | CubeIDE workspace launcher dialog | Red-circle the path field; caption "shallow, space-free path — §4.2" |
| V14 | §5.3 | New Project wizard → Board Selector, "NUCLEO-F411RE" typed in filter | Red-circle filter box + selected board row; no full-window shot |
| V15 | §5.4 | `.ioc` pinout editor, PA5 labeled LD2 in green | Red-circle the `LD2` label + GPIO_Output color coding |
| V16 | §5.5 | Project Explorer tree (Core/, Drivers/, `.ioc`) | Red-circle `main.c` or the `.ioc` node; crop to tree pane |
| V17 | §5.6 | `main.c` with USER CODE BEGIN 3/END 3 + two inserted lines | Red-circle markers and the two lines; ~15 lines of code, no chrome |
| V18 | §5.7 | CubeIDE debug perspective, breakpoint on `HAL_Delay`, Variables view | Red-circle breakpoint dot + one Variables row; crop the window |
| V19 | §6.1 | VS Code Extensions view, ST pack listed | Red-circle publisher name + Install button; sidebar only |
| V20 | §6.2 | Bundle Manager mid-download (progress rows) | Red-circle a bundle row + progress/status indicator |
| V21 | §6.3 | Command palette with the ST create-project command | Red-circle the command; optional: CubeMX2 picker filtered to "F411RE" |
| V22 | §6.5 | Empty-project (bare CMake) creation flow | Red-circle the CMake/empty template selection |
| V23 | §6.6 | VS Code: same two lines in USER CODE markers, CMake status bar visible | Red-circle markers; caption "identical to §5.6 — same board, different tooling" |
| V24 | §6.6 (optional) | Side-by-side: same `main.c` snippet in CubeIDE and VS Code | Caption "same file, same two lines — the whole tutorial in one image"; optional, powerful |
| V25 | §6.7 | VS Code debug session at breakpoint with ST DAP, Debug sidebar | Red-circle breakpoint + debug toolbar |
| V26 | §6.7 | Board Manager view (ST-LINK serial + firmware version) | Crop to the view pane |

**Optional GIF** (not a screenshot — same capture rules): §5.7, stepping over `HAL_GPIO_TogglePin` with the Variables view updating, <5 s.

---

## Appendix B — Smoke-test snippet (reference copy)

The complete snippet referenced by §5.6 and §6.6. One rule governs it: **the two lines live inside the `USER CODE` markers** so they survive code regeneration.

```c
  /* USER CODE BEGIN 3 */
  HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);  /* LD2 green LED, PA5 */
  HAL_Delay(500);
  /* USER CODE END 3 */
```

**Placement:** inside the template's existing `while (1)` loop in `main()`. Do not add your own loop — the template already loops. (Fallback bare-CMake projects, §6.5, have no markers; put the lines at the top of your `while (1)` and expect them to be overwritten by any manual regeneration.)

**Why 500 ms:** the factory demo blinks at ~1 s; newer ST demo samples often blink at ~200 ms. 500 ms is deliberately distinguishable from both by eye — when you see that rate, the code running is *yours*, which is the whole point of the test: it validates compile → link → flash → reset with zero peripherals involved.

**Success criteria (all three):**

1. Build ends with 0 errors (warnings don't matter for this test).
2. The board's LD2 blinks green at a clearly-visible ~500 ms cadence (1 blink per second, on for half).
3. Debugger halts at the breakpoint and the Variables/register view shows `GPIOA->ODR` bit 5 flipping as you step.

If the LED blinks at a different rate, you flashed demo firmware — re-check that the flash step targeted your build, then re-flash.

---

## Before publishing — open items

The `[PLACEHOLDER: …]` flags live inline where they belong; this is the consolidated list:

1. **Version numbers** (§5.1): CubeIDE installer release at time of writing.
2. **Bundle Manager labels** (§6.2): exact bundle names shown by the 3.x view.
3. **ST create-project command label** (§6.3) and **empty-project dialog labels** (§6.5): confirm against the Extension Commands docs page.
4. **ST DAP launch-config labels** (§6.7): confirm against the Debug docs page.
5. **F411RE / CubeMX2 pack support** (§6.4): verify the board appears in the picker with current packs — this is the one upstream condition that could invalidate the Path B happy path; the fallback (§6.5) and Path A remain valid regardless.
6. **All screenshots**: capture per Appendix A (V1–V26), crop tight, one red-circle per shot.
