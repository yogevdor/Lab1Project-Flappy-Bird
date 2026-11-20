// Optional replacement for the `audio` block (NOAUDIO=1 ./build.sh ...).
// The browser build has no sound yet, and the audio chain (sine table, prescaler, melody ROM, ...) costs
// simulation time on every clock, so it can be switched off. Nothing visible depends on it.
module audio (
    input  wire       resetN,
    input  wire       clk,
    input  wire       volume,
    input  wire       startMelody,
    input  wire [1:2] AUDIN,
    input  wire [3:0] melodySelect,
    output wire [4:7] AUDOUT
);
    assign AUDOUT = 4'b0000;
endmodule
