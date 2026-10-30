# Cuphead's 64-bit build, sourced by Cuphead.sh on a firmware without 32-bit support. Unity has no
# 64-bit Android player for Cuphead's Unity version and its 64-bit players are IL2CPP ones: the
# game's code runs on Unity 2017.4.40f1's 64-bit player through Unity's Mono for aarch64, which the
# port ships (the Mono route; with CUPHEAD_64_IL2CPP=1 the setup compiles the code with IL2CPP
# instead). Its files are its own: setup64/, .cuphead_ready64 and arm64/ (the player, the game, the
# saves in arm64/data/).

T="one to a few hours, once"; [ "${CUPHEAD_64_IL2CPP:-0}" = 1 ] && T="several hours, once"
[ -f "$GAMEDIR/.cuphead_ready64" ] || run_setup "$GAMEDIR/setup64/patchscript" "$T"
if [ ! -f "$GAMEDIR/.cuphead_ready64" ]; then
  if [ -f "$GAMEDIR/gamedata/.setup64/.step_game" ]; then   # (the game's files are taken in: only the rest is left)
    pm_message "The setup stopped before it finished (log: ports/cuphead/patchlog.txt). Launch Cuphead again: it continues where it stopped."
  else
    pm_message "Cuphead (64-bit) is not set up yet: put Cuphead.app or GOG's macOS installers in ports/cuphead/gamedata and launch again (log: ports/cuphead/patchlog.txt)."
  fi
  sleep 8
  pm_finish
  exit 1
fi
dlc_waiting "$GAMEDIR/arm64" && export DLC_TARGET="$GAMEDIR/arm64" && run_setup "$GAMEDIR/setup/dlcscript" "about half an hour, once" no-questions

# the picture shape the setup asked for (aspect.txt: "fill", "16:9" for the game's letterbox on any
# screen, "crop" to fill 4:3 screens too, or a shape such as "4:3" between the two),
# and an optional smaller render size (resolution.txt: a share of the panel's, e.g. 0.75, which the
# display engine scales up to the whole panel)
A=$(cat "$GAMEDIR/aspect.txt" 2>/dev/null); case "$A" in crop|[0-9]*:[0-9]*) export CUPHEAD_ASPECT="$A" ;; esac
R=$(cat "$GAMEDIR/resolution.txt" 2>/dev/null); [ -n "$R" ] && [ "$R" != device ] && export UA_RENDER_SCALE="$R"

# the helper's code warm-up is for Mono's JIT (the Mono route: on, as in the 32-bit build); IL2CPP's
# code is compiled already
[ -f "$GAMEDIR/arm64/lib/libmonobdwgc-2.0.so" ] || export CUPHEAD_CODEWARM=0
$ESUDO chmod +x "$GAMEDIR/ua_host64"
$GPTOKEYB "ua_host64" -c "$GAMEDIR/cuphead_hotkey.gptk" &
pm_platform_helper "$GAMEDIR/ua_host64"
# NextUI's PortMaster library path may select GL4ES instead of native GLES.
# This subshell scopes overrides to Cuphead and keeps symlinks off the FAT card.
(
  native_egl=""
  native_gles=""
  for candidate in /usr/lib64/libEGL.so /usr/lib/libEGL.so; do
    [ -f "$candidate" ] && { native_egl="$candidate"; break; }
  done
  for candidate in /usr/lib64/libGLESv2.so /usr/lib/libGLESv2.so; do
    [ -f "$candidate" ] && { native_gles="$candidate"; break; }
  done
  if [ -z "$native_egl" ] || [ -z "$native_gles" ]; then
    echo "NextUI Cuphead: native EGL/GLES provider missing"
    exit 1
  fi
  gpu_dir=$(mktemp -d /tmp/cuphead-nextui-gpu.XXXXXXXX) || exit 1
  cleanup_gpu() {
    rm -f "$gpu_dir/libEGL.so" "$gpu_dir/libEGL.so.1" \
      "$gpu_dir/libGLESv2.so" "$gpu_dir/libGLESv2.so.2"
    rmdir "$gpu_dir" 2>/dev/null || true
  }
  trap cleanup_gpu EXIT
  ln -s "$native_egl" "$gpu_dir/libEGL.so" || exit 1
  ln -s "$native_egl" "$gpu_dir/libEGL.so.1" || exit 1
  ln -s "$native_gles" "$gpu_dir/libGLESv2.so" || exit 1
  ln -s "$native_gles" "$gpu_dir/libGLESv2.so.2" || exit 1
  export LD_LIBRARY_PATH="$gpu_dir:/usr/trimui/lib:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH"
  export SDL_VIDEO_EGL_DRIVER="$native_egl"
  export SDL_VIDEO_GL_DRIVER="$native_gles"
  export UA_DISPLAY=sdl
  unset UA_AUDIO_RATE
  export SDL_AUDIODRIVER=dsp
  export AUDIODEV=/dev/dsp
  export UA_AUDIO_FRAMES=512
  export ANDROID_SLES_SAMPLES=2048
  # Release default: tracing off. No audio diagnostic Python is required.
  export ANDROID_SHIM_TRACE=0
  if command -v aplay >/dev/null 2>&1; then
    export ANDROID_SLES_OUTPUT=pipe
    export ANDROID_SLES_PIPE_CMD='exec aplay -q -D plughw:0,0 -t raw -f S16_LE -r 48000 -c 2 --buffer-time=160000 --period-time=20000 -'
    echo "NextUI Cuphead audio: system aplay, 48000 Hz stereo, 160 ms buffer"
  else
    export ANDROID_SLES_OUTPUT=sdl
    echo "NextUI Cuphead audio: system aplay missing; retaining SDL dsp output"
  fi
  echo "NextUI Cuphead: SDL display; native EGL=$native_egl GLES=$native_gles"
  "$GAMEDIR/ua_host64" "$GAMEDIR/arm64"
)

pm_finish
