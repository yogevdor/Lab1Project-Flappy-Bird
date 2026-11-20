# Flappy Fish - playable in the browser (runs the real RTL)

This branch (`web-demo`) does **not** change the game. It contains only what is needed to run the
SystemVerilog design from `main` inside a web page:

```
SystemVerilog RTL (main)  ──Verilator──►  C++ model  ──Emscripten──►  game.wasm  +  index.html
```

The DE10 board is replaced by a small C++ harness (`sim/main.cpp`): it toggles the clock, turns the
`OVGA` pins into a 640x480 picture, and feeds keyboard presses to the design as real PS/2 frames.

| Folder | What |
|---|---|
| `hdl/generated/` | Verilog exported from the `.bdf` schematics with Quartus (`tools/export_bdf.sh`). Committed so CI needs no Quartus. |
| `hdl/stubs/` | Simulation stand-ins for things Quartus provides: `CLK_31P5` (PLL), `KBDINTF` (PS/2, precompiled `.qxp`), `audio_codec_controller` (`.QXP`), `lpm_rom` (ROMs). |
| `tools/convert_mif.py` | `.mif` -> hex word lists (so `$readmemh` can load the sprites). |
| `sim/main.cpp` | Verilator harness / "the board". |
| `web/index.html` | The page. |
| `build.sh` | `./build.sh native` (test, writes PPM frames) or `./build.sh web` (WebAssembly into `site/`). |
| `.github/workflows/pages.yml` | Builds from `main` + this branch and publishes to GitHub Pages. |

## Publishing

1. Push this branch: `git push -u origin web-demo`.
2. Repo **Settings -> Pages -> Source: GitHub Actions**.
3. (If the deploy job is refused) **Settings -> Environments -> github-pages -> Deployment branches**: allow `web-demo`.
4. The page appears at `https://<user>.github.io/<repo>/`.

The workflow checks out `main` every run, so re-run it (Actions -> *Run workflow*) after you change the RTL.

## When the schematics change

If you edit a `.bdf` on `main`, regenerate the Verilog and commit it here:

```
tools/export_bdf.sh ../Project      # needs Quartus; run in Git Bash
```

## Speed and smoothness

The whole chip is simulated clock by clock, which is far more work than the FPGA does for free. Two things keep the
game playable:

- **Game speed is always 100%.** The game advances one step per "start of frame" pulse (the board draws 72.8
  frames/s: 31.5 MHz / (832 x 520)). The page runs a fixed-timestep loop: before each displayed frame it asks the VGA
  block for as many extra pulses as real time requires, so the fish and pipes move at the board's speed on any machine.
  A machine that draws 30 frames/s simply shows bigger steps per frame (like any 30 fps game), not slow motion.
- **Frame rate adapts to the machine, picture quality first.** The cost of a frame is proportional to the number of
  lines clocked through the VGA block. The page uses full resolution whenever the machine reaches 45 frames/s with
  it; otherwise it tells the block to simulate only every 2nd line and repeats it. Skipping more lines (x2.7 / x3.5
  faster, `?res=3` / `?res=4`) breaks thin details such as the sardines, so it is never chosen automatically; columns
  are never skipped (the scrolling background is dithered and sampling every 2nd column makes it flicker). The
  status line under the game shows which one is in use; `?res=full|2|3|4` in the URL forces one (for testing).

## Differences from main (everything else is the RTL as it is)

`main` itself is never modified. The simulated design differs from it in these build-time ways, all in the video
timing block or in blocks the browser cannot use:

1. **A copy of `vga_controller.sv` is adapted** (`FAST_VGA`, default on; `tools/patch_vga_controller.py`). This is the
   only RTL change; no game logic is touched.
   - *Shortened blanking*: porch/sync/back-porch lengths cut (e.g. 192 -> 20 clocks per line); they exist for analog
     monitors only. ~1.3x fewer clocks per frame.
   - *Extra start-of-frame pulses* (`extraTicks`, written by the simulator): up to 7 more pulses 64 clocks apart,
     right after the real one and long before the first visible line.
   - *Row skipping* (`stepY`, written by the simulator): the line counter advances by 1..4 inside the visible area.
     The harness repeats the sampled rows.
2. **No audio chain** (`NOAUDIO`, default on; `hdl/optional/audio_off.v`). The browser build has no sound, so the
   audio block is replaced by an empty one (~10% faster, picture bit-identical).

What was checked (native simulation, key presses, game over included; frames compared bit for bit):
- shortened blanking + extra-pulse logic idle vs. the original controller: identical;
- 2, 3 and 4 game ticks per displayed frame vs. one tick per frame: identical frames at the same tick count
  (collisions are only evaluated on displayed frames, as pixel overlap is what triggers them);
- row skipping changes the picture by design (lower vertical resolution); the game state is the same, and the
  brightness of the dithered sky no longer flickers between frames (it did when columns were skipped).

Use `FAST_VGA=0 NOAUDIO=0 ./build.sh web` for the unmodified controller and the audio logic.
Free-running counters (e.g. `random`) see a different number of clocks per frame than on the board, so the same key
press can yield different pipe gaps.

## Known limits

- No sound yet.
- Needs `tools/export_bdf.sh` re-run (and a commit here) when a `.bdf` schematic changes on `main`.
- Below ~20 simulated frames/s even the lowest resolution cannot keep real-time speed (the page catches up by up to
  8 ticks per frame, then slows down).

## Notes on the conversion

- `tools/fix_params.py`: Quartus' BDF -> Verilog converter drops parameters that a block passes down to its
  inner modules (e.g. each background object's sprite file and start position); this restores them.
- `tools/prune_defparams.py`: removes `defparam`s that name a parameter the target module does not have
  (Quartus ignores them, Verilator aborts).
- `lpm_rom` keeps `DEPTH + 64K` words so `.mif` files longer than the instance (sardines.mif) still load;
  addressing is unchanged, so it matches the FPGA's truncation.
