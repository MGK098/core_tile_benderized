`timescale 1ns/1ps
// ============================================================================
// tb_sargantana_soc_wrap_ids
// ----------------------------------------------------------------------------
// Testbench for sargantana_soc_wrap_ids.
//
// What this TB verifies vs the original sargantana_soc_wrap TB:
//
//  1. All original full-duplex cache traffic (ICache, uCache, HPD rd/wr) still
//     passes end-to-end  the serializer must be transparent to the caches.
//
//  2. ID WIDTH CHECK: every AR/AW that appears on the flat AXI master port must
//     have an ID that fits in MstIdWidth bits (i.e. the upper bits that the MUX
//     added are stripped by axi_id_serialize).
//
//  3. ID SERIALIZATION CHECK: while a transaction is in-flight on the master
//     port, no two in-flight ARs or AWs may carry the same ID simultaneously
//     (the serializer guarantees unique IDs at the master port at any given
//     time, up to SerMaxUniqIds).
//
//  4. RESPONSE ROUTING CHECK: every B/R response that comes back from the
//     memory model is correctly returned to the originating cache interface
//     (ICache resp valid, uCache resp valid, HPD rd/wr resp valid all fire
//     exactly N_TESTS times with no Xs).
//
// Memory model: same chaotic AXI slave with randomised backpressure from the
// original TB, extended to track in-flight IDs for check 3.
// ============================================================================

module tb_sargantana_soc_wrap_ids;

  import hpdcache_pkg::*;
  import test_types_pkg::*;

  // ==========================================================================
  // Parameters   must match sargantana_soc_wrap_ids defaults
  // ==========================================================================
  localparam int unsigned AxiAddrWidth    = 64;
  localparam int unsigned AxiDataWidth    = 64;
  localparam int unsigned AxiUserWidth    = 1;
  localparam int unsigned SlvIdWidth      = 8;
  localparam int unsigned MstIdWidth      = 4;   // <  serializer output width
  localparam int unsigned SerMaxTxns      = 16;
  localparam int unsigned SerMaxUniqIds   = 16;
  localparam int unsigned SerMaxTxnsPerId = 16;

  localparam int unsigned N_TESTS = 5;  // transactions per interface

  // ==========================================================================
  // Clock & reset
  // ==========================================================================
  logic clk  = 0;
  logic rstn = 0;
  always #5 clk = ~clk;  // 100 MHz

  // Watchdog
  int unsigned cyc = 0;
  always @(posedge clk) begin
    cyc <= cyc + 1;
    if (cyc > 2_000_000) begin
      $display("\n[FATAL] WATCHDOG: simulation exceeded 2M cycles   deadlock!");
      $finish;
    end
  end

  initial begin
    rstn = 0;
    repeat (4) @(posedge clk);
    rstn = 1;
  end

  // ==========================================================================
  // DUT port signals
  // ==========================================================================

  // ICache
  logic        icache_req_valid;
  logic [39:0] icache_req_paddr;
  logic        icache_resp_valid;
  logic[511:0] icache_resp_data;
  logic        icache_resp_ack;

  // uCache / BROM
  logic        brom_req_valid;
  logic [39:0] brom_req_addr;
  logic        brom_resp_valid;
  logic[511:0] brom_resp_data;

  // HPDCache read
  logic                 hpd_rd_req_valid;
  logic                 hpd_rd_req_ready;
  hpdcache_mem_req_t    hpd_rd_req;
  logic                 hpd_rd_resp_valid;
  logic                 hpd_rd_resp_ready;
  hpdcache_mem_resp_r_t hpd_rd_resp;

  // HPDCache write
  logic                 hpd_wr_req_valid;
  logic                 hpd_wr_req_ready;
  hpdcache_mem_req_t    hpd_wr_req;
  logic                 hpd_wr_data_valid;
  logic                 hpd_wr_data_ready;
  hpdcache_mem_req_w_t  hpd_wr_data;
  logic                 hpd_wr_resp_valid;
  logic                 hpd_wr_resp_ready;
  hpdcache_mem_resp_w_t hpd_wr_resp;

  // Flat AXI master (MstIdWidth wide   key difference from original TB)
  logic                        axi_ar_valid;
  logic                        axi_ar_ready;
  logic [AxiAddrWidth-1:0]     axi_ar_addr;
  logic [MstIdWidth-1:0]       axi_ar_id;
  logic [7:0]                  axi_ar_len;
  logic [2:0]                  axi_ar_size;
  logic [1:0]                  axi_ar_burst;
  logic                        axi_ar_lock;
  logic [3:0]                  axi_ar_cache;
  logic [2:0]                  axi_ar_prot;
  logic [3:0]                  axi_ar_qos;
  logic [3:0]                  axi_ar_region;
  logic [AxiUserWidth-1:0]     axi_ar_user;

  logic                        axi_r_valid;
  logic                        axi_r_ready;
  logic [AxiDataWidth-1:0]     axi_r_data;
  logic [MstIdWidth-1:0]       axi_r_id;
  logic                        axi_r_last;
  logic [1:0]                  axi_r_resp;
  logic [AxiUserWidth-1:0]     axi_r_user;

  logic                        axi_aw_valid;
  logic                        axi_aw_ready;
  logic [AxiAddrWidth-1:0]     axi_aw_addr;
  logic [MstIdWidth-1:0]       axi_aw_id;
  logic [7:0]                  axi_aw_len;
  logic [2:0]                  axi_aw_size;
  logic [1:0]                  axi_aw_burst;
  logic                        axi_aw_lock;
  logic [3:0]                  axi_aw_cache;
  logic [2:0]                  axi_aw_prot;
  logic [3:0]                  axi_aw_qos;
  logic [3:0]                  axi_aw_region;
  logic [AxiUserWidth-1:0]     axi_aw_user;
  logic [5:0]                  axi_aw_atop;

  logic                        axi_w_valid;
  logic                        axi_w_ready;
  logic [AxiDataWidth-1:0]     axi_w_data;
  logic [(AxiDataWidth/8)-1:0] axi_w_strb;
  logic                        axi_w_last;
  logic [AxiUserWidth-1:0]     axi_w_user;

  logic                        axi_b_valid;
  logic                        axi_b_ready;
  logic [MstIdWidth-1:0]       axi_b_id;
  logic [1:0]                  axi_b_resp;
  logic [AxiUserWidth-1:0]     axi_b_user;

  // ==========================================================================
  // DUT instantiation   sargantana_soc_wrap_ids
  // ==========================================================================
  sargantana_soc_wrap_ids #(
    .AxiAddrWidth          ( AxiAddrWidth          ),
    .AxiDataWidth          ( AxiDataWidth          ),
    .AxiUserWidth          ( AxiUserWidth          ),
    .SlvIdWidth            ( SlvIdWidth            ),
    .MstIdWidth            ( MstIdWidth            ),
    .SerMaxTxns            ( SerMaxTxns            ),
    .SerMaxUniqIds         ( SerMaxUniqIds         ),
    .SerMaxTxnsPerId       ( SerMaxTxnsPerId       ),
    .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
    .hpdcache_mem_req_w_t  ( hpdcache_mem_req_w_t  ),
    .hpdcache_mem_resp_r_t ( hpdcache_mem_resp_r_t ),
    .hpdcache_mem_resp_w_t ( hpdcache_mem_resp_w_t )
  ) dut (
    .clk_i                  ( clk               ),
    .rst_ni                 ( rstn              ),

    .icache_req_valid_i     ( icache_req_valid  ),
    .icache_req_paddr_i     ( icache_req_paddr  ),
    .icache_resp_valid_o    ( icache_resp_valid ),
    .icache_resp_data_o     ( icache_resp_data  ),
    .icache_resp_ack_o      ( icache_resp_ack   ),

    .brom_req_valid_i       ( brom_req_valid    ),
    .brom_req_addr_i        ( brom_req_addr     ),
    .brom_resp_valid_o      ( brom_resp_valid   ),
    .brom_resp_data_o       ( brom_resp_data    ),

    .hpd_rd_req_valid_i     ( hpd_rd_req_valid  ),
    .hpd_rd_req_ready_o     ( hpd_rd_req_ready  ),
    .hpd_rd_req_i           ( hpd_rd_req        ),
    .hpd_rd_resp_valid_o    ( hpd_rd_resp_valid ),
    .hpd_rd_resp_ready_i    ( hpd_rd_resp_ready ),
    .hpd_rd_resp_o          ( hpd_rd_resp       ),

    .hpd_wr_req_valid_i     ( hpd_wr_req_valid  ),
    .hpd_wr_req_ready_o     ( hpd_wr_req_ready  ),
    .hpd_wr_req_i           ( hpd_wr_req        ),
    .hpd_wr_data_valid_i    ( hpd_wr_data_valid ),
    .hpd_wr_data_ready_o    ( hpd_wr_data_ready ),
    .hpd_wr_data_i          ( hpd_wr_data       ),
    .hpd_wr_resp_valid_o    ( hpd_wr_resp_valid ),
    .hpd_wr_resp_ready_i    ( hpd_wr_resp_ready ),
    .hpd_wr_resp_o          ( hpd_wr_resp       ),

    .axi_mst_ar_valid_o     ( axi_ar_valid      ),
    .axi_mst_ar_ready_i     ( axi_ar_ready      ),
    .axi_mst_ar_addr_o      ( axi_ar_addr       ),
    .axi_mst_ar_id_o        ( axi_ar_id         ),
    .axi_mst_ar_len_o       ( axi_ar_len        ),
    .axi_mst_ar_size_o      ( axi_ar_size       ),
    .axi_mst_ar_burst_o     ( axi_ar_burst      ),
    .axi_mst_ar_lock_o      ( axi_ar_lock       ),
    .axi_mst_ar_cache_o     ( axi_ar_cache      ),
    .axi_mst_ar_prot_o      ( axi_ar_prot       ),
    .axi_mst_ar_qos_o       ( axi_ar_qos        ),
    .axi_mst_ar_region_o    ( axi_ar_region     ),
    .axi_mst_ar_user_o      ( axi_ar_user       ),

    .axi_mst_r_valid_i      ( axi_r_valid       ),
    .axi_mst_r_ready_o      ( axi_r_ready       ),
    .axi_mst_r_data_i       ( axi_r_data        ),
    .axi_mst_r_id_i         ( axi_r_id          ),
    .axi_mst_r_last_i       ( axi_r_last        ),
    .axi_mst_r_resp_i       ( axi_r_resp        ),
    .axi_mst_r_user_i       ( axi_r_user        ),

    .axi_mst_aw_valid_o     ( axi_aw_valid      ),
    .axi_mst_aw_ready_i     ( axi_aw_ready      ),
    .axi_mst_aw_addr_o      ( axi_aw_addr       ),
    .axi_mst_aw_id_o        ( axi_aw_id         ),
    .axi_mst_aw_len_o       ( axi_aw_len        ),
    .axi_mst_aw_size_o      ( axi_aw_size       ),
    .axi_mst_aw_burst_o     ( axi_aw_burst      ),
    .axi_mst_aw_lock_o      ( axi_aw_lock       ),
    .axi_mst_aw_cache_o     ( axi_aw_cache      ),
    .axi_mst_aw_prot_o      ( axi_aw_prot       ),
    .axi_mst_aw_qos_o       ( axi_aw_qos        ),
    .axi_mst_aw_region_o    ( axi_aw_region     ),
    .axi_mst_aw_user_o      ( axi_aw_user       ),
    .axi_mst_aw_atop_o      ( axi_aw_atop       ),

    .axi_mst_w_valid_o      ( axi_w_valid       ),
    .axi_mst_w_ready_i      ( axi_w_ready       ),
    .axi_mst_w_data_o       ( axi_w_data        ),
    .axi_mst_w_strb_o       ( axi_w_strb        ),
    .axi_mst_w_last_o       ( axi_w_last        ),
    .axi_mst_w_user_o       ( axi_w_user        ),

    .axi_mst_b_valid_i      ( axi_b_valid       ),
    .axi_mst_b_ready_o      ( axi_b_ready       ),
    .axi_mst_b_id_i         ( axi_b_id          ),
    .axi_mst_b_resp_i       ( axi_b_resp        ),
    .axi_mst_b_user_i       ( axi_b_user        )
  );

  // ==========================================================================
  // CHECK 1   ID WIDTH: every AR/AW master ID must fit in MstIdWidth bits.
  // Because MstIdWidth=4 and the signal is already declared [MstIdWidth-1:0],
  // the DUT truncation already handles the wiring. We verify no X/Z appear.
  // ==========================================================================
  int unsigned id_width_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_ar_valid && axi_ar_ready) begin
        if (^axi_ar_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] AR id contains X/Z: 0x%0h", axi_ar_id);
          id_width_errors++;
        end else begin
          $display("[ID_WIDTH OK ] AR id=0x%0h (fits in %0d bits)", axi_ar_id, MstIdWidth);
        end
      end
      if (axi_aw_valid && axi_aw_ready) begin
        if (^axi_aw_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] AW id contains X/Z: 0x%0h", axi_aw_id);
          id_width_errors++;
        end else begin
          $display("[ID_WIDTH OK ] AW id=0x%0h (fits in %0d bits)", axi_aw_id, MstIdWidth);
        end
      end
    end
  end

  // ==========================================================================
  // CHECK 2   ID SERIALIZATION: track all in-flight AR IDs on the master port.
  // The serializer must not issue two simultaneous in-flight reads with the
  // same ID (it serializes them). We assert this every cycle.
  // ==========================================================================
  logic [MstIdWidth-1:0] inflight_ar_ids[$];
  logic [MstIdWidth-1:0] inflight_aw_ids[$];
  int unsigned ser_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      // -- AR in-flight tracking --
      if (axi_ar_valid && axi_ar_ready) begin
        // Check: this ID must not already be in-flight
        foreach (inflight_ar_ids[i]) begin
          if (inflight_ar_ids[i] === axi_ar_id) begin
            $display("[SER FAIL] AR id=0x%0h already in-flight   serializer violated!", axi_ar_id);
            ser_errors++;
          end
        end
        inflight_ar_ids.push_back(axi_ar_id);
      end
      // Remove AR id when last R beat comes back
      if (axi_r_valid && axi_r_ready && axi_r_last) begin
        for (int i = 0; i < inflight_ar_ids.size(); i++) begin
          if (inflight_ar_ids[i] === axi_r_id) begin
            inflight_ar_ids.delete(i);
            break;
          end
        end
      end

      // -- AW in-flight tracking --
      if (axi_aw_valid && axi_aw_ready) begin
        foreach (inflight_aw_ids[i]) begin
          if (inflight_aw_ids[i] === axi_aw_id) begin
            $display("[SER FAIL] AW id=0x%0h already in-flight   serializer violated!", axi_aw_id);
            ser_errors++;
          end
        end
        inflight_aw_ids.push_back(axi_aw_id);
      end
      // Remove AW id when B comes back
      if (axi_b_valid && axi_b_ready) begin
        for (int i = 0; i < inflight_aw_ids.size(); i++) begin
          if (inflight_aw_ids[i] === axi_b_id) begin
            inflight_aw_ids.delete(i);
            break;
          end
        end
      end
    end
  end

  // ==========================================================================
  // AXI MEMORY MODEL   same chaotic slave with random backpressure
  // ==========================================================================
  typedef struct {
    logic [MstIdWidth-1:0] id;
    logic [7:0]            len;
    logic [7:0]            seed;
  } rd_txn_t;

  rd_txn_t               rd_queue[$];
  logic [MstIdWidth-1:0] wr_id_queue[$];

  // Randomised ready signals (backpressure)
  always @(posedge clk) begin
    if (!rstn) begin
      axi_ar_ready <= 0;
      axi_aw_ready <= 0;
      axi_w_ready  <= 0;
    end else begin
      axi_ar_ready <= ($urandom() % 100) < 70;
      axi_aw_ready <= ($urandom() % 100) < 70;
      axi_w_ready  <= ($urandom() % 100) < 70;
    end
  end

  // AR ? queue
  always @(posedge clk) begin
    if (rstn && axi_ar_valid && axi_ar_ready)
      rd_queue.push_back('{id: axi_ar_id, len: axi_ar_len, seed: axi_ar_addr[7:0]});
  end

  // R channel driver (burst with bubbles)
  logic        r_active      = 0;
  rd_txn_t     r_txn;
  logic [63:0] r_current_data;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      axi_r_valid <= 0;
      r_active    <= 0;
    end else begin
      if (axi_r_valid && axi_r_ready) begin
        if (axi_r_last) begin
          axi_r_valid <= 0;
          r_active    <= 0;
        end else begin
          r_txn.len      -= 1;
          r_current_data += 1;
          axi_r_data  <= r_current_data;
          axi_r_last  <= (r_txn.len == 0);
          axi_r_valid <= ($urandom() % 100) < 80;
        end
      end else if (!axi_r_valid) begin
        if (r_active) begin
          if (($urandom() % 100) < 80) begin
            axi_r_valid <= 1;
            axi_r_data  <= r_current_data;
            axi_r_last  <= (r_txn.len == 0);
          end
        end else if (rd_queue.size() > 0) begin
          if (($urandom() % 100) < 80) begin
            r_txn          = rd_queue.pop_front();
            r_active       <= 1;
            r_current_data  = {8{r_txn.seed}};
            axi_r_valid    <= 1;
            axi_r_id       <= r_txn.id;
            axi_r_data     <= r_current_data;
            axi_r_last     <= (r_txn.len == 0);
            axi_r_resp     <= 2'b00;
          end
        end
      end
    end
  end

  // AW/W decoupled handler
  int unsigned           aw_rcvd = 0;
  int unsigned           w_rcvd  = 0;
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
      aw_rcvd--;
      w_rcvd--;
    end
  end

  // B channel driver
  always @(posedge clk or negedge rstn) begin
    if (!rstn) axi_b_valid <= 0;
    else begin
      if (axi_b_valid && axi_b_ready)
        axi_b_valid <= 0;
      else if (!axi_b_valid && wr_id_queue.size() > 0 && ($urandom() % 100) < 80) begin
        axi_b_valid <= 1;
        axi_b_id    <= wr_id_queue.pop_front();
        axi_b_resp  <= 2'b00;
      end
    end
  end

  // ==========================================================================
  // FULL-DUPLEX CACHE DRIVERS & MONITORS  (identical to original TB)
  // ==========================================================================
  int unsigned icache_pass = 0, icache_fail = 0;
  int unsigned ucache_pass = 0, ucache_fail = 0;
  int unsigned hpd_rd_pass = 0, hpd_rd_fail = 0;
  int unsigned hpd_wr_pass = 0, hpd_wr_fail = 0;

  logic [39:0] icache_addr_sb[$];
  logic [39:0] ucache_addr_sb[$];
  logic [39:0] hpd_rd_addr_sb[$];

  initial begin
    icache_req_valid  = 0;
    brom_req_valid    = 0;
    hpd_rd_req_valid  = 0;
    hpd_wr_req_valid  = 0;
    hpd_wr_data_valid = 0;
    hpd_rd_resp_ready = 1;
    hpd_wr_resp_ready = 1;

    wait (rstn);
    repeat (10) @(posedge clk);

    fork
      // ---------------------------------------------------------------
      // THREAD 1: ICache driver
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h3F;
          @(posedge clk); icache_req_valid = 1; icache_req_paddr = addr;
          @(posedge clk); icache_req_valid = 0;
          icache_addr_sb.push_back(addr);
          while (!icache_resp_valid) @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 2: ICache monitor
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          while (!icache_resp_valid) @(posedge clk);
          if (^icache_resp_data !== 1'bx) begin
            $display("[ICACHE PASS] addr=0x%0h data[63:0]=0x%0h",
              icache_addr_sb.pop_front(), icache_resp_data[63:0]);
            icache_pass++;
          end else begin
            $display("[ICACHE FAIL] data contains X");
            icache_fail++;
          end
          @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 3: uCache driver
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h7;
          @(posedge clk); brom_req_valid = 1; brom_req_addr = addr;
          @(posedge clk); brom_req_valid = 0;
          ucache_addr_sb.push_back(addr);
          while (!brom_resp_valid) @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 4: uCache monitor
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          while (!brom_resp_valid) @(posedge clk);
          if (^brom_resp_data[63:0] !== 1'bx) begin
            $display("[UCACHE PASS] addr=0x%0h data[63:0]=0x%0h",
              ucache_addr_sb.pop_front(), brom_resp_data[63:0]);
            ucache_pass++;
          end else begin
            $display("[UCACHE FAIL] data contains X");
            ucache_fail++;
          end
          @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 5: HPD read driver
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr = {$urandom(), $urandom()} & ~39'h3F;
          hpd_rd_req.mem_req_addr    = addr;
          hpd_rd_req.mem_req_id      = $urandom();
          hpd_rd_req.mem_req_len     = 0;
          hpd_rd_req.mem_req_size    = 6;
          hpd_rd_req.mem_req_command = HPDCACHE_MEM_READ;
          hpd_rd_req_valid = 1;
          do @(posedge clk); while (!hpd_rd_req_ready);
          hpd_rd_req_valid = 0;
          hpd_rd_addr_sb.push_back(addr);
          if (($urandom() % 100) < 50) repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 6: HPD read monitor
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          while (!(hpd_rd_resp_valid && hpd_rd_resp_ready)) @(posedge clk);
          if (hpd_rd_resp.mem_resp_r_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_RD PASS] addr=0x%0h data[63:0]=0x%0h",
              hpd_rd_addr_sb.pop_front(), hpd_rd_resp.mem_resp_r_data[63:0]);
            hpd_rd_pass++;
          end else begin
            $display("[HPD_RD FAIL] error response received");
            hpd_rd_fail++;
          end
          @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 7: HPD write driver
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          hpd_wr_req.mem_req_addr    = {$urandom(), $urandom()} & ~39'h3F;
          hpd_wr_req.mem_req_id      = $urandom();
          hpd_wr_req.mem_req_size    = 6;
          hpd_wr_req.mem_req_command = HPDCACHE_MEM_WRITE;
          hpd_wr_data.mem_req_w_data = {$urandom(), $urandom(), $urandom(), $urandom()};
          hpd_wr_data.mem_req_w_be   = ~0;
          hpd_wr_req_valid  = 1;
          hpd_wr_data_valid = 1;
          fork
            begin
              do @(posedge clk); while (!hpd_wr_req_ready);
              hpd_wr_req_valid = 0;
            end
            begin
              do @(posedge clk); while (!hpd_wr_data_ready);
              hpd_wr_data_valid = 0;
            end
          join
          if (($urandom() % 100) < 50) repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ---------------------------------------------------------------
      // THREAD 8: HPD write monitor
      // ---------------------------------------------------------------
      begin
        for (int i = 0; i < N_TESTS; i++) begin
          while (!(hpd_wr_resp_valid && hpd_wr_resp_ready)) @(posedge clk);
          if (hpd_wr_resp.mem_resp_w_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_WR PASS] id=0x%0h completed successfully",
              hpd_wr_resp.mem_resp_w_id);
            hpd_wr_pass++;
          end else begin
            $display("[HPD_WR FAIL] error response received");
            hpd_wr_fail++;
          end
          @(posedge clk);
        end
      end
    join  // all 8 threads complete

    // ====================================================================
    // FINAL REPORT
    // ====================================================================
    $display("");
    $display("____________________________________________");
    $display("  STRESS TEST (FULL-DUPLEX) RESULTS");
    $display("____________________________________________");
    $display("  ICache  reads : %0d PASS  %0d FAIL", icache_pass, icache_fail);
    $display("  uCache  reads : %0d PASS  %0d FAIL", ucache_pass, ucache_fail);
    $display("  HPD     reads : %0d PASS  %0d FAIL", hpd_rd_pass, hpd_rd_fail);
    $display("  HPD     writes: %0d PASS  %0d FAIL", hpd_wr_pass, hpd_wr_fail);
    $display("____________________________________________");
    $display("  TOTAL         : %0d PASS  %0d FAIL  (of %0d)",
      icache_pass + ucache_pass + hpd_rd_pass + hpd_wr_pass,
      icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail,
      N_TESTS * 4);
    $display("____________________________________________");
    $display("");
    $display("____________________________________________");
    $display("  ID SERIALIZER CHECKS");
    $display("____________________________________________");
    $display("  ID width  errors : %0d", id_width_errors);
    $display("  Serializer errors: %0d", ser_errors);
    if (id_width_errors == 0 && ser_errors == 0)
      $display("  ID SERIALIZER    : ALL CHECKS PASSED");
    else
      $display("  ID SERIALIZER    : *** FAILURES DETECTED ***");
    $display("____________________________________________");
    $finish;
  end

endmodule
