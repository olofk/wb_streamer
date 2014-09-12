module wb_stream_writer_tb;

   localparam FIFO_MAX_BLOCK_SIZE = 32;
   localparam FIFO_AW = 5;
   localparam RAM_AW = 9;
   
   localparam MAX_BURST_LEN = 128;
   
   localparam WB_AW = 32;
   localparam WB_DW = 32;
   localparam WSB = WB_DW/8; //Word size in bytes
   
   localparam MEM_SIZE = 512; //Memory size in bytes
   
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

   //Wishbone configuration interface
   wire [WB_AW-1:0]    wb_m2s_cfg_adr;
   wire [WB_DW-1:0]    wb_m2s_cfg_dat;
   wire [WB_DW/8-1:0]  wb_m2s_cfg_sel;
   wire 	       wb_m2s_cfg_we;
   wire 	       wb_m2s_cfg_cyc;
   wire 	       wb_m2s_cfg_stb;
   wire [2:0] 	       wb_m2s_cfg_cti;
   wire [1:0] 	       wb_m2s_cfg_bte;
   wire [WB_DW-1:0]    wb_s2m_cfg_dat;
   wire 	       wb_s2m_cfg_ack;
   wire 	       wb_s2m_cfg_err;
   wire 	       wb_s2m_cfg_rty;

   //Stream interface
   wire [WB_DW-1:0]    stream_data;
   wire 	       stream_valid;
   wire 	       stream_ready;

   wb_stream_writer
     #(.FIFO_AW (FIFO_AW),
       .MAX_BURST_LEN (MAX_BURST_LEN))
   wb_stream_writer0
     (.clk       (clk),
      .rst       (rst),
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
      .stream_m_data_o  (stream_data),
      .stream_m_valid_o (stream_valid),
      .stream_m_ready_i (stream_ready),
      .wbs_adr_i (wb_m2s_cfg_adr),
      .wbs_dat_i (wb_m2s_cfg_dat),
      .wbs_sel_i (wb_m2s_cfg_sel),
      .wbs_we_i  (wb_m2s_cfg_we), 
      .wbs_cyc_i (wb_m2s_cfg_cyc),
      .wbs_stb_i (wb_m2s_cfg_stb),
      .wbs_cti_i (wb_m2s_cfg_cti),
      .wbs_bte_i (wb_m2s_cfg_bte),
      .wbs_dat_o (wb_s2m_cfg_dat),
      .wbs_ack_o (wb_s2m_cfg_ack),
      .wbs_err_o (wb_s2m_cfg_err),
      .wbs_rty_o (wb_s2m_cfg_rty));

   fifo_fwft_reader
     #(.WIDTH (WB_DW),
       .MAX_BLOCK_SIZE (FIFO_MAX_BLOCK_SIZE))
   fifo_reader0
     (.clk   (clk),
      .din   (stream_data),
      .rden  (stream_ready),
      .empty (!stream_valid));

   wb_ram
     #(.depth (MEM_SIZE))
   wb_ram0
     (//Wishbone Master interface
      .wb_clk_i (clk),
      .wb_rst_i (rst),
      .wb_adr_i	(wb_m2s_data_adr[$clog2(MEM_SIZE)-1:0]),
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

   wb_bfm_master
     #(.MAX_BURST_LENGTH (1)) 
   wb_cfg
     (.wb_clk_i (clk),
      .wb_rst_i (rst),
      .wb_adr_o (wb_m2s_cfg_adr),
      .wb_dat_o (wb_m2s_cfg_dat),
      .wb_sel_o (wb_m2s_cfg_sel),
      .wb_we_o  (wb_m2s_cfg_we), 
      .wb_cyc_o (wb_m2s_cfg_cyc),
      .wb_stb_o (wb_m2s_cfg_stb),
      .wb_cti_o (wb_m2s_cfg_cti),
      .wb_bte_o (wb_m2s_cfg_bte),
      .wb_dat_i (wb_s2m_cfg_dat),
      .wb_ack_i (wb_s2m_cfg_ack),
      .wb_err_i (wb_s2m_cfg_err),
      .wb_rty_i (wb_s2m_cfg_rty));
   
   integer 	       TRANSACTIONS;
   
   initial begin
      if(!$value$plusargs("transactions=%d", TRANSACTIONS))
	TRANSACTIONS = 1000;

      @(negedge rst);
      @(posedge clk);

      wb_write(8, BUF_SIZE);
      wb_write(12, BURST_SIZE);
      //fifo_writer0.rate = 0.1;

      //Initialize memory
      init_mem();
      
      @(posedge clk);
      @(posedge clk);
      
      repeat (TRANSACTIONS) test_main();
      $display("All done");
      $finish;
   end

   task test_main;
      reg [BUF_SIZE*WB_DW-1:0] expected;
      reg [BUF_SIZE*WB_DW-1:0] received;
      integer 		       samples;
      integer 		       idx;
      integer 		       start_addr;
      integer 		       seed;
      integer 		       tmp;
      
      begin
	 samples = BUF_SIZE/WSB;
	 
	 tmp = $dist_uniform(seed,0,(MEM_SIZE-BUF_SIZE)/WSB);
	 
	 start_addr = tmp*4;
	 $display("Setting start address to 0x%8x", start_addr);
	 wb_stream_writer0.cfg.start_adr = start_addr;
	 @(posedge clk);
	
	 //Strobe enable signal
	 wb_write(0, 1);
	 
	 //Start receive transactor
	 fifo_read(received, samples);
	 
	 verify(received, samples, start_addr);
      end
   endtask

   task wb_write;
      input [WB_AW-1:0] addr_i;
      input [WB_DW-1:0] data_i;

      reg 		err;
      begin
	 wb_cfg.write(addr_i, data_i, 4'hf, err);
	 if(err)
	   $error("Error writing to config interface address 0x%8x", addr_i);
      end
   endtask
   
   task fifo_read;
      output [FIFO_MAX_BLOCK_SIZE*WB_DW-1:0] data_o;
      input integer 			     length_i;
      
      begin
	 fifo_reader0.read_block(data_o, length_i);
      end
   endtask

   task init_mem;
      integer 	      idx;
      integer 	      tmp;
      integer 	      seed;
      
      begin
	 for(idx = 0; idx < MEM_SIZE/WSB ; idx = idx + 1) begin
	    tmp = $random(seed);
	    wb_ram0.ram0.mem[idx] = tmp[WB_DW-1:0];
	    $display("Writing 0x%8x to address 0x%8x", tmp, idx*WSB);
	 end
      end
   endtask

   task verify;
      input [BUF_SIZE*WB_DW-1:0] received_i;
      input integer 		 samples_i;
      input integer 		 start_addr_i;

      integer 			 idx;
      reg [WB_DW-1:0] 		 expected;
      reg [WB_DW-1:0] 		 received;
      reg 			 err;
      
      begin
	 err = 0;
	 for(idx=0 ; idx<samples_i ; idx=idx+1) begin
	    expected = wb_ram0.ram0.mem[start_addr_i/WSB+idx];
	    received = received_i[idx*WB_DW+:WB_DW];
	    
	    if(expected !==
	       received) begin
	       $display("Error at address 0x%8x. Expected 0x%8x, got 0x%8x", start_addr_i+idx*4, expected, received);
	       err = 1'b1;
	    end
	    //else $display("0x%8x", received);
	 end
	 if(!err)
	   $display("Successfully verified %0d words", idx);
	 else
	   $finish;
      end
   endtask
   
endmodule
