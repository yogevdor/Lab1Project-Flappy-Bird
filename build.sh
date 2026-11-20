#!/usr/bin/env bash
# Builds the Flappy-Fish RTL (from the main branch) into a native test simulator and/or a WebAssembly game.
#
#   ./build.sh native [RTL_DIR]     -> build/native/sim      (needs verilator + g++)
#   ./build.sh web    [RTL_DIR]     -> site/game.js/.wasm    (needs verilator + emscripten)
#
# RTL_DIR is the folder that CONTAINS the RTL/ directory of main (default ../Project).
# Env: VERILATOR (default "verilator"), PYTHON (default python3)
set -euo pipefail
MODE="${1:-web}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "${2:-$HERE/../Project}" && pwd)"
VERILATOR="${VERILATOR:-verilator}"
PYTHON="${PYTHON:-python3}"
VROOT="$($VERILATOR --getenv VERILATOR_ROOT)"
B="$HERE/build"

mkdir -p "$B"
# 1. ROM files: .mif -> hex words (same file names; the lpm_rom model reads them with $readmemh)
rm -rf "$B/rom"
"$PYTHON" "$HERE/tools/convert_mif.py" "$SRC" "$B/rom"

# 2. RTL -> C++
mapfile -t SV < <(find "$SRC/RTL" \( -name '*.sv' -o -name '*.SV' \) | sort)

# FAST_VGA (default 1): simulate with shortened VGA blanking (analog-monitor timing the browser does not need).
# Same 640x480 picture and same per-frame game logic, ~1.38x fewer clocks per frame. Works on a patched COPY;
# main is untouched. FAST_VGA=0 builds the original timing.
if [ "${FAST_VGA:-1}" = 1 ]; then
  mkdir -p "$B/patched"
  "$PYTHON" "$HERE/tools/patch_vga_controller.py" "$SRC/RTL/VGA/vga_controller.sv" "$B/patched/vga_controller.sv"
  SV_ALL=("${SV[@]}"); SV=()
  for f in "${SV_ALL[@]}"; do [ "$(basename "$f")" = vga_controller.sv ] || SV+=("$f"); done
  SV+=("$B/patched/vga_controller.sv")
fi
rm -rf "$B/obj"
rm -rf "$B/gen" && mkdir -p "$B/gen" && cp "$HERE"/hdl/generated/*.v "$B/gen/"
# NOAUDIO (default 1): swap the audio chain (silent in the browser anyway) for an empty block: ~10% faster, identical picture. NOAUDIO=0 keeps it.
if [ "${NOAUDIO:-1}" = 1 ]; then cp "$HERE/hdl/optional/audio_off.v" "$B/gen/audio.v"; fi
"$PYTHON" "$HERE/tools/prune_defparams.py" "$B/gen" "$B"/gen/*.v "$HERE"/hdl/stubs/*.v "${SV[@]}"

"$VERILATOR" --cc --top-module TOP_FLAPPY_FISH -Mdir "$B/obj" \
  -Wno-fatal -Wno-lint -Wno-style -Wno-WIDTH -Wno-PINNOTFOUND -Wno-TIMESCALEMOD \
  -O3 --x-assign fast --x-initial fast --noassert --no-timing ${VFLAGS:-} \
  "$B"/gen/*.v "$HERE"/hdl/stubs/*.v "${SV[@]}"

# Hierarchical prefix of the signals added to vga_controller by patch_vga_controller.py, as the simulator sees them
MAINDEFS=()
if [ "${FAST_VGA:-1}" = 1 ]; then
  VGAINST="$(grep -oE '^vga_controller[[:space:]]+[A-Za-z0-9_]+' "$B/gen/TOP_FLAPPY_FISH.v" | awk '{print $2}')"
  MAINDEFS+=("-DVGA_PREFIX=TOP_FLAPPY_FISH__DOT__${VGAINST}__DOT__")
fi

CPP=("$B"/obj/*.cpp "$VROOT/include/verilated.cpp" "$VROOT/include/verilated_threads.cpp")
INC=(-I"$B/obj" -I"$VROOT/include" -I"$VROOT/include/vltstd")

if [ "$MODE" = "native" ]; then
  mkdir -p "$B/native"
  g++ -O3 -std=c++17 -include stdint.h ${CXXEXTRA:-} "${INC[@]}" "${CPP[@]}" "${MAINDEFS[@]}" "$HERE/sim/main.cpp" -o "$B/native/sim"
  echo "built $B/native/sim  (run it from $B/rom so RTL/*.mif is found)"
else
  mkdir -p "$HERE/site"
  em++ -O3 -std=c++17 -include stdint.h -DVL_IGNORE_UNKNOWN_ARCH ${EMFLAGS:-} "${INC[@]}" "${CPP[@]}" "${MAINDEFS[@]}" "$HERE/sim/main.cpp" \
    --preload-file "$B/rom/RTL@/RTL" \
    -s ALLOW_MEMORY_GROWTH=1 -s MODULARIZE=1 -s EXPORT_NAME=FlappyFish \
    -s EXPORTED_FUNCTIONS=_sim_init,_sim_frame,_sim_framebuffer,_sim_set_switches,_sim_set_extra_ticks,_sim_has_ticks,_sim_set_vstep,_sim_key,_sim_hex,_sim_cycles \
    -s EXPORTED_RUNTIME_METHODS=HEAPU8,HEAPU32,ccall \
    -o "$HERE/site/game.js"
  cp "$HERE/web/index.html" "$HERE/site/index.html"
  echo "built $HERE/site/"
fi
