

module speed_controller (
	input  logic       clk,
	input  logic       resetN,
	input  logic       point,

	output logic [7:0] speedBoost
);

parameter int PIPES_PER_STEP = 7;
parameter int SPEED_STEP     = 8;     // +0.125 px/frame
parameter int MAX_BOOST      = 128;   // cap: +2 px/frame

logic [3:0] cnt;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		cnt        <= 4'd0;
		speedBoost <= 8'd0;
	end
	else if (point) begin
		if (cnt == PIPES_PER_STEP - 1) begin
			cnt <= 4'd0;
			if (speedBoost < MAX_BOOST)
				speedBoost <= speedBoost + SPEED_STEP;
		end
		else
			cnt <= cnt + 4'd1;
	end
end

endmodule
