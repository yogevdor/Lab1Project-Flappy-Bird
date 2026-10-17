module best_score_display (
	input  logic       clk,
	input  logic       resetN,
	input  logic [3:0] hundreds, tens, ones,   // current score from score_counter
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

logic [3:0] bestHundreds, bestTens, bestOnes;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		bestHundreds <= 4'd0;  bestTens <= 4'd0;  bestOnes <= 4'd0;
	end

	else if ({hundreds, tens, ones} > {bestHundreds, bestTens, bestOnes}) begin
		bestHundreds <= hundreds;  bestTens <= tens;  bestOnes <= ones;
	end
end

logic showHundreds, showTens;
assign showHundreds = (bestHundreds != 4'd0);
assign showTens = (bestHundreds != 4'd0) || (bestTens != 4'd0);

SEG7 seg_ones (.clk(clk), .resetN(resetN), .iDIG(bestOnes), .darkN(1'b1), .oSEG(HEX0));
SEG7 seg_tens (.clk(clk), .resetN(resetN), .iDIG(bestTens), .darkN(showTens), .oSEG(HEX1));
SEG7 seg_hund (.clk(clk), .resetN(resetN), .iDIG(bestHundreds), .darkN(showHundreds), .oSEG(HEX2));

assign HEX3 = 7'b1111111;                      //  currently unused so off
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

endmodule
