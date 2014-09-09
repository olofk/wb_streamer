module wb_stream_writer_tb;

   localparam FIFO_MAX_BLOCK_SIZE = 32;
   localparam FIFO_AW = 5;
   localparam RAM_AW = 9;
   
   localparam MAX_BURST_LEN = 128;
   
   localparam WB_AW = 32;
   localparam WB_DW = 32;
   localparam WSB = WB_DW/8; //Word size in bytes
   
   localparam BUF_SIZE = 128; //Buffer size in bytes
   localparam BURST_SIZE = 8;
   
   reg clk = 1'b1;
   reg rst = 1'b1;
   
   always#10 clk <= ~clk;
   initial #100 rst <= 0;

   vlog_tb_utils vlog_tb_utils0();
   
   //Wishbone memory interface
   wire [WB_AW-1:0]    wb_m2s_data_adr;
   wire [WB_DW-1:0]    wb_m2s_data_dat;
   wire [WB_DW/8-1:0]  wb_m2s_data_sel;
   wire 	       wb_m2s_data_we;
   wire 	       wb_m2s_data_cyc;
   wire 	       wb_m2s_data_stb;
   wire [2:0] 	       wb_m2s_data_cti;
   wire [1:0] 	       wb_m2s_data_bte;
   wire [WB_DW-1:0]    wb_s2m_data_dat;
   wire 	       wb_s2m_data_ack;
   wire 	       wb_s2m_data_err;
   wire 	       wb_s2m_data_rty;

   //Stream interface
   wire [WB_DW-1:0]    stream_data;
   wire 	       stream_dv;
   wire 	       stream_busy;

   reg 		       rst2 = 1'b1;
   initial #150 rst2 <= 0;
   
   wb_stream_writer
     #(.FIFO_AW (FIFO_AW),
       .MAX_BURST_LEN (MAX_BURST_LEN))
   wb_stream_writer0
     (.clk       (clk),
      .rst       (rst2),
      //Stream data output
      .wbm_adr_o (wb_m2s_data_adr),
      .wbm_dat_o (wb_m2s_data_dat),
      .wbm_sel_o (wb_m2s_data_sel),
      .wbm_we_o  (wb_m2s_data_we),
      .wbm_cyc_o (wb_m2s_data_cyc),
      .wbm_stb_o (wb_m2s_data_stb),
      .wbm_cti_o (wb_m2s_data_cti),
      .wbm_bte_o (wb_m2s_data_bte),
      .wbm_dat_i (wb_s2m_data_dat),
      .wbm_ack_i (wb_s2m_data_ack),
      .wbm_err_i (wb_s2m_data_err),
      .wbm_rty_i (wb_s2m_data_rty),
      //FIFO interface
      .stream_data_o (stream_data),
      .stream_dv_o   (stream_dv),
      .stream_busy_i (!stream_busy));

   fifo_fwft_reader
     #(.WIDTH (WB_DW),
       .MAX_BLOCK_SIZE (FIFO_MAX_BLOCK_SIZE))
   fifo_reader0
     (.clk   (clk),
      .din   (stream_data),
      .rden  (stream_busy),
      .empty (!stream_dv));

   wb_ram
     #(.depth (BUF_SIZE))
   wb_ram0
     (//Wishbone Master interface
      .wb_clk_i (clk),
      .wb_rst_i (rst2),
      .wb_adr_i	(wb_m2s_data_adr[$clog2(BUF_SIZE)-1:0]),
      .wb_dat_i	(wb_m2s_data_dat),
      .wb_sel_i	(wb_m2s_data_sel),
      .wb_we_i	(wb_m2s_data_we),
      .wb_cyc_i	(wb_m2s_data_cyc),
      .wb_stb_i	(wb_m2s_data_stb),
      .wb_cti_i	(wb_m2s_data_cti),
      .wb_bte_i	(wb_m2s_data_bte),
      .wb_dat_o	(wb_s2m_data_dat),
      .wb_ack_o	(wb_s2m_data_ack),
      .wb_err_o (wb_s2m_data_err));
   
   integer 			       i;
   reg [WB_DW-1:0] 		       start_adr;
   
   initial begin
      @(negedge rst);
      @(posedge clk);

      start_adr = 0;
      
      //FIXME: Implement wb slave config IF
      wb_stream_writer0.cfg.buf_size = BUF_SIZE;
      wb_stream_writer0.cfg.burst_size = BURST_SIZE;
      wb_stream_writer0.cfg.start_adr = start_adr;
      
      //fifo_writer0.rate = 0.1;
      
      test_main();
      $display("All done");
      $finish;
   end

   task test_main;
      reg [BUF_SIZE*WB_DW-1:0] expected;
      reg [BUF_SIZE*WB_DW-1:0] received;
      integer 		       samples;
      integer 		       idx;
      integer 		       tmp;
      integer 		       seed;
      integer 		       start_addr;
      
      begin
	 start_addr = 0;
	 
	 //Generate stimuli
	 for(idx=0 ; idx<BUF_SIZE/WSB ; idx=idx+1) begin
	    tmp = $random(seed);
	    expected[WB_DW*idx+:WB_DW] = tmp[WB_DW-1:0];
	 end
	 samples = idx;
	 
	 //Initialize memory
	 $display("Initializing memory with %0d samples starting at %0d", samples, start_addr);
	 mem_write(expected, samples, start_addr);

	 @(posedge clk);
	 
	 //Start receive transactor
	 fifo_read(received, samples);

	 compare(expected, received, samples);
      end
   endtask
   
   task fifo_read;
      output [FIFO_MAX_BLOCK_SIZE*WB_DW-1:0] data_o;
      input integer 			    length_i;
      
      begin
	 fifo_reader0.read_block(data_o, length_i);
	 $display("Done reading %0d words from DUT", length_i);
      end
   endtask

   task mem_write;
      input [BUF_SIZE*WB_DW-1:0] data_i;
      input integer 		 length_i;
      input [WB_AW-1:0] 	 start_addr_i;
      
      integer 	      idx;
      
      begin
	 for(idx = 0; idx < length_i ; idx = idx + 1) begin
	    $display("Writing 0x%8x to address 0x%8x", data_i[idx*WB_DW+:WB_DW], start_addr_i+idx*4);
	    wb_ram0.ram0.mem[start_addr_i+idx] = data_i[idx*WB_DW+:WB_DW];
	 end
      end
   endtask

   task compare;
      input [BUF_SIZE*WB_DW-1:0] expected_i;
      input [BUF_SIZE*WB_DW-1:0] received_i;
      input integer 		 samples;

      integer 			 idx;
      reg [WB_DW-1:0] expected;
      reg [WB_DW-1:0] received;

      begin
	 for(idx=0 ; idx<samples ; idx=idx+1) begin
	    expected = expected_i[idx*WB_DW+:WB_DW];
	    received = received_i[idx*WB_DW+:WB_DW];
	 
	    if(expected !==
	       received) begin
	       $display("Error at sample %0d. Expected 0x%8x, got 0x%8x", idx, expected, received);
	      
	    end
	 end
      end
   endtask
   
endmodule
