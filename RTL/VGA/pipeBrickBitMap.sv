// System-Verilog 'written by Alex Grinshpun May 2018
// New bitmap dudy February 2025
// (c) Technion IIT, Department of Electrical Engineering 2025 



module	pipeBrickBitMap	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic	InsideRectangle, //input that the pixel is within a bracket 
					input 	logic [10:0] gapTop,
					input 	logic regenerate,
					
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;


localparam int PIPE_TOP_HEIGHT = 32;
localparam int PIPE_BOTTOM_HEIGHT = 32;
localparam int SCREEN_HEIGHT = 480;

parameter int GAP_SIZE_Y = 108 ;
parameter logic [1:0] INITIAL_PILLAR_TYPE = 2'b00;


logic [4:0]  local_y; // 5 bits for 32 pixels height, y value in relation to the object itself
logic [10:0] gapBottom;
logic [10:0] pipe_top_y;
logic [10:0] pipe_bottom_y;
logic [10:0] rom_address;

logic [1:0] pillar_type;

logic [7:0] top_color;
logic [7:0] mid_color;
logic [7:0] bottom_color;


assign gapBottom = gapTop + GAP_SIZE_Y;
assign rom_address = {local_y[4:0], offsetX[5:0]};

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 



// **********************
// 		 pillar 1
// **********************
logic	[7:0] bottom_color_0;
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
) bottom_rom_0_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(bottom_color_0)
);

logic	[7:0] mid_color_0;
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
) mid_rom_0_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(mid_color_0)
);

logic	[7:0] top_color_0;
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
) top_rom_0_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(top_color_0)
);




// **********************
// 		 pillar 2
// **********************
logic	[7:0] bottom_color_1;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_bottom_2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) bottom_rom_1_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(bottom_color_1)
);

logic	[7:0] mid_color_1;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_mid_2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) mid_rom_1_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(mid_color_1)
);

logic	[7:0] top_color_1;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_top_2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) top_rom_1_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(top_color_1)
);



// **********************
// 		 pillar 3
// **********************
logic	[7:0] bottom_color_2;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_bottom_3v2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) bottom_rom_2_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(bottom_color_2)
);

logic	[7:0] mid_color_2;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_mid_3v2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) mid_rom_2_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(mid_color_2)
);

logic	[7:0] top_color_2;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_top_3.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) top_rom_2_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(top_color_2)
);



// **********************
// 		 pillar 4
// **********************
logic	[7:0] bottom_color_3;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_bottom_4.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) bottom_rom_3_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(bottom_color_3)
);

logic	[7:0] mid_color_3;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_mid_4.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) mid_rom_3_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(mid_color_3)
);

logic	[7:0] top_color_3;
lpm_rom #(
   .LPM_WIDTH(8),
   .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
   .LPM_FILE("RTL/pillar_top_4.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
     .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) top_rom_3_inst (
   .address(rom_address),
	 .inclock(clk),
	// .outclock(clk),
   .q(top_color_3)
);




// -------------------------------------------------------

// set the pillar's chosen graphic

always_comb begin
    case (pillar_type)
        2'b00: begin
				top_color = top_color_0;
				mid_color = mid_color_0;
				bottom_color = bottom_color_0;
			end
        2'b01: begin
				top_color = top_color_1;
				mid_color = mid_color_1;
				bottom_color = bottom_color_1;
			end
        2'b10: begin	
				top_color = top_color_2;
				mid_color = mid_color_2;
				bottom_color = bottom_color_2;
			end
        2'b11: begin
				top_color = top_color_3;
				mid_color = mid_color_3;
				bottom_color = bottom_color_3;
			end
		  default: begin
            top_color = top_color_0;
            mid_color = mid_color_0;
            bottom_color = bottom_color_0;
        end
    endcase
end




//////////--------------------------------------------------------------------------------------------------------------=

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <= TRANSPARENT_ENCODING;
		pillar_type <= INITIAL_PILLAR_TYPE;

	end

	else begin
		if (regenerate)
				pillar_type <= pillar_type + 2'd1;
				
		
		RGBout <= TRANSPARENT_ENCODING ; // default  

		if (InsideRectangle == 1'b1 ) begin // inside an external bracket 
		
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
					local_y <= (offsetY - gapBottom - 1);	
				end
				else if (offsetY < SCREEN_HEIGHT - PIPE_BOTTOM_HEIGHT) begin
					// mid part of floor pillar
					RGBout <= mid_color;
					local_y <= offsetY - (gapBottom + PIPE_TOP_HEIGHT) - 1;
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
					local_y <= (gapTop - offsetY - 1);	
				end
				else if (offsetY < gapTop - PIPE_TOP_HEIGHT && offsetY >= 0) begin
					// mid part of floor pillar
					RGBout <= mid_color;
					local_y <= (gapTop - PIPE_TOP_HEIGHT - offsetY - 1);
				end
			end
		end  	
	end
		
end

//--------------------------------------------------------------------------------------------------------------=

// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; 

endmodule