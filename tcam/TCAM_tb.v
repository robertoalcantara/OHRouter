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
	wire[7:0] prefix_size;
	wire valid;
	reg wr_en;
	reg [(WIDTH*2)-1 +4:0] addr_in;
	reg[7:0] wr_index;
	
	reg clk_out;
	
	reg [(WIDTH*2)-1+4:0] content [SIZE-1:0];  // [(WIDTH*2)-1 +4:(WIDTH*2)]->if_idx  [(WIDTH*2)-1 : WIDTH ] -> netmask  [WIDTH-1:0] ->prefix
	
	integer idx;

	TCAM tcam( .clk(clk_out), .addr_in(addr_in), .addr_out(addr_out), .if_idx(if_idx), .prefix_size(prefix_size), .wr_en(wr_en), .valid(valid), .wr_index(wr_index) );
			 
			 
	initial begin
		clk_out=0;
		wr_en = 0;	
		addr_in = 0;	

		lookup(32'hc0a80001); //192.168.0.1
		lookup(32'hc0a8000a); //192.168.0.10
		lookup(32'hc0a8000f); //192.168.0.16
		lookup(32'hc0a8001e); //192.168.0.30
		lookup(32'hc0a80020); //192.168.0.32
		lookup(32'hc0a80021); //192.168.0.33
		lookup(32'hc0a8003c); //192.168.0.60
		lookup(32'hc0a8007e); //192.168.0.126
		lookup(32'hc0a800fa); //192.168.0.250
		lookup(32'hc0a80101); //192.168.1.1

		lookup(32'h0a00000a); //10.0.0.10
		lookup(32'h0a000a02); //10.0.0.2
		
	end
	
	task lookup ( input [31:0] addr);
	begin
		$display("-----------------------------"); 
		addr_in = addr;
		$display("addr_in = %d.%d.%d.%d", addr_in[31:24], addr_in[23:16],addr_in[15:8], addr_in[7:0] );
		#5
		clk_out = 1;
		#10
		clk_out = 0;
		
		if (valid) begin		
			
			$display("if_out=%d", if_idx);
			$display("net = %d.%d.%d.%d/%d", addr_out[31:24], addr_out[23:16],addr_out[15:8], addr_out[7:0], prefix_size );
		end
		else
			$display("Invalid");
	end
	endtask


	task table_list;
	begin
	
	end
	endtask


endmodule