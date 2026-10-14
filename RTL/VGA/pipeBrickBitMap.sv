// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module	pipeBrickBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input 	logic 	[10:0] gapTop,

					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout,  //rgb value from the bitmap 
				   output   logic	[2:0] HitEdgeCode 
 ) ;


// localparam logic [7:0] PIPES_COLOR = 8'b11100000 ; //temporary
localparam int PIPE_TOP_HEIGHT = 32;
localparam int PIPE_BOTTOM_HEIGHT = 32;
localparam int SCREEN_HEIGHT = 480;

parameter int GAP_SIZE_Y = 108 ;

logic [4:0]  local_y; // 5 bits for 32 pixels height
logic [10:0] gapBottom;
logic [10:0] pipe_top_y;
logic [10:0] pipe_bottom_y;
logic [10:0] rom_address;

assign gapBottom = gapTop + GAP_SIZE_Y;
assign rom_address = {local_y[4:0], offsetX[5:0]};

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

//  // this is the devider used to access the right pixel 
// localparam  int OBJECT_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 
// localparam  int OBJECT_NUMBER_OF_X_BITS = 6;  // 2^6 = 64 

// localparam  logic	[10:0] OBJECT_HEIGHT_Y = 11'b1 <<  OBJECT_NUMBER_OF_Y_BITS ;
// localparam  logic	[10:0] OBJECT_WIDTH_X = 11'b1 <<  OBJECT_NUMBER_OF_X_BITS;


//  logic	[10:0] HitCodeX ;// offset of Hitcode 
//  logic	[10:0] HitCodeY ; 
// assign HitCodeX = offsetX >> ( OBJECT_NUMBER_OF_X_BITS - 4 );	//hitedge code MSB of the offset
// assign HitCodeY = offsetY >> ( OBJECT_NUMBER_OF_Y_BITS - 4 );	 	 
// //assign address = ((OBJECT_HEIGHT_Y-offsetY)*OBJECT_WIDTH_X + offsetX);
// assign address = (offsetY * OBJECT_WIDTH_X + offsetX);

// generating a smiley bitmap from a MIF file

logic	[7:0] bottom_color;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_bottom_1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) bottom_rom_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(bottom_color)
);

logic	[7:0] mid_color;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_mid_1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) mid_rom_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(mid_color)
);

logic	[7:0] top_color;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_top_1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) top_rom_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(top_color)
);


// pipeline (ff) to get the pixel color from the array 	 

//////////--------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <= TRANSPARENT_ENCODING;
		HitEdgeCode <= 3'h0;

	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  
		HitEdgeCode <= 3'h0;

		if (InsideRectangle == 1'b1 ) 
		begin // inside an external bracket 
			if (offsetY >= gapTop) begin	// gap or floor pillar
			// **||  GAP  ||**
				if (offsetY <= gapBottom) begin
					// inside gap
					RGBout <= TRANSPARENT_ENCODING;
					local_y <= 0;
				end

			// **||  FLOOR PILLAR  ||**
				else if (offsetY <= gapBottom + PIPE_TOP_HEIGHT) begin
					// top part of floor pillar
					RGBout <= top_color;
					local_y <= (offsetY - gapBottom);	
				end
				else if (offsetY <= SCREEN_HEIGHT - PIPE_BOTTOM_HEIGHT) begin
					// mid part of floor pillar
					RGBout <= mid_color;
					local_y <= offsetY - (gapBottom + PIPE_TOP_HEIGHT);
				end
				else begin
					// bottom part of floor pillar
					RGBout <= bottom_color;
					local_y <= offsetY - (SCREEN_HEIGHT - PIPE_BOTTOM_HEIGHT);
				end
			end
			
			else begin	// ceiling pillar
			
			// **||  CEILING PILLAR  ||**
				if (offsetY >= gapTop - PIPE_TOP_HEIGHT) begin
					// top part of ceiling pillar
					RGBout <= top_color;
					local_y <= (gapTop - offsetY);	
				end
				else if (offsetY < gapTop - PIPE_TOP_HEIGHT && offsetY >= 0) begin
					// mid part of floor pillar
					RGBout <= mid_color;
					local_y <= (gapTop - PIPE_TOP_HEIGHT - offsetY);
				end
			end
//			HitEdgeCode <= hit_colors[HitCodeY][HitCodeX];	//get hit edge code from the colors table  
		end  	
	end
		
end

//////////--------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule