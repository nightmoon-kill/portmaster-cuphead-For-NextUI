# Cuphead for PortMaster on NextUI

The original PortMaster version of Cuphead wouldn’t run on NextUI—it just wouldn't launch. Once I finally got it to boot, the audio was broken. I decided to dig into it and find a fix, and now that it's working.
PS. I used the Cuphead game files version 1.3.3 for playtesting.   

## Downloads

Get the assets from [Releases](https://github.com/nightmoon-kill/portmaster-cuphead-For-NextUI/releases).

- `cuphead-nextui-2026.10.31.zip`: complete upstream port/runtime/setup tools with the NextUI launchers, based on upstream release **2026.10.28.3**. This is not the complete PortMaster manager or NextUI firmware.
- `cuphead-nextui-scripts-2026.10.31.zip`: launcher-only update for an existing installation of that upstream release.
- `SHA256SUMS.txt`: checksums for both downloads.

No Cuphead game data, converted game APK/OBB, installers, saves or personal logs are included. The full package retains upstream's blank Unity donor APKs: these provide engine scaffolding for conversion and are not the Cuphead game. Runtime binaries and third-party notices are retained unchanged from upstream.

## Installation

1. Install the PortMaster Pak for NextUI first. This release assumes its working Ports launcher and `EMU_DIR` environment.
2. Extract the chosen ZIP into `Roms/Ports (PORTS)/.ports/` on the SD card. The resulting paths are `.ports/Cuphead.sh` and `.ports/cuphead/`. NextUI's PortMaster Pak copies the menu script to the visible Ports folder; if necessary, copy `.ports/Cuphead.sh` to `Roms/Ports (PORTS)/Cuphead.sh` yourself.
3. For a fresh installation, supply your own GOG macOS Cuphead copy in `.ports/cuphead/gamedata/` and follow [upstream setup instructions](https://github.com/wild1walker/portmaster-cuphead#install). Conversion is still required on first launch.
4. Start Cuphead from Ports. Back up existing saves before updating; neither release archive contains saves or deletes them.

## Changes

- `Cuphead.sh`: prefer `$EMU_DIR/control.txt` for NextUI's PortMaster location.
- `cuphead/launch64.sh`: create temporary native EGL/GLES aliases under `/tmp`, prefer the device drivers over the conflicting GL4ES path, and select SDL display output. Remove aliases after the process exits.
- Route 64-bit audio through system `aplay`: stereo S16_LE, 48000 Hz, `plughw:0,0`, 160 ms buffer and 20 ms period. If `aplay` is absent, retain SDL DSP output with an explicit log message; that fallback has not resolved the reported audio issue.
- Keep the 512-frame engine hint and 2048-sample SDL fallback buffer. Diagnostic shim tracing is off in this release. No extra diagnostic Python helper is needed.

The Unity/Mono host, conversion tools and core port are upstream's work. This release reconstructs the successful launcher changes on the pinned upstream package; it is not a dump of the owner's SD card. The packaged clean-install conversion and release ZIP have not been tested on hardware. The successful device test used already-converted game data.

## Reproducible packaging

Run `python tools/build_nextui_release.py --output dist` to download the pinned upstream archive, verify its SHA256, apply only the two launcher overlays and assemble the two downloads. Packaging never reads a user's game installation. GitHub Actions runs syntax and packaging checks before publishing.

## Credits and licence

Original port: **wild1walker** and contributors. NextUI compatibility adjustments: **nightmoon-kill**. Keep the MIT licence and all upstream third-party notices when redistributing. See `LICENSE` and the full package's `cuphead/licenses/` directory.
