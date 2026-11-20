#!/usr/bin/env python3
"""Rewrite every Quartus .mif under <src> as a plain hex word list (readable by $readmemh)
under <dst>, keeping the same relative path and file name (RTL/fish.mif -> <dst>/RTL/fish.mif).

usage: convert_mif.py <src_dir_containing_RTL> <dst_dir>
"""
import re
import sys
from pathlib import Path


def convert(path: Path) -> list[str]:
    depth, width = None, 8
    addr_radix, data_radix = 16, 16
    in_content = False
    words: dict[int, int] = {}
    radix = {"HEX": 16, "DEC": 10, "BIN": 2, "OCT": 8, "UNS": 10}

    for raw in path.read_text(errors="replace").splitlines():
        line = raw.split("--")[0].strip()
        if not line:
            continue
        up = line.upper()
        if not in_content:
            m = re.match(r"(DEPTH|WIDTH|ADDRESS_RADIX|DATA_RADIX)\s*=\s*(\w+)\s*;", up)
            if m:
                k, v = m.groups()
                if k == "DEPTH": depth = int(v)
                elif k == "WIDTH": width = int(v)
                elif k == "ADDRESS_RADIX": addr_radix = radix[v]
                elif k == "DATA_RADIX": data_radix = radix[v]
            elif up.startswith("CONTENT"):
                in_content = True
            continue
        if up.startswith("END"):
            break
        m = re.match(r"(?:\[\s*(\w+)\s*\.\.\s*(\w+)\s*\]|(\w+))\s*:\s*([\w\s]+);", line)
        if not m:
            continue
        lo, hi, single, data = m.groups()
        lo = int(lo or single, addr_radix)
        hi = int(hi, addr_radix) if hi else lo
        for i, tok in enumerate(data.split()):   # "a : d0 d1 ..." fills consecutive addresses
            val = int(tok, data_radix)
            if hi != lo or i == 0:
                for a in range(lo, hi + 1):
                    words[a + (i if hi == lo else 0)] = val
            else:
                words[lo + i] = val

    if depth is None:
        depth = max(words) + 1 if words else 0
    digits = (width + 3) // 4
    fill = (1 << width) - 1
    return [f"{words.get(a, fill):0{digits}X}" for a in range(depth)]


def main() -> None:
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    n = 0
    for mif in sorted(src.rglob("*.mif")):
        rel = mif.relative_to(src)
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(convert(mif)) + "\n")
        n += 1
    print(f"converted {n} .mif files -> {dst}")


if __name__ == "__main__":
    main()
