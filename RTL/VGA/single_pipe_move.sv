
module	single_pipe_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic gameOn,
					input  logic objectsResetN,
					input  logic [9:0] speedBoost,
					
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,		// can be negative , if the object is partliy outside
					output logic passed,
					output logic regenerate
					
);
 int 	 topLeftX_tmp; // output the top left corner 
 int   topLeftY_tmp;  // can be negative , if the object is partialy outside 

parameter int INITIAL_X = 0;
parameter int INITIAL_Y = 0;
parameter int INITIAL_X_SPEED = 0;
parameter int INITIAL_Y_SPEED = 0;


parameter int FISH_X = 130; //fish X cordianate
localparam int PIPE_W = 52;

logic scored;

const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // must be 2^n 

// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 64;

const int X_MIN_LIMIT = -OBJECT_WIDTH_X * FIXED_POINT_MULTIPLIER;


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST,	// startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  

logic startOfFrame_D ;
logic gameOn_D ;

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= INITIAL_X_SPEED   ; 
		Yspeed <= INITIAL_Y_SPEED  ; 
		Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER  ; 
		Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER   ; 
		startOfFrame_D <= 0 ;
		regenerate <= 0;
	
	end 	
	
	else begin
	
		startOfFrame_D <= startOfFrame ;
		gameOn_D <= gameOn ;
		regenerate <= 0;
		
		if (!objectsResetN) begin
			Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER  ; 
			Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER   ; 
		end
	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
				
				Xspeed  <= INITIAL_X_SPEED ; 
				Yspeed  <= INITIAL_Y_SPEED  ; 
				Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER; 

				if (gameOn && startOfFrame && !startOfFrame_D)
						SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------

				if (gameOn && startOfFrame && !startOfFrame_D)
					SM_Motion <= POSITION_CHANGE_ST ; 								
			end 
		

		//------------------------
			POSITION_CHANGE_ST : begin
		//------------------------
				if (!gameOn) begin
					Xspeed <= 0;
					Yspeed <= 0;
				end
				else if (gameOn_D) begin
					Xposition <= Xposition + Xspeed - int'(speedBoost) ;
					Yposition <= Yposition + Yspeed ;
				end
				else begin
					Xspeed  <= INITIAL_X_SPEED ;
					Yspeed  <= INITIAL_Y_SPEED  ;
				end

				SM_Motion <= POSITION_LIMITS_ST ;
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
				if (Xposition <= X_MIN_LIMIT) begin
						Xposition <= 640 * FIXED_POINT_MULTIPLIER ;
						regenerate <= 1;
				end
				
				SM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 

	end 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER ;    

assign 	topLeftX = {topLeftX_tmp[10:0]} ;   // note it must be 2^n 
assign 	topLeftY = {topLeftY_tmp[10:0]} ;  



///////////////////// For score counting /////////////////

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        scored <= 1'b0;
        passed <= 1'b0;
    end
	 
    else begin
        passed <= 1'b0;
        if (!objectsResetN)
            scored <= 1'b0;
        else if (topLeftX > FISH_X)
            scored <= 1'b0;
        else if (!scored && gameOn && (topLeftX + PIPE_W < FISH_X)) begin
            scored <= 1'b1;
            passed <= 1'b1;
        end
    end
end

//////////////////////////////////////////////////////////  	

endmodule