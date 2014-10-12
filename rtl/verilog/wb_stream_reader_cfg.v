module wb_stream_cfg
  #(parameter WB_AW = 32,
    parameter WB_DW = 32)
  (
   input 		  wb_clk_i,
   input 		  wb_rst_i,
   //Wishbone IF
   input [WB_AW-1:0] 	  wb_adr_i,
   input [WB_DW-1:0] 	  wb_dat_i,
   input [WB_DW/8-1:0] 	  wb_sel_i,
   input 		  wb_we_i ,
   input 		  wb_cyc_i,
   input 		  wb_stb_i,
   input [2:0] 		  wb_cti_i,
   input [1:0] 		  wb_bte_i,
   output [WB_DW-1:0] 	  wb_dat_o,
   output reg 		  wb_ack_o,
   output 		  wb_err_o,
   output 		  wb_rty_o,
   //Application IF
   output reg 		  enable,
   output reg [WB_AW-1:0] start_adr,
   output reg [WB_AW-1:0] buf_size,
   output reg [WB_AW-1:0] burst_size);

   initial begin
      enable = 1'b1;
      start_adr = 0; 
      buf_size  = 8;//FIXME
      burst_size = 4; //FIXME
   end
  
  endmodule // wb_stream_cfg
