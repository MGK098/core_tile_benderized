`timescale 1ns/1ps
module tb_sargantana_soc_wrap_F;

  import hpdcache_pkg::*;
  import test_types_pkg::*;

  // ================================================================
  // Parameters
  // ================================================================
  localparam int unsigned AxiAddrWidth     = 64;
  localparam int unsigned AxiDataWidth     = 64;
  localparam int unsigned AxiUserWidth     = 1;
  localparam int unsigned SlvIdWidth       = 2;
  localparam int unsigned MstIdWidth       = 4;
  localparam int unsigned SerMaxTxns       = 16;
  localparam int unsigned SerMaxUniqIds    = 16;
  localparam int unsigned SerMaxTxnsPerId  = 16;

  localparam int unsigned N_TESTS = 5;

  logic clk  = 0;
  logic rstn = 0;
  always #5 clk = ~clk;  

  int unsigned cyc = 0;
  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cyc > 2_000_000) begin
      $display("\n[FATAL] WATCHDOG: simulation exceeded 2M cycles! Deadlock detected.");
      $finish;
    end
  end

  // ================================================================
  // DUT port signals 
  // ================================================================
  logic        icache_req_valid;
  logic [39:0] icache_req_paddr;
  logic        icache_resp_valid;
  logic[511:0] icache_resp_data;
  logic        icache_resp_ack;

  logic        brom_req_valid;
  logic [39:0] brom_req_addr;
  logic        brom_resp_valid;
  logic [511:0]brom_resp_data;

  logic                   hpd_rd_req_valid;
  logic                   hpd_rd_req_ready;
  hpdcache_mem_req_t      hpd_rd_req;
  logic                   hpd_rd_resp_valid;
  logic                   hpd_rd_resp_ready;
  hpdcache_mem_resp_r_t   hpd_rd_resp;

  logic                   hpd_wr_req_valid;
  logic                   hpd_wr_req_ready;
  hpdcache_mem_req_t      hpd_wr_req;
  logic                   hpd_wr_data_valid;
  logic                   hpd_wr_data_ready;
  hpdcache_mem_req_w_t    hpd_wr_data;
  logic                   hpd_wr_resp_valid;
  logic                   hpd_wr_resp_ready;
  hpdcache_mem_resp_w_t   hpd_wr_resp;

  // AXI master output
  logic                        axi_ar_valid;
  logic                        axi_ar_ready;
  logic[AxiAddrWidth-1:0]      axi_ar_addr;
  logic[MstIdWidth-1:0]        axi_ar_id;
  logic [7:0]                  axi_ar_len;
  logic[2:0]                   axi_ar_size;
  logic[1:0]                   axi_ar_burst;
  logic                        axi_ar_lock;
  logic [3:0]                  axi_ar_cache;
  logic[2:0]                   axi_ar_prot;
  logic [3:0]                  axi_ar_qos;
  logic[3:0]                   axi_ar_region;
  logic[AxiUserWidth-1:0]      axi_ar_user;
  
  logic                        axi_r_valid;
  logic                        axi_r_ready;
  logic [AxiDataWidth-1:0]     axi_r_data;
  logic[MstIdWidth-1:0]        axi_r_id;
  logic                        axi_r_last;
  logic [1:0]                  axi_r_resp;
  logic[AxiUserWidth-1:0]      axi_r_user;
  
  logic                        axi_aw_valid;
  logic                        axi_aw_ready;
  logic[AxiAddrWidth-1:0]      axi_aw_addr;
  logic[MstIdWidth-1:0]        axi_aw_id;
  logic [7:0]                  axi_aw_len;
  logic[2:0]                   axi_aw_size;
  logic [1:0]                  axi_aw_burst;
  logic                        axi_aw_lock;
  logic[3:0]                   axi_aw_cache;
  logic [2:0]                  axi_aw_prot;
  logic [3:0]                  axi_aw_qos;
  logic [3:0]                  axi_aw_region;
  logic[AxiUserWidth-1:0]      axi_aw_user;
  logic[5:0]                   axi_aw_atop;
  
  logic                        axi_w_valid;
  logic                        axi_w_ready;
  logic[AxiDataWidth-1:0]      axi_w_data;
  logic [(AxiDataWidth/8)-1:0] axi_w_strb;
  logic                        axi_w_last;
  logic[AxiUserWidth-1:0]      axi_w_user;
  
  logic                        axi_b_valid;
  logic                        axi_b_ready;
  logic [MstIdWidth-1:0]       axi_b_id;
  logic[1:0]                   axi_b_resp;
  logic[AxiUserWidth-1:0]      axi_b_user;
// ================================================================
  // DUT Instantiation (RTL STRUCT MAPPING)
  // ================================================================
  sargantana_soc_wrap #(
    .AxiAddrWidth           ( AxiAddrWidth          ),
    .AxiDataWidth           ( AxiDataWidth          ),
    .AxiUserWidth           ( AxiUserWidth          ),
    .SlvIdWidth             ( SlvIdWidth            ),
    .MstIdWidth             ( MstIdWidth            ),
    .SerMaxTxns             ( SerMaxTxns            ),
    .SerMaxUniqIds          ( SerMaxUniqIds         ),
    .SerMaxTxnsPerId        ( SerMaxTxnsPerId       ),
    .hpdcache_mem_req_t     ( hpdcache_mem_req_t    ),
    .hpdcache_mem_req_w_t   ( hpdcache_mem_req_w_t  ),
    .hpdcache_mem_resp_r_t  ( hpdcache_mem_resp_r_t ),
    .hpdcache_mem_resp_w_t  ( hpdcache_mem_resp_w_t ) 
  ) dut (
    .clk_i                  ( clk                  ),
    .rst_ni                 ( rstn                 ),
    
    .icache_req_valid_i     ( icache_req_valid     ),
    .icache_req_paddr_i     ( icache_req_paddr     ),
    .icache_resp_valid_o    ( icache_resp_valid    ),
    .icache_resp_data_o     ( icache_resp_data     ),
    .icache_resp_ack_o      ( icache_resp_ack      ),
    
    .brom_req_valid_i       ( brom_req_valid       ),
    .brom_req_addr_i        ( brom_req_addr        ),
    .brom_resp_valid_o      ( brom_resp_valid      ),
    .brom_resp_data_o       ( brom_resp_data       ),
    
    // --- Restored Native Struct Mapping! ---
    .hpd_rd_req_valid_i     ( hpd_rd_req_valid     ),
    .hpd_rd_req_ready_o     ( hpd_rd_req_ready     ),
    .hpd_rd_req_i           ( hpd_rd_req           ),
    .hpd_rd_resp_valid_o    ( hpd_rd_resp_valid    ),
    .hpd_rd_resp_ready_i    ( hpd_rd_resp_ready    ),
    .hpd_rd_resp_o          ( hpd_rd_resp          ),

    .hpd_wr_req_valid_i     ( hpd_wr_req_valid     ),
    .hpd_wr_req_ready_o     ( hpd_wr_req_ready     ),
    .hpd_wr_req_i           ( hpd_wr_req           ),
    .hpd_wr_data_valid_i    ( hpd_wr_data_valid    ),
    .hpd_wr_data_ready_o    ( hpd_wr_data_ready    ),
    .hpd_wr_data_i          ( hpd_wr_data          ),
    .hpd_wr_resp_valid_o    ( hpd_wr_resp_valid    ),
    .hpd_wr_resp_ready_i    ( hpd_wr_resp_ready    ),
    .hpd_wr_resp_o          ( hpd_wr_resp          ),
    // ----------------------------------------

    .axi_mst_ar_valid_o     ( axi_ar_valid         ),
    .axi_mst_ar_ready_i     ( axi_ar_ready         ),
    .axi_mst_ar_addr_o      ( axi_ar_addr          ),
    .axi_mst_ar_id_o        ( axi_ar_id            ),
    .axi_mst_ar_len_o       ( axi_ar_len           ),
    .axi_mst_ar_size_o      ( axi_ar_size          ),
    .axi_mst_ar_burst_o     ( axi_ar_burst         ),
    .axi_mst_ar_lock_o      ( axi_ar_lock          ),
    .axi_mst_ar_cache_o     ( axi_ar_cache         ),
    .axi_mst_ar_prot_o      ( axi_ar_prot          ),
    .axi_mst_ar_qos_o       ( axi_ar_qos           ),
    .axi_mst_ar_region_o    ( axi_ar_region        ),
    .axi_mst_ar_user_o      ( axi_ar_user          ),
    
    .axi_mst_r_valid_i      ( axi_r_valid          ),
    .axi_mst_r_ready_o      ( axi_r_ready          ),
    .axi_mst_r_data_i       ( axi_r_data           ),
    .axi_mst_r_id_i         ( axi_r_id             ),
    .axi_mst_r_last_i       ( axi_r_last           ),
    .axi_mst_r_resp_i       ( axi_r_resp           ),
    .axi_mst_r_user_i       ( axi_r_user           ),
    
    .axi_mst_aw_valid_o     ( axi_aw_valid         ),
    .axi_mst_aw_ready_i     ( axi_aw_ready         ),
    .axi_mst_aw_addr_o      ( axi_aw_addr          ),
    .axi_mst_aw_id_o        ( axi_aw_id            ),
    .axi_mst_aw_len_o       ( axi_aw_len           ),
    .axi_mst_aw_size_o      ( axi_aw_size          ),
    .axi_mst_aw_burst_o     ( axi_aw_burst         ),
    .axi_mst_aw_lock_o      ( axi_aw_lock          ),
    .axi_mst_aw_cache_o     ( axi_aw_cache         ),
    .axi_mst_aw_prot_o      ( axi_aw_prot          ),
    .axi_mst_aw_qos_o       ( axi_aw_qos           ),
    .axi_mst_aw_region_o    ( axi_aw_region        ),
    .axi_mst_aw_user_o      ( axi_aw_user          ),
    .axi_mst_aw_atop_o      ( axi_aw_atop          ),
    
    .axi_mst_w_valid_o      ( axi_w_valid          ),
    .axi_mst_w_ready_i      ( axi_w_ready          ),
    .axi_mst_w_data_o       ( axi_w_data           ),
    .axi_mst_w_strb_o       ( axi_w_strb           ),
    .axi_mst_w_last_o       ( axi_w_last           ),
    .axi_mst_w_user_o       ( axi_w_user           ),
    
    .axi_mst_b_valid_i      ( axi_b_valid          ),
    .axi_mst_b_ready_o      ( axi_b_ready          ),
    .axi_mst_b_id_i         ( axi_b_id             ),
    .axi_mst_b_resp_i       ( axi_b_resp           ),
    .axi_mst_b_user_i       ( axi_b_user           )
  );

  // ================================================================
  // CHAOTIC AXI MEMORY MODEL (WITH BACKPRESSURE)
  // ================================================================
  typedef struct { logic [MstIdWidth-1:0] id; logic [7:0] len; logic [7:0] seed; } rd_txn_t;
  rd_txn_t rd_queue[$];
  logic [MstIdWidth-1:0] wr_id_queue[$];

  // Randomized Ready Signals (Backpressure)
  always @(posedge clk) begin
    if (!rstn) begin
      axi_ar_ready <= 0; axi_aw_ready <= 0; axi_w_ready  <= 0;
    end else begin
      axi_ar_ready <= ($urandom() % 100) < 70;
      axi_aw_ready <= ($urandom() % 100) < 70;
      axi_w_ready  <= ($urandom() % 100) < 70;
    end
  end

  // AR Handler
  always @(posedge clk) begin
    if (rstn && axi_ar_valid && axi_ar_ready) begin
      rd_queue.push_back('{id: axi_ar_id, len: axi_ar_len, seed: axi_ar_addr[7:0]});
    end
  end

  // R Channel Driver (Robust Burst & Bubble Handler)
  logic        r_active = 0;
  rd_txn_t     r_txn;
  logic [63:0] r_current_data;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      axi_r_valid <= 0; r_active <= 0;
    end else begin
      if (axi_r_valid && axi_r_ready) begin
        if (axi_r_last) begin
          axi_r_valid <= 0; r_active <= 0; // End of burst
        end else begin
          r_txn.len -= 1;
          r_current_data += 1; // Increment data payload per beat
          axi_r_data <= r_current_data;
          axi_r_last <= (r_txn.len == 0);
          axi_r_valid <= ($urandom() % 100) < 80; // Random bubble
        end
      end else if (!axi_r_valid) begin
        if (r_active) begin // Resume from bubble
          if (($urandom() % 100) < 80) begin
            axi_r_valid <= 1;
            axi_r_data  <= r_current_data;
            axi_r_last  <= (r_txn.len == 0);
          end
        end else if (rd_queue.size() > 0) begin // Start new burst
          if (($urandom() % 100) < 80) begin
            r_txn = rd_queue.pop_front();
            r_active <= 1;
            r_current_data = {8{r_txn.seed}}; // Init data seed
            axi_r_valid <= 1;
            axi_r_id    <= r_txn.id;
            axi_r_data  <= r_current_data;
            axi_r_last  <= (r_txn.len == 0);
            axi_r_resp  <= 2'b00;
          end
        end
      end
    end
  end

  // AW/W Decoupled Handler
  int unsigned aw_rcvd = 0;
  int unsigned w_rcvd  = 0;
  logic [MstIdWidth-1:0] pending_aw_ids[$];

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_aw_valid && axi_aw_ready) begin
        pending_aw_ids.push_back(axi_aw_id);
        aw_rcvd++;
      end
      if (axi_w_valid && axi_w_ready && axi_w_last) begin
        w_rcvd++;
      end
    end
  end

  always @(posedge clk) begin
    if (rstn && aw_rcvd > 0 && w_rcvd > 0) begin
        wr_id_queue.push_back(pending_aw_ids.pop_front());
        aw_rcvd--; w_rcvd--;
    end
  end

  // B Channel Driver (with random stalls)
  always @(posedge clk or negedge rstn) begin
    if (!rstn) axi_b_valid <= 0;
    else begin
      if (axi_b_valid && axi_b_ready) axi_b_valid <= 0;
      else if (!axi_b_valid && wr_id_queue.size() > 0 && ($urandom() % 100) < 80) begin
        axi_b_valid <= 1;
        axi_b_id    <= wr_id_queue.pop_front();
        axi_b_resp  <= 2'b00;
      end
    end
  end

  // ================================================================
  // FULL-DUPLEX DRIVERS & MONITORS
  // ================================================================
  int unsigned icache_pass = 0, icache_fail = 0;
  int unsigned ucache_pass = 0, ucache_fail = 0;
  int unsigned hpd_rd_pass = 0, hpd_rd_fail = 0;
  int unsigned hpd_wr_pass = 0, hpd_wr_fail = 0;

  logic [39:0] icache_addr_sb [$];
  logic [39:0] ucache_addr_sb [$];
  logic [63:0] hpd_rd_addr_sb [$];

  initial begin
    icache_req_valid = 0; brom_req_valid = 0;
    hpd_rd_req_valid = 0; hpd_wr_req_valid = 0; hpd_wr_data_valid = 0;
    hpd_rd_resp_ready = 1; hpd_wr_resp_ready = 1;
    wait (rstn); repeat (10) @(posedge clk);

    // Concurrently launch all traffic
    fork
    // THREAD 1: ICache Driver
    begin
      for(int i=0; i<N_TESTS; i++) begin
        automatic logic[39:0] addr = {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h3F;
        @(posedge clk); icache_req_valid = 1; icache_req_paddr = addr;
        @(posedge clk); icache_req_valid = 0;
        icache_addr_sb.push_back(addr);
        while(!icache_resp_valid) @(posedge clk);
      end
    end
    
    // THREAD 2: ICache Monitor
    begin
      for(int i=0; i<N_TESTS; i++) begin
        while(!icache_resp_valid) @(posedge clk);
        if (^icache_resp_data !== 1'bx) begin
          $display("[ICACHE PASS] addr=0x%0h data[63:0]=0x%0h", icache_addr_sb.pop_front(), icache_resp_data[63:0]);
          icache_pass++;
        end else icache_fail++;
        @(posedge clk);
      end
    end
    
    // THREAD 3: UCache Driver
    begin
      for(int i=0; i<N_TESTS; i++) begin
        automatic logic[39:0] addr = {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h7;
        @(posedge clk); brom_req_valid = 1; brom_req_addr = addr;
        @(posedge clk); brom_req_valid = 0;
        ucache_addr_sb.push_back(addr);
        while(!brom_resp_valid) @(posedge clk);
      end
    end
    
    // THREAD 4: UCache Monitor
    begin
      for(int i=0; i<N_TESTS; i++) begin
        while(!brom_resp_valid) @(posedge clk);
        if (^brom_resp_data[63:0] !== 1'bx) begin
          $display("[UCACHE PASS] addr=0x%0h data[63:0]=0x%0h", ucache_addr_sb.pop_front(), brom_resp_data[63:0]);
          ucache_pass++;
        end else ucache_fail++;
        @(posedge clk);
      end
    end
    
    // THREAD 5: HPD Read Driver (Pipelined)
    begin
      for(int i=0; i<N_TESTS; i++) begin
        automatic logic[63:0] addr = {$urandom(), $urandom()} & ~64'h3F;
        hpd_rd_req.mem_req_addr = addr; hpd_rd_req.mem_req_id = $urandom();
        hpd_rd_req.mem_req_len = 0; hpd_rd_req.mem_req_size = 6; hpd_rd_req.mem_req_command = HPDCACHE_MEM_READ;
        hpd_rd_req_valid = 1;
        do @(posedge clk); while(!hpd_rd_req_ready);
        hpd_rd_req_valid = 0;
        hpd_rd_addr_sb.push_back(addr);
        if(($urandom()%100)<50) repeat($urandom()%5) @(posedge clk);
      end
    end
    
    // THREAD 6: HPD Read Monitor
    begin
      for(int i=0; i<N_TESTS; i++) begin
        while(!(hpd_rd_resp_valid && hpd_rd_resp_ready)) @(posedge clk);
        if (hpd_rd_resp.mem_resp_r_error == HPDCACHE_MEM_RESP_OK) begin
          $display("[HPD_RD PASS] addr=0x%0h data[63:0]=0x%0h", hpd_rd_addr_sb.pop_front(), hpd_rd_resp.mem_resp_r_data[63:0]);
          hpd_rd_pass++;
        end else hpd_rd_fail++;
        @(posedge clk);
      end
    end

    // THREAD 7: HPD Write Driver (Overlapping req and data)
    begin
      for(int i=0; i<N_TESTS; i++) begin
        hpd_wr_req.mem_req_addr = {$urandom(), $urandom()} & ~64'h3F;
        hpd_wr_req.mem_req_id = $urandom(); hpd_wr_req.mem_req_size = 6; hpd_wr_req.mem_req_command = HPDCACHE_MEM_WRITE;
        hpd_wr_data.mem_req_w_data = {$urandom(), $urandom(), $urandom(), $urandom()}; hpd_wr_data.mem_req_w_be = ~0;
        
        hpd_wr_req_valid = 1; hpd_wr_data_valid = 1;
        fork
          begin do @(posedge clk); while(!hpd_wr_req_ready); hpd_wr_req_valid = 0; end
          begin do @(posedge clk); while(!hpd_wr_data_ready); hpd_wr_data_valid = 0; end
        join
        if(($urandom()%100)<50) repeat($urandom()%5) @(posedge clk);
      end
    end

    // THREAD 8: HPD Write Monitor
    begin
      for(int i=0; i<N_TESTS; i++) begin
        while(!(hpd_wr_resp_valid && hpd_wr_resp_ready)) @(posedge clk);
        if (hpd_wr_resp.mem_resp_w_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_WR PASS] id=0x%0h completed successfully", hpd_wr_resp.mem_resp_w_id);
            hpd_wr_pass++;
        end else hpd_wr_fail++;
        @(posedge clk);
      end
    end
    join

    // Final Report
    $display("____________________________________________");
    $display("  STRESS TEST (FULL-DUPLEX) RESULTS");
    $display("____________________________________________");
    $display("  ICache  reads : %0d PASS  %0d FAIL", icache_pass, icache_fail);
    $display("  uCache  reads : %0d PASS  %0d FAIL", ucache_pass, ucache_fail);
    $display("  HPD     reads : %0d PASS  %0d FAIL", hpd_rd_pass, hpd_rd_fail);
    $display("  HPD     writes: %0d PASS  %0d FAIL", hpd_wr_pass, hpd_wr_fail);
    $display("____________________________________________");
    $display("  TOTAL         : %0d PASS  %0d FAIL  (of %0d)", 
      icache_pass+ucache_pass+hpd_rd_pass+hpd_wr_pass, 
      icache_fail+ucache_fail+hpd_rd_fail+hpd_wr_fail, 
      N_TESTS * 4);
    $display("____________________________________________");
    $finish;
  end

  // Reset task
  initial begin
    rstn = 0; repeat (4) @(posedge clk); rstn = 1;
  end

endmodule
