`timescale 1 ns / 100 ps
//
//  OHRouter
//  TCAM for route lookup - brute force, easy and fast - not resource optimized, good for small number of routes
//  Roberto Alcantara <roberto at eletronica.org>
//



module TCAM (
	input wire clk,
	input  wire[(32*2)-1 +4:0] addr_in,   //address input. [WIDTH-1:0] for read only operations
	output reg[31:0] addr_out,    //next hop
	output reg[3:0] if_idx,      //interface index to route packet
	output reg[32-1:0] prefix_size, //best match prefix size
	
	input wire wr_en,          //write enable
	input wire[8-1:0] wr_index //memory position
	);

parameter WIDTH = 32;
parameter SIZE = 8;	

reg [(WIDTH*2)-1+4:0] content [SIZE-1:0]; // [(WIDTH*2)-1 +4:(WIDTH*2)]->if_idx  [(WIDTH*2)-1 : WIDTH ] -> netmask  [WIDTH-1:0] ->prefix
reg [8:0] count_ones[SIZE-1:0]; 

integer idx[SIZE-1:0];
integer six;
integer best_value;
integer best_six;
reg[WIDTH-1:0] addr_in_mask [SIZE-1:0];
 
 


	initial begin
		$readmemh("content_tb.list", content);		
	end

always @addr_in begin

	best_value = 0;
	best_six = 0;
	for (six=0; six<SIZE; six = six + 1) begin
	  count_ones[six] = {WIDTH{1'b0}};
	  addr_in_mask[six] = addr_in[WIDTH-1:0] & content[six][(WIDTH*2)-1:WIDTH];
	  
	  if ( addr_in_mask[six] == content[six][WIDTH-1:0] ) begin //Prefix MATCH
		  for( idx[six] = 0; idx[six]<WIDTH; idx[six] = idx[six] + 1) begin
			 count_ones[six] = count_ones[six] + content[six][idx[six]+WIDTH];
		  end
		  
		  if (count_ones[six]>best_value) begin
				best_value = count_ones[six];
				best_six = six;
		  end
		end
	end
end


always @(posedge clk) begin
	if (wr_en==0) begin
		//output lookup date
		addr_out <= content[best_six][WIDTH-1:0];
		prefix_size <= best_six;
		if_idx <= content[best_six][(WIDTH*2)-1 +4:(WIDTH*2)];
	end
	else begin
		//update memory content
		content[wr_index] <= addr_in;
	end
end
 
	
endmodule