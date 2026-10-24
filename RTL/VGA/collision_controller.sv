
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	collision_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
			input	logic	drawing_request_fish,
			input logic drawing_request_pipe1,
			input logic drawing_request_pipe2,
			input logic drawing_request_pipe3,
			input logic signed [10:0] fishTopY,

			output logic collision		
);

localparam int Y_TOP_LIMIT    = 2;    // = SafetyMargin in Fish_move
localparam int Y_BOTTOM_LIMIT = 445;  // = 479 - SafetyMargin - 32 in Fish_move

logic hit_frame_edge;
assign hit_frame_edge = (fishTopY <= Y_TOP_LIMIT) || (fishTopY >= Y_BOTTOM_LIMIT);

assign collision = (drawing_request_fish && (drawing_request_pipe1 || drawing_request_pipe2 || drawing_request_pipe3)) ||
						 hit_frame_edge;


endmodule

