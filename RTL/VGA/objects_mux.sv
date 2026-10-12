
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		   // fish
					input		logic	fishDrawingRequest, // two set of inputs per unit
					input		logic	[7:0] fishRGB, 
			
			// single pipes:
					input		logic	singlePipe1DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] singlePipe1RGB, 

					input		logic	singlePipe2DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] singlePipe2RGB, 

					input		logic	singlePipe3DrawingRequest, // two set of inputs per unit
					input		logic	[7:0] singlePipe3RGB, 
			
			
		  // add the box here 
					input		logic scoreDrawingRequest,
					input		logic [7:0] SQR_RGB,
			  
		  ////////////////////////
		  // background 
					input    logic startScreenDrawingRequest,
					input		logic	[7:0] startScreenRGB,
		
					input    logic gameOverScreenDrawingRequest,
					input		logic	[7:0] gameOverScreenRGB,  
					
					input		logic	[7:0] backGroundRGB, 
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] RGB_MIF, 
			  
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		if (startScreenDrawingRequest == 1'b1)
			RGBOut <= startScreenRGB;  //first priority

		else if (gameOverScreenDrawingRequest == 1'b1)
			RGBOut <= gameOverScreenRGB;

		else if (fishDrawingRequest == 1'b1 )
			RGBOut <= fishRGB;
			
		else if (scoreDrawingRequest == 1'b1 )
			RGBOut <= SQR_RGB;
		 
		else if (singlePipe1DrawingRequest == 1'b1 )
			RGBOut <= singlePipe1RGB;
		
		else if (singlePipe2DrawingRequest == 1'b1 )
			RGBOut <= singlePipe2RGB;

		else if (singlePipe3DrawingRequest == 1'b1 )
			RGBOut <= singlePipe3RGB;
				
		else if (BGDrawingRequest == 1'b1)
				RGBOut <= backGroundRGB ;
				
		else RGBOut <= RGB_MIF ;// last priority 
		end ; 
	end

endmodule


