// Simulation model of the Quartus lpm_rom megafunction (same ports/parameters as RTL uses).
// Behaves like the Cyclone V ROM with a REGISTERED address: q shows the data one clock after the address.
// The ROM files (LPM_FILE, e.g. "RTL/fish.mif") are read with $readmemh, so tools/convert_mif.py
// rewrites every .mif into a plain list of hex words under the same file name.
module lpm_rom #(
    parameter LPM_WIDTH = 8,
    parameter LPM_WIDTHAD = 8,
    parameter LPM_NUMWORDS = 0,
    parameter LPM_FILE = "",
    parameter LPM_TYPE = "LPM_ROM",
    parameter LPM_ADDRESS_CONTROL = "REGISTERED",
    parameter LPM_OUTDATA = "UNREGISTERED",
    parameter AUTO_CARRY_CHAINS = "ON",
    parameter AUTO_CASCADE_BUFFERS = "ON",
    parameter INTENDED_DEVICE_FAMILY = "Cyclone V"
)(
    input  [LPM_WIDTHAD-1:0] address,
    input                    inclock,
    output [LPM_WIDTH-1:0]   q
);
    localparam DEPTH = (LPM_NUMWORDS == 0) ? (1 << LPM_WIDTHAD) : LPM_NUMWORDS;
    // Array larger than DEPTH on purpose: some .mif files hold more words than the instance uses
    // (the FPGA ROM just keeps the first DEPTH words); $readmemh must not abort on them.
    localparam MEMSZ = DEPTH + 65536;
    reg [LPM_WIDTH-1:0]   mem [0:MEMSZ-1];
    reg [LPM_WIDTHAD-1:0] addr_q;

    integer n;
    initial begin
        for (n = 0; n < DEPTH; n = n + 1) mem[n] = {LPM_WIDTH{1'b1}};
        $readmemh(LPM_FILE, mem);
    end

    always @(posedge inclock) addr_q <= address;
    assign q = (LPM_ADDRESS_CONTROL == "REGISTERED") ? mem[addr_q] : mem[address];
endmodule
