module PauseScreenBitMap(
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic        enable,

    output logic        drawingRequest,
    output logic [7:0]  RGBout
);

localparam int X0 = 192;
localparam int Y0 = 112;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

logic [10:0] relX, relY;
logic insideRectangle, inside_d, enable_d;
logic [13:0] address;
logic [7:0]  romColor;

assign relX   = pixelX - X0;
assign relY   = pixelY - Y0;
assign insideRectangle = (pixelX >= X0) && (pixelX < X0 + 256) &&
                (pixelY >= Y0) && (pixelY < Y0 + 256);

assign address = {relY[7:1], relX[7:1]};   // 128 x 128, shown 2x

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(14),
    .LPM_NUMWORDS(16384),
    .LPM_FILE("RTL/pauseNew.mif"),
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"),
    .LPM_OUTDATA("UNREGISTERED"),
    .AUTO_CARRY_CHAINS("ON"),
    .AUTO_CASCADE_BUFFERS("ON"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) rom_inst (
    .address(address),
    .inclock(clk),
    .q(romColor)
);


always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        enable_d <= 1'b0;
		  inside_d <= 1'b0;
	 end
    else begin
        enable_d <= enable;
		  inside_d <= insideRectangle;
	 end
end

assign RGBout         = romColor;
assign drawingRequest = enable_d && inside_d && (romColor != TRANSPARENT_ENCODING);

endmodule
