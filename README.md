# Cuphead for PortMaster on NextUI
Test on Trimui Brick Pro

- Game launch and graphics — launch64.sh
  - Original: Starts the game directly:"$GAMEDIR/ua_host64" "$GAMEDIR/arm64"
  - Modified: Creates temporary aliases for the device’s native EGL/GLES libraries and sets:export LD_LIBRARY_PATH="$gpu_dir:/usr/trimui/lib:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH"
    export SDL_VIDEO_EGL_DRIVER="$native_egl"
    export SDL_VIDEO_GL_DRIVER="$native_gles"
    export UA_DISPLAY=sdl
    This avoids the GL4ES library that caused the startup crash. Temporary aliases are removed when the game exits.
- Audio — launch64.sh
  - Original: The 64-bit launcher does not explicitly route audio through aplay.
  - Modified: When aplay is available, uses:export UA_AUDIO_FRAMES=512
    export ANDROID_SLES_OUTPUT=pipe
    export ANDROID_SLES_PIPE_CMD='exec aplay -q -D plughw:0,0 -t raw -f S16_LE -r 48000 -c 2 --buffer-time=160000 --period-time=20000 -'
    Routes stereo 48 kHz audio through the system player with a 160 ms buffer to resolve audio stuttering. Upstream already uses a similar approach for the 32-bit route on older dArkOS kernels.
- PortMaster detection — Cuphead.sh
  - Original: Selects a PortMaster location using the existing launcher logic, then loads:source $controlfolder/control.txt
  - Modified: Adds priority detection of $EMU_DIR/control.txt to locate NextUI’s PortMaster installation.
- Diagnostics
  - Original: Does not include our additional audio diagnostic helper.
  - Modified: Adds setup/nextui_audio_drivers.py and enables:export ANDROID_SHIM_TRACE=1
    These provide troubleshooting information and are not required for the graphics or audio fixes themselves.
- Core port
  - Unchanged: Uses wild1walker’s existing ua_host64, Unity/Mono runtime, and game conversion system. Our changes primarily adapt the launcher for NextUI.
