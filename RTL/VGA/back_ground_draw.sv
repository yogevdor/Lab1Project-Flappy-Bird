
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


// scrolling the background

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
    .q(BG_RGB)
); // background

endmodule

