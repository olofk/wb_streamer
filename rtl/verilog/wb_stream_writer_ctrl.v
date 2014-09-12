module wb_stream_writer_ctrl
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
   output reg [WB_DW-1:0]   fifo_d,
   output reg 		    fifo_wr,
   input [FIFO_AW-1:0] 	    fifo_cnt,
   //Configuration interface
   input 		    enable,
   input [WB_AW-1:0] 	    start_adr,
   input [WB_AW-1:0] 	    buf_size,
   input [WB_AW-1:0] 	    burst_size);
   
   
//`include "wb_bfm_params.v"
   
   initial if(FIFO_AW == 0) $error("%m : Error: FIFO_AW must be > 0");

   reg [WB_AW-1:0] 	    adr;
   reg 			    active;

   wire 		    timeout = 1'b0;
   reg 			    const_burst;
   reg 			    last_adr;
   reg [$clog2(MAX_BURST_LEN-1):0] burst_cnt;
   reg 				   enable_r;
   
   //FSM states
   localparam S_IDLE   = 0;
   localparam S_ACTIVE = 1;
   
   reg [1:0] 			      state;


   wire 			      burst_end = (burst_cnt == burst_size-1);

   always @(active or burst_end or const_burst) begin
      wbm_cti_o = !active     ? 3'b000 :
		  burst_end   ? 3'b111 :
		  3'b010; //LINEAR_BURST;
   end
   
   always @(posedge wb_clk_i) begin

      fifo_d  <= wbm_dat_i;
      fifo_wr <= wbm_ack_i;

      //Address generation
      last_adr = (adr == buf_size[WB_AW-1:2]-1);
      if(wbm_ack_i)
	if (last_adr)
	  adr = 0;
	else
	  adr = adr+1;
      wbm_adr_o <= start_adr + adr*4;
      
      wbm_dat_o <= {WB_DW{1'b0}};
      
      wbm_sel_o <= {4{active}};
      wbm_we_o  <= 1'b0;
      wbm_cyc_o <= active & !burst_end;
      wbm_stb_o <= active & !burst_end;

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
	   if (enable_r & (fifo_cnt+burst_size < 2**FIFO_AW)) begin
	      state <= S_ACTIVE;
	      active <= 1'b1;
	   end
	   if (enable)
	     enable_r <= 1'b1;

	end
	S_ACTIVE : begin
	   active <= 1'b1;
	   if(burst_end) begin
	      active <= 1'b0;
	      state <= S_IDLE;
	      if (last_adr)
		enable_r <= 1'b0;
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
	 enable_r <= 1'b0;
	 
      end
   end
   
endmodule
