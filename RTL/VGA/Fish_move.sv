
module	fish_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic Y_direction_key,   //move Y Up   
					input	 logic gameOn,
					input  logic objectsResetN,
					
					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY  // can be negative , if the object is partliy outside 
					
);
 int   topLeftY_tmp; // can be negative , if the object is partialy outside


parameter int INITIAL_X = 130;
parameter int INITIAL_Y = 240;
parameter int INITIAL_Y_SPEED = 0;
parameter int Y_ACCEL = -10;

const int MAX_Y_SPEED = 500;
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // must be 2^n 


// movement limits 
const int   OBJECT_HIGHT_Y = 32;
const int	SafetyMargin   =	2;

const int	y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

enum  logic [1:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Yspeed  ;
int Yposition ;

logic Y_direction_key_D ;
logic gameOn_D ;


//---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Yspeed <= 0  ; 
		Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER   ; 
		Y_direction_key_D <= 0 ;
		gameOn_D <= 0 ;
	
	end 	
	
	else begin
	
		Y_direction_key_D <= Y_direction_key ;
		gameOn_D          <= gameOn ;
	
	
		if (!objectsResetN) begin
			Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER  ; 
		end
		 
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Yspeed  <= INITIAL_Y_SPEED  ; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER; 

				if (gameOn && startOfFrame)
						SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------
		// keys direction change 

					if (Y_direction_key & !Y_direction_key_D)
						Yspeed <= -352;
					
					if (gameOn && startOfFrame )
						SM_Motion <= POSITION_CHANGE_ST ; 						
				
		end 

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
				if (!gameOn) begin
						Yspeed <= 0;
				end				
				else if(gameOn_D) begin 
					Yposition <= Yposition + Yspeed ;
					if (Yspeed < MAX_Y_SPEED)
						Yspeed <= Yspeed - Y_ACCEL;
				end
				
				else begin
					Yspeed <= INITIAL_Y_SPEED;
				end
				
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
		if (Yposition < y_FRAME_TOP) 
						Yposition <= y_FRAME_TOP ; 
		if (Yposition > y_FRAME_BOTTOM) 
						Yposition <= y_FRAME_BOTTOM ; 

				SM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 

		
	end 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER ;

assign 	topLeftX = INITIAL_X ;   // fish does not move horizontally
assign 	topLeftY = {topLeftY_tmp[10:0]} ;    	

endmodule	
//---------------
 
