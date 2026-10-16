

module gap_mover (
	input  logic        clk,
	input  logic        resetN,
	input  logic        objectsResetN,
	input  logic        startOfFrame,
	input  logic        game_on,
	input  logic        bossActive,
	input  logic [10:0] gapIn,            // gapTop from random.sv
	output logic [10:0] gapOut            // to the gapTop pin of Pipes_Block_T
);

parameter int GAP_MIN   = 32;             
parameter int GAP_MAX   = 276;
parameter int GAP_SPEED = 1;              // px per frame

logic [10:0] gapIn_D;
logic        sof_D; // startOfFrame_D
logic        goingDown;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		gapIn_D   <= 11'd0;
		sof_D     <= 1'b0;
		goingDown <= 1'b0;
		gapOut    <= gapIn;
	end
	else begin
		gapIn_D <= gapIn;
		sof_D   <= startOfFrame;

		if (!objectsResetN || gapIn != gapIn_D) begin
			gapOut    <= gapIn;
			goingDown <= gapIn[0];                        // picks if up or down by the first bit
		end
		else if (bossActive && game_on && startOfFrame && !sof_D) begin
			if (goingDown) begin
				if (gapOut + GAP_SPEED >= GAP_MAX) begin
					gapOut    <= GAP_MAX;
					goingDown <= 1'b0;
				end
				else
					gapOut <= gapOut + GAP_SPEED;
			end
			else begin
				if (gapOut <= GAP_MIN + GAP_SPEED) begin
					gapOut    <= GAP_MIN;
					goingDown <= 1'b1;
				end
				else
					gapOut <= gapOut - GAP_SPEED;
			end
		end
	end
end

endmodule
