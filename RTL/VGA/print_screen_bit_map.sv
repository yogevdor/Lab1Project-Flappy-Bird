module print_screen_bit_map #(
    parameter string MIF_FILE = "RTL/start_screen320x240.mif"
)(
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic        enable,

    output logic        drawingRequest,
    output logic [7:0]  RGBout
);

localparam int W = 320;                       // stored picture width (will be x2 the size)
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

logic [16:0] address;
logic [7:0]  romColor;
logic        enable_D;

// each stored pixel covers 2x2 screen pixels
assign address = (pixelY >> 1) * W + (pixelX >> 1);

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(17),
    .LPM_NUMWORDS(76800),
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
    if (!resetN)
        enable_D <= 1'b0;
    else
        enable_D <= enable;
end

assign RGBout         = romColor;
assign drawingRequest = enable_D && (romColor != TRANSPARENT_ENCODING);

endmodule
