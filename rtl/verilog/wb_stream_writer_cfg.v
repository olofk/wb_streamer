module wb_stream_writer_cfg
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
   output reg 		  irq,
   input 		  busy,
   output reg 		  enable,
   output reg [WB_AW-1:0] start_adr,
   output reg [WB_AW-1:0] buf_size,
   output reg [WB_AW-1:0] burst_size);

/*   initial begin
      enable = 1'b0;
      start_adr = 0; 
      buf_size  = 8;//FIXME
      burst_size = 4; //FIXME
   end*/

   reg 			  busy_r;
   always @(posedge wb_clk_i)
     if (wb_rst_i)
       busy_r <= 0;
     else
       busy_r <= busy;

   // Read
   assign wb_dat_o = wb_adr_i[5:2] == 0 ? {{(WB_DW-2){1'b0}}, irq, busy} : 0;

   always @(posedge wb_clk_i) begin
      // Ack generation
      if (wb_ack_o)
	wb_ack_o <= 0;
      else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
	wb_ack_o <= 1;

      //Read/Write logic
      enable <= 0;
      if (wb_stb_i & wb_cyc_i & wb_we_i & wb_ack_o) begin
	 case (wb_adr_i[31:2])
	   0 : begin
	      if (wb_dat_i[0]) enable <= 1;
	      if (wb_dat_i[1]) irq <= 0;
	   end
	   1 : start_adr <= wb_dat_i;
	   2 : buf_size  <= wb_dat_i;
	   3 : burst_size <= wb_dat_i;
	   default : ;
	 endcase // case (wb_adr_i[31:2])
      end

      // irq logic, signal on falling edge of busy
      if (!busy & busy_r)
	irq <= 1;

      if (wb_rst_i) begin
	 wb_ack_o   <= 0;
	 enable     <= 1'b0;
	 start_adr  <= 0; 
	 buf_size   <= 0;
	 burst_size <= 0;
	 irq <= 0;
      end
   end
   assign wb_err_o = 0;
   assign wb_rty_o = 0;

endmodule
