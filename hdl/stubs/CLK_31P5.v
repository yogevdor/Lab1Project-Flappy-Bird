// Simulation stand-in for the Quartus PLL IP (CLK_31P5.v on main).
// The simulator has no real clock frequencies, so the "31.5MHz" clock is simply the clock we toggle,
// and `locked` (which the design uses as its reset) goes high after a few hundred cycles, like a real PLL.
module CLK_31P5 (
    input  wire refclk,
    input  wire rst,
    output wire outclk_0,
    output wire locked
);
    reg [8:0] cnt = 9'd0;
    always @(posedge refclk) begin
        if (rst)                cnt <= 9'd0;
        else if (cnt != 9'h1FF) cnt <= cnt + 9'd1;
    end
    assign outclk_0 = refclk;
    assign locked   = (cnt == 9'h1FF);
endmodule
