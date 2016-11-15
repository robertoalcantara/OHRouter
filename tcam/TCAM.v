`timescale 1 ns / 100 ps
/*
  OHRouter
  Roberto Alcantara <roberto at eletronica.org>

  TCAM for route lookup - Easy and fast lookup.  
  Notes: Brute force, resource hungry. Good for small tables. 
  
*/



module TCAM (
	input wire clk,
	input  wire[(32*2)-1 +4:0] addr_in,  // address input. [WIDTH-1:0] for read only operations
	output reg[31:0] addr_out,    		 // prefix found
	output reg[7:0] prefix_size,         // netmask found
	output reg[3:0] if_idx,              // interface index to route
	output reg valid,						 	 // output is valid
	input wire wr_en,                    // write enable
	input wire[7:0] wr_index            // memory position 256 entries max
	);

parameter WIDTH = 32;
parameter SIZE = 32;   //info: 8=608(594)   16=1262 (1146reg)    32=2498(2250reg)

reg [(WIDTH*2)-1+4+1:0] content [SIZE-1:0]; // [bit 1]->valid [(WIDTH*2)-1 +4:(WIDTH*2)]->if_idx  [(WIDTH*2)-1 : WIDTH ] -> netmask  [WIDTH-1:0] ->prefix
parameter VALID_ENTRY_POS = (WIDTH*2)-1+4;

reg [7:0] count_ones[SIZE-1:0]; 
integer idx[SIZE-1:0];
integer best_value;

reg [7:0] best_six; //256 entries max (SIZE) 
reg [7:0] six;      //256 entries max (SIZE)

reg[WIDTH-1:0] addr_in_mask [SIZE-1:0];


initial begin
	$readmemh("content_tb.list", content); 
	valid = 1'b0;	
end


always @addr_in begin
	valid = 1'b0;

	best_value = 0;
	best_six = 0;
   	
	for (six=0; six<SIZE; six = six + 7'd1) begin
	  count_ones[six] = 0;
	  addr_in_mask[six] = addr_in[WIDTH-1:0] & content[six][(WIDTH*2)-1:WIDTH];
	  
	  if ( content[six][VALID_ENTRY_POS]==1'b1 && addr_in_mask[six] == content[six][WIDTH-1:0] ) begin //Prefix MATCH
		  for( idx[six] = 0; idx[six]<WIDTH; idx[six] = idx[six] + 1) begin
			 count_ones[six] = count_ones[six] + content[six][idx[six]+WIDTH];
		  end
		  
		  if ( count_ones[six]>=best_value ) begin
				best_value = count_ones[six];
				best_six = six;
				valid = 1'b1;
		  end
		end
	end
end


always @(posedge clk) begin

	if (wr_en==0) begin
		//output lookup date
		addr_out <= content[best_six][WIDTH-1:0];
		prefix_size <= count_ones[best_six];
		if_idx <= content[best_six][(WIDTH*2)-1 +4:(WIDTH*2)];
	end
	else begin
		//update memory content
		content[wr_index] <= addr_in;
	end
end

 
	
endmodule