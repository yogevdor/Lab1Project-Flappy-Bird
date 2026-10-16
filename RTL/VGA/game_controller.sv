module	game_controller	(	
 
					input logic clk,
					input logic resetN,
					input logic startOfFrame,
					input logic collision,
					input logic keyIsPressed8, //key: 8
					input logic keyIsPressed0, //key: 0
					input logic keyIsPressedNUMLK, //key: num Lk for godMode
					
					output logic startDrawingReq,
					output logic gameOverDrawingReq,
					output logic pauseDrawingReq,
					output logic objectsResetN,
					output logic game_on
//					output logic darkModeOn
);

logic key8_D, key0_D, keyNUMLK_D;
logic key8_pulse, key0_pulse, keyNUMLK_pulse;
logic godMode;  

assign key8_pulse = keyIsPressed8 && !key8_D;
assign key0_pulse = keyIsPressed0 && !key0_D;
assign keyNUMLK_pulse = keyIsPressedNUMLK && !keyNUMLK_D;

enum  logic [1:0] {START_SCREEN_ST,
				   GAME_ON_ST,
				   PAUSE_ST,
				   GAMEOVER_ST 
				  } SM_GAME ;

always_ff @(posedge clk or negedge resetN)
	begin
	
		if (resetN == 1'b0) begin 
			SM_GAME <= START_SCREEN_ST ;
			game_on <= 1'b0;
//			darkModeOn <= 1'b0;
			startDrawingReq <= 1'b0;
			pauseDrawingReq <= 1'b0;
			gameOverDrawingReq <= 1'b0;
			key8_D <= 1'b0;
			key0_D <= 1'b0;
			keyNUMLK_D <= 1'b0;
			godMode <= 1'b0;
			objectsResetN <= 1'b0;
		end
		
		else begin
			game_on <= 1'b0;
			startDrawingReq <= 1'b0;
			pauseDrawingReq <= 1'b0;
			gameOverDrawingReq <= 1'b0;
			key8_D <= keyIsPressed8;
			key0_D <= keyIsPressed0;
			keyNUMLK_D <= keyIsPressedNUMLK;
			objectsResetN <= 1'b1;

			if (keyNUMLK_pulse)
				godMode <= ~godMode;
			
			case(SM_GAME)
			
				START_SCREEN_ST: begin
					game_on <= 1'b0;
//					darkModeOn <= 1'b0;
					startDrawingReq <= 1'b1;
					objectsResetN <= 1'b0;
					godMode <= 1'b0;          // every new game starts in normal mode
					if (key8_pulse) begin
						SM_GAME <= GAME_ON_ST;
					end
				end
				
				GAME_ON_ST: begin
					game_on <= 1'b1;
//					darkModeOn <= 1'b0;
					if (key0_pulse) begin
						SM_GAME <= PAUSE_ST;
					end
					else if (collision && !godMode) begin
						SM_GAME <= GAMEOVER_ST;
					end
					else begin
						SM_GAME <= GAME_ON_ST;
					end
				end
				
				PAUSE_ST: begin
					game_on <= 1'b0;
					pauseDrawingReq <= 1'b1;
					if (key0_pulse) begin
						SM_GAME <= GAME_ON_ST;
					end
				end
				
				GAMEOVER_ST: begin
					game_on <= 1'b0;
//					darkModeOn <= 1'b0;
					gameOverDrawingReq <= 1'b1;
					if (key0_pulse) begin
						SM_GAME <= START_SCREEN_ST;
					end
				end
			endcase
		end
	end		
endmodule			