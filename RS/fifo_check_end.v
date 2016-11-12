//pcs_fifo



module FIFO_CHECK_END (
	input wire[7:0] data,
	input wire datak,
	input wire clk,
	output wire early_end,
	output wire r_r_i,  //tri_rri
	output wire t_r_r,
	output wire r_r_r,
	output wire r_r_s
);


//******************************************************************************
//internal signals                                                              
//******************************************************************************


reg [7:0] buffer [2:0] ;
reg buffer_k [2:0];

parameter IDLE = 8'hBC;
parameter COMMA = 8'b10111111; 
parameter SOP = 8'hFB; 
parameter EOP = 8'hFD; //T
parameter CARRIER_EX = 8'hF7; //R
	
	
	
always @(posedge clk) begin  //or data na condicao. removido

	buffer[2] <= buffer[1];
	buffer[1] <= buffer[0];
	buffer[0] <= data;
	
	buffer_k[2] <= buffer_k[1];
	buffer_k[1] <= buffer_k[0];
	buffer_k[0] <= datak;

end


assign r_r_r = (
	(buffer[0]==CARRIER_EX & buffer_k[0]==1)  &  (buffer[1]==CARRIER_EX & buffer_k[1]==1)  & (buffer[2]==CARRIER_EX & buffer_k[2]==1)
);

assign t_r_r = (
	(buffer[0]==CARRIER_EX & buffer_k[0]==1)  &  (buffer[1]==CARRIER_EX & buffer_k[1]==1)  & (buffer[2]==EOP & buffer_k[2]==1)
);

assign r_r_i = (
	(buffer[0]==IDLE & buffer_k[0]==1)  &  (buffer[1]==CARRIER_EX & buffer_k[1]==1)  & (buffer[2]==EOP & buffer_k[2]==1)
);

assign r_r_s = (
	(buffer[0]==SOP & buffer_k[0]==1)  &  (buffer[1]==CARRIER_EX & buffer_k[1]==1)  & (buffer[2]==CARRIER_EX & buffer_k[2]==1)
);


/*	
	function is_carrier_extend; // /R/
	input [7:0] data_check;
		is_carrier_extend = (data_check == 8'hF7 & xcvr_rx_datak==1 );
	endfunction
	
	function is_sop; // /S/  Start of Packet
	input [7:0] data_check;
		is_sop = (data_check == 8'hFB & xcvr_rx_datak==1 );
	endfunction

	function is_eop; // /T/  End of Packet
	input [7:0] data_check;
		is_eop = (data_check == 8'hFD & xcvr_rx_datak==1 );
	endfunction
	
	function is_error_prop; // /V/  Error propagation
	input [7:0] data_check;
		is_error_prop = (data_check == 8'hFE & xcvr_rx_datak==1 );
	endfunction*/
		
	/*function is_check_end_early_end;
	input cnt;
		is_check_end_early_end =  (
			is_idle(xcvr_rcv_check_end[cnt-2], xcvr_rcv_datak_check_end[cnt-2]) &  xcvr_rcv_datak_check_end[cnt-1]==0 & is_idle(xcvr_rcv_check_end[cnt],xcvr_rcv_datak_check_end[cnt])   
				| ( is_idle( xcvr_rcv_check_end[cnt-2], xcvr_rcv_datak_check_end[cnt-2]) & ( xcvr_rcv_datak_check_end[cnt-1]==0 & (xcvr_rcv_check_end[cnt-1]==8'hB5 | xcvr_rcv_check_end[cnt-1]==8'h42) & xcvr_rcv_check_end[cnt]==8'h00) & rx_even )
				);
	endfunction*/
	
endmodule