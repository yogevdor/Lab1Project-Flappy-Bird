module speed_controller (
	input  logic       clk,
	input  logic       resetN,        
	input  logic       point,
	input  logic       turbo2, turbo3,

	output logic [9:0] speedBoost
);

parameter int PIPES_PER_STEP = 7;
parameter int SPEED_STEP     = 8;
parameter int MAX_BOOST      = 128;
localparam int BASE_SPEED    = 128;

logic [3:0] cnt;
logic [7:0] scoreBoost;
logic [1:0] t2_s, t3_s; //to sychronize to our clock we need delay
logic [1:0] mult;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		cnt        <= 4'd0;
		scoreBoost <= 8'd0;
		t2_s       <= 2'b00;
		t3_s       <= 2'b00;
	end
	else begin
//		t2_s <= {t2_s[0], turbo2};
//		t3_s <= {t3_s[0], turbo3};

		if (point) begin
			if (cnt == PIPES_PER_STEP - 1) begin
				cnt <= 4'd0;
				if (scoreBoost < MAX_BOOST)
					scoreBoost <= scoreBoost + SPEED_STEP;
			end
			else
				cnt <= cnt + 4'd1;
		end
	end
end

assign mult       = t3_s[1] ? 2'd3 : (t2_s[1] ? 2'd2 : 2'd1);
assign speedBoost = (BASE_SPEED + scoreBoost) * mult - BASE_SPEED;   // equals scoreBoost when mult = 1

endmodule
