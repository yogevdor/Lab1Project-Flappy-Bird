module MazeTopXLocationCounter (
	input logic clk,
	input logic resetN,
	input logic enable,
	output logic [10:0] result
	);
	
	
always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		result <= 1'b0;
		end
	else if (enable) begin
		if (result >= -640) begin
			result <= result - 1;
			end
		else
			result <= 1'b0;
	end
end

endmodule