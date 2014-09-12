module wb_stream_reader
  #(parameter WB_DW = 32,
    parameter WB_AW = 32,
    parameter FIFO_AW = 0,
    parameter MAX_BURST_LEN = 2**FIFO_AW)
   (input 		 clk,
    input 		 rst,
    //Stream data output
    output [WB_AW-1:0] 	 wbm_adr_o,
    output [WB_DW-1:0] 	 wbm_dat_o,
    output [WB_DW/8-1:0] wbm_sel_o,
    output 		 wbm_we_o ,
    output 		 wbm_cyc_o,
    output 		 wbm_stb_o,
    output [2:0] 	 wbm_cti_o,
    output [1:0] 	 wbm_bte_o,
    input [WB_DW-1:0] 	 wbm_dat_i,
    input 		 wbm_ack_i,
    input 		 wbm_err_i,
    input 		 wbm_rty_i,
   //FIFO interface
    input [WB_DW-1:0] 	 stream_s_data_i,
    input 		 stream_s_valid_i,
    output 		 stream_s_ready_o,
   //Configuration interface
    input [WB_AW-1:0] 	 wbs_adr_i,
    input [WB_DW-1:0] 	 wbs_dat_i,
    input [WB_DW/8-1:0]  wbs_sel_i,
    input 		 wbs_we_i ,
    input 		 wbs_cyc_i,
    input 		 wbs_stb_i,
    input 		 wbs_cti_i,
    output 		 wbs_bte_i,
    output 		 wbs_dat_o,
    output 		 wbs_ack_o,
    output 		 wbs_err_o,
    output 		 wbs_rty_o);


   //FIFO interface
   wire [WB_DW-1:0] 	 fifo_dout;
   wire [FIFO_AW-1:0] 	 fifo_cnt;
   wire 		 fifo_rd;
   wire 		 fifo_full;

   //Configuration parameters
   wire 		 enable;
   wire [WB_AW-1:0] 	 start_adr; 
   wire [WB_AW-1:0] 	 buf_size;
   wire [WB_AW-1:0] 	 burst_size;
   
   
   wb_stream_ctrl
     #(.WB_AW (WB_AW),
       .WB_DW (WB_DW),
       .FIFO_AW (FIFO_AW),
       .MAX_BURST_LEN (MAX_BURST_LEN))
   wb_stream_ctrl0
     (.wb_clk_i    (clk),
      .wb_rst_i    (rst),
      //Stream data output
      .wbm_adr_o (wbm_adr_o),
      .wbm_dat_o (wbm_dat_o),
      .wbm_sel_o (wbm_sel_o),
      .wbm_we_o  (wbm_we_o),
      .wbm_cyc_o (wbm_cyc_o),
      .wbm_stb_o (wbm_stb_o),
      .wbm_cti_o (wbm_cti_o),
      .wbm_bte_o (wbm_bte_o),
      .wbm_dat_i (wbm_dat_i),
      .wbm_ack_i (wbm_ack_i),
      .wbm_err_i (wbm_err_i),
      .wbm_rty_i (wbm_rty_i),
      //FIFO interface
      .fifo_d   (fifo_dout),
      .fifo_dv  (!fifo_empty),
      .fifo_cnt (fifo_cnt),
      .fifo_rd  (fifo_rd),
      //Configuration interface
      .start_adr  (start_adr),
      .buf_size   (buf_size),
      .burst_size (burst_size),
      .enable     (enable));

   wb_stream_cfg
     #(.WB_AW (WB_AW),
       .WB_DW (WB_DW))
   wb_stream_cfg0
     (.wb_clk_i  (clk),
      .wb_rst_i  (rst),
      //Wishbone IF
      .wbs_adr_i (wbs_adr_i),
      .wbs_dat_i (wbs_dat_i),
      .wbs_sel_i (wbs_sel_i),
      .wbs_we_i  (wbs_we_i),
      .wbs_cyc_i (wbs_cyc_i),
      .wbs_stb_i (wbs_stb_i),
      .wbs_cti_i (wbs_cti_i),
      .wbs_bte_i (wbs_bte_i),
      .wbs_dat_o (wbs_dat_o),
      .wbs_ack_o (wbs_ack_o),
      .wbs_err_o (wbs_err_o),
      .wbs_rty_o (wbs_rty_o),
      //Application IF
      .enable    (enable),
      .start_adr (start_adr),
      .buf_size  (buf_size),
      .burst_size (burst_size));

   assign stream_ready_o = !fifo_full;
   
   fifo_fwft
     #(.DATA_WIDTH (WB_DW),
       .DEPTH_WIDTH (FIFO_AW))
   fifo0
   (.clk (clk),
    .rst (rst),
    .din (stream_data_i),
    .wr_en (stream_valid_i),
    .full (fifo_full),
    .dout (fifo_dout),
    .rd_en (fifo_rd),
    .empty (fifo_empty),
    .cnt  (fifo_cnt));

endmodule
