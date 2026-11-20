// Stand-in for the precompiled KBDINTF.qxp (PS/2 keyboard interface, black box on main).
// Same ports. It is a real PS/2 receiver: the simulator (main.cpp) bit-bangs scan-code frames onto
// PS2_CLK / PS2_DAT, and this module turns them into keyCode[8:0] + make / break pulses.
//   keyCode[8] = extended (E0) flag, keyCode[7:0] = scan code.
`begin_keywords "1364-2005"
module KBDINTF (
    input  wire       CLOCK_50,
    input  wire       resetN,
    input  wire       PS2_CLK,
    input  wire       PS2_DAT,
    output reg        make,
    output reg        break,
    output reg  [8:0] keyCode
);
    reg       clk_d;
    reg [3:0] cnt;
    reg [7:0] sh;
    reg       ext, brk;

    always @(posedge CLOCK_50 or negedge resetN) begin
        if (!resetN) begin
            clk_d <= 1'b1; cnt <= 4'd0; sh <= 8'd0; ext <= 1'b0; brk <= 1'b0;
            make <= 1'b0; break <= 1'b0; keyCode <= 9'd0;
        end else begin
            clk_d <= PS2_CLK;
            make  <= 1'b0;
            break <= 1'b0;
            if (clk_d && !PS2_CLK) begin               // falling edge of PS2_CLK: sample a bit
                if (cnt == 4'd0) cnt <= 4'd1;           // start bit
                else if (cnt <= 4'd8) begin             // 8 data bits, LSB first
                    sh[cnt - 4'd1] <= PS2_DAT;
                    cnt <= cnt + 4'd1;
                end else if (cnt == 4'd9) cnt <= 4'd10; // parity (ignored)
                else begin                              // stop bit: byte complete
                    cnt <= 4'd0;
                    if (sh == 8'hE0)      ext <= 1'b1;
                    else if (sh == 8'hF0) brk <= 1'b1;
                    else begin
                        keyCode <= {ext, sh};
                        make    <= ~brk;
                        break   <= brk;
                        ext     <= 1'b0;
                        brk     <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
`end_keywords
