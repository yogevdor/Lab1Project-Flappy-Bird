

module	audio_selector	(	
					input logic	clk,
					input logic	resetN,
					input logic startScreen,
					input logic gameOver,
					input logic pause,
					input logic objectsResetN,
					input logic game_on,
 
				   output logic	[3:0] melodySelect
);

localparam logic [3:0] UNDER_THE_SEA = 4'd0;
localparam logic [3:0] GAME_OVER_SOUND = 4'd1;

always_ff@(posedge clk or negedge resetN) begin
	
		if(!resetN) begin
				melodySelect	<= 4'b0;
		end
		
		else begin
			melodySelect <= 4'b0;
			if ( objectsResetN == 1'b0 || game_on == 1'b1)
				melodySelect <= UNDER_THE_SEA;  

			else if (gameOver == 1'b1 )
				melodySelect <= GAME_OVER_SOUND; 
		end
	end

endmodule


