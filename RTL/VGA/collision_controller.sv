
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021


module	collision_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz 
			input	logic	drawing_request_fish,
			input logic drawing_request_pipe,

			output logic collision		
);

logic collision_fish_pipe; // collision between Smiley and number - is not output

//assign collision_fish_pipe = (drawing_request_fish && drawing_request_pipe);

assign collision = (drawing_request_fish && drawing_request_pipe); 


endmodule

