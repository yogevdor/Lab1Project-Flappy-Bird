module	fish_bit_map	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic darkModeOn,
					input logic Y_direction_key,   // jump key, starts the flap animation
					input logic startOfFrame,

					output logic drawingRequest, //output that the pixel should be dispalyed 
					output logic [7:0] RGBout  //rgb value from the bitmap 
 ) ;

// 32x32 sprite: 5 bits of row and 5 bits of column give the 10 bit ROM address
logic	[9:0] address;
assign address = {offsetY[4:0], offsetX[4:0]};

logic	[7:0] color;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;

logic [7:0] default_fish_color;
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fish.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_default_inst (
    .address(address),
	 .inclock(clk),
    .q(default_fish_color)
);


logic [7:0] dark_mode_fish_color;
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishWithBulb.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_dark_mode_inst (
    .address(address),
	 .inclock(clk),
    .q(dark_mode_fish_color)
);

// flap animation
logic [7:0] anim1_color, anim2_color, anim3_color;

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishAnimation1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_anim1_inst (
    .address(address),
	 .inclock(clk),
    .q(anim1_color)
);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishAnimation2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_anim2_inst (
    .address(address),
	 .inclock(clk),
    .q(anim2_color)
);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishAnimation3.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_anim3_inst (
    .address(address),
	 .inclock(clk),
    .q(anim3_color)
);

// flap animation in dark mode (fish with bulb)
logic [7:0] bulb_anim1_color, bulb_anim2_color, bulb_anim3_color;

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishBulbAnimation1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_bulb_anim1_inst (
    .address(address),
	 .inclock(clk),
    .q(bulb_anim1_color)
);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishBulbAnimation2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_bulb_anim2_inst (
    .address(address),
	 .inclock(clk),
    .q(bulb_anim2_color)
);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/fishBulbAnimation3.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"),
		.LPM_OUTDATA            ("UNREGISTERED"),
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")
) rom_bulb_anim3_inst (
    .address(address),
	 .inclock(clk),
    .q(bulb_anim3_color)
);

localparam int FRAMES_PER_STEP = 8;   // video frames each animation picture 

logic [1:0] animStep;                 // 0 = normal fish and 1..3 = animation pictures
logic [2:0] frameCnt;
logic Y_direction_key_D;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		animStep <= 2'd0;
		frameCnt <= 3'd0;
		Y_direction_key_D <= 1'b0;
	end
	else begin
		Y_direction_key_D <= Y_direction_key;

		if (Y_direction_key && !Y_direction_key_D) begin   // start animation
			animStep <= 2'd1;
			frameCnt <= 3'd0;
		end
		else if (animStep != 2'd0 && startOfFrame) begin
			if (frameCnt == FRAMES_PER_STEP - 1) begin
				frameCnt <= 3'd0;
				animStep <= (animStep == 2'd3) ? 2'd0 : animStep + 2'd1;
			end
			else
				frameCnt <= frameCnt + 3'd1;
		end
	end
end

always_comb begin
	case (animStep)
		2'd1:    color = (darkModeOn) ? bulb_anim1_color : anim1_color;
		2'd2:    color = (darkModeOn) ? bulb_anim2_color : anim2_color;
		2'd3:    color = (darkModeOn) ? bulb_anim3_color : anim3_color;
		default: color = (darkModeOn) ? dark_mode_fish_color : default_fish_color;
	endcase
end

 

logic InsideRectangle_D;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN)
		InsideRectangle_D <= 1'b0;
	else
		InsideRectangle_D <= InsideRectangle;
end

// output register: the ROM color inside the bracket, transparent outside it

//--------------------------------------------------------------------------------------------------------------=

always_ff @(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <= 8'h00;
	end

	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default

		if (InsideRectangle_D == 1'b1 ) begin // inside an external bracket
			RGBout <= color;		
		end  	

	end
		
end

//--------------------------------------------------------------------------------------------------------------=

// decide if to draw the pixel or not 
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ;

endmodule