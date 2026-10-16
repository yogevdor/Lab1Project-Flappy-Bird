
module	background_object_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic Y_direction_key,   //move Y Up   
					input	 logic toggle_x_key,      //toggle X   
					input	 logic gameOn,
					input  logic objectsResetN,
					input  logic [7:0] speedBoost,
					
					output logic signed [10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,		// can be negative , if the object is partliy outside
					output logic regenerate
					
);
 int 	 topLeftX_tmp; // output the top left corner 
 int   topLeftY_tmp;  // can be negative , if the object is partliy outside 

// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 0;
parameter int INITIAL_Y = 0;
parameter int INITIAL_X_SPEED = 0;
parameter int INITIAL_Y_SPEED = 0;


// parameter int Y_ACCEL = -10;

// const int MAX_Y_SPEED = 500;
//const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 64;
const int   OBJECT_HIGHT_Y = 32;

const int X_MIN_LIMIT = -OBJECT_WIDTH_X * FIXED_POINT_MULTIPLIER;


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST, 	          // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  

logic toggle_x_key_D ;
logic Y_direction_key_D ;
logic startOfFrame_D ;
logic gameOn_D ;

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= INITIAL_X_SPEED   ; 
		Yspeed <= INITIAL_Y_SPEED  ; 
//		Xposition <= 0  ; 
//		Yposition <= 0   ; 
		Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER  ; 
		Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER   ; 
		toggle_x_key_D <= 0 ;
		Y_direction_key_D <= 0 ;
		startOfFrame_D <= 0 ;
		regenerate <= 0;
	
	end 	
	
	else begin
	
		toggle_x_key_D <= toggle_x_key ;  //shift register to detect edge 
		Y_direction_key_D <= Y_direction_key ;
		startOfFrame_D <= startOfFrame ;
		gameOn_D <= gameOn ;
		
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
				Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER; 

				if (gameOn && startOfFrame && !startOfFrame_D)
						SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------

				if (gameOn && startOfFrame && !startOfFrame_D)
					SM_Motion <= START_OF_FRAME_ST ; 
								
				
			end 
		
		//------------
			START_OF_FRAME_ST:  begin      //check if any colisin was detected 
		//------------				
				
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
						regenerate <= ~regenerate;
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


endmodule