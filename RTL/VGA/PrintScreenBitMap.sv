module PrintScreenBitMap #(
    parameter string MIF_FILE = "RTL/startscreen.mif",
    parameter int TOP_X = 192,
    parameter int TOP_Y = 112
)(
    
	 input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic        enable,
	 
	 output logic        drawingRequest,
    output logic [7:0]  RGBout
	 
);

localparam int W = 256;
localparam int H = 256;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

logic        insideRectangle;
logic [10:0] offsetX, offsetY;
logic [15:0] address;
logic [7:0]  romColor;
logic        inside_D, enable_D;

assign insideRectangle  = (pixelX >= TOP_X) && (pixelX < TOP_X + W) &&(pixelY >= TOP_Y) && (pixelY < TOP_Y + H);
assign offsetX = pixelX - TOP_X;
assign offsetY = pixelY - TOP_Y;
assign address = {offsetY[7:0], offsetX[7:0]};

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(16),
    .LPM_NUMWORDS(65536),
    .LPM_FILE(MIF_FILE),
    .LPM_TYPE("LPM_ROM"),
    .LPM_ADDRESS_CONTROL("REGISTERED"),
    .LPM_OUTDATA("UNREGISTERED"),
    .INTENDED_DEVICE_FAMILY("Cyclone V")
) rom_inst (
    .address(address),
    .inclock(clk),
    .q(romColor)
);

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        inside_D <= 1'b0;
        enable_D <= 1'b0;
    end
    else begin
        inside_D <= insideRectangle;
        enable_D <= enable;
    end
end

assign RGBout         = romColor;
assign drawingRequest = enable_D && inside_D && (romColor != TRANSPARENT_ENCODING);

endmodule