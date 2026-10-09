module score_counter (
    input  logic clk,
	 input  logic resetN,
    input  logic point,
	
    output logic [3:0] hundreds, tens, ones
);

always_ff @(posedge clk or negedge resetN) begin

	if (!resetN) begin
		hundreds <= 0;
		tens <= 0;
		ones <= 0;
	end
	
	else if (point) begin
		if (ones != 9)
			ones <= ones + 1;
		else begin
			ones <= 0;
			if (tens != 9)
				tens <= tens + 1;
            else begin
                tens <= 0;
                if (hundreds != 9)
					hundreds <= hundreds + 1;
                else begin
					hundreds <= 9; tens <= 9; ones <= 9;   // stay at 999
				end
            end
        end
    end
end
endmodule