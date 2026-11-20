#!/usr/bin/env bash
# Re-generates hdl/generated/*.v from the schematic (.bdf) files on main, using Quartus' own converter.
# Needs Quartus (Windows, Git Bash).  Run it again whenever a .bdf changes on main; the result is committed
# so GitHub Actions does not need Quartus.
#
#   tools/export_bdf.sh [path-to-main-checkout]      (default: ../Project)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$(cd "${1:-$HERE/../Project}" && pwd)"
QMAP="${QUARTUS_MAP:-/c/intelFPGA_lite/17.0/quartus/bin64/quartus_map.exe}"
for c in "${PYTHON:-}" /c/Users/dordo/AppData/Local/Programs/Python/Python313/python.exe python3 python; do if [ -n "$c" ] && [ "$("$c" -c "print(1)" 2>/dev/null)" = 1 ]; then PY="$c"; break; fi; done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -r "$MAIN/RTL" "$TMP/RTL"
cp "$MAIN"/Lab1Demo.qpf "$MAIN"/Lab1Demo.qsf "$TMP/"
cp "$MAIN"/*.qip "$MAIN"/*.v "$TMP/" 2>/dev/null || true
[ -d "$MAIN/CLK_31P5" ] && cp -r "$MAIN/CLK_31P5" "$TMP/CLK_31P5"
cp "$MAIN"/*.qxp "$MAIN"/*.QXP "$TMP/" 2>/dev/null || true

OUT="$HERE/hdl/generated"
mkdir -p "$OUT"
rm -f "$OUT"/*.v
cd "$TMP"
for bdf in $(find RTL -iname '*.bdf'); do
  "$QMAP" Lab1Demo --convert_bdf_to_verilog="$bdf" > /dev/null
  v="${bdf%.bdf}.v"
  name="$(basename "$v")"
  # Quartus matches module names case-insensitively, Verilator does not.
  sed -i 's/^module Background_Object_Block_T(/module background_object_block_t(/' "$v"
  # KBDINTF has a port called "break": only legal as a Verilog-2001 identifier.
  if grep -q '\.break(' "$v"; then
    { echo '`begin_keywords "1364-2005"'; cat "$v"; echo '`end_keywords'; } > "$v.tmp" && mv "$v.tmp" "$v"
  fi
  "$PY" "$HERE/tools/fix_params.py" "$bdf" "$v"
  cp "$v" "$OUT/$name"
  echo "exported $name"
done
