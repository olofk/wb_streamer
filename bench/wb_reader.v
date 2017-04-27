`default_nettype none
module wb_reader
  #(parameter WB_AW = 32,
    parameter WB_DW = 32,
    parameter MAX_BURST_LEN = 0)
   (input wire               wb_clk_i,
    input wire               wb_rst_i,

    input wire [WB_AW-1:0]   wb_adr_i,
    input wire [WB_DW-1:0]   wb_dat_i,
    input wire [WB_DW/8-1:0] wb_sel_i,
    input wire               wb_we_i,
    input wire [1:0]         wb_bte_i,
    input wire [2:0]         wb_cti_i,
    input wire               wb_cyc_i,
    input wire               wb_stb_i,

    output wire              wb_ack_o,
    output wire              wb_err_o,
    output wire [WB_DW-1:0]  wb_dat_o);

   wb_bfm_slave
     #(.aw (WB_AW),
       .dw (WB_DW))
   bfm0
     (.wb_clk   (wb_clk_i),
      .wb_rst   (wb_rst_i),
      .wb_adr_i (wb_adr_i),
      .wb_dat_i (wb_dat_i),
      .wb_sel_i (wb_sel_i),
      .wb_we_i  (wb_we_i), 
      .wb_cyc_i (wb_cyc_i),
      .wb_stb_i (wb_stb_i),
      .wb_cti_i (wb_cti_i),
      .wb_bte_i (wb_bte_i),
      .wb_dat_o (wb_dat_o),
      .wb_ack_o (wb_ack_o),
      .wb_err_o (wb_err_o),
      .wb_rty_o ());
   
   task wb_read_burst;
      output [MAX_BURST_LEN*WB_AW-1:0] addr_o;
      output [MAX_BURST_LEN*WB_DW-1:0] data_o;
      output integer 	 length_o;

      reg [WB_AW-1:0] 	 addr;
      reg [WB_DW-1:0] 	 data;
      integer 		 idx;
      
      begin

	 bfm0.init();
	 
	 addr = wb_adr_i;
	 
	 if(bfm0.op !== bfm0.WRITE)
	   $error("%m : Expected a wishbone write operation");
	 else if(bfm0.cycle_type !== bfm0.BURST_CYCLE)
	   $error("%m : Expected a burst cycle");
	 else begin
	    idx = 0;
	    while(bfm0.has_next) begin
	       //FIXME: Check mask
	       bfm0.write_ack(data);
	       //$display("%d : Got new data %x", idx, data);
	       data_o[idx*WB_DW+:WB_DW] = data;
	       addr_o[idx*WB_DW+:WB_AW] = addr;
	       idx = idx + 1;
	       addr = bfm0.next_addr(addr, bfm0.burst_type);
	    end
	    length_o = idx;
	 end // else: !if(bfm0.cycle_type !== BURST_CYCLE)
      end
   endtask
   
endmodule
