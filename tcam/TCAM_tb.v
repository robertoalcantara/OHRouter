`timescale 1 ns / 100 ps
//
//  OHRouter
//  TCAM tb for route lookup - brute force, easy and fast - not resource optimized, good for small number of routes
//  Roberto Alcantara <roberto at eletronica.org>
//


module TCAM_tb();

	parameter WIDTH = 32;
	parameter SIZE = 8;	

		
	wire[31:0] addr_out;    //next hop
	wire[3:0] if_idx;      //interface index to route packet
	wire[WIDTH-1:0] prefix_size;
	
	reg wr_en;
	reg[SIZE-1:0] wr_index;
	reg [(WIDTH*2)-1 +4:0] addr_in;
	
	reg clk_out;

	
	reg clk_125;

	
	//(* ram_init_file = "content_tb.mif" *) 
	reg [(WIDTH*2)-1+4:0] content [SIZE-1:0];  // [(WIDTH*2)-1 +4:(WIDTH*2)]->if_idx  [(WIDTH*2)-1 : WIDTH ] -> netmask  [WIDTH-1:0] ->prefix
	
	integer idx;

	TCAM tcam( .clk(clk_out), .addr_in(addr_in), .addr_out(addr_out), .if_idx(if_idx), .prefix_size(prefix_size), .wr_en(wr_en) );
			 
			 
	initial begin
		//$readmemh("content_tb.list", content);
		clk_125 = 0;
		clk_out=0;
		wr_en = 0;		
		
		addr_in = 32'd3232235521; //192.168.0.1
	end
	
	
	
	always begin
		#8 clk_125 = !clk_125; //125Mhz
	
	end
	
	
	always @(posedge clk_125) begin 
	
		#100
		addr_in = addr_in +1;		
		clk_out = 1;
		#1
		clk_out = 0;
	
	end
	
	


endmodule