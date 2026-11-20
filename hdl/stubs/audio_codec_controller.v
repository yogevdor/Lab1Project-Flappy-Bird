// Stand-in for the precompiled audio_codec_controller.QXP (WM8731 codec driver, black box on main).
// The browser build reads the sample straight from the design (see main.cpp), so this only needs
// to satisfy the port list. `last_sample` is kept so the value can be inspected in a waveform.
module audio_codec_controller (
    input  wire        CLOCK31_5,
    input  wire        resetN,
    input  wire        AUD_ADCLRCK,
    input  wire        AUD_BCLK,
    inout  wire        AUD_I2C_SDAT,
    input  wire [15:0] dacdata_left,
    input  wire [15:0] dacdata_right,
    output wire        AUD_DACDAT,
    output wire        AUD_XCK,
    output wire        AUD_I2C_SCLK
);
    reg [15:0] last_sample;
    always @(posedge CLOCK31_5) last_sample <= dacdata_left;
    assign AUD_DACDAT   = last_sample[15];
    assign AUD_XCK      = 1'b0;
    assign AUD_I2C_SCLK = 1'b1;
    assign AUD_I2C_SDAT = 1'bz;
endmodule
