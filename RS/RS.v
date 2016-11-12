`timescale 1 ns / 100 ps
//
//  OHRouter
//  PCS layer
//  Roberto Alcantara <roberto at eletronica.org>
//
//
//          in            out                in           out                  in                              out
//    Tx_mac_data[32]    mac_txd[8]       mac_txd[8]  xcvr_txd[8]      eth_xcvr0_tx_parallel[8]            eth_xcvr0_tx_serial_data_export[1]
//
//                 TX  +-----+      TX        +-------+                     TX  +------+ 
//       ------------> |     | ------------>  |   P   | --------------------->  |      | ------------> TX_SERIAL_DATA  
//      Logic          | MAC |                |   C   |                         | xcvr | 
//       <------------ |     | <-----------   |   S   | <--------------------   |      | <------------ RX_SERIAL_DATA  
//                 RX  +-----+      RX        +-------+                     RX +------+
//      
// !! Rx_mac_data[32]    mac_rxd[8]       mac_rxd[8]  xcvr_rxd[8]      eth_xcvr0_rx_parallel[8]            eth_xcvr0_rx_serial_data_export[1]
//          out           in                 out          in                  out                             in
//
//


module PCS (
		input  wire mac_tx_er,   //GMII signals 
		input  wire mac_tx_en,
		input  wire mac_gtx_clk,
		input  wire[7:0] mac_txd,		
		output reg mac_rx_er,
		output reg mac_rx_dv,
		output reg[7:0] mac_rxd,
		output wire mac_rx_clk,
		output wire mac_crs,
		output wire mac_col,
	    
		output wire [7:0] xcvr_txd,	 //XCVR signals ( Cyclone V GX Custom PHY)	
		output wire xcvr_tx_datak,
		input  wire xcvr_tx_ready,
		input  wire xcvr_tx_clk,
		
		input  wire [7:0] xcvr_rxd,   
		input  wire xcvr_rx_datak,
		input  wire xcvr_rx_ready,
		input  wire	xcvr_rx_disparity,
		input  wire xcvr_rx_clk,
		
		input wire reset_n,   
		input clk_125		
	);

//******************************************************************************
//internal signals                                                              
//******************************************************************************

	wire comma;
	wire sop;
	wire cgbad; 
	wire cggood;
	wire xcvr_rxd_invalid;
	reg rx_even;     
	reg [2:0] good_cgs; 
	reg[4:0] sync_state; 	
	reg[4:0] xcvr_rcv_state;

				  
	//fifo check_end
  	wire early_end;
	wire check_end_r_r_i;
	wire check_end_t_r_r;
	wire check_end_r_r_r;			
	wire check_end_r_r_s;
	
	
	
	parameter LOSS_OF_SYNC   = 0,
			  COMMA_DETECT_1   = 1,
			  ACQUIRE_SYNC_1   = 2,
			  COMMA_DETECT_2   = 3,
			  ACQUIRE_SYNC_2   = 4,
			  COMMA_DETECT_3   = 5,
			  SYNC_ACQUIRED_1  = 6,
			  SYNC_ACQUIRED_2  = 7,
			  SYNC_ACQUIRED_2Z = 8,
			  SYNC_ACQUIRED_2A = 9,
			  SYNC_ACQUIRED_2AZ = 10,
			  SYNC_ACQUIRED_3   = 11,
			  SYNC_ACQUIRED_3Z  = 12,
			  SYNC_ACQUIRED_3A  = 13,
			  SYNC_ACQUIRED_3AZ = 14,
			  SYNC_ACQUIRED_4   = 15,
			  SYNC_ACQUIRED_4Z  = 16,
			  SYNC_ACQUIRED_4A  = 17,	
			  SYNC_ACQUIRED_4AZ = 18;	

	parameter SYNC_FAIL = 0,
			  SYNC_OK = 1;
			  
	
	parameter RCV_IDLE 			  = 0,
			  RCV_START_OF_PACKET = 1,
			  RCV_RECEIVE 		  = 2,
			  RCV_EARLY_END 	  = 3,
			  RCV_RX_DATA_ERROR   = 4,
			  RCV_TRI_RRI         = 5,
			  RCV_RX_DATA         = 6,
			  RCV_TRR_EXTEND	  = 7,
			  RCV_EARLY_END_EXT   = 8,
			  RCV_EPD2_CHECK_END  = 9,
			  RCV_EXTEND_ERR	  = 10,
			  RCV_PACKET_BURST_RRS = 11;
 
	assign comma = is_comma(xcvr_rxd, xcvr_rx_datak );
	assign sop = is_sop( xcvr_rxd, xcvr_rx_datak );
	assign xcvr_rxd_invalid = 0;  //TODO: need check if is possible to receive invalid data from transceiver phy.
	assign cgbad = ( is_comma(xcvr_rxd, xcvr_rx_datak) && rx_even==1) | xcvr_rxd_invalid ;
	assign cggood = !cgbad;
	assign mac_rx_clk = xcvr_rx_clk;

	
	function is_comma; // /COMMA/
	input [7:0] data_check;
	input datak;
		is_comma = ( ( (data_check & 8'b00111111) == 8'b00111111 ) & datak==1) ;
	endfunction
	
	function is_sop; // /S/  Start of Packet
	input [7:0] data_check;
	input datak;
		is_sop = (data_check == 8'hFB & datak==1 );
	endfunction
	
	function is_idle; // /I/  K28.5
	input [7:0] data_check;
	input datak;
		is_idle = (data_check == 8'hBC & datak==1);
	endfunction	
	

	FIFO_CHECK_END fifo_check_end( .data(xcvr_rxd), .datak(xcvr_rx_datak), .clk( xcvr_rx_clk ), .early_end(early_end), .r_r_i(check_end_r_r_i), .t_r_r(check_end_t_r_r), .r_r_r(check_end_r_r_r), .r_r_s(check_end_r_r_s) );
	
	
	always @(negedge xcvr_rx_clk) begin
	
	
		/* new data arrived from transceivers (xcvr)  */ 
	
	  if (reset_n==0) begin
			sync_state <= LOSS_OF_SYNC;
			xcvr_rcv_state <= RCV_IDLE;
			mac_rxd <= 0;
		end
				

	
		// IEEE 802.3z page 1.245 (section 3.62)	
		
		case (sync_state)
		
			LOSS_OF_SYNC: begin
				if ( xcvr_rx_ready==1 && comma ) sync_state <= COMMA_DETECT_1;
				rx_even <= !rx_even;
			end
			
			COMMA_DETECT_1: begin
				sync_state <= xcvr_rx_datak ? ACQUIRE_SYNC_1 : LOSS_OF_SYNC; 
				rx_even <= 1;
			end 
			
			ACQUIRE_SYNC_1: begin
				if ( rx_even==0 && comma ) sync_state <= COMMA_DETECT_2;
				if ( cgbad ) sync_state <= LOSS_OF_SYNC;
				rx_even <= !rx_even;
			end
			
			COMMA_DETECT_2: begin
				sync_state <= xcvr_rx_datak ? ACQUIRE_SYNC_2 : LOSS_OF_SYNC;
				rx_even <= 1;
			end
			
			ACQUIRE_SYNC_2: begin
				if (rx_even==0 && comma ) sync_state <= COMMA_DETECT_3;
				if ( cgbad ) sync_state <= LOSS_OF_SYNC;
				rx_even <= !rx_even;
			end
			
			COMMA_DETECT_3: begin
				sync_state <= !xcvr_rx_datak ? SYNC_ACQUIRED_1 : LOSS_OF_SYNC;
				rx_even <= 1;
			end 
			
			SYNC_ACQUIRED_1: begin
				if (cgbad) sync_state <= SYNC_ACQUIRED_2;
				rx_even <= !rx_even;
			end
			
			SYNC_ACQUIRED_2: begin
				sync_state <= SYNC_ACQUIRED_2Z;
				rx_even <= !rx_even;	
			end
			
			SYNC_ACQUIRED_2Z: begin
				sync_state <= cgbad ? SYNC_ACQUIRED_3 : SYNC_ACQUIRED_2A;
				good_cgs <= 0;
			end
			
			SYNC_ACQUIRED_3: begin
				sync_state <= SYNC_ACQUIRED_3Z;
				rx_even <= !rx_even;			
			end
			
			SYNC_ACQUIRED_3Z: begin
				sync_state <= cgbad ? SYNC_ACQUIRED_4 : SYNC_ACQUIRED_3A;
				good_cgs <= 0;
			end
			
			SYNC_ACQUIRED_2A: begin
				sync_state <= SYNC_ACQUIRED_2AZ;
				rx_even <= !rx_even;
			end
			
			SYNC_ACQUIRED_2AZ: begin
				if ( cgbad ) sync_state <= SYNC_ACQUIRED_3;
				if ( (good_cgs==3) & cggood ) sync_state <= SYNC_ACQUIRED_1;
				good_cgs <= good_cgs + 1'b1;
			end
			
			SYNC_ACQUIRED_3A: begin
				sync_state <= SYNC_ACQUIRED_3AZ;	
				rx_even <= !rx_even;
			end
			
			SYNC_ACQUIRED_3AZ:  begin
				if ( cgbad ) sync_state <= SYNC_ACQUIRED_4;
				if ( (good_cgs==3) & cggood ) sync_state <= SYNC_ACQUIRED_2;
				good_cgs <= good_cgs + 1'b1;
			end
			
			SYNC_ACQUIRED_4: begin
				sync_state <= SYNC_ACQUIRED_4Z;
				rx_even <= !rx_even;
			end
			
			SYNC_ACQUIRED_4Z: begin
				sync_state <= cgbad ? LOSS_OF_SYNC : SYNC_ACQUIRED_4A;
				good_cgs <= 0;
			end
			
			SYNC_ACQUIRED_4A: begin
				sync_state <= SYNC_ACQUIRED_4AZ;
				rx_even <= !rx_even;
			end
			
			SYNC_ACQUIRED_4AZ: begin
				if ( cgbad ) sync_state <= LOSS_OF_SYNC;
				if ( (good_cgs==3) & cggood ) sync_state <= SYNC_ACQUIRED_3;
				good_cgs <= good_cgs + 1'b1;
			end
		endcase
			


		if ( sync_state == SYNC_ACQUIRED_1 ) begin //Sync state machine: IEEE 802.3z page 1.242 (36-7b)
			
			case (xcvr_rcv_state)
			
				RCV_IDLE: begin
					//receiving = 0;
					mac_rx_dv <= 0;
					mac_rx_er <= 0;
				
					if (sop) begin
						mac_rx_dv <= 1;
						mac_rx_er <= 0;
						mac_rxd <= 8'b01010101;
						xcvr_rcv_state <= RCV_RECEIVE;
					end
				end
			
				RCV_START_OF_PACKET: begin
					mac_rx_dv <= 1;
					mac_rx_er <= 0;
					mac_rxd <= 8'b01010101;
					xcvr_rcv_state <= RCV_RECEIVE;
				end
		
				RCV_RECEIVE: begin  //TODO Mais estados para ver...
					
					if ( xcvr_rx_datak == 0 ) begin
						//data code
						mac_rx_er <= 0;
						mac_rxd <= xcvr_rxd;					
					end else begin
						mac_rx_dv <= 0;
					end			
					
					if ( check_end_t_r_r ) begin 
						mac_rx_dv <= 0;
						mac_rx_er <= 1;
						mac_rxd <= 8'h0F;
						xcvr_rcv_state <= RCV_EPD2_CHECK_END;						
					end
					
					if ( check_end_r_r_r ) begin
						mac_rx_er <= 1;
						xcvr_rcv_state <= RCV_EPD2_CHECK_END;
					end
					if ( check_end_r_r_i & rx_even ) begin
						mac_rx_dv <= 0;
						mac_rx_er <= 0;
						//receiving <= 0;
						xcvr_rcv_state <= RCV_IDLE; //checar, checar... pela nossa sequencia
					end
					
				end

				RCV_EARLY_END: begin		
				end

				RCV_RX_DATA_ERROR: begin		
				end

				RCV_TRI_RRI: begin		
					end

				RCV_TRR_EXTEND: begin
				end

				RCV_EARLY_END_EXT: begin
				end

				
				RCV_EPD2_CHECK_END: begin
					if ( check_end_r_r_r ) xcvr_rcv_state <= RCV_TRR_EXTEND;
					else
						if ( check_end_r_r_i & rx_even ) xcvr_rcv_state <= RCV_TRI_RRI;
						else
							if ( check_end_r_r_s ) xcvr_rcv_state <= RCV_PACKET_BURST_RRS;
							else
								xcvr_rcv_state <= RCV_EXTEND_ERR;
				end

				RCV_EXTEND_ERR: begin
					mac_rx_dv <= 0;
					mac_rxd <= 8'h1F;
					if ( is_idle(xcvr_rxd, xcvr_rx_datak ) & rx_even)
						xcvr_rcv_state <= RCV_IDLE; //STATE B
						
					else if ( sop ) 
							xcvr_rcv_state <= RCV_START_OF_PACKET;
						else
							if ( !sop &  !(is_idle(xcvr_rxd, xcvr_rx_datak ) & rx_even) ) 
								xcvr_rcv_state <= RCV_EPD2_CHECK_END;							
							
						
				end
			
				RCV_PACKET_BURST_RRS: begin
					if ( sop ) begin
						xcvr_rcv_state <= RCV_START_OF_PACKET;
					end
					mac_rx_dv <= 0;
					mac_rxd <= 8'h0F;	
				end	
			endcase
		end
		
	end
			  
		
				 	
	

	
	
endmodule
	
	
	
	
	
		