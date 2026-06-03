`timescale 1ns/1ps
`include "hpdcache_typedef.svh"
// ============================================================================
// tb_sargantana_soc_axi_wrap
// ----------------------------------------------------------------------------
// Top-level testbench for sargantana_soc_axi_wrap.
//
// KEY FIX vs previous version
// ----------------------------
// The previous TB hardcoded [39:0] for ICache and HPDCache address widths.
// sim_top.sv shows the correct approach:
//
//   sim_top                              this TB
//   -----------------------------------------------------------------
//   logic [drac_pkg::PHY_ADDR_SIZE-1:0]  same  ? ICache addr width
//   hpdcache_mem_addr_t from DRAC_CFG    same  ? HPD addr width
//   hpdcache_mem_id_t   from DRAC_CFG    same  ? HPD id width
//   hpdcache_mem_data_t from DRAC_CFG    same  ? HPD data width
//   [39:0] brom_req_address              same  ? uCache addr (always 40b)
//
// This ensures forced signals match top_tile's internal port widths exactly,
// eliminating silent truncation of upper address bits.
//
// FORCE TARGETS  (output ports of dut.u_core_tile)
// -------------------------------------------------
//   .io_mem_acquire_valid            ? icache req valid
//   .io_mem_acquire_bits_addr_block  ? icache req addr [PHY_ADDR_SIZE-1:0]
//   .brom_req_valid_o                ? ucache req valid
//   .brom_req_address_o              ? ucache req addr [39:0]
//   .mem_req_read_valid_o            ? HPD read req valid
//   .mem_req_read_o                  ? HPD read req struct
//   .mem_resp_read_ready_o           ? HPD read resp ready
//   .mem_req_write_valid_o           ? HPD write req valid
//   .mem_req_write_o                 ? HPD write req struct
//   .mem_req_write_data_valid_o      ? HPD write data valid
//   .mem_req_write_data_o            ? HPD write data struct
//   .mem_resp_write_ready_o          ? HPD write resp ready
//
// OBSERVE TARGETS  (input ports of dut.u_core_tile + bridge output wires)
// ------------------------------------------------------------------------
//   dut.icache_resp_valid/data       ? ICache response
//   dut.brom_resp_valid/data         ? uCache response
//   .mem_req_read_ready_i            ? HPD read req ready
//   .mem_resp_read_valid_i           ? HPD read resp valid
//   .mem_resp_read_i                 ? HPD read resp struct
//   .mem_req_write_ready_i           ? HPD write req ready
//   .mem_req_write_data_ready_i      ? HPD write data ready
//   .mem_resp_write_valid_i          ? HPD write resp valid
//   .mem_resp_write_i                ? HPD write resp struct
// ============================================================================

module tb_sargantana_soc_axi_wrap;

  import drac_pkg::*;
  import hpdcache_pkg::*;

  // ==========================================================================
  // DRAC configuration  mirror sim_top exactly
  // ==========================================================================
  localparam drac_pkg::drac_cfg_t DRAC_CFG = drac_pkg::DracDefaultConfig;

  // HPDCache types derived from DRAC_CFG  identical to sim_top
  parameter type hpdcache_mem_addr_t   = logic [DRAC_CFG.MemAddrWidth-1:0];
  parameter type hpdcache_mem_id_t     = logic [DRAC_CFG.MemIDWidth-1:0];
  parameter type hpdcache_mem_data_t   = logic [DRAC_CFG.MemDataWidth-1:0];
  parameter type hpdcache_mem_be_t     = logic [DRAC_CFG.MemDataWidth/8-1:0];
  parameter type hpdcache_mem_req_t    =
      `HPDCACHE_DECL_MEM_REQ_T(hpdcache_mem_addr_t, hpdcache_mem_id_t);
  parameter type hpdcache_mem_resp_r_t =
      `HPDCACHE_DECL_MEM_RESP_R_T(hpdcache_mem_id_t, hpdcache_mem_data_t);
  parameter type hpdcache_mem_req_w_t  =
      `HPDCACHE_DECL_MEM_REQ_W_T(hpdcache_mem_data_t, hpdcache_mem_be_t);
  parameter type hpdcache_mem_resp_w_t =
      `HPDCACHE_DECL_MEM_RESP_W_T(hpdcache_mem_id_t);

  // ==========================================================================
  // AXI parameters
  // ==========================================================================
  localparam int unsigned AxiAddrWidth    = 64;
  localparam int unsigned AxiDataWidth    = 64;
  localparam int unsigned AxiUserWidth    = 1;
  localparam int unsigned SlvIdWidth      = 8;
  localparam int unsigned MstIdWidth      = 4;
  localparam int unsigned SerMaxTxns      = 16;
  localparam int unsigned SerMaxUniqIds   = 16;
  localparam int unsigned SerMaxTxnsPerId = 16;

  localparam int unsigned N_TESTS = 5;

  // ==========================================================================
  // Clock & reset
  // ==========================================================================
  logic clk  = 0;
  logic rstn = 0;
  always #5 clk = ~clk;

  int unsigned cyc_cnt = 0;
  always @(posedge clk) begin
    cyc_cnt <= cyc_cnt + 1;
    if (cyc_cnt > 2_000_000) begin
      $display("\n[FATAL] WATCHDOG: exceeded 2M cycles  deadlock!");
      $finish;
    end
  end

  initial begin
    rstn = 0;
    repeat (8) @(posedge clk);
    @(negedge clk);
    rstn = 1;
  end

  // ==========================================================================
  // Width diagnostics  print once after reset to catch any remaining mismatches
  // ==========================================================================
  initial begin
    wait (rstn);
    @(posedge clk);
    $display("[WIDTHS] drac_pkg::PHY_ADDR_SIZE                    = %0d bits",
             drac_pkg::PHY_ADDR_SIZE);
    $display("[WIDTHS] DRAC_CFG.MemAddrWidth                      = %0d bits",
             DRAC_CFG.MemAddrWidth);
    $display("[WIDTHS] DRAC_CFG.MemIDWidth                        = %0d bits",
             DRAC_CFG.MemIDWidth);
    $display("[WIDTHS] DRAC_CFG.MemDataWidth                      = %0d bits",
             DRAC_CFG.MemDataWidth);
    $display("[WIDTHS] io_mem_acquire_bits_addr_block port width  = %0d bits",
             $bits(dut.u_core_tile.io_mem_acquire_bits_addr_block));
    $display("[WIDTHS] brom_req_address_o port width              = %0d bits",
             $bits(dut.u_core_tile.brom_req_address_o));
    $display("[WIDTHS] mem_req_read_o.mem_req_addr width          = %0d bits",
             $bits(dut.u_core_tile.mem_req_read_o.mem_req_addr));
    $display("[WIDTHS] dut.icache_req_paddr wire width            = %0d bits",
             $bits(dut.icache_req_paddr));
    $display("[WIDTHS] dut.brom_req_addr wire width               = %0d bits",
             $bits(dut.brom_req_addr));
  end

  // ==========================================================================
  // TB stimulus signals  widths now derived from drac_pkg / DRAC_CFG
  // ==========================================================================

  // ICache  [PHY_ADDR_SIZE-1:0] to match top_tile port exactly
  logic                               tb_icache_req_valid = 0;
  logic [drac_pkg::PHY_ADDR_SIZE-1:0] tb_icache_req_paddr = '0;

  // uCache  [39:0] matching sim_top brom_req_address declaration
  logic        tb_brom_req_valid = 0;
  logic [39:0] tb_brom_req_addr  = '0;

  // HPDCache read  struct types from DRAC_CFG
  logic                  tb_hpd_rd_req_valid  = 0;
  hpdcache_mem_req_t     tb_hpd_rd_req        = '0;
  logic                  tb_hpd_rd_resp_ready = 1;

  // HPDCache write  struct types from DRAC_CFG
  logic                  tb_hpd_wr_req_valid  = 0;
  hpdcache_mem_req_t     tb_hpd_wr_req        = '0;
  logic                  tb_hpd_wr_data_valid = 0;
  hpdcache_mem_req_w_t   tb_hpd_wr_data       = '0;
  logic                  tb_hpd_wr_resp_ready = 1;

  // ==========================================================================
  // Flat AXI4 master port
  // ==========================================================================
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
  // Other DUT ports  tied off
  // reset_addr mirrors sim_top: boot from 0x0100
  // ==========================================================================
  logic        soft_rstn  = 1;
  logic [63:0] reset_addr = 64'h0000_0000_0000_0100;
  logic [63:0] core_id    = 64'h0;
  logic [63:0] time_val   = 64'h0;
  logic        time_irq   = 0;
  logic [1:0]  irq        = 2'b00;
  logic        soft_irq   = 0;
  logic        pmu_l2_hit = 0;

  logic       dbg_halt_req    = 0, dbg_resume_req  = 0;
  logic       dbg_progbuf_req = 0, dbg_halt_on_rst = 0;
  logic       dbg_rnm_rd_en   = 0, dbg_rf_en       = 0;
  logic       dbg_rf_we       = 0;
  reg_t       dbg_rnm_rd_reg  = '0;
  phreg_t     dbg_rf_preg     = '0;
  bus64_t     dbg_rf_wdata    = '0;

  logic          dbg_halt_ack, dbg_halted, dbg_resume_ack, dbg_running;
  logic          dbg_progbuf_ack, dbg_parked, dbg_unavail;
  logic          dbg_progbuf_xcpt, dbg_havereset;
  phreg_t        dbg_rnm_rd_resp;
  bus64_t        dbg_rf_rdata;
  visa_signals_t visa;

  // ==========================================================================
  // DUT
  // ==========================================================================
  sargantana_soc_axi_wrap #(
    .AxiAddrWidth    ( AxiAddrWidth    ),
    .AxiDataWidth    ( AxiDataWidth    ),
    .AxiUserWidth    ( AxiUserWidth    ),
    .SlvIdWidth      ( SlvIdWidth      ),
    .MstIdWidth      ( MstIdWidth      ),
    .SerMaxTxns      ( SerMaxTxns      ),
    .SerMaxUniqIds   ( SerMaxUniqIds   ),
    .SerMaxTxnsPerId ( SerMaxTxnsPerId )
  ) dut (
    .clk_i                       ( clk              ),
    .rstn_i                      ( rstn             ),
    .soft_rstn_i                 ( soft_rstn        ),
    .reset_addr_i                ( reset_addr       ),
    .core_id_i                   ( core_id          ),
    .time_irq_i                  ( time_irq         ),
    .irq_i                       ( irq              ),
    .soft_irq_i                  ( soft_irq         ),
    .time_i                      ( time_val         ),
    .io_core_pmu_l2_hit_i        ( pmu_l2_hit       ),
    .debug_contr_halt_req_i      ( dbg_halt_req     ),
    .debug_contr_resume_req_i    ( dbg_resume_req   ),
    .debug_contr_progbuf_req_i   ( dbg_progbuf_req  ),
    .debug_contr_halt_on_reset_i ( dbg_halt_on_rst  ),
    .debug_reg_rnm_read_en_i     ( dbg_rnm_rd_en    ),
    .debug_reg_rnm_read_reg_i    ( dbg_rnm_rd_reg   ),
    .debug_reg_rf_en_i           ( dbg_rf_en        ),
    .debug_reg_rf_preg_i         ( dbg_rf_preg      ),
    .debug_reg_rf_we_i           ( dbg_rf_we        ),
    .debug_reg_rf_wdata_i        ( dbg_rf_wdata     ),
    .debug_contr_halt_ack_o      ( dbg_halt_ack     ),
    .debug_contr_halted_o        ( dbg_halted       ),
    .debug_contr_resume_ack_o    ( dbg_resume_ack   ),
    .debug_contr_running_o       ( dbg_running      ),
    .debug_contr_progbuf_ack_o   ( dbg_progbuf_ack  ),
    .debug_contr_parked_o        ( dbg_parked       ),
    .debug_contr_unavail_o       ( dbg_unavail      ),
    .debug_contr_progbuf_xcpt_o  ( dbg_progbuf_xcpt ),
    .debug_contr_havereset_o     ( dbg_havereset    ),
    .debug_reg_rnm_read_resp_o   ( dbg_rnm_rd_resp  ),
    .debug_reg_rf_rdata_o        ( dbg_rf_rdata     ),
    .visa_o                      ( visa             ),
    .axi_mst_ar_valid_o          ( axi_ar_valid     ),
    .axi_mst_ar_ready_i          ( axi_ar_ready     ),
    .axi_mst_ar_addr_o           ( axi_ar_addr      ),
    .axi_mst_ar_id_o             ( axi_ar_id        ),
    .axi_mst_ar_len_o            ( axi_ar_len       ),
    .axi_mst_ar_size_o           ( axi_ar_size      ),
    .axi_mst_ar_burst_o          ( axi_ar_burst     ),
    .axi_mst_ar_lock_o           ( axi_ar_lock      ),
    .axi_mst_ar_cache_o          ( axi_ar_cache     ),
    .axi_mst_ar_prot_o           ( axi_ar_prot      ),
    .axi_mst_ar_qos_o            ( axi_ar_qos       ),
    .axi_mst_ar_region_o         ( axi_ar_region    ),
    .axi_mst_ar_user_o           ( axi_ar_user      ),
    .axi_mst_r_valid_i           ( axi_r_valid      ),
    .axi_mst_r_ready_o           ( axi_r_ready      ),
    .axi_mst_r_data_i            ( axi_r_data       ),
    .axi_mst_r_id_i              ( axi_r_id         ),
    .axi_mst_r_last_i            ( axi_r_last       ),
    .axi_mst_r_resp_i            ( axi_r_resp       ),
    .axi_mst_r_user_i            ( axi_r_user       ),
    .axi_mst_aw_valid_o          ( axi_aw_valid     ),
    .axi_mst_aw_ready_i          ( axi_aw_ready     ),
    .axi_mst_aw_addr_o           ( axi_aw_addr      ),
    .axi_mst_aw_id_o             ( axi_aw_id        ),
    .axi_mst_aw_len_o            ( axi_aw_len       ),
    .axi_mst_aw_size_o           ( axi_aw_size      ),
    .axi_mst_aw_burst_o          ( axi_aw_burst     ),
    .axi_mst_aw_lock_o           ( axi_aw_lock      ),
    .axi_mst_aw_cache_o          ( axi_aw_cache     ),
    .axi_mst_aw_prot_o           ( axi_aw_prot      ),
    .axi_mst_aw_qos_o            ( axi_aw_qos       ),
    .axi_mst_aw_region_o         ( axi_aw_region    ),
    .axi_mst_aw_user_o           ( axi_aw_user      ),
    .axi_mst_aw_atop_o           ( axi_aw_atop      ),
    .axi_mst_w_valid_o           ( axi_w_valid      ),
    .axi_mst_w_ready_i           ( axi_w_ready      ),
    .axi_mst_w_data_o            ( axi_w_data       ),
    .axi_mst_w_strb_o            ( axi_w_strb       ),
    .axi_mst_w_last_o            ( axi_w_last       ),
    .axi_mst_w_user_o            ( axi_w_user       ),
    .axi_mst_b_valid_i           ( axi_b_valid      ),
    .axi_mst_b_ready_o           ( axi_b_ready      ),
    .axi_mst_b_id_i              ( axi_b_id         ),
    .axi_mst_b_resp_i            ( axi_b_resp       ),
    .axi_mst_b_user_i            ( axi_b_user       )
  );

  always @(posedge clk or negedge rstn)
    if (!rstn) time_val <= 0;
    else       time_val <= time_val + 1;

  // ==========================================================================
  // HIERARCHICAL FORCE  output ports of dut.u_core_tile
  // ==========================================================================
  initial begin
    wait (rstn);
    repeat (2) @(posedge clk);

    force dut.u_core_tile.io_mem_acquire_valid           = tb_icache_req_valid;
    force dut.u_core_tile.io_mem_acquire_bits_addr_block = tb_icache_req_paddr;
    force dut.u_core_tile.brom_req_valid_o               = tb_brom_req_valid;
    force dut.u_core_tile.brom_req_address_o             = tb_brom_req_addr;
    force dut.u_core_tile.mem_req_read_valid_o           = tb_hpd_rd_req_valid;
    force dut.u_core_tile.mem_req_read_o                 = tb_hpd_rd_req;
    force dut.u_core_tile.mem_resp_read_ready_o          = tb_hpd_rd_resp_ready;
    force dut.u_core_tile.mem_req_write_valid_o          = tb_hpd_wr_req_valid;
    force dut.u_core_tile.mem_req_write_o                = tb_hpd_wr_req;
    force dut.u_core_tile.mem_req_write_data_valid_o     = tb_hpd_wr_data_valid;
    force dut.u_core_tile.mem_req_write_data_o           = tb_hpd_wr_data;
    force dut.u_core_tile.mem_resp_write_ready_o         = tb_hpd_wr_resp_ready;

    $display("[FORCE] core tile output ports overridden at t=%0t", $time);
  end

  // ==========================================================================
  // HIERARCHICAL READ-BACK  input ports of dut.u_core_tile
  // ==========================================================================
  wire        icache_resp_valid = dut.icache_resp_valid;
  wire[511:0] icache_resp_data  = dut.icache_resp_data;
  wire        brom_resp_valid   = dut.brom_resp_valid;
  wire[511:0] brom_resp_data    = dut.brom_resp_data;

  wire hpd_rd_req_ready  = dut.u_core_tile.mem_req_read_ready_i;
  wire hpd_wr_req_ready  = dut.u_core_tile.mem_req_write_ready_i;
  wire hpd_wr_data_ready = dut.u_core_tile.mem_req_write_data_ready_i;
  wire hpd_rd_resp_valid = dut.u_core_tile.mem_resp_read_valid_i;
  wire hpd_wr_resp_valid = dut.u_core_tile.mem_resp_write_valid_i;

  hpdcache_mem_resp_r_t hpd_rd_resp_obs;
  hpdcache_mem_resp_w_t hpd_wr_resp_obs;
  assign hpd_rd_resp_obs = dut.u_core_tile.mem_resp_read_i;
  assign hpd_wr_resp_obs = dut.u_core_tile.mem_resp_write_i;

  // ==========================================================================
  // CHECK 2  ID WIDTH
  // ==========================================================================
  int unsigned id_width_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_ar_valid && axi_ar_ready) begin
        if (^axi_ar_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AR id X/Z: 0x%0h", $time, axi_ar_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AR id=0x%0h  addr=0x%0h  len=%0d",
                   $time, axi_ar_id, axi_ar_addr, axi_ar_len);
      end
      if (axi_aw_valid && axi_aw_ready) begin
        if (^axi_aw_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AW id X/Z: 0x%0h", $time, axi_aw_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AW id=0x%0h  addr=0x%0h",
                   $time, axi_aw_id, axi_aw_addr);
      end
    end
  end

  // ==========================================================================
  // CHECK 3  ID ORDERING
  // ==========================================================================
  logic [AxiAddrWidth-1:0] ar_order_q [2**MstIdWidth][$];
  int unsigned             order_errors = 0;

  always @(posedge clk) begin
    if (!rstn) begin
      foreach (ar_order_q[i]) ar_order_q[i] = {};
    end else begin
      if (axi_ar_valid && axi_ar_ready) begin
        ar_order_q[axi_ar_id].push_back(axi_ar_addr);
        $display("[ORDER_TRACK] t=%0t  AR id=0x%0h  addr=0x%0h  depth=%0d",
                 $time, axi_ar_id, axi_ar_addr, ar_order_q[axi_ar_id].size());
      end
      if (axi_r_valid && axi_r_ready && axi_r_last) begin
        if (ar_order_q[axi_r_id].size() == 0) begin
          $display("[ORDER FAIL] t=%0t  R-last id=0x%0h  no pending AR!",
                   $time, axi_r_id);
          order_errors++;
        end else begin
          automatic logic [AxiAddrWidth-1:0] oldest = ar_order_q[axi_r_id].pop_front();
          $display("[ORDER_OK   ] t=%0t  R-last id=0x%0h  retired addr=0x%0h",
                   $time, axi_r_id, oldest);
        end
      end
    end
  end

  // ==========================================================================
  // AXI MEMORY MODEL
  // ==========================================================================
  typedef struct {
    logic [MstIdWidth-1:0]   id;
    logic [7:0]              len;
    logic [AxiAddrWidth-1:0] base_addr;
    logic [7:0]              beat_idx;
  } rd_txn_t;

  rd_txn_t               rd_queue[$];
  logic [MstIdWidth-1:0] b_id_queue[$];
  logic [MstIdWidth-1:0] pending_aw_ids[$];
  int unsigned           aw_rcvd      = 0;
  int unsigned           w_burst_rcvd = 0;

  always @(posedge clk) begin
    if (!rstn) begin
      axi_ar_ready <= 0; axi_aw_ready <= 0; axi_w_ready <= 0;
    end else begin
      axi_ar_ready <= ($urandom() % 100) < 75;
      axi_aw_ready <= ($urandom() % 100) < 75;
      axi_w_ready  <= ($urandom() % 100) < 80;
    end
  end

  always @(posedge clk)
    if (rstn && axi_ar_valid && axi_ar_ready)
      rd_queue.push_back('{
        id: axi_ar_id, len: axi_ar_len,
        base_addr: axi_ar_addr, beat_idx: 8'h00
      });

  logic    r_active = 0;
  rd_txn_t r_cur;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      axi_r_valid <= 0; r_active <= 0;
    end else begin
      if (axi_r_valid && axi_r_ready) begin
        if (r_cur.len == 0) begin
          axi_r_valid <= 0; r_active <= 0;
        end else begin
          r_cur.len      -= 1;
          r_cur.beat_idx  = r_cur.beat_idx + 1;
          axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
          axi_r_last  <= (r_cur.len == 0);
          axi_r_valid <= (($urandom() % 100) < 80);
        end
      end else if (!axi_r_valid) begin
        if (r_active) begin
          if (($urandom() % 100) < 80) begin
            axi_r_valid <= 1;
            axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
            axi_r_last  <= (r_cur.len == 0);
          end
        end else if (rd_queue.size() > 0 && ($urandom() % 100) < 80) begin
          r_cur        = rd_queue.pop_front();
          r_active    <= 1;
          axi_r_valid <= 1;
          axi_r_id    <= r_cur.id;
          axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
          axi_r_last  <= (r_cur.len == 0);
          axi_r_resp  <= 2'b00;
          axi_r_user  <= '0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rstn && axi_aw_valid && axi_aw_ready) begin
      pending_aw_ids.push_back(axi_aw_id); aw_rcvd++;
    end
  end
  always @(posedge clk)
    if (rstn && axi_w_valid && axi_w_ready && axi_w_last) w_burst_rcvd++;
  always @(posedge clk)
    if (rstn && aw_rcvd > 0 && w_burst_rcvd > 0) begin
      b_id_queue.push_back(pending_aw_ids.pop_front());
      aw_rcvd--; w_burst_rcvd--;
    end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) axi_b_valid <= 0;
    else begin
      if (axi_b_valid && axi_b_ready) axi_b_valid <= 0;
      else if (!axi_b_valid && b_id_queue.size() > 0 && ($urandom() % 100) < 80) begin
        axi_b_valid <= 1;
        axi_b_id    <= b_id_queue.pop_front();
        axi_b_resp  <= 2'b00;
        axi_b_user  <= '0;
      end
    end
  end

  // ==========================================================================
  // SCOREBOARD
  // ==========================================================================
  int unsigned icache_pass = 0, icache_fail = 0;
  int unsigned ucache_pass = 0, ucache_fail = 0;
  int unsigned hpd_rd_pass = 0, hpd_rd_fail = 0;
  int unsigned hpd_wr_pass = 0, hpd_wr_fail = 0;

  logic [drac_pkg::PHY_ADDR_SIZE-1:0] icache_addr_sb[$];
  logic [39:0]                        ucache_addr_sb[$];
  logic [drac_pkg::PHY_ADDR_SIZE-1:0] hpd_rd_addr_sb[$];

  // ==========================================================================
  // MAIN STIMULUS + MONITOR THREADS
  // ==========================================================================
  initial begin
    axi_r_valid = 0; axi_r_data = '0; axi_r_id = '0;
    axi_r_last  = 0; axi_r_resp = '0; axi_r_user = '0;
    axi_b_valid = 0; axi_b_id   = '0; axi_b_resp = '0; axi_b_user = '0;

    wait (rstn);
    repeat (10) @(posedge clk);

    $display("[TB] Force active. Starting traffic injection...");

    fork

      // -- THREAD 1: ICache driver --
      begin : icache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [drac_pkg::PHY_ADDR_SIZE-1:0] addr =
            ($urandom()) & ~(40'h3F);
          @(posedge clk);
          tb_icache_req_valid = 1;
          tb_icache_req_paddr = addr;
          @(posedge clk);
          tb_icache_req_valid = 0;
          icache_addr_sb.push_back(addr);
          @(posedge clk iff icache_resp_valid);
        end
      end

      // -- THREAD 2: ICache monitor --
      begin : icache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff icache_resp_valid);
          if (^icache_resp_data !== 1'bx) begin
            $display("[ICACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, icache_addr_sb.pop_front(), icache_resp_data[63:0]);
            icache_pass++;
          end else begin
            $display("[ICACHE FAIL] t=%0t  data X/Z", $time);
            icache_fail++;
          end
          @(posedge clk);
        end
      end

      // -- THREAD 3: uCache driver --
      begin : ucache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr = ($urandom()) & ~40'h7;
          @(posedge clk);
          tb_brom_req_valid = 1;
          tb_brom_req_addr  = addr;
          @(posedge clk);
          tb_brom_req_valid = 0;
          ucache_addr_sb.push_back(addr);
          @(posedge clk iff brom_resp_valid);
        end
      end

      // -- THREAD 4: uCache monitor --
      begin : ucache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff brom_resp_valid);
          if (^brom_resp_data[63:0] !== 1'bx) begin
            $display("[UCACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, ucache_addr_sb.pop_front(), brom_resp_data[63:0]);
            ucache_pass++;
          end else begin
            $display("[UCACHE FAIL] t=%0t  data X/Z", $time);
            ucache_fail++;
          end
          @(posedge clk);
        end
      end

      // -- THREAD 5: HPD read driver --
      begin : hpd_rd_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [drac_pkg::PHY_ADDR_SIZE-1:0] addr =
            ($urandom()) & ~(40'h3F);
          tb_hpd_rd_req.mem_req_addr    = addr;
          tb_hpd_rd_req.mem_req_id      = $urandom();
          tb_hpd_rd_req.mem_req_len     = 0;
          tb_hpd_rd_req.mem_req_size    = 6;
          tb_hpd_rd_req.mem_req_command = HPDCACHE_MEM_READ;
          tb_hpd_rd_req_valid = 1;
          do @(posedge clk); while (!hpd_rd_req_ready);
          tb_hpd_rd_req_valid = 0;
          hpd_rd_addr_sb.push_back(addr);
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // -- THREAD 6: HPD read monitor --
      begin : hpd_rd_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_rd_resp_valid && tb_hpd_rd_resp_ready));
          if (hpd_rd_resp_obs.mem_resp_r_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_RD PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, hpd_rd_addr_sb.pop_front(),
              hpd_rd_resp_obs.mem_resp_r_data[63:0]);
            hpd_rd_pass++;
          end else begin
            $display("[HPD_RD FAIL] t=%0t  error resp", $time);
            hpd_rd_fail++;
          end
          @(posedge clk);
        end
      end

      // -- THREAD 7: HPD write driver --
      begin : hpd_wr_drv
        for (int i = 0; i < N_TESTS; i++) begin
          tb_hpd_wr_req.mem_req_addr    =
            ($urandom()) & ~(40'h3F);
          tb_hpd_wr_req.mem_req_id      = $urandom();
          tb_hpd_wr_req.mem_req_size    = 6;
          tb_hpd_wr_req.mem_req_command = HPDCACHE_MEM_WRITE;
          tb_hpd_wr_data.mem_req_w_data = {$urandom(),$urandom(),
                                           $urandom(),$urandom()};
          tb_hpd_wr_data.mem_req_w_be   = ~0;
          tb_hpd_wr_req_valid  = 1;
          tb_hpd_wr_data_valid = 1;
          fork
            begin
              do @(posedge clk); while (!hpd_wr_req_ready);
              tb_hpd_wr_req_valid = 0;
            end
            begin
              do @(posedge clk); while (!hpd_wr_data_ready);
              tb_hpd_wr_data_valid = 0;
            end
          join
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // -- THREAD 8: HPD write monitor --
      begin : hpd_wr_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_wr_resp_valid && tb_hpd_wr_resp_ready));
          if (hpd_wr_resp_obs.mem_resp_w_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_WR PASS] t=%0t  id=0x%0h  completed",
              $time, hpd_wr_resp_obs.mem_resp_w_id);
            hpd_wr_pass++;
          end else begin
            $display("[HPD_WR FAIL] t=%0t  error resp", $time);
            hpd_wr_fail++;
          end
          @(posedge clk);
        end
      end

    join

    // Release all forces
    release dut.u_core_tile.io_mem_acquire_valid;
    release dut.u_core_tile.io_mem_acquire_bits_addr_block;
    release dut.u_core_tile.brom_req_valid_o;
    release dut.u_core_tile.brom_req_address_o;
    release dut.u_core_tile.mem_req_read_valid_o;
    release dut.u_core_tile.mem_req_read_o;
    release dut.u_core_tile.mem_resp_read_ready_o;
    release dut.u_core_tile.mem_req_write_valid_o;
    release dut.u_core_tile.mem_req_write_o;
    release dut.u_core_tile.mem_req_write_data_valid_o;
    release dut.u_core_tile.mem_req_write_data_o;
    release dut.u_core_tile.mem_resp_write_ready_o;

    // ================================================================
    // FINAL REPORT
    // ================================================================
    $display("");
    $display("------------------------------------------------------------");
    $display("  TOP-LEVEL MEMORY SUBSYSTEM TEST  (core tile port forcing)");
    $display("------------------------------------------------------------");
    $display("");
    $display("  Signal widths aligned with sim_top.sv / drac_pkg:");
    $display("    ICache addr : [PHY_ADDR_SIZE-1:0] = [%0d:0]",
             drac_pkg::PHY_ADDR_SIZE-1);
    $display("    uCache addr : [39:0]  (fixed, matches sim_top)");
    $display("    HPD types   : from DRAC_CFG.MemAddrWidth=%0d / IDWidth=%0d",
             DRAC_CFG.MemAddrWidth, DRAC_CFG.MemIDWidth);
    $display("");
    $display("  -- Cache Traffic (end-to-end) ---------------------------");
    $display("  ICache  reads : %0d PASS  %0d FAIL", icache_pass, icache_fail);
    $display("  uCache  reads : %0d PASS  %0d FAIL", ucache_pass, ucache_fail);
    $display("  HPD     reads : %0d PASS  %0d FAIL", hpd_rd_pass, hpd_rd_fail);
    $display("  HPD     writes: %0d PASS  %0d FAIL", hpd_wr_pass, hpd_wr_fail);
    $display("  TOTAL         : %0d PASS  %0d FAIL  (of %0d)",
      icache_pass + ucache_pass + hpd_rd_pass + hpd_wr_pass,
      icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail,
      N_TESTS * 4);
    $display("");
    $display("  -- AXI ID Checks ----------------------------------------");
    $display("  ID width  errors : %0d", id_width_errors);
    $display("  ID order  errors : %0d", order_errors);
    if (id_width_errors == 0 && order_errors == 0)
      $display("  AXI ID CHECKS    : ALL PASSED");
    else
      $display("  AXI ID CHECKS    : *** FAILURES DETECTED ***");
    $display("");
    begin
      automatic int total_fail =
        icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail +
        id_width_errors + order_errors;
      if (total_fail == 0)
        $display("  ?  OVERALL: ALL CHECKS PASSED ?");
      else
        $display("  ?  OVERALL: %0d FAILURE(S) DETECTED ?", total_fail);
    end
    $display("------------------------------------------------------------");
    $finish;
  end

endmodule

/*
`timescale 1ns/1ps
// ============================================================================
// tb_sargantana_soc_axi_wrap
// ----------------------------------------------------------------------------
// Top-level testbench for sargantana_soc_axi_wrap.
//
// STRATEGY
// --------
//   Force signals at the OUTPUT PORTS of u_core_tile (top_tile instance)
//   inside sargantana_soc_axi_wrap, going one level deeper than the previous
//   TB which forced the intermediate wires between u_core_tile and u_axi_bridge.
//
//   This exercises the full path:
//
//     TB stimulus
//       ¦
//       ?  force dut.u_core_tile.<port_name>
//     top_tile output ports   (validates port name mapping in instantiation)
//       ¦
//       ?  intermediate wires inside sargantana_soc_axi_wrap
//     sargantana_soc_wrap_ids (u_axi_bridge) inputs
//       ¦
//       ?  AXI MUX + ID Serializer
//     Flat AXI4 master port   (TB acts as memory here)
//       ¦
//       ?  AXI memory model returns R / B responses
//     sargantana_soc_wrap_ids outputs
//       ¦
//       ?  intermediate wires
//     top_tile input ports    (observed via hierarchical read-back)
//       ¦
//       ?
//     TB monitors response
//
//   Forced ports on dut.u_core_tile:
//     OUTPUT (TB drives):
//       .io_mem_acquire_valid            ? icache request valid
//       .io_mem_acquire_bits_addr_block  ? icache request address
//       .brom_req_valid_o                ? ucache request valid
//       .brom_req_address_o              ? ucache request address
//       .mem_req_read_valid_o            ? HPD read request valid
//       .mem_req_read_o                  ? HPD read request struct
//       .mem_resp_read_ready_o           ? HPD read response ready
//       .mem_req_write_valid_o           ? HPD write request valid
//       .mem_req_write_o                 ? HPD write request struct
//       .mem_req_write_data_valid_o      ? HPD write data valid
//       .mem_req_write_data_o            ? HPD write data struct
//       .mem_resp_write_ready_o          ? HPD write response ready
//
//     INPUT (TB observes via hierarchical wire aliases):
//       .io_mem_grant_valid              ? icache/ucache response valid
//       .io_mem_grant_bits_data          ? icache/ucache response data
//       .mem_req_read_ready_i            ? HPD read request ready
//       .mem_resp_read_valid_i           ? HPD read response valid
//       .mem_resp_read_i                 ? HPD read response struct
//       .mem_req_write_ready_i           ? HPD write request ready
//       .mem_req_write_data_ready_i      ? HPD write data ready
//       .mem_resp_write_valid_i          ? HPD write response valid
//       .mem_resp_write_i                ? HPD write response struct
//
// CHECKS
// ------
//   1. End-to-end cache traffic (ICache, uCache, HPD rd, HPD wr)  20/20 pass
//   2. ID width   every AR/AW at master port has valid MstIdWidth ID (no X/Z)
//   3. ID ordering  responses for a given ID retire in issue order
// ============================================================================

module tb_sargantana_soc_axi_wrap;

  import drac_pkg::*;
  import hpdcache_pkg::*;
  import test_types_pkg::*;

  // ==========================================================================
  // Parameters
  // ==========================================================================
  localparam int unsigned AxiAddrWidth    = 64;
  localparam int unsigned AxiDataWidth    = 64;
  localparam int unsigned AxiUserWidth    = 1;
  localparam int unsigned SlvIdWidth      = 8;
  localparam int unsigned MstIdWidth      = 4;
  localparam int unsigned SerMaxTxns      = 16;
  localparam int unsigned SerMaxUniqIds   = 16;
  localparam int unsigned SerMaxTxnsPerId = 16;

  localparam int unsigned N_TESTS = 5;   // transactions per cache interface

  // ==========================================================================
  // Clock & reset
  // ==========================================================================
  logic clk  = 0;
  logic rstn = 0;
  always #5 clk = ~clk;   // 100 MHz

  int unsigned cyc_cnt = 0;
  always @(posedge clk) begin
    cyc_cnt <= cyc_cnt + 1;
    if (cyc_cnt > 2_000_000) begin
      $display("\n[FATAL] WATCHDOG: simulation exceeded 2M cycles  deadlock!");
      $finish;
    end
  end

  initial begin
    rstn = 0;
    repeat (8) @(posedge clk);
    @(negedge clk);
    rstn = 1;
  end

  // ==========================================================================
  // TB-side stimulus signals
  // These will be forced onto the OUTPUT PORTS of dut.u_core_tile
  // ==========================================================================

  // ICache
  logic        tb_icache_req_valid = 0;
  logic [39:0] tb_icache_req_paddr = '0;

  // uCache / BROM
  logic        tb_brom_req_valid   = 0;
  logic [39:0] tb_brom_req_addr    = '0;

  // HPDCache read
  logic                 tb_hpd_rd_req_valid  = 0;
  hpdcache_mem_req_t    tb_hpd_rd_req        = '0;
  logic                 tb_hpd_rd_resp_ready = 1;

  // HPDCache write
  logic                 tb_hpd_wr_req_valid  = 0;
  hpdcache_mem_req_t    tb_hpd_wr_req        = '0;
  logic                 tb_hpd_wr_data_valid = 0;
  hpdcache_mem_req_w_t  tb_hpd_wr_data       = '0;
  logic                 tb_hpd_wr_resp_ready = 1;

  // ==========================================================================
  // Flat AXI4 master port wires  (TB acts as the memory system)
  // ==========================================================================
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
  // Other DUT ports  tied off (not under test)
  // ==========================================================================
  logic        soft_rstn  = 1;
  logic [63:0] reset_addr = 64'h8000_0000;
  logic [63:0] core_id    = 64'h0;
  logic [63:0] time_val   = 64'h0;
  logic        time_irq   = 0;
  logic [1:0]  irq        = 2'b00;
  logic        soft_irq   = 0;
  logic        pmu_l2_hit = 0;

  logic       dbg_halt_req    = 0, dbg_resume_req  = 0;
  logic       dbg_progbuf_req = 0, dbg_halt_on_rst = 0;
  logic       dbg_rnm_rd_en   = 0, dbg_rf_en       = 0;
  logic       dbg_rf_we       = 0;
  reg_t       dbg_rnm_rd_reg  = '0;
  phreg_t     dbg_rf_preg     = '0;
  bus64_t     dbg_rf_wdata    = '0;

  logic          dbg_halt_ack, dbg_halted, dbg_resume_ack, dbg_running;
  logic          dbg_progbuf_ack, dbg_parked, dbg_unavail;
  logic          dbg_progbuf_xcpt, dbg_havereset;
  phreg_t        dbg_rnm_rd_resp;
  bus64_t        dbg_rf_rdata;
  visa_signals_t visa;

  // ==========================================================================
  // DUT instantiation
  // ==========================================================================
  sargantana_soc_axi_wrap #(
    .AxiAddrWidth    ( AxiAddrWidth    ),
    .AxiDataWidth    ( AxiDataWidth    ),
    .AxiUserWidth    ( AxiUserWidth    ),
    .SlvIdWidth      ( SlvIdWidth      ),
    .MstIdWidth      ( MstIdWidth      ),
    .SerMaxTxns      ( SerMaxTxns      ),
    .SerMaxUniqIds   ( SerMaxUniqIds   ),
    .SerMaxTxnsPerId ( SerMaxTxnsPerId )
  ) dut (
    .clk_i                       ( clk              ),
    .rstn_i                      ( rstn             ),
    .soft_rstn_i                 ( soft_rstn        ),
    .reset_addr_i                ( reset_addr       ),
    .core_id_i                   ( core_id          ),
    .time_irq_i                  ( time_irq         ),
    .irq_i                       ( irq              ),
    .soft_irq_i                  ( soft_irq         ),
    .time_i                      ( time_val         ),
    .io_core_pmu_l2_hit_i        ( pmu_l2_hit       ),
    .debug_contr_halt_req_i      ( dbg_halt_req     ),
    .debug_contr_resume_req_i    ( dbg_resume_req   ),
    .debug_contr_progbuf_req_i   ( dbg_progbuf_req  ),
    .debug_contr_halt_on_reset_i ( dbg_halt_on_rst  ),
    .debug_reg_rnm_read_en_i     ( dbg_rnm_rd_en    ),
    .debug_reg_rnm_read_reg_i    ( dbg_rnm_rd_reg   ),
    .debug_reg_rf_en_i           ( dbg_rf_en        ),
    .debug_reg_rf_preg_i         ( dbg_rf_preg      ),
    .debug_reg_rf_we_i           ( dbg_rf_we        ),
    .debug_reg_rf_wdata_i        ( dbg_rf_wdata     ),
    .debug_contr_halt_ack_o      ( dbg_halt_ack     ),
    .debug_contr_halted_o        ( dbg_halted       ),
    .debug_contr_resume_ack_o    ( dbg_resume_ack   ),
    .debug_contr_running_o       ( dbg_running      ),
    .debug_contr_progbuf_ack_o   ( dbg_progbuf_ack  ),
    .debug_contr_parked_o        ( dbg_parked       ),
    .debug_contr_unavail_o       ( dbg_unavail      ),
    .debug_contr_progbuf_xcpt_o  ( dbg_progbuf_xcpt ),
    .debug_contr_havereset_o     ( dbg_havereset    ),
    .debug_reg_rnm_read_resp_o   ( dbg_rnm_rd_resp  ),
    .debug_reg_rf_rdata_o        ( dbg_rf_rdata     ),
    .visa_o                      ( visa             ),
    .axi_mst_ar_valid_o          ( axi_ar_valid     ),
    .axi_mst_ar_ready_i          ( axi_ar_ready     ),
    .axi_mst_ar_addr_o           ( axi_ar_addr      ),
    .axi_mst_ar_id_o             ( axi_ar_id        ),
    .axi_mst_ar_len_o            ( axi_ar_len       ),
    .axi_mst_ar_size_o           ( axi_ar_size      ),
    .axi_mst_ar_burst_o          ( axi_ar_burst     ),
    .axi_mst_ar_lock_o           ( axi_ar_lock      ),
    .axi_mst_ar_cache_o          ( axi_ar_cache     ),
    .axi_mst_ar_prot_o           ( axi_ar_prot      ),
    .axi_mst_ar_qos_o            ( axi_ar_qos       ),
    .axi_mst_ar_region_o         ( axi_ar_region    ),
    .axi_mst_ar_user_o           ( axi_ar_user      ),
    .axi_mst_r_valid_i           ( axi_r_valid      ),
    .axi_mst_r_ready_o           ( axi_r_ready      ),
    .axi_mst_r_data_i            ( axi_r_data       ),
    .axi_mst_r_id_i              ( axi_r_id         ),
    .axi_mst_r_last_i            ( axi_r_last       ),
    .axi_mst_r_resp_i            ( axi_r_resp       ),
    .axi_mst_r_user_i            ( axi_r_user       ),
    .axi_mst_aw_valid_o          ( axi_aw_valid     ),
    .axi_mst_aw_ready_i          ( axi_aw_ready     ),
    .axi_mst_aw_addr_o           ( axi_aw_addr      ),
    .axi_mst_aw_id_o             ( axi_aw_id        ),
    .axi_mst_aw_len_o            ( axi_aw_len       ),
    .axi_mst_aw_size_o           ( axi_aw_size      ),
    .axi_mst_aw_burst_o          ( axi_aw_burst     ),
    .axi_mst_aw_lock_o           ( axi_aw_lock      ),
    .axi_mst_aw_cache_o          ( axi_aw_cache     ),
    .axi_mst_aw_prot_o           ( axi_aw_prot      ),
    .axi_mst_aw_qos_o            ( axi_aw_qos       ),
    .axi_mst_aw_region_o         ( axi_aw_region    ),
    .axi_mst_aw_user_o           ( axi_aw_user      ),
    .axi_mst_aw_atop_o           ( axi_aw_atop      ),
    .axi_mst_w_valid_o           ( axi_w_valid      ),
    .axi_mst_w_ready_i           ( axi_w_ready      ),
    .axi_mst_w_data_o            ( axi_w_data       ),
    .axi_mst_w_strb_o            ( axi_w_strb       ),
    .axi_mst_w_last_o            ( axi_w_last       ),
    .axi_mst_w_user_o            ( axi_w_user       ),
    .axi_mst_b_valid_i           ( axi_b_valid      ),
    .axi_mst_b_ready_o           ( axi_b_ready      ),
    .axi_mst_b_id_i              ( axi_b_id         ),
    .axi_mst_b_resp_i            ( axi_b_resp       ),
    .axi_mst_b_user_i            ( axi_b_user       )
  );

  // Free-running time counter
  always @(posedge clk or negedge rstn)
    if (!rstn) time_val <= 0;
    else       time_val <= time_val + 1;

  // ==========================================================================
  // HIERARCHICAL FORCE BLOCK
  // Force the OUTPUT PORTS of dut.u_core_tile (top_tile instance).
  // Port names taken directly from the top_tile instantiation in
  // sargantana_soc_axi_wrap.sv.
  //
  // ICache:
  //   .io_mem_acquire_valid           ? icache_req_valid
  //   .io_mem_acquire_bits_addr_block ? icache_req_paddr
  //
  // uCache:
  //   .brom_req_valid_o               ? brom_req_valid
  //   .brom_req_address_o             ? brom_req_addr
  //
  // HPDCache read:
  //   .mem_req_read_valid_o           ? hpd_rd_req_valid
  //   .mem_req_read_o                 ? hpd_rd_req
  //   .mem_resp_read_ready_o          ? hpd_rd_resp_ready
  //
  // HPDCache write:
  //   .mem_req_write_valid_o          ? hpd_wr_req_valid
  //   .mem_req_write_o                ? hpd_wr_req
  //   .mem_req_write_data_valid_o     ? hpd_wr_data_valid
  //   .mem_req_write_data_o           ? hpd_wr_data
  //   .mem_resp_write_ready_o         ? hpd_wr_resp_ready
  // ==========================================================================
  initial begin
    wait (rstn);
    repeat (2) @(posedge clk);

    // -- ICache output ports --
    force dut.u_core_tile.io_mem_acquire_valid           = tb_icache_req_valid;
    force dut.u_core_tile.io_mem_acquire_bits_addr_block = tb_icache_req_paddr;

    // -- uCache output ports --
    force dut.u_core_tile.brom_req_valid_o               = tb_brom_req_valid;
    force dut.u_core_tile.brom_req_address_o             = tb_brom_req_addr;

    // -- HPDCache read output ports --
    force dut.u_core_tile.mem_req_read_valid_o           = tb_hpd_rd_req_valid;
    force dut.u_core_tile.mem_req_read_o                 = tb_hpd_rd_req;
    force dut.u_core_tile.mem_resp_read_ready_o          = tb_hpd_rd_resp_ready;

    // -- HPDCache write output ports --
    force dut.u_core_tile.mem_req_write_valid_o          = tb_hpd_wr_req_valid;
    force dut.u_core_tile.mem_req_write_o                = tb_hpd_wr_req;
    force dut.u_core_tile.mem_req_write_data_valid_o     = tb_hpd_wr_data_valid;
    force dut.u_core_tile.mem_req_write_data_o           = tb_hpd_wr_data;
    force dut.u_core_tile.mem_resp_write_ready_o         = tb_hpd_wr_resp_ready;

    $display("[FORCE] Core tile output ports overridden at t=%0t", $time);
  end

  // ==========================================================================
  // HIERARCHICAL READ-BACK
  // Observe the INPUT PORTS of dut.u_core_tile to see what the bridge
  // is sending back to the core.
  //
  // ICache / uCache shared response:
  //   .io_mem_grant_valid          ? io_mem_grant_valid  (merged resp)
  //   .io_mem_grant_bits_data      ? io_mem_grant_bits_data
  //
  // icache_resp_ack is driven back separately via io_mem_grant_bits_addr_beat
  // We observe the bridge outputs directly for clean per-interface tracking:
  //   dut.icache_resp_valid        ? ICache response valid
  //   dut.icache_resp_data         ? ICache response data
  //   dut.brom_resp_valid          ? uCache response valid
  //   dut.brom_resp_data           ? uCache response data
  //
  // HPDCache read response (bridge ? core input ports):
  //   .mem_req_read_ready_i        ? hpd_rd_req_ready
  //   .mem_resp_read_valid_i       ? hpd_rd_resp_valid
  //   .mem_resp_read_i             ? hpd_rd_resp
  //
  // HPDCache write response (bridge ? core input ports):
  //   .mem_req_write_ready_i       ? hpd_wr_req_ready
  //   .mem_req_write_data_ready_i  ? hpd_wr_data_ready
  //   .mem_resp_write_valid_i      ? hpd_wr_resp_valid
  //   .mem_resp_write_i            ? hpd_wr_resp
  // ==========================================================================

  // ICache / uCache responses observed at bridge output wires
  wire        icache_resp_valid = dut.icache_resp_valid;
  wire[511:0] icache_resp_data  = dut.icache_resp_data;
  wire        brom_resp_valid   = dut.brom_resp_valid;
  wire[511:0] brom_resp_data    = dut.brom_resp_data;

  // HPDCache ready signals observed at core input ports
  wire        hpd_rd_req_ready  = dut.u_core_tile.mem_req_read_ready_i;
  wire        hpd_wr_req_ready  = dut.u_core_tile.mem_req_write_ready_i;
  wire        hpd_wr_data_ready = dut.u_core_tile.mem_req_write_data_ready_i;

  // HPDCache response signals observed at core input ports
  wire        hpd_rd_resp_valid = dut.u_core_tile.mem_resp_read_valid_i;
  wire        hpd_wr_resp_valid = dut.u_core_tile.mem_resp_write_valid_i;

  hpdcache_mem_resp_r_t hpd_rd_resp_obs;
  hpdcache_mem_resp_w_t hpd_wr_resp_obs;
  assign hpd_rd_resp_obs = dut.u_core_tile.mem_resp_read_i;
  assign hpd_wr_resp_obs = dut.u_core_tile.mem_resp_write_i;

  // ==========================================================================
  // CHECK 2  ID WIDTH: every accepted AR/AW must have no X/Z in its ID
  // ==========================================================================
  int unsigned id_width_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_ar_valid && axi_ar_ready) begin
        if (^axi_ar_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AR id contains X/Z: 0x%0h", $time, axi_ar_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AR id=0x%0h  addr=0x%0h  len=%0d",
                   $time, axi_ar_id, axi_ar_addr, axi_ar_len);
      end
      if (axi_aw_valid && axi_aw_ready) begin
        if (^axi_aw_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AW id contains X/Z: 0x%0h", $time, axi_aw_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AW id=0x%0h  addr=0x%0h",
                   $time, axi_aw_id, axi_aw_addr);
      end
    end
  end

  // ==========================================================================
  // CHECK 3  ID ORDERING
  // axi_id_serialize guarantees in-order responses per master ID.
  // For each ID we maintain a FIFO of issued AR addresses.
  // On R-last, we verify the response retires the oldest pending entry
  // for that ID (queue must not be empty = no spurious response).
  //
  // NOTE: Multiple in-flight ARs with the same ID is LEGAL because
  // SerMaxTxnsPerId > 1. The serializer sequences their responses.
  // We do NOT flag same-ID concurrent transactions as errors.
  // ==========================================================================
  logic [AxiAddrWidth-1:0] ar_order_q [2**MstIdWidth][$];
  int unsigned             order_errors = 0;

  always @(posedge clk) begin
    if (!rstn) begin
      foreach (ar_order_q[i]) ar_order_q[i] = {};
    end else begin
      // Record new AR in per-ID FIFO
      if (axi_ar_valid && axi_ar_ready) begin
        ar_order_q[axi_ar_id].push_back(axi_ar_addr);
        $display("[ORDER_TRACK] t=%0t  AR id=0x%0h  addr=0x%0h  queue_depth=%0d",
                 $time, axi_ar_id, axi_ar_addr, ar_order_q[axi_ar_id].size());
      end
      // On R-last verify queue non-empty and retire oldest entry
      if (axi_r_valid && axi_r_ready && axi_r_last) begin
        if (ar_order_q[axi_r_id].size() == 0) begin
          $display("[ORDER FAIL] t=%0t  R-last for id=0x%0h but no pending AR!",
                   $time, axi_r_id);
          order_errors++;
        end else begin
          automatic logic [AxiAddrWidth-1:0] oldest = ar_order_q[axi_r_id].pop_front();
          $display("[ORDER_OK   ] t=%0t  R-last id=0x%0h  retired addr=0x%0h",
                   $time, axi_r_id, oldest);
        end
      end
    end
  end

  // ==========================================================================
  // AXI MEMORY MODEL  (chaotic slave  randomised backpressure + bubbles)
  // ==========================================================================
  typedef struct {
    logic [MstIdWidth-1:0]   id;
    logic [7:0]              len;
    logic [AxiAddrWidth-1:0] base_addr;
    logic [7:0]              beat_idx;
  } rd_txn_t;

  rd_txn_t               rd_queue[$];
  logic [MstIdWidth-1:0] b_id_queue[$];
  logic [MstIdWidth-1:0] pending_aw_ids[$];
  int unsigned           aw_rcvd      = 0;
  int unsigned           w_burst_rcvd = 0;

  // Randomised backpressure on AR / AW / W
  always @(posedge clk) begin
    if (!rstn) begin
      axi_ar_ready <= 0;
      axi_aw_ready <= 0;
      axi_w_ready  <= 0;
    end else begin
      axi_ar_ready <= ($urandom() % 100) < 75;
      axi_aw_ready <= ($urandom() % 100) < 75;
      axi_w_ready  <= ($urandom() % 100) < 80;
    end
  end

  // Enqueue accepted AR
  always @(posedge clk)
    if (rstn && axi_ar_valid && axi_ar_ready)
      rd_queue.push_back('{
        id        : axi_ar_id,
        len       : axi_ar_len,
        base_addr : axi_ar_addr,
        beat_idx  : 8'h00
      });

  // R channel driver with random bubbles
  logic    r_active = 0;
  rd_txn_t r_cur;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      axi_r_valid <= 0;
      r_active    <= 0;
    end else begin
      if (axi_r_valid && axi_r_ready) begin
        if (r_cur.len == 0) begin
          // burst complete
          axi_r_valid <= 0;
          r_active    <= 0;
        end else begin
          // next beat
          r_cur.len      -= 1;
          r_cur.beat_idx  = r_cur.beat_idx + 1;
          axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
          axi_r_last  <= (r_cur.len == 0);
          axi_r_valid <= (($urandom() % 100) < 80);
        end
      end else if (!axi_r_valid) begin
        if (r_active) begin
          // resume after bubble
          if (($urandom() % 100) < 80) begin
            axi_r_valid <= 1;
            axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
            axi_r_last  <= (r_cur.len == 0);
          end
        end else if (rd_queue.size() > 0) begin
          // start new burst
          if (($urandom() % 100) < 80) begin
            r_cur        = rd_queue.pop_front();
            r_active    <= 1;
            axi_r_valid <= 1;
            axi_r_id    <= r_cur.id;
            axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
            axi_r_last  <= (r_cur.len == 0);
            axi_r_resp  <= 2'b00;
            axi_r_user  <= '0;
          end
        end
      end
    end
  end

  // AW acceptance
  always @(posedge clk)
    if (rstn && axi_aw_valid && axi_aw_ready) begin
      pending_aw_ids.push_back(axi_aw_id);
      aw_rcvd++;
    end

  // W burst last beat
  always @(posedge clk)
    if (rstn && axi_w_valid && axi_w_ready && axi_w_last)
      w_burst_rcvd++;

  // Pair AW + W ? B queue
  always @(posedge clk)
    if (rstn && aw_rcvd > 0 && w_burst_rcvd > 0) begin
      b_id_queue.push_back(pending_aw_ids.pop_front());
      aw_rcvd--;
      w_burst_rcvd--;
    end

  // B channel driver with random bubbles
  always @(posedge clk or negedge rstn) begin
    if (!rstn) axi_b_valid <= 0;
    else begin
      if (axi_b_valid && axi_b_ready)
        axi_b_valid <= 0;
      else if (!axi_b_valid && b_id_queue.size() > 0 && ($urandom() % 100) < 80) begin
        axi_b_valid <= 1;
        axi_b_id    <= b_id_queue.pop_front();
        axi_b_resp  <= 2'b00;
        axi_b_user  <= '0;
      end
    end
  end

  // ==========================================================================
  // SCOREBOARD
  // ==========================================================================
  int unsigned icache_pass = 0, icache_fail = 0;
  int unsigned ucache_pass = 0, ucache_fail = 0;
  int unsigned hpd_rd_pass = 0, hpd_rd_fail = 0;
  int unsigned hpd_wr_pass = 0, hpd_wr_fail = 0;

  logic [39:0] icache_addr_sb[$];
  logic [39:0] ucache_addr_sb[$];
  logic [39:0] hpd_rd_addr_sb[$];

  // ==========================================================================
  // MAIN STIMULUS + MONITOR THREADS
  // ==========================================================================
  initial begin
    // Initialise AXI memory model outputs
    axi_r_valid = 0; axi_r_data = '0; axi_r_id   = '0;
    axi_r_last  = 0; axi_r_resp = '0; axi_r_user = '0;
    axi_b_valid = 0; axi_b_id   = '0; axi_b_resp = '0; axi_b_user = '0;

    wait (rstn);
    // Allow force block to apply (2 extra cycles after reset)
    repeat (10) @(posedge clk);

    $display("[TB] Force active on u_core_tile ports. Starting traffic injection...");

    fork

      // ----------------------------------------------------------
      // THREAD 1  ICache driver
      // Drives: dut.u_core_tile.io_mem_acquire_valid
      //         dut.u_core_tile.io_mem_acquire_bits_addr_block
      // ----------------------------------------------------------
      begin : icache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h3F;
          @(posedge clk);
          tb_icache_req_valid = 1;
          tb_icache_req_paddr = addr;
          @(posedge clk);
          tb_icache_req_valid = 0;
          icache_addr_sb.push_back(addr);
          @(posedge clk iff icache_resp_valid);
        end
      end

      // ----------------------------------------------------------
      // THREAD 2  ICache monitor
      // Observes: dut.icache_resp_valid / dut.icache_resp_data
      // ----------------------------------------------------------
      begin : icache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff icache_resp_valid);
          if (^icache_resp_data !== 1'bx) begin
            $display("[ICACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, icache_addr_sb.pop_front(), icache_resp_data[63:0]);
            icache_pass++;
          end else begin
            $display("[ICACHE FAIL] t=%0t  data contains X/Z", $time);
            icache_fail++;
          end
          @(posedge clk);
        end
      end

      // ----------------------------------------------------------
      // THREAD 3  uCache driver
      // Drives: dut.u_core_tile.brom_req_valid_o
      //         dut.u_core_tile.brom_req_address_o
      // ----------------------------------------------------------
      begin : ucache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h7;
          @(posedge clk);
          tb_brom_req_valid = 1;
          tb_brom_req_addr  = addr;
          @(posedge clk);
          tb_brom_req_valid = 0;
          ucache_addr_sb.push_back(addr);
          @(posedge clk iff brom_resp_valid);
        end
      end

      // ----------------------------------------------------------
      // THREAD 4  uCache monitor
      // Observes: dut.brom_resp_valid / dut.brom_resp_data
      // ----------------------------------------------------------
      begin : ucache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff brom_resp_valid);
          if (^brom_resp_data[63:0] !== 1'bx) begin
            $display("[UCACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, ucache_addr_sb.pop_front(), brom_resp_data[63:0]);
            ucache_pass++;
          end else begin
            $display("[UCACHE FAIL] t=%0t  data contains X/Z", $time);
            ucache_fail++;
          end
          @(posedge clk);
        end
      end

      // ----------------------------------------------------------
      // THREAD 5  HPD read driver
      // Drives: dut.u_core_tile.mem_req_read_valid_o
      //         dut.u_core_tile.mem_req_read_o
      // Observes ready: dut.u_core_tile.mem_req_read_ready_i
      // ----------------------------------------------------------
      begin : hpd_rd_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {$urandom(), $urandom()} & ~39'h3F;
          tb_hpd_rd_req.mem_req_addr    = addr;
          tb_hpd_rd_req.mem_req_id      = $urandom();
          tb_hpd_rd_req.mem_req_len     = 0;
          tb_hpd_rd_req.mem_req_size    = 6;
          tb_hpd_rd_req.mem_req_command = HPDCACHE_MEM_READ;
          tb_hpd_rd_req_valid = 1;
          do @(posedge clk); while (!hpd_rd_req_ready);
          tb_hpd_rd_req_valid = 0;
          hpd_rd_addr_sb.push_back(addr);
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ----------------------------------------------------------
      // THREAD 6  HPD read monitor
      // Observes: dut.u_core_tile.mem_resp_read_valid_i
      //           dut.u_core_tile.mem_resp_read_i
      // ----------------------------------------------------------
      begin : hpd_rd_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_rd_resp_valid && tb_hpd_rd_resp_ready));
          if (hpd_rd_resp_obs.mem_resp_r_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_RD PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, hpd_rd_addr_sb.pop_front(),
              hpd_rd_resp_obs.mem_resp_r_data[63:0]);
            hpd_rd_pass++;
          end else begin
            $display("[HPD_RD FAIL] t=%0t  error response", $time);
            hpd_rd_fail++;
          end
          @(posedge clk);
        end
      end

      // ----------------------------------------------------------
      // THREAD 7  HPD write driver
      // Drives: dut.u_core_tile.mem_req_write_valid_o
      //         dut.u_core_tile.mem_req_write_o
      //         dut.u_core_tile.mem_req_write_data_valid_o
      //         dut.u_core_tile.mem_req_write_data_o
      // Observes ready: dut.u_core_tile.mem_req_write_ready_i
      //                 dut.u_core_tile.mem_req_write_data_ready_i
      // ----------------------------------------------------------
      begin : hpd_wr_drv
        for (int i = 0; i < N_TESTS; i++) begin
          tb_hpd_wr_req.mem_req_addr    = {$urandom(), $urandom()} & ~39'h3F;
          tb_hpd_wr_req.mem_req_id      = $urandom();
          tb_hpd_wr_req.mem_req_size    = 6;
          tb_hpd_wr_req.mem_req_command = HPDCACHE_MEM_WRITE;
          tb_hpd_wr_data.mem_req_w_data = {$urandom(), $urandom(),
                                           $urandom(), $urandom()};
          tb_hpd_wr_data.mem_req_w_be   = ~0;
          tb_hpd_wr_req_valid  = 1;
          tb_hpd_wr_data_valid = 1;
          fork
            begin
              do @(posedge clk); while (!hpd_wr_req_ready);
              tb_hpd_wr_req_valid = 0;
            end
            begin
              do @(posedge clk); while (!hpd_wr_data_ready);
              tb_hpd_wr_data_valid = 0;
            end
          join
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ----------------------------------------------------------
      // THREAD 8  HPD write monitor
      // Observes: dut.u_core_tile.mem_resp_write_valid_i
      //           dut.u_core_tile.mem_resp_write_i
      // ----------------------------------------------------------
      begin : hpd_wr_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_wr_resp_valid && tb_hpd_wr_resp_ready));
          if (hpd_wr_resp_obs.mem_resp_w_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_WR PASS] t=%0t  id=0x%0h  completed",
              $time, hpd_wr_resp_obs.mem_resp_w_id);
            hpd_wr_pass++;
          end else begin
            $display("[HPD_WR FAIL] t=%0t  error response", $time);
            hpd_wr_fail++;
          end
          @(posedge clk);
        end
      end

    join   // all 8 threads complete

    // Release all forces cleanly
    release dut.u_core_tile.io_mem_acquire_valid;
    release dut.u_core_tile.io_mem_acquire_bits_addr_block;
    release dut.u_core_tile.brom_req_valid_o;
    release dut.u_core_tile.brom_req_address_o;
    release dut.u_core_tile.mem_req_read_valid_o;
    release dut.u_core_tile.mem_req_read_o;
    release dut.u_core_tile.mem_resp_read_ready_o;
    release dut.u_core_tile.mem_req_write_valid_o;
    release dut.u_core_tile.mem_req_write_o;
    release dut.u_core_tile.mem_req_write_data_valid_o;
    release dut.u_core_tile.mem_req_write_data_o;
    release dut.u_core_tile.mem_resp_write_ready_o;

    // ================================================================
    // FINAL REPORT
    // ================================================================
    $display("");
    $display("------------------------------------------------------------");
    $display("  TOP-LEVEL MEMORY SUBSYSTEM TEST  (core tile port forcing)");
    $display("------------------------------------------------------------");
    $display("");
    $display("  Forced at  : dut.u_core_tile.<port>  (top_tile output ports)");
    $display("  Observed at: dut.u_core_tile.<port>  (top_tile input ports)");
    $display("               + dut.icache_resp_* / dut.brom_resp_* wires");
    $display("");
    $display("  -- Cache Traffic (end-to-end) ---------------------------");
    $display("  ICache  reads : %0d PASS  %0d FAIL", icache_pass, icache_fail);
    $display("  uCache  reads : %0d PASS  %0d FAIL", ucache_pass, ucache_fail);
    $display("  HPD     reads : %0d PASS  %0d FAIL", hpd_rd_pass, hpd_rd_fail);
    $display("  HPD     writes: %0d PASS  %0d FAIL", hpd_wr_pass, hpd_wr_fail);
    $display("  TOTAL         : %0d PASS  %0d FAIL  (of %0d)",
      icache_pass + ucache_pass + hpd_rd_pass + hpd_wr_pass,
      icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail,
      N_TESTS * 4);
    $display("");
    $display("  -- AXI ID Checks ----------------------------------------");
    $display("  ID width  errors : %0d", id_width_errors);
    $display("  ID order  errors : %0d", order_errors);
    if (id_width_errors == 0 && order_errors == 0)
      $display("  AXI ID CHECKS    : ALL PASSED");
    else
      $display("  AXI ID CHECKS    : *** FAILURES DETECTED ***");
    $display("");
    begin
      automatic int total_fail =
        icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail +
        id_width_errors + order_errors;
      if (total_fail == 0)
        $display("  ?  OVERALL: ALL CHECKS PASSED ?");
      else
        $display("  ?  OVERALL: %0d FAILURE(S) DETECTED ?", total_fail);
    end
    $display("------------------------------------------------------------");
    $finish;
  end

endmodule
*/

/*
`timescale 1ns/1ps
// ============================================================================
// tb_sargantana_soc_axi_wrap
// ----------------------------------------------------------------------------
// Top-level testbench for sargantana_soc_axi_wrap.
//
// STRATEGY
// --------
//   Rather than waiting for the real core to generate traffic (which requires
//   valid boot-ROM / instruction memory), this TB uses SystemVerilog
//   hierarchical `force` statements to OVERRIDE the internal wires that
//   connect top_tile to u_axi_bridge inside sargantana_soc_axi_wrap.
//
//   The wires being forced are declared in sargantana_soc_axi_wrap itself:
//
//     dut.icache_req_valid      dut.icache_req_paddr
//     dut.brom_req_valid        dut.brom_req_addr
//     dut.hpd_rd_req_valid      dut.hpd_rd_req        dut.hpd_rd_resp_ready
//     dut.hpd_wr_req_valid      dut.hpd_wr_req
//     dut.hpd_wr_data_valid     dut.hpd_wr_data
//
//   This lets us verify that the MEMORY SUBSYSTEM (u_axi_bridge) correctly:
//      Transports ICache  requests  ? AXI AR  ? R  responses ? ICache  resp
//      Transports uCache  requests  ? AXI AR  ? R  responses ? uCache  resp
//      Transports HPD     read req  ? AXI AR  ? R  responses ? HPD     rd resp
//      Transports HPD     write req ? AXI AW+W? B  response  ? HPD     wr resp
//
//   The same AXI memory model and ID checks from tb_sargantana_soc_wrap_ids
//   are reused unchanged.
//
// CHECKS (identical to lower-level TB)
// ------
//   1. End-to-end cache traffic passes without data errors
//   2. ID width   every AR/AW at master port has a valid MstIdWidth ID
//   3. ID serialisation  no duplicate in-flight IDs at master port
//   4. Response routing  each cache interface sees exactly N_TESTS responses
// ============================================================================

module tb_sargantana_soc_axi_wrap;

  import drac_pkg::*;
  import hpdcache_pkg::*;
  import test_types_pkg::*;

  // ==========================================================================
  // Parameters
  // ==========================================================================
  localparam int unsigned AxiAddrWidth    = 64;
  localparam int unsigned AxiDataWidth    = 64;
  localparam int unsigned AxiUserWidth    = 1;
  localparam int unsigned SlvIdWidth      = 8;
  localparam int unsigned MstIdWidth      = 4;
  localparam int unsigned SerMaxTxns      = 16;
  localparam int unsigned SerMaxUniqIds   = 16;
  localparam int unsigned SerMaxTxnsPerId = 16;

  localparam int unsigned N_TESTS = 5;  // transactions per cache interface

  // ==========================================================================
  // Clock & reset
  // ==========================================================================
  logic clk  = 0;
  logic rstn = 0;
  always #5 clk = ~clk;   // 100 MHz

  int unsigned cyc_cnt = 0;
  always @(posedge clk) begin
    cyc_cnt <= cyc_cnt + 1;
    if (cyc_cnt > 2_000_000) begin
      $display("\n[FATAL] WATCHDOG: simulation exceeded 2M cycles  deadlock!");
      $finish;
    end
  end

  initial begin
    rstn = 0;
    repeat (8) @(posedge clk);
    @(negedge clk);
    rstn = 1;
  end

  // ==========================================================================
  // TB-side cache stimulus signals
  // (These will be forced onto the DUT's internal wires)
  // ==========================================================================

  // ICache
  logic        tb_icache_req_valid  = 0;
  logic [39:0] tb_icache_req_paddr  = '0;

  // uCache / BROM
  logic        tb_brom_req_valid    = 0;
  logic [39:0] tb_brom_req_addr     = '0;

  // HPDCache read
  logic                   tb_hpd_rd_req_valid  = 0;
  hpdcache_mem_req_t      tb_hpd_rd_req        = '0;
  logic                   tb_hpd_rd_resp_ready = 1;

  // HPDCache write
  logic                   tb_hpd_wr_req_valid  = 0;
  hpdcache_mem_req_t      tb_hpd_wr_req        = '0;
  logic                   tb_hpd_wr_data_valid = 0;
  hpdcache_mem_req_w_t    tb_hpd_wr_data       = '0;
  logic                   tb_hpd_wr_resp_ready = 1;

  // ==========================================================================
  // DUT  sargantana_soc_axi_wrap (full top with core + bridge)
  // ==========================================================================

  // Flat AXI4 master port wires (TB acts as memory)
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

  // Other DUT top-level ports (tied off  we don't test core logic here)
  logic         soft_rstn  = 1;
  logic [63:0]  reset_addr = 64'h8000_0000;
  logic [63:0]  core_id    = 64'h0;
  logic [63:0]  time_val   = 64'h0;
  logic         time_irq   = 0;
  logic [1:0]   irq        = 2'b00;
  logic         soft_irq   = 0;
  logic         pmu_l2_hit = 0;

  // Debug tied off
  logic       dbg_halt_req     = 0, dbg_resume_req  = 0;
  logic       dbg_progbuf_req  = 0, dbg_halt_on_rst = 0;
  logic       dbg_rnm_rd_en    = 0, dbg_rf_en       = 0;
  logic       dbg_rf_we        = 0;
  reg_t       dbg_rnm_rd_reg   = '0;
  phreg_t     dbg_rf_preg      = '0;
  bus64_t     dbg_rf_wdata     = '0;

  // Debug outputs (not checked)
  logic       dbg_halt_ack, dbg_halted, dbg_resume_ack, dbg_running;
  logic       dbg_progbuf_ack, dbg_parked, dbg_unavail;
  logic       dbg_progbuf_xcpt, dbg_havereset;
  phreg_t     dbg_rnm_rd_resp;
  bus64_t     dbg_rf_rdata;
  visa_signals_t visa;

  sargantana_soc_axi_wrap #(
    .AxiAddrWidth    ( AxiAddrWidth    ),
    .AxiDataWidth    ( AxiDataWidth    ),
    .AxiUserWidth    ( AxiUserWidth    ),
    .SlvIdWidth      ( SlvIdWidth      ),
    .MstIdWidth      ( MstIdWidth      ),
    .SerMaxTxns      ( SerMaxTxns      ),
    .SerMaxUniqIds   ( SerMaxUniqIds   ),
    .SerMaxTxnsPerId ( SerMaxTxnsPerId )
  ) dut (
    .clk_i                       ( clk              ),
    .rstn_i                      ( rstn             ),
    .soft_rstn_i                 ( soft_rstn        ),
    .reset_addr_i                ( reset_addr       ),
    .core_id_i                   ( core_id          ),
    .time_irq_i                  ( time_irq         ),
    .irq_i                       ( irq              ),
    .soft_irq_i                  ( soft_irq         ),
    .time_i                      ( time_val         ),
    .io_core_pmu_l2_hit_i        ( pmu_l2_hit       ),
    .debug_contr_halt_req_i      ( dbg_halt_req     ),
    .debug_contr_resume_req_i    ( dbg_resume_req   ),
    .debug_contr_progbuf_req_i   ( dbg_progbuf_req  ),
    .debug_contr_halt_on_reset_i ( dbg_halt_on_rst  ),
    .debug_reg_rnm_read_en_i     ( dbg_rnm_rd_en    ),
    .debug_reg_rnm_read_reg_i    ( dbg_rnm_rd_reg   ),
    .debug_reg_rf_en_i           ( dbg_rf_en        ),
    .debug_reg_rf_preg_i         ( dbg_rf_preg      ),
    .debug_reg_rf_we_i           ( dbg_rf_we        ),
    .debug_reg_rf_wdata_i        ( dbg_rf_wdata     ),
    .debug_contr_halt_ack_o      ( dbg_halt_ack     ),
    .debug_contr_halted_o        ( dbg_halted       ),
    .debug_contr_resume_ack_o    ( dbg_resume_ack   ),
    .debug_contr_running_o       ( dbg_running      ),
    .debug_contr_progbuf_ack_o   ( dbg_progbuf_ack  ),
    .debug_contr_parked_o        ( dbg_parked       ),
    .debug_contr_unavail_o       ( dbg_unavail      ),
    .debug_contr_progbuf_xcpt_o  ( dbg_progbuf_xcpt ),
    .debug_contr_havereset_o     ( dbg_havereset    ),
    .debug_reg_rnm_read_resp_o   ( dbg_rnm_rd_resp  ),
    .debug_reg_rf_rdata_o        ( dbg_rf_rdata     ),
    .visa_o                      ( visa             ),
    // AXI master (TB is the memory)
    .axi_mst_ar_valid_o          ( axi_ar_valid     ),
    .axi_mst_ar_ready_i          ( axi_ar_ready     ),
    .axi_mst_ar_addr_o           ( axi_ar_addr      ),
    .axi_mst_ar_id_o             ( axi_ar_id        ),
    .axi_mst_ar_len_o            ( axi_ar_len       ),
    .axi_mst_ar_size_o           ( axi_ar_size      ),
    .axi_mst_ar_burst_o          ( axi_ar_burst     ),
    .axi_mst_ar_lock_o           ( axi_ar_lock      ),
    .axi_mst_ar_cache_o          ( axi_ar_cache     ),
    .axi_mst_ar_prot_o           ( axi_ar_prot      ),
    .axi_mst_ar_qos_o            ( axi_ar_qos       ),
    .axi_mst_ar_region_o         ( axi_ar_region    ),
    .axi_mst_ar_user_o           ( axi_ar_user      ),
    .axi_mst_r_valid_i           ( axi_r_valid      ),
    .axi_mst_r_ready_o           ( axi_r_ready      ),
    .axi_mst_r_data_i            ( axi_r_data       ),
    .axi_mst_r_id_i              ( axi_r_id         ),
    .axi_mst_r_last_i            ( axi_r_last       ),
    .axi_mst_r_resp_i            ( axi_r_resp       ),
    .axi_mst_r_user_i            ( axi_r_user       ),
    .axi_mst_aw_valid_o          ( axi_aw_valid     ),
    .axi_mst_aw_ready_i          ( axi_aw_ready     ),
    .axi_mst_aw_addr_o           ( axi_aw_addr      ),
    .axi_mst_aw_id_o             ( axi_aw_id        ),
    .axi_mst_aw_len_o            ( axi_aw_len       ),
    .axi_mst_aw_size_o           ( axi_aw_size      ),
    .axi_mst_aw_burst_o          ( axi_aw_burst     ),
    .axi_mst_aw_lock_o           ( axi_aw_lock      ),
    .axi_mst_aw_cache_o          ( axi_aw_cache     ),
    .axi_mst_aw_prot_o           ( axi_aw_prot      ),
    .axi_mst_aw_qos_o            ( axi_aw_qos       ),
    .axi_mst_aw_region_o         ( axi_aw_region    ),
    .axi_mst_aw_user_o           ( axi_aw_user      ),
    .axi_mst_aw_atop_o           ( axi_aw_atop      ),
    .axi_mst_w_valid_o           ( axi_w_valid      ),
    .axi_mst_w_ready_i           ( axi_w_ready      ),
    .axi_mst_w_data_o            ( axi_w_data       ),
    .axi_mst_w_strb_o            ( axi_w_strb       ),
    .axi_mst_w_last_o            ( axi_w_last       ),
    .axi_mst_w_user_o            ( axi_w_user       ),
    .axi_mst_b_valid_i           ( axi_b_valid      ),
    .axi_mst_b_ready_o           ( axi_b_ready      ),
    .axi_mst_b_id_i              ( axi_b_id         ),
    .axi_mst_b_resp_i            ( axi_b_resp       ),
    .axi_mst_b_user_i            ( axi_b_user       )
  );

  // Free-running time
  always @(posedge clk or negedge rstn)
    if (!rstn) time_val <= 0;
    else       time_val <= time_val + 1;

  // ==========================================================================
  // HIERARCHICAL FORCE BLOCK
  // Override the internal wires inside sargantana_soc_axi_wrap that connect
  // top_tile outputs to u_axi_bridge inputs.  This completely replaces the
  // core as the traffic source for the memory subsystem test.
  //
  // Wire path inside dut:
  //   dut.icache_req_valid       ? dut.u_axi_bridge.icache_req_valid_i
  //   dut.icache_req_paddr       ? dut.u_axi_bridge.icache_req_paddr_i
  //   dut.brom_req_valid         ? dut.u_axi_bridge.brom_req_valid_i
  //   dut.brom_req_addr          ? dut.u_axi_bridge.brom_req_addr_i
  //   dut.hpd_rd_req_valid       ? dut.u_axi_bridge.hpd_rd_req_valid_i
  //   dut.hpd_rd_req             ? dut.u_axi_bridge.hpd_rd_req_i
  //   dut.hpd_wr_req_valid       ? dut.u_axi_bridge.hpd_wr_req_valid_i
  //   dut.hpd_wr_req             ? dut.u_axi_bridge.hpd_wr_req_i
  //   dut.hpd_wr_data_valid      ? dut.u_axi_bridge.hpd_wr_data_valid_i
  //   dut.hpd_wr_data            ? dut.u_axi_bridge.hpd_wr_data_i
  //
  // The response wires (icache_resp_*, brom_resp_*, hpd_rd_resp_*, 
  // hpd_wr_resp_*) flow back from u_axi_bridge to top_tile and are
  // monitored via the same hierarchical paths.
  // ==========================================================================
  initial begin
    // Wait until reset is released before asserting forces
    wait (rstn);
    repeat (2) @(posedge clk);

    // --- Force request inputs into the bridge ---
    force dut.icache_req_valid  = tb_icache_req_valid;
    force dut.icache_req_paddr  = tb_icache_req_paddr;
    force dut.brom_req_valid    = tb_brom_req_valid;
    force dut.brom_req_addr     = tb_brom_req_addr;
    force dut.hpd_rd_req_valid  = tb_hpd_rd_req_valid;
    force dut.hpd_rd_req        = tb_hpd_rd_req;
    force dut.hpd_wr_req_valid  = tb_hpd_wr_req_valid;
    force dut.hpd_wr_req        = tb_hpd_wr_req;
    force dut.hpd_wr_data_valid = tb_hpd_wr_data_valid;
    force dut.hpd_wr_data       = tb_hpd_wr_data;

    // Also force the ready/resp-ready signals that flow FROM the TB
    // back toward the bridge response outputs
    force dut.hpd_rd_resp_ready = tb_hpd_rd_resp_ready;
    force dut.hpd_wr_resp_ready = tb_hpd_wr_resp_ready;

    $display("[FORCE] Hierarchical force active  core outputs overridden at t=%0t", $time);
  end

  // ==========================================================================
  // Response monitoring via hierarchical read-back
  // We observe the bridge's response outputs by reading dut internal wires.
  // ==========================================================================

  // Aliases for readability
  wire        icache_resp_valid = dut.icache_resp_valid;
  wire[511:0] icache_resp_data  = dut.icache_resp_data;

  wire        brom_resp_valid   = dut.brom_resp_valid;
  wire[511:0] brom_resp_data    = dut.brom_resp_data;

  wire        hpd_rd_resp_valid = dut.hpd_rd_resp_valid;
  wire        hpd_rd_req_ready  = dut.hpd_rd_req_ready;   // bridge ? core ready

  wire        hpd_wr_resp_valid = dut.hpd_wr_resp_valid;
  wire        hpd_wr_req_ready  = dut.hpd_wr_req_ready;
  wire        hpd_wr_data_ready = dut.hpd_wr_data_ready;

  // HPD response structs (read back from dut internal wires)
  hpdcache_mem_resp_r_t hpd_rd_resp_obs;
  hpdcache_mem_resp_w_t hpd_wr_resp_obs;
  assign hpd_rd_resp_obs = dut.hpd_rd_resp;
  assign hpd_wr_resp_obs = dut.hpd_wr_resp;

  // ==========================================================================
  // CHECK 2  ID WIDTH
  // ==========================================================================
  int unsigned id_width_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_ar_valid && axi_ar_ready) begin
        if (^axi_ar_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AR id X/Z: 0x%0h", $time, axi_ar_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AR id=0x%0h addr=0x%0h len=%0d",
                   $time, axi_ar_id, axi_ar_addr, axi_ar_len);
      end
      if (axi_aw_valid && axi_aw_ready) begin
        if (^axi_aw_id === 1'bx) begin
          $display("[ID_WIDTH FAIL] t=%0t  AW id X/Z: 0x%0h", $time, axi_aw_id);
          id_width_errors++;
        end else
          $display("[ID_WIDTH OK ] t=%0t  AW id=0x%0h addr=0x%0h",
                   $time, axi_aw_id, axi_aw_addr);
      end
    end
  end

  // ==========================================================================
  // CHECK 3  ID SERIALIZATION
  // ==========================================================================
  logic [MstIdWidth-1:0] inflight_ar_ids[$];
  logic [MstIdWidth-1:0] inflight_aw_ids[$];
  int unsigned           ser_errors = 0;

  always @(posedge clk) begin
    if (rstn) begin
      if (axi_ar_valid && axi_ar_ready) begin
        foreach (inflight_ar_ids[i])
          if (inflight_ar_ids[i] === axi_ar_id) begin
            $display("[SER FAIL] t=%0t  AR id=0x%0h already in-flight!", $time, axi_ar_id);
            ser_errors++;
          end
        inflight_ar_ids.push_back(axi_ar_id);
      end
      if (axi_r_valid && axi_r_ready && axi_r_last) begin
        for (int i = 0; i < inflight_ar_ids.size(); i++)
          if (inflight_ar_ids[i] === axi_r_id) begin
            inflight_ar_ids.delete(i); break;
          end
      end
      if (axi_aw_valid && axi_aw_ready) begin
        foreach (inflight_aw_ids[i])
          if (inflight_aw_ids[i] === axi_aw_id) begin
            $display("[SER FAIL] t=%0t  AW id=0x%0h already in-flight!", $time, axi_aw_id);
            ser_errors++;
          end
        inflight_aw_ids.push_back(axi_aw_id);
      end
      if (axi_b_valid && axi_b_ready) begin
        for (int i = 0; i < inflight_aw_ids.size(); i++)
          if (inflight_aw_ids[i] === axi_b_id) begin
            inflight_aw_ids.delete(i); break;
          end
      end
    end
  end

  // ==========================================================================
  // AXI MEMORY MODEL  (chaotic slave  same as lower-level TB)
  // ==========================================================================
  typedef struct {
    logic [MstIdWidth-1:0]   id;
    logic [7:0]              len;
    logic [AxiAddrWidth-1:0] base_addr;
    logic [7:0]              beat_idx;
  } rd_txn_t;

  rd_txn_t               rd_queue[$];
  logic [MstIdWidth-1:0] b_id_queue[$];
  logic [MstIdWidth-1:0] pending_aw_ids[$];
  int unsigned           aw_rcvd       = 0;
  int unsigned           w_burst_rcvd  = 0;

  // Randomised backpressure
  always @(posedge clk) begin
    if (!rstn) begin
      axi_ar_ready <= 0;
      axi_aw_ready <= 0;
      axi_w_ready  <= 0;
    end else begin
      axi_ar_ready <= ($urandom() % 100) < 75;
      axi_aw_ready <= ($urandom() % 100) < 75;
      axi_w_ready  <= ($urandom() % 100) < 80;
    end
  end

  // Enqueue accepted AR
  always @(posedge clk)
    if (rstn && axi_ar_valid && axi_ar_ready)
      rd_queue.push_back('{
        id        : axi_ar_id,
        len       : axi_ar_len,
        base_addr : axi_ar_addr,
        beat_idx  : 8'h00
      });

  // R channel driver
  logic    r_active = 0;
  rd_txn_t r_cur;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      axi_r_valid <= 0;
      r_active    <= 0;
    end else begin
      if (axi_r_valid && axi_r_ready) begin
        if (r_cur.len == 0) begin
          axi_r_valid <= 0;
          r_active    <= 0;
        end else begin
          r_cur.len     -= 1;
          r_cur.beat_idx = r_cur.beat_idx + 1;
          axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
          axi_r_last  <= (r_cur.len == 0);
          axi_r_valid <= (($urandom() % 100) < 80);
        end
      end else if (!axi_r_valid) begin
        if (r_active) begin
          if (($urandom() % 100) < 80) begin
            axi_r_valid <= 1;
            axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
            axi_r_last  <= (r_cur.len == 0);
          end
        end else if (rd_queue.size() > 0) begin
          if (($urandom() % 100) < 80) begin
            r_cur        = rd_queue.pop_front();
            r_active    <= 1;
            axi_r_valid <= 1;
            axi_r_id    <= r_cur.id;
            axi_r_data  <= {r_cur.base_addr[31:0], 24'h0, r_cur.beat_idx};
            axi_r_last  <= (r_cur.len == 0);
            axi_r_resp  <= 2'b00;
            axi_r_user  <= '0;
          end
        end
      end
    end
  end

  // AW acceptance
  always @(posedge clk)
    if (rstn && axi_aw_valid && axi_aw_ready) begin
      pending_aw_ids.push_back(axi_aw_id);
      aw_rcvd++;
    end

  // W burst completion
  always @(posedge clk)
    if (rstn && axi_w_valid && axi_w_ready && axi_w_last)
      w_burst_rcvd++;

  // Pair AW + W ? B queue
  always @(posedge clk)
    if (rstn && aw_rcvd > 0 && w_burst_rcvd > 0) begin
      b_id_queue.push_back(pending_aw_ids.pop_front());
      aw_rcvd--;
      w_burst_rcvd--;
    end

  // B channel driver
  always @(posedge clk or negedge rstn) begin
    if (!rstn) axi_b_valid <= 0;
    else begin
      if (axi_b_valid && axi_b_ready)
        axi_b_valid <= 0;
      else if (!axi_b_valid && b_id_queue.size() > 0 && ($urandom() % 100) < 80) begin
        axi_b_valid <= 1;
        axi_b_id    <= b_id_queue.pop_front();
        axi_b_resp  <= 2'b00;
        axi_b_user  <= '0;
      end
    end
  end

  // ==========================================================================
  // SCOREBOARD COUNTERS
  // ==========================================================================
  int unsigned icache_pass = 0, icache_fail = 0;
  int unsigned ucache_pass = 0, ucache_fail = 0;
  int unsigned hpd_rd_pass = 0, hpd_rd_fail = 0;
  int unsigned hpd_wr_pass = 0, hpd_wr_fail = 0;

  // Scoreboard queues (store sent addresses to verify responses)
  logic [39:0] icache_addr_sb[$];
  logic [39:0] ucache_addr_sb[$];
  logic [39:0] hpd_rd_addr_sb[$];

  // ==========================================================================
  // MAIN STIMULUS + MONITOR THREADS
  // Mirrors the fork/join structure of tb_sargantana_soc_wrap_ids exactly,
  // but reads back responses through the hierarchical wire aliases above.
  // ==========================================================================
  initial begin
    // Initialise AXI memory-model outputs
    axi_r_valid = 0; axi_r_data = '0; axi_r_id = '0;
    axi_r_last  = 0; axi_r_resp = '0; axi_r_user = '0;
    axi_b_valid = 0; axi_b_id   = '0; axi_b_resp = '0; axi_b_user = '0;

    wait (rstn);
    // Wait a bit more so force block above has applied
    repeat (10) @(posedge clk);

    $display("[TB] Force active. Starting cache traffic injection...");

    fork

      // ------------------------------------------------------------
      // THREAD 1  ICache driver
      // ------------------------------------------------------------
      begin : icache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h3F;
          @(posedge clk);
          tb_icache_req_valid = 1;
          tb_icache_req_paddr = addr;
          @(posedge clk);
          tb_icache_req_valid = 0;
          icache_addr_sb.push_back(addr);
          // Wait for the bridge to deliver the response
          @(posedge clk iff icache_resp_valid);
        end
      end

      // ------------------------------------------------------------
      // THREAD 2  ICache monitor
      // ------------------------------------------------------------
      begin : icache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff icache_resp_valid);
          if (^icache_resp_data !== 1'bx) begin
            $display("[ICACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, icache_addr_sb.pop_front(), icache_resp_data[63:0]);
            icache_pass++;
          end else begin
            $display("[ICACHE FAIL] t=%0t  data contains X/Z", $time);
            icache_fail++;
          end
          @(posedge clk);
        end
      end

      // ------------------------------------------------------------
      // THREAD 3  uCache / BROM driver
      // ------------------------------------------------------------
      begin : ucache_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {2'($urandom_range(0,3)), 38'($urandom())} & ~40'h7;
          @(posedge clk);
          tb_brom_req_valid = 1;
          tb_brom_req_addr  = addr;
          @(posedge clk);
          tb_brom_req_valid = 0;
          ucache_addr_sb.push_back(addr);
          @(posedge clk iff brom_resp_valid);
        end
      end

      // ------------------------------------------------------------
      // THREAD 4  uCache monitor
      // ------------------------------------------------------------
      begin : ucache_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff brom_resp_valid);
          if (^brom_resp_data[63:0] !== 1'bx) begin
            $display("[UCACHE PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, ucache_addr_sb.pop_front(), brom_resp_data[63:0]);
            ucache_pass++;
          end else begin
            $display("[UCACHE FAIL] t=%0t  data contains X/Z", $time);
            ucache_fail++;
          end
          @(posedge clk);
        end
      end

      // ------------------------------------------------------------
      // THREAD 5  HPD read driver
      // ------------------------------------------------------------
      begin : hpd_rd_drv
        for (int i = 0; i < N_TESTS; i++) begin
          automatic logic [39:0] addr =
            {$urandom(), $urandom()} & ~39'h3F;
          tb_hpd_rd_req.mem_req_addr    = addr;
          tb_hpd_rd_req.mem_req_id      = $urandom();
          tb_hpd_rd_req.mem_req_len     = 0;
          tb_hpd_rd_req.mem_req_size    = 6;
          tb_hpd_rd_req.mem_req_command = HPDCACHE_MEM_READ;
          tb_hpd_rd_req_valid = 1;
          // Wait for bridge to accept (hpd_rd_req_ready comes from bridge)
          do @(posedge clk); while (!hpd_rd_req_ready);
          tb_hpd_rd_req_valid = 0;
          hpd_rd_addr_sb.push_back(addr);
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ------------------------------------------------------------
      // THREAD 6  HPD read monitor
      // ------------------------------------------------------------
      begin : hpd_rd_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_rd_resp_valid && tb_hpd_rd_resp_ready));
          if (hpd_rd_resp_obs.mem_resp_r_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_RD PASS] t=%0t  addr=0x%0h  data[63:0]=0x%0h",
              $time, hpd_rd_addr_sb.pop_front(),
              hpd_rd_resp_obs.mem_resp_r_data[63:0]);
            hpd_rd_pass++;
          end else begin
            $display("[HPD_RD FAIL] t=%0t  error response", $time);
            hpd_rd_fail++;
          end
          @(posedge clk);
        end
      end

      // ------------------------------------------------------------
      // THREAD 7  HPD write driver
      // ------------------------------------------------------------
      begin : hpd_wr_drv
        for (int i = 0; i < N_TESTS; i++) begin
          tb_hpd_wr_req.mem_req_addr    = {$urandom(), $urandom()} & ~39'h3F;
          tb_hpd_wr_req.mem_req_id      = $urandom();
          tb_hpd_wr_req.mem_req_size    = 6;
          tb_hpd_wr_req.mem_req_command = HPDCACHE_MEM_WRITE;
          tb_hpd_wr_data.mem_req_w_data = {$urandom(), $urandom(),
                                           $urandom(), $urandom()};
          tb_hpd_wr_data.mem_req_w_be   = ~0;
          tb_hpd_wr_req_valid  = 1;
          tb_hpd_wr_data_valid = 1;
          // Handshake both req and data
          fork
            begin
              do @(posedge clk); while (!hpd_wr_req_ready);
              tb_hpd_wr_req_valid = 0;
            end
            begin
              do @(posedge clk); while (!hpd_wr_data_ready);
              tb_hpd_wr_data_valid = 0;
            end
          join
          if (($urandom() % 100) < 50)
            repeat ($urandom() % 5) @(posedge clk);
        end
      end

      // ------------------------------------------------------------
      // THREAD 8  HPD write monitor
      // ------------------------------------------------------------
      begin : hpd_wr_mon
        for (int i = 0; i < N_TESTS; i++) begin
          @(posedge clk iff (hpd_wr_resp_valid && tb_hpd_wr_resp_ready));
          if (hpd_wr_resp_obs.mem_resp_w_error == HPDCACHE_MEM_RESP_OK) begin
            $display("[HPD_WR PASS] t=%0t  id=0x%0h completed",
              $time, hpd_wr_resp_obs.mem_resp_w_id);
            hpd_wr_pass++;
          end else begin
            $display("[HPD_WR FAIL] t=%0t  error response", $time);
            hpd_wr_fail++;
          end
          @(posedge clk);
        end
      end

    join   // all 8 threads complete

    // Release all forces cleanly
    release dut.icache_req_valid;
    release dut.icache_req_paddr;
    release dut.brom_req_valid;
    release dut.brom_req_addr;
    release dut.hpd_rd_req_valid;
    release dut.hpd_rd_req;
    release dut.hpd_wr_req_valid;
    release dut.hpd_wr_req;
    release dut.hpd_wr_data_valid;
    release dut.hpd_wr_data;
    release dut.hpd_rd_resp_ready;
    release dut.hpd_wr_resp_ready;

    // ================================================================
    // FINAL REPORT
    // ================================================================
    $display("");
    $display("--------------------------------------------------------");
    $display("  TOP-LEVEL MEMORY SUBSYSTEM TEST  (force-inject mode)");
    $display("--------------------------------------------------------");
    $display("");
    $display("  -- Cache Traffic (end-to-end) -----------------------");
    $display("  ICache  reads : %0d PASS  %0d FAIL", icache_pass, icache_fail);
    $display("  uCache  reads : %0d PASS  %0d FAIL", ucache_pass, ucache_fail);
    $display("  HPD     reads : %0d PASS  %0d FAIL", hpd_rd_pass, hpd_rd_fail);
    $display("  HPD     writes: %0d PASS  %0d FAIL", hpd_wr_pass, hpd_wr_fail);
    $display("  TOTAL         : %0d PASS  %0d FAIL  (of %0d)",
      icache_pass + ucache_pass + hpd_rd_pass + hpd_wr_pass,
      icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail,
      N_TESTS * 4);
    $display("");
    $display("  -- AXI ID Serialiser Checks -------------------------");
    $display("  ID width  errors : %0d", id_width_errors);
    $display("  Serialiser errors: %0d", ser_errors);
    if (id_width_errors == 0 && ser_errors == 0)
      $display("  ID SERIALISER    : ALL CHECKS PASSED");
    else
      $display("  ID SERIALISER    : *** FAILURES DETECTED ***");
    $display("");
    begin
      automatic int total_fail =
        icache_fail + ucache_fail + hpd_rd_fail + hpd_wr_fail +
        id_width_errors + ser_errors;
      if (total_fail == 0)
        $display("  ?  OVERALL: ALL CHECKS PASSED ?");
      else
        $display("  ?  OVERALL: %0d FAILURE(S) DETECTED ?", total_fail);
    end
    $display("--------------------------------------------------------");
    $finish;
  end

endmodule
*/
