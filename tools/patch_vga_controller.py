#!/usr/bin/env python3
"""Write a copy of vga_controller.sv adapted for running in a browser. main is never modified.

Three changes, all only in the video timing block (no game logic anywhere is touched):

1. Shortened blanking. The porch / sync / back-porch lengths exist for analog monitors; cutting them leaves the
   640x480 picture and the per-frame game logic unchanged but needs ~322k instead of ~433k clocks per frame.

2. Extra game ticks. The whole game advances one step per `startOfFrame` pulse. The simulator can now ask for
   up to 7 extra pulses (`extraTicks`, written by the harness) right after the real one, long before the first
   visible line. The page uses that to keep the game at real-time speed (~73 ticks/s, the board's frame rate)
   even though the simulated chip draws fewer frames per second than that.

3. Optional row skipping. `stepY` (1..4, written by the harness, normally 1) makes the line counter advance by
   `stepY` inside the visible area, so only every stepY-th row is simulated and the harness repeats it. Cuts the
   work per frame roughly by stepY at the price of vertical resolution; used only on machines too slow for full
   resolution. (Skipping columns was tried and rejected: the scrolling dithered background flickers.)

usage: patch_vga_controller.py <in vga_controller.sv> <out vga_controller.sv>
"""
import re
import sys
from pathlib import Path

# H_BACK must leave the row counter and the drawing pipeline (registered ROM addresses etc.) time to settle
# before the first visible pixel; 2 clocks was too few (first column of some rows was drawn from the previous row).
BLANKING = {"H_FRONT": 2, "H_SYNC": 2, "H_BACK": 16, "V_FRONT": 2, "V_SYNC": 2, "V_BACK": 2}

TICKS = """\
// ---- web-demo: extra game ticks -----------------------------------------------------------------
// `extraTicks` is written by the simulator (public). Right after the real start-of-frame pulse, that many more
// pulses are generated, TICK_GAP clocks apart (enough for the game's state machines to settle between them).
// All of them happen in the vertical blanking, so a displayed frame shows the game after 1 + extraTicks steps.
logic [2:0] extraTicks /*verilator public_flat_rw*/ = 3'd0;
localparam int TICK_GAP = 64;
logic       realTick;
logic       extraPulse;
logic [2:0] extraLeft;
logic [6:0] gapCnt;

assign realTick = !oVGA_VS && VGA_VS_d;

always_ff @(posedge clk or negedge resetN)
begin
	if (!resetN) begin
		extraPulse <= 1'b0;
		extraLeft  <= 3'd0;
		gapCnt     <= 7'd0;
	end
	else begin
		extraPulse <= 1'b0;
		if (realTick) begin
			extraLeft <= extraTicks;
			gapCnt    <= 7'd0;
		end
		else if (extraLeft != 3'd0) begin
			if (gapCnt == TICK_GAP - 1) begin
				extraPulse <= 1'b1;
				extraLeft  <= extraLeft - 3'd1;
				gapCnt     <= 7'd0;
			end
			else
				gapCnt <= gapCnt + 7'd1;
		end
	end
end

assign startOfFrame = realTick | extraPulse;
"""

src = Path(sys.argv[1]).read_text()

for name, value in BLANKING.items():
    pat = re.compile(rf"(const\s+logic\s*\[10:0\]\s+{name}\s*=\s*)\d+(\s*;)")
    src, n = pat.subn(rf"\g<1>{value}\g<2>", src)
    if n != 1:
        sys.exit(f"patch_vga_controller: expected exactly one '{name}' constant, found {n}")

pat = re.compile(r"assign\s+startOfFrame\s*=\s*!oVGA_VS\s*&&\s*VGA_VS_d\s*;[^\n]*")
src, n = pat.subn(lambda m: TICKS, src)
if n != 1:
    sys.exit(f"patch_vga_controller: expected exactly one startOfFrame assignment, found {n}")

# 3. row skipping knob + counter
DECL = """// ---- web-demo: optional row skipping (set by the simulator, normally 1) --------------------------
logic [2:0] stepY /*verilator public_flat_rw*/ = 3'd1;
"""
pat = re.compile(r"(logic\s+timer_done\s*;[^\n]*\n)")
src, n = pat.subn(lambda m: m.group(1) + DECL, src)
if n != 1:
    sys.exit(f"patch_vga_controller: expected exactly one 'timer_done' declaration, found {n}")

pat = re.compile(r"V_Cont\s*<=\s*V_Cont\s*\+\s*1'b1\s*;")
src, n = pat.subn("V_Cont <= V_Cont + ((V_Cont >= V_BLANK && stepY > 3'd1) ? {8'd0, stepY} : 11'd1);", src)
if n != 1:
    sys.exit(f"patch_vga_controller: expected exactly one V_Cont increment, found {n}")

header = "// NOTE: adapted for the browser build by web-demo/tools/patch_vga_controller.py (shortened blanking, extra ticks, optional row skipping)\n"
Path(sys.argv[2]).write_text(header + src)
print("vga_controller.sv: blanking shortened + extra-tick generator + row-skip knob added")
