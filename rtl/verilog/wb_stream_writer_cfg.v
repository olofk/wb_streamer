module wb_stream_writer_cfg
  #(parameter WB_AW = 32,
    parameter WB_DW = 32)
  (
   input 		  wb_clk_i,
   input 		  wb_rst_i,
   //Wishbone IF
   input [WB_AW-1:0] 	  wbs_adr_i,
   input [WB_DW-1:0] 	  wbs_dat_i,
   input [WB_DW/8-1:0] 	  wbs_sel_i,
   input 		  wbs_we_i ,
   input 		  wbs_cyc_i,
   input 		  wbs_stb_i,
   input 		  wbs_cti_i,
   output 		  wbs_bte_i,
   output 		  wbs_dat_o,
   output 		  wbs_ack_o,
   output 		  wbs_err_o,
   output 		  wbs_rty_o,
   //Application IF
   output reg 		  enable,
   output reg [WB_AW-1:0] start_adr,
   output reg [WB_AW-1:0] buf_size,
   output reg [WB_AW-1:0] burst_size);

   initial begin
      enable = 1'b0;
      start_adr = 0; 
      buf_size  = 8;//FIXME
      burst_size = 4; //FIXME
   end
  
  endmodule // wb_stream_cfg
