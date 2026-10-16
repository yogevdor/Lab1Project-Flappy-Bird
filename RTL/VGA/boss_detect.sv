module boss_detect (
	input  logic [3:0] hundreds, tens,     // from score_counter
	output logic       bossActive
);

assign bossActive = (tens == 4'd5) || (tens == 4'd0 && hundreds != 4'd0);

endmodule
