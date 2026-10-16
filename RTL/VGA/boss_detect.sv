module boss_detect (
	input  logic [3:0] hundreds, tens,     // from score_counter
	output logic       bossActive,
	output logic		 darkModeOn
);

assign bossActive = (tens == 4'd5) || (tens == 4'd0 && hundreds != 4'd0);
assign darkModeOn = (tens == 4'd2) || (tens == 4'd7);

endmodule
