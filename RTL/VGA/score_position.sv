module score_position (
	input  logic        gameOver,
	output logic [10:0] topLeftX,
	output logic [10:0] topLeftY
);


localparam logic [10:0] PLAY_X = 296;
localparam logic [10:0] PLAY_Y = 16;

localparam logic [10:0] OVER_X = 354;
localparam logic [10:0] OVER_Y = 230;

assign topLeftX = gameOver ? OVER_X : PLAY_X;
assign topLeftY = gameOver ? OVER_Y : PLAY_Y;

endmodule
