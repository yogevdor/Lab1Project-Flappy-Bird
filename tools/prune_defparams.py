#!/usr/bin/env python3
"""Drop `defparam inst.NAME = ...;` lines whose target module has no parameter NAME.

Quartus silently ignores those (they are leftovers in the .bdf schematics); Verilator aborts on them.
Rewrites the given generated .v files in place.

usage: prune_defparams.py <generated_dir> <source files...>   (sources: every .sv/.v that defines modules)
"""
import re
import sys
from pathlib import Path


def strip_comments(t: str) -> str:
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    return re.sub(r"//[^\n]*", "", t)


def split_top(s: str) -> list[str]:
    out, depth, cur, instr = [], 0, "", False
    for ch in s:
        if ch == '"':
            instr = not instr
        if not instr:
            if ch in "([{": depth += 1
            elif ch in ")]}": depth -= 1
            elif ch == "," and depth == 0:
                out.append(cur); cur = ""; continue
        cur += ch
    out.append(cur)
    return out


def module_params(text: str) -> dict[str, set[str]]:
    text = strip_comments(text)
    mods: dict[str, set[str]] = {}
    for m in re.finditer(r"\bmodule\s+(\w+)", text):
        name, pos = m.group(1), m.end()
        end = text.find("endmodule", pos)
        body = text[pos:end if end != -1 else len(text)]
        params: set[str] = set()
        hdr = re.match(r"\s*(?:import\s+[^;]*;\s*)*#\s*\(", body)
        if hdr:                                    # parameter port list  #( ... )
            i, depth = hdr.end(), 1
            while i < len(body) and depth:
                depth += (body[i] == "(") - (body[i] == ")")
                i += 1
            for piece in split_top(body[hdr.end():i - 1]):
                left = piece.split("=")[0]
                if "localparam" in left:
                    continue
                ids = re.findall(r"\w+", left)
                if ids:
                    params.add(ids[-1])
        for pm in re.finditer(r"\bparameter\b([^;]*);", body):   # body-level parameter statements
            for piece in split_top(pm.group(1)):
                ids = re.findall(r"\w+", piece.split("=")[0])
                if ids:
                    params.add(ids[-1])
        mods[name] = params
    return mods


def main() -> None:
    gen = Path(sys.argv[1])
    mods: dict[str, set[str]] = {}
    for f in sys.argv[2:]:
        mods.update(module_params(Path(f).read_text(errors="replace")))

    dropped = 0
    for v in sorted(gen.glob("*.v")):
        text = v.read_text()
        inst_mod = {i: m for m, i in re.findall(r"^(\w+)\s+(b2v_\w+)\s*\(", text, re.M)}

        def repl(m):
            nonlocal dropped
            inst, name = m.group(1), m.group(2)
            mod = inst_mod.get(inst)
            if mod in mods and name not in mods[mod]:
                dropped += 1
                print(f"  {v.name}: dropped defparam {inst}.{name} ({mod} has no such parameter)")
                return f"// (dropped) {m.group(0)}"
            return m.group(0)

        v.write_text(re.sub(r"defparam\s+(\w+)\.(\w+)\s*=[^;]*;", repl, text))
    print(f"pruned {dropped} defparams")


if __name__ == "__main__":
    main()
