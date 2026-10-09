module score_digit_select (
    input  logic [10:0] offsetX,
    input  logic [3:0]  hundreds, tens, ones,
	
    output logic [3:0]  digit,
    output logic [10:0] offsetX_digit
);

always_comb begin

    offsetX_digit = {7'b0, offsetX[3:0]};

    if (offsetX < 16)
        digit = hundreds;
    else if (offsetX < 32)
        digit = tens;
    else
        digit = ones;
end

endmodule