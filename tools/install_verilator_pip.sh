#!/usr/bin/env bash
# Installs the pinned Verilator from PyPI into <dir> and writes a wrapper <dir>/verilator that sets VERILATOR_ROOT.
# build.sh needs exactly this Verilator version: tools/slim_snapshot.py relies on the layout of the code it generates.
#
#   VERILATOR="$(tools/install_verilator_pip.sh /some/dir)" ./build.sh web ../Project
set -euo pipefail
VER="${VERILATOR_VERSION:-5.48.0}"
DIR="$(mkdir -p "$1" && cd "$1" && pwd)"
python3 -m pip install --quiet --target "$DIR/pkg" "verilator==$VER" \
  || python3 -m pip install --quiet --break-system-packages --target "$DIR/pkg" "verilator==$VER"
ROOT="$DIR/pkg/verilator"
[ -x "$ROOT/bin/verilator_bin" ] || { echo "verilator_bin not found in $ROOT" >&2; exit 1; }
cat > "$DIR/verilator" <<EOF
#!/usr/bin/env bash
export VERILATOR_ROOT="$ROOT"
exec "$ROOT/bin/verilator_bin" "\$@"
EOF
chmod +x "$DIR/verilator"
echo "$DIR/verilator"
