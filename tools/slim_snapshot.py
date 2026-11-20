#!/usr/bin/env python3
"""Keep the ROM contents out of the chip snapshots.

`verilator --savable` writes every variable of the model into a snapshot, including the sprite / background ROM
arrays (the `mem` arrays of hdl/stubs/lpm_rom.v): ~3.5 MB that never change after start-up. This removes those
arrays from the generated save / restore functions, so a snapshot only holds the registers (a few KB). A simulator
that restores a snapshot has already run its first evaluation, which loads the ROMs from the .mif files as usual.

usage: slim_snapshot.py <verilator obj dir>
"""
import re
import sys
from pathlib import Path

pat = re.compile(
    r"\n[ \t]*for \(int __Vi0 = 0; __Vi0 < \d+; \+\+__Vi0\) \{\n"
    r"[ \t]*os(?:<<|>>)[A-Za-z0-9_]*__DOT__mem\[__Vi0\];\n"
    r"[ \t]*\}")

removed = 0
for f in sorted(Path(sys.argv[1]).glob("*.cpp")):
    text = f.read_text()
    new, n = pat.subn("", text)
    if n:
        f.write_text(new)
        removed += n
print(f"slim_snapshot: removed {removed} ROM array (de)serialisation loops")
if removed == 0:
    sys.exit("slim_snapshot: found no ROM arrays to remove (generated code changed?)")
