//TODO: Allow burst size = 1
//TODO: Add timeout counter to clear out FIFO
module wb_stream_ctrl
  #(parameter WB_AW = 32,
    parameter WB_DW = 32,
    parameter FIFO_AW = 0,
    parameter MAX_BURST_LEN = 0)
  (//Stream data output
   input 		    wb_clk_i,
   input 		    wb_rst_i,
   output reg [WB_AW-1:0]   wbm_adr_o,
   output reg [WB_DW-1:0]   wbm_dat_o,
   output reg [WB_DW/8-1:0] wbm_sel_o,
   output reg 		    wbm_we_o ,
   output reg 		    wbm_cyc_o,
   output reg 		    wbm_stb_o,
   output reg [2:0] 	    wbm_cti_o,
   output reg [1:0] 	    wbm_bte_o,
   input [WB_DW-1:0] 	    wbm_dat_i,
   input 		    wbm_ack_i,
   input 		    wbm_err_i,
   input 		    wbm_rty_i,
   //FIFO interface
   input [WB_DW-1:0] 	    fifo_d,
   input 		    fifo_dv,
   input [FIFO_AW-1:0] 	    fifo_cnt,
   output reg 		    fifo_rd,
   //Configuration interface
   input 		    enable,
   input [WB_AW-1:0] 	    start_adr,
   input [WB_AW-1:0] 	    buf_size,
   input [WB_AW-1:0] 	    burst_size,
   input 		    continous);
   
`include "wb_bfm_params.v"
   
   initial if(FIFO_AW == 0) $error("%m : Error: FIFO_AW must be > 0");
   
   reg [WB_AW-1:0] 	    adr;
   reg 			    active;

   wire 		    timeout = 1'b0;
   reg 			    const_burst;
   reg 			    last_adr;
   reg 			    wrap_buf;
   reg [$clog2(MAX_BURST_LEN-1):0] burst_cnt;
   
   //FSM states
   localparam S_IDLE   = 0;
   localparam S_ACTIVE = 1;
   localparam S_LAST   = 2;
   
   reg [1:0] 			      state;

   wire 			      burst_end = (burst_cnt == burst_size-1);

   always @(active or burst_end or const_burst) begin
      wbm_cti_o = !active     ? 3'b000 :
		  burst_end   ? 3'b111 :
		  const_burst ? 3'b001 : //CONSTANT_BURST :
		  3'b010; //LINEAR_BURST;
   end
   
   always @(posedge wb_clk_i) begin
      //Default assignments
      const_burst <= (buf_size == 1);

      //Read new data from FIFO
      fifo_rd <= fifo_dv & active;

      //Address generation
      last_adr = 1'b0;
      wrap_buf = 1'b0;
      if(wbm_ack_i)
	if(adr == buf_size-1) begin
	  wrap_buf = !const_burst;
	  adr = 0;
	end else
	  adr = adr+1;
      wbm_adr_o <= start_adr + adr*4;
      
      wbm_dat_o <= fifo_d;
      
      wbm_sel_o <= {4{active}};
      wbm_we_o  <= active;
      wbm_cyc_o <= active;
      wbm_stb_o <= active;

      wbm_bte_o <= 2'b00;

      //Burst counter
      if(!active)
	burst_cnt <= 0;
      else
	if(wbm_ack_i)
	  burst_cnt <= burst_cnt + 1;
      
      //FSM
      active <= 1'b0;
      case (state)
	S_IDLE : begin
	   if ((fifo_cnt >= burst_size) | timeout) begin
	     /*if(burst_size == 1)
	       state <= S_LAST;
	     else*/
	      state <= S_ACTIVE;
	      active <= 1'b1;
	      //fifo_rd <= fifo_dv;
	   end
	end
	S_ACTIVE : begin
	   active <= 1'b1;
	   if(wrap_buf | burst_end) begin
	      active <= 1'b0;
	      state <= S_IDLE;
	      fifo_rd <= 1'b0;
	   end
	end
	default : begin
	   state <= S_IDLE;
	end
      endcase // case (state)
      
      if(wb_rst_i) begin
	 wbm_cyc_o <= 1'b0;
	 wbm_stb_o <= 1'b0;
	 adr <= 0;
	 
      end
   end
   
endmodule
