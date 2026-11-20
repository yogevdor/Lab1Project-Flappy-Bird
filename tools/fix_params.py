#!/usr/bin/env python3
"""Restore parameter pass-through lost by Quartus' BDF -> Verilog converter.

In a .bdf, an instance parameter is stored as three strings:  (parameter "INNER" "VALUE" "default").
When VALUE is the name of a parameter of the enclosing block (e.g. "INITIAL_X", "MIF_FILE_") the inner
instance receives the block's parameter. The converter writes the block's *default* as a literal instead,
so every instance of the block would get the same values. This rewrites those defparams back to
`defparam inst.INNER = BLOCKPARAM;` .

usage: fix_params.py <file.bdf> <file.v>      (rewrites the .v in place)
"""
import re
import sys
from pathlib import Path

bdf = Path(sys.argv[1]).read_text(errors="replace")
vfile = Path(sys.argv[2])
v = vfile.read_text()

block_params = set(re.findall(r"^parameter\s+(\w+)\s*=", v, re.M))
if not block_params:
    sys.exit(0)

# (parameter "INNER" "VALUE" "..." ) triples
pairs = {}
for m in re.finditer(r'\(parameter\s+"([^"]*)"\s+"([^"]*)"\s+"([^"]*)"', bdf):
    inner, value, _ = m.groups()
    if value in block_params and inner != "":
        pairs.setdefault(inner, value)

def repl(m):
    inst, name = m.group(1), m.group(2)
    if name in pairs:
        return f"defparam\t{inst}.{name} = {pairs[name]};"
    return m.group(0)

new = re.sub(r"defparam\s+(\w+)\.(\w+)\s*=\s*[^;]+;", repl, v)
if new != v:
    vfile.write_text(new)
    print(f"  fixed pass-through params in {vfile.name}: {sorted(pairs)}")
