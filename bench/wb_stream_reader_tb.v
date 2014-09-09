module wb_streamer_tb;

   localparam FIFO_MAX_BLOCK_SIZE = 8;
   localparam FIFO_AW = 5;
   localparam RAM_AW = 9;
   
   localparam MAX_BURST_LEN = 128;
   
   localparam WB_AW = 32;
   localparam WB_DW = 32;
   localparam WSB = WB_DW/8; //Word size in bytes
   
   localparam BUF_SIZE = 8;
   localparam BURST_SIZE = 8;
   
   reg clk = 1'b1;
   reg rst = 1'b1;
   
   always#10 clk <= ~clk;
   initial #100 rst <= 0;

   vlog_tb_utils vlog_tb_utils0();
   
   //Stream data output
   wire [WB_AW-1:0]    wb_m2s_ctrl_rx_adr;
   wire [WB_DW-1:0]    wb_m2s_ctrl_rx_dat;
   wire [WB_DW/8-1:0]  wb_m2s_ctrl_rx_sel;
   wire 	    wb_m2s_ctrl_rx_we;
   wire 	    wb_m2s_ctrl_rx_cyc;
   wire 	    wb_m2s_ctrl_rx_stb;
   wire [2:0]	    wb_m2s_ctrl_rx_cti;
   wire [1:0]	    wb_m2s_ctrl_rx_bte;
   wire [WB_DW-1:0] wb_s2m_ctrl_rx_dat;
   wire 	    wb_s2m_ctrl_rx_ack;
   wire 	    wb_s2m_ctrl_rx_err;
   wire 	    wb_s2m_ctrl_rx_rty;
   //FIFO interface
   wire [WB_DW-1:0] fifo_d;
   wire 	    fifo_wr;
   wire 	    fifo_full;
   
   wb_stream_reader
     #(.FIFO_AW (FIFO_AW),
       .MAX_BURST_LEN (MAX_BURST_LEN))
   wb_stream_reader0
     (.clk       (clk),
      .rst       (rst),
      //Stream data output
      .wbm_adr_o (wb_m2s_ctrl_rx_adr),
      .wbm_dat_o (wb_m2s_ctrl_rx_dat),
      .wbm_sel_o (wb_m2s_ctrl_rx_sel),
      .wbm_we_o  (wb_m2s_ctrl_rx_we),
      .wbm_cyc_o (wb_m2s_ctrl_rx_cyc),
      .wbm_stb_o (wb_m2s_ctrl_rx_stb),
      .wbm_cti_o (wb_m2s_ctrl_rx_cti),
      .wbm_bte_o (wb_m2s_ctrl_rx_bte),
      .wbm_dat_i (wb_s2m_ctrl_rx_dat),
      .wbm_ack_i (wb_s2m_ctrl_rx_ack),
      .wbm_err_i (wb_s2m_ctrl_rx_err),
      .wbm_rty_i (wb_s2m_ctrl_rx_rty),
      //FIFO interface
      .stream_data (fifo_d),
      .stream_dv   (fifo_wr),
      .stream_halt (fifo_full));

   fifo_writer
     #(.WIDTH (WB_DW),
       .MAX_BLOCK_SIZE (FIFO_MAX_BLOCK_SIZE))
   fifo_writer0
     (.clk (clk),
      .dout (fifo_d),
      .wren (fifo_wr),
      .full (fifo_full));

   wb_reader
     #(.WB_AW (WB_AW),
       .WB_DW (WB_DW),
       .MAX_BURST_LEN (MAX_BURST_LEN))
   wb_reader0
     (// Wishbone interface
      .wb_clk_i (clk),
      .wb_rst_i (rst),
      .wb_adr_i (wb_m2s_ctrl_rx_adr[WB_AW-1:0]),
      .wb_dat_i (wb_m2s_ctrl_rx_dat),
      .wb_sel_i (wb_m2s_ctrl_rx_sel),
      .wb_we_i  (wb_m2s_ctrl_rx_we) ,
      .wb_cyc_i (wb_m2s_ctrl_rx_cyc),
      .wb_stb_i (wb_m2s_ctrl_rx_stb),
      .wb_cti_i (wb_m2s_ctrl_rx_cti),
      .wb_bte_i (wb_m2s_ctrl_rx_bte),
      .wb_dat_o (wb_s2m_ctrl_rx_dat),
      .wb_ack_o (wb_s2m_ctrl_rx_ack),
      .wb_err_o ());
   
   integer 			       i;
   reg [WB_DW-1:0] 		       start_adr;
   
   initial begin
      @(negedge rst);
      @(posedge clk);

      start_adr = 0;
      
      //FIXME: Implement wb slave config IF
      wb_stream_reader0.wb_stream_cfg0.buf_size = BUF_SIZE;
      wb_stream_reader0.wb_stream_cfg0.burst_size = BURST_SIZE;
      wb_stream_reader0.wb_stream_cfg0.start_adr = start_adr;
      
      fifo_writer0.rate = 0.1;
      
      for(i=0 ; i < 4 ; i=i+1) begin
	 test_main(start_adr);
      end
      $display("All done");
      $finish;
   end

   task test_main;
      input [WB_AW-1:0]        start_addr;

      reg [BUF_SIZE*WB_DW-1:0] expected;
      integer 		       samples;
      integer 		       idx;
      integer 		       tmp;
      integer 		       seed;
      
      begin
	 //Generate stimuli
	 for(idx=0 ; idx<FIFO_MAX_BLOCK_SIZE ; idx=idx+1) begin
	    tmp = $random(seed);
	    expected[WB_DW*idx+:WB_DW] = tmp[WB_DW-1:0];
	 end
	 samples = idx;

	 //Start transmit and receive transactors
	 fork
	    fifo_write(expected, samples);
	    wb_read(expected, samples, start_addr);
	 join
	 
      end
   endtask
   
   task fifo_write;
      input [FIFO_MAX_BLOCK_SIZE*WB_DW-1:0] data_i;
      input integer 			    length_i;
      
      
      begin
	 fifo_writer0.write_block(data_i, length_i);
	 $display("Done sending %0d words to DUT", length_i);
      end
   endtask
      
   task wb_read;
      input [BUF_SIZE*WB_DW-1:0] wr_data_block;
      input integer 		 samples;
      input [WB_AW-1:0] 	 start_addr;
      
      reg [WB_DW-1:0] expected;
      reg [WB_DW-1:0] received;
      reg [MAX_BURST_LEN*WB_DW-1:0] data_vec;

      integer 	      sample_idx;
      integer 	      idx;
      integer 	      length;
      reg 	      err;
      
      begin
	 sample_idx = 0;
	 while(sample_idx < samples) begin
	    wb_read_range(start_addr, data_vec, length, err);
	    $display("wb_read_range got %0d samples starting at address 0x%8x", length, start_addr);
	    
	    for(idx = 0; idx < length ; idx = idx + 1) begin
	       expected = wr_data_block[(sample_idx+idx)*WB_DW+:WB_DW];
	       received = data_vec[idx*WB_DW+:WB_DW];
	       
	      if(received !== expected)
		$error("%m : Verify failed at address 0x%8x. Expected 0x%8x : Got 0x%8x",
		       start_addr + idx*WSB,
		       expected,
		       received);
	    end
	    start_addr = start_addr + length*WSB;
	    sample_idx = sample_idx + length;
	 end
      end
   endtask
   
   task wb_read_range;
      input [WB_AW-1:0] 	       start_addr_i;
      output [MAX_BURST_LEN*WB_DW-1:0] data_o;
      output integer 		       length_o;
      output 			       err_o;
      
      
      integer 			       idx;
      reg [MAX_BURST_LEN*WB_AW-1:0]    addr_vec;
      reg [WB_AW-1:0] 		       expected;
      reg [WB_AW-1:0] 		       received;
      
      
      begin
	 wb_reader0.wb_read_burst(addr_vec, data_o, length_o);
	 
	 //Verify consecutive addresses
	 for(idx=0;idx < length_o;idx=idx+1) begin
	    expected = start_addr_i+idx*WSB;
	    received = addr_vec[idx*WB_AW+:WB_AW];
	    if(received !== expected) begin
	       $error("%m : Address mismatch. Expected 0x%8x. Got 0x%8x",
		     expected,
		      received);
	       err_o = 1'b1;
	    end
	 end
      end
   endtask
   
endmodule
