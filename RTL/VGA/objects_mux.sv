
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input logic	clk,
					input logic	resetN,
		   // fish
					input logic	fishDrawingRequest, // two set of inputs per unit
					input logic	[7:0] fishRGB, 
			
			// single pipes:
					input logic	singlePipe1DrawingRequest, // two set of inputs per unit
					input logic	[7:0] singlePipe1RGB, 

					input logic	singlePipe2DrawingRequest, // two set of inputs per unit
					input logic	[7:0] singlePipe2RGB, 

					input logic	singlePipe3DrawingRequest, // two set of inputs per unit
					input logic	[7:0] singlePipe3RGB, 
			
			
		  // add the box here 
					input logic scoreDrawingRequest,
					input logic [7:0] SQR_RGB,
			  
		  ////////////////////////
		  // background 
					input logic startScreenDrawingRequest,
					input logic	[7:0] startScreenRGB,
		
					input logic gameOverScreenDrawingRequest,
					input logic	[7:0] gameOverScreenRGB,  
					
					input logic backgroundObjectDrawingRequest,
					input logic [7:0] BGObjRGB, // background objects over the full screen background
					
					input logic	[7:0] backGroundRGB, 
					input logic	BGDrawingRequest, 
					
					input logic	[7:0] RGB_MIF, 
					
			// DARK-MODE
					input logic darkModeOn,
					input logic [10:0] fishTopLeftX,
					input logic [10:0] fishTopLeftY,
					input logic [10:0] pixelX,
					input logic [10:0] pixelY,

			  
				   output logic	[7:0] RGBOut
);

localparam logic [7:0] DARK_MODE_COLOR = 8'h04;
localparam int DARK_MODE_RADIUS = 200; 
localparam int DARK_MODE_RADIUS_SQUARED = DARK_MODE_RADIUS * DARK_MODE_RADIUS;

// function that makes every RGB darker by shifting
function automatic logic [7:0] darken(input logic [7:0] c);
	return {1'b0, c[7:6],  1'b0, c[4:3],  1'b0, c[1]};
endfunction

int dx, dy, squared_distance;

// dark-mode distance from fish calculation
always_comb begin
	dx = pixelX - (fishTopLeftX + 16);
	dy = pixelY - (fishTopLeftY + 16);
	squared_distance = (dx * dx) + (dy * dy);
end

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (startScreenDrawingRequest == 1'b1)
			RGBOut <= startScreenRGB;  //first priority

		else if (scoreDrawingRequest == 1'b1 )   // score above the game over screen, so it shows in its panel
			RGBOut <= SQR_RGB;

		else if (gameOverScreenDrawingRequest == 1'b1)
			RGBOut <= gameOverScreenRGB;
		 
		else if (darkModeOn && (squared_distance > DARK_MODE_RADIUS_SQUARED))
			RGBOut <= DARK_MODE_COLOR;
			
		else if (fishDrawingRequest == 1'b1 )
			RGBOut <= fishRGB;
		// pipe and bg gets darker if dark mode is on
		else if (singlePipe1DrawingRequest == 1'b1 )
			RGBOut <= darkModeOn ? darken(singlePipe1RGB) : singlePipe1RGB;
		
		else if (singlePipe2DrawingRequest == 1'b1 )
			RGBOut <= darkModeOn ? darken(singlePipe2RGB) : singlePipe2RGB;

		else if (singlePipe3DrawingRequest == 1'b1 )
			RGBOut <= darkModeOn ? darken(singlePipe3RGB) : singlePipe3RGB;
		
		else if (backgroundObjectDrawingRequest == 1'b1 )
			RGBOut <= darkModeOn ? darken(BGObjRGB) : BGObjRGB;
				
		else if (BGDrawingRequest == 1'b1)
				RGBOut <= darkModeOn ? darken(backGroundRGB) : backGroundRGB ;
				
		else RGBOut <= darkModeOn ? darken(RGB_MIF) : RGB_MIF ;// last priority 
		end ; 
	end

endmodule


