
module	back_ground_draw	(	

					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0]	pixelX,
					input logic	[10:0]	pixelY,
					input logic	[18:0]	address,
					input logic startOfFrame,
					input logic game_on,
					input logic [9:0] speedBoost,

					output	logic	[7:0] BG_RGB
);


logic [2:0] redBits;
logic [2:0] greenBits;
logic [1:0] blueBits;


localparam logic [2:0] DARK_COLOR = 3'b111 ;// bitmap of a dark color

// **************************************************************
// ****************************
// for scrolling the backgorund
// ****************************

localparam int BG_W = 640;
parameter  int BG_SPEED = 1;	// starting speed, px/frame

logic [15:0] bgPos;	// fixed point: [15:6] = pixel, [5:0] = 1/64 px
logic [15:0] bgStep;
logic [9:0]  bgOffset;
logic [10:0] sumX;
logic [10:0] shiftedX;
logic [18:0] bgAddress;

assign bgStep   = BG_SPEED * 64 + (speedBoost >> 1); // half of the pipes boost
assign bgOffset = bgPos[15:6];

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN)
        bgPos <= 16'd0;
    else if (startOfFrame && game_on) begin
        if (bgPos + bgStep >= BG_W * 64)
            bgPos <= bgPos + bgStep - BG_W * 64;
        else
            bgPos <= bgPos + bgStep;
    end
end

assign sumX = pixelX + bgOffset;
assign shiftedX = (sumX >= BG_W) ? (sumX - BG_W) : sumX;
assign bgAddress = pixelY * BG_W + shiftedX;

//***************************************************************



 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(19),
	 .LPM_NUMWORDS(307200),
    .LPM_FILE("RTL/reef_seamless_fixed_640x480.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(bgAddress),
	 .inclock(clk),
	// .outclock(clk),
    .q(BG_RGB)
); // background
 
 
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
				redBits <= DARK_COLOR ;	
				greenBits <= DARK_COLOR  ;	
				blueBits <= DARK_COLOR[1:0] ;	 
	end 
	else begin

	// defaults 
		greenBits <= 3'b111 ; 
		redBits <= 3'b000 ;
		blueBits <= 2'b11;//LIGHT_COLOR;
		
	end; 	
end 
endmodule

