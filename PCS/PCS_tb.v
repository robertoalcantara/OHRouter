`timescale 1 ns / 100 ps

//  OHRouter
//  PCS layer
//  Roberto Alcantara <roberto at eletronica.org>



module PCS_tb ();


	reg clk_125;
	reg reset_n;

	reg [0:7] xcvr_rxd;
	reg xcvr_rx_datak;
	reg xcvr_rx_ready;
	
	reg xcvr_rx_clk;

	parameter IDLE = 8'hBC;
	parameter COMMA = 8'b10111111; 
	parameter SOP = 8'hFB; 
	parameter EOP = 8'hFD; //T
	parameter CARRIER_EX = 8'hF7; //R
	
	PCS pcs( .mac_tx_er(), .mac_tx_en(),  .mac_gtx_clk(), .mac_txd(),
			 .mac_rx_er(mac_rx_er), .mac_rx_dv(mac_rx_dv), .mac_rxd(mac_rxd), .mac_rx_clk(),	 .mac_crs(), .mac_col(), 
			 .xcvr_txd(), .xcvr_tx_datak(), .xcvr_tx_ready(), .xcvr_tx_clk(), 
			 .xcvr_rxd(xcvr_rxd), .xcvr_rx_datak(xcvr_rx_datak), .xcvr_rx_ready(xcvr_rx_ready), .xcvr_rx_disparity(), .xcvr_rx_clk(xcvr_rx_clk),
			 .reset_n( reset_n ), .clk_125( clk_125 )	
			 );
		

			 
	initial begin
		reset_n = 0;
		clk_125 = 0;
		xcvr_rx_datak = 0;
		xcvr_rxd = 0;
		xcvr_rx_ready = 0;
		xcvr_rx_clk = 0;
		
		#40
		reset_n = 1;
		xcvr_rx_ready = 1;
	end
	
	
	always begin
		#8 clk_125 = !clk_125; //125Mhz
	end

	
	initial begin
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		
		
		xmit_from_xcvr_to_pcs( COMMA, 1 );
		xmit_from_xcvr_to_pcs( 8'h00, 0 );
		xmit_from_xcvr_to_pcs( COMMA, 1 );
		xmit_from_xcvr_to_pcs( 8'hAA, 0 );
		xmit_from_xcvr_to_pcs( COMMA, 1 );
		xmit_from_xcvr_to_pcs( 8'hBB, 0 ); //SYNC
	
		
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		
		/*xmit_from_xcvr_to_pcs( SOP, 1 );
		xmit_from_xcvr_to_pcs( 8'hAA, 0 );
		xmit_from_xcvr_to_pcs( EOP, 1 );
		xmit_from_xcvr_to_pcs( CARRIER_EX, 1 );
		xmit_from_xcvr_to_pcs( CARRIER_EX, 1 );
		
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );*/

		
		xmit_from_xcvr_to_pcs( SOP, 1 );
		xmit_from_xcvr_to_pcs( 1, 0 );
		xmit_from_xcvr_to_pcs( 2, 0 );
		xmit_from_xcvr_to_pcs( 3, 0 );
		xmit_from_xcvr_to_pcs( 4, 0 );
		xmit_from_xcvr_to_pcs( 5, 0 );
		xmit_from_xcvr_to_pcs( EOP, 1 );
		xmit_from_xcvr_to_pcs( CARRIER_EX, 1 );
		xmit_from_xcvr_to_pcs( CARRIER_EX, 1 );
		xmit_from_xcvr_to_pcs( SOP, 1 );			
  	 


		xmit_from_xcvr_to_pcs( SOP, 1 );
		xmit_from_xcvr_to_pcs( 8'h10, 0 );
		xmit_from_xcvr_to_pcs( 8'h11, 0 );
		xmit_from_xcvr_to_pcs( 8'h12, 0 );
		xmit_from_xcvr_to_pcs( 8'h13, 0 );
		xmit_from_xcvr_to_pcs( 8'h14, 0 );
		xmit_from_xcvr_to_pcs( 8'h15, 0 );
		xmit_from_xcvr_to_pcs( EOP, 1 );
		xmit_from_xcvr_to_pcs( CARRIER_EX, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		
		
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );		
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );
		xmit_from_xcvr_to_pcs( IDLE, 1 );		
		
		
	end

	
	task xmit_from_xcvr_to_pcs;
		input [7:0] data;
		input datak;

		begin
			@(posedge clk_125) begin 
				xcvr_rx_clk = 1;
				xcvr_rx_datak = datak;
				xcvr_rxd = data;
			end
			@(posedge clk_125);
			@(posedge clk_125);
			@(posedge clk_125);
			@(posedge clk_125);
			
			xcvr_rx_clk = 0; //time to transmit 8 bits data
			@(posedge clk_125);
			@(posedge clk_125);
			@(posedge clk_125);
			
		end
	endtask
	
	



	
endmodule
