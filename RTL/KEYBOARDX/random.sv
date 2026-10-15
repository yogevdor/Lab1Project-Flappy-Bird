// (c) Technion IIT, Department of Electrical Engineering 2025 
module random 	
 ( 
	input	logic clk,
	input	logic resetN, 
	input	logic	rise,
	input logic flap,
	output logic unsigned [SIZE_BITS-1:0] dout	
  ) ;

// Generating a random number by latching a fast counter with the rising edge of an input ( e.g. key pressed )
  
parameter SIZE_BITS = 9;
parameter unsigned [SIZE_BITS-1:0] MIN_VAL = 32;  //set the min and max values 
parameter unsigned [SIZE_BITS-1:0] MAX_VAL = 276;
parameter int START_COUNTER = 53;

	logic unsigned  [SIZE_BITS-1:0] counter/* synthesis keep = 1 */;
	logic rise_d /* synthesis keep = 1 */;
	logic flap_d;
	logic [2:0] flap_cnt;

	localparam int RANGE = MAX_VAL - MIN_VAL + 1;      

	logic [SIZE_BITS:0] next_counter;                  // extra bit for overflow
	assign next_counter = counter + SIZE_BITS'(START_COUNTER) + SIZE_BITS'(flap_cnt);
	
	
always_ff @(posedge clk or negedge resetN) begin
		if (!resetN) begin
			dout <= START_COUNTER;  //  divide by 2
			counter <= START_COUNTER;
			rise_d <= 1'b0;
			flap_d <= 1'b0;
			flap_cnt <= 3'b0;
		end
		
		else begin
			if (next_counter > MAX_VAL)
				counter <= next_counter - RANGE;    // = MIN_VAL + (next - MAX_VAL - 1)
			else
				counter <= next_counter;
			rise_d <= rise;
			flap_d <= flap;
				
			if (flap && !flap_d)            
				flap_cnt <= flap_cnt + 1'b1;
			
			if (rise && !rise_d) // rising edge 
				dout <= counter;
		end
	
	end
 
endmodule

