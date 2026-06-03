`timescale 1ns/1ps

//`include "sargantana_typedef.svh"

module sargantana_soc_axi_wrap
  import drac_pkg::*;
  import sargantana_icache_pkg::*;
  import mmu_pkg::*;
  import hpdcache_pkg::*;
  import test_types_pkg::*;
#(
  // Core Parameters
  parameter drac_pkg::drac_cfg_t DracCfg = drac_pkg::DracDefaultConfig,

  // AXI Subsystem Parameters
  parameter int unsigned AxiAddrWidth      = 64,
  parameter int unsigned AxiDataWidth      = 64,
  parameter int unsigned AxiUserWidth      = 1,
  parameter int unsigned SlvIdWidth        = 8,   // HPDCache natively uses 8 bits
  parameter int unsigned MstIdWidth        = 4,   // Cheshire expects 4 bits
  parameter int unsigned SerMaxTxns        = 16,
  parameter int unsigned SerMaxUniqIds     = 16,
  parameter int unsigned SerMaxTxnsPerId   = 16
)(
  // ---------------------------------------------------------
  // Core Clocks & Resets
  // ---------------------------------------------------------
  input  logic                 clk_i,
  input  logic                 rstn_i,
  input  logic                 soft_rstn_i,
  input  logic [AxiAddrWidth-1:0] reset_addr_i,
  input  logic [63:0]          core_id_i,

`ifdef INTEL_FSCAN_CTECH
  input  logic                 fscan_rstbypen,
`endif
`ifdef PITON_CINCORANCH
  input  logic [1:0]           boot_main_id_i,
`endif
`ifdef EXTERNAL_HPM_EVENT_NUM
  input  logic[`EXTERNAL_HPM_EVENT_NUM-1: 0] external_hpm_i,
`endif

  // ---------------------------------------------------------
  // Interrupts & PMU
  // ---------------------------------------------------------
  input  logic                 time_irq_i,
  input  logic [1:0]           irq_i,
  input  logic                 soft_irq_i,
  input  logic [63:0]          time_i,
  input  logic                 io_core_pmu_l2_hit_i,

  // ---------------------------------------------------------
  // Debug Module
  // ---------------------------------------------------------
  input  logic                 debug_contr_halt_req_i,
  input  logic                 debug_contr_resume_req_i,
  input  logic                 debug_contr_progbuf_req_i,
  input  logic                 debug_contr_halt_on_reset_i,
  input  logic                 debug_reg_rnm_read_en_i,
  input  reg_t                 debug_reg_rnm_read_reg_i,
  input  logic                 debug_reg_rf_en_i,
  input  phreg_t               debug_reg_rf_preg_i,
  input  logic                 debug_reg_rf_we_i,
  input  bus64_t               debug_reg_rf_wdata_i,

  output logic                 debug_contr_halt_ack_o,
  output logic                 debug_contr_halted_o,
  output logic                 debug_contr_resume_ack_o,
  output logic                 debug_contr_running_o,
  output logic                 debug_contr_progbuf_ack_o,
  output logic                 debug_contr_parked_o,
  output logic                 debug_contr_unavail_o,
  output logic                 debug_contr_progbuf_xcpt_o,
  output logic                 debug_contr_havereset_o,
  output phreg_t               debug_reg_rnm_read_resp_o,
  output bus64_t               debug_reg_rf_rdata_o,
  output visa_signals_t        visa_o,

`ifdef CONF_SARGANTANA_ENABLE_PCR
  input  logic                 pcr_req_ready_i,
  input  logic                 pcr_resp_valid_i,
  input  logic [63:0]          pcr_resp_data_i,
  input  logic [63:0]          pcr_resp_core_id_i,
  output logic                 pcr_req_valid_o,
  output logic [11:0]          pcr_req_addr_o,
  output logic [63:0]          pcr_req_data_o,
  output logic [2:0]           pcr_req_we_o,
  output logic [63:0]          pcr_req_core_id_o,
`endif

  // ---------------------------------------------------------
  // FLAT AXI4 MASTER PORT (To Cheshire Crossbar)
  // ---------------------------------------------------------
  output logic                        axi_mst_ar_valid_o,
  input  logic                        axi_mst_ar_ready_i,
  output logic [AxiAddrWidth-1:0]     axi_mst_ar_addr_o,
  output logic [MstIdWidth-1:0]       axi_mst_ar_id_o,
  output logic [7:0]                  axi_mst_ar_len_o,
  output logic [2:0]                  axi_mst_ar_size_o,
  output logic [1:0]                  axi_mst_ar_burst_o,
  output logic                        axi_mst_ar_lock_o,
  output logic [3:0]                  axi_mst_ar_cache_o,
  output logic [2:0]                  axi_mst_ar_prot_o,
  output logic [3:0]                  axi_mst_ar_qos_o,
  output logic[3:0]                  axi_mst_ar_region_o,
  output logic[AxiUserWidth-1:0]     axi_mst_ar_user_o,

  input  logic                        axi_mst_r_valid_i,
  output logic                        axi_mst_r_ready_o,
  input  logic [AxiDataWidth-1:0]     axi_mst_r_data_i,
  input  logic [MstIdWidth-1:0]       axi_mst_r_id_i,
  input  logic                        axi_mst_r_last_i,
  input  logic[1:0]                  axi_mst_r_resp_i,
  input  logic[AxiUserWidth-1:0]     axi_mst_r_user_i,

  output logic                        axi_mst_aw_valid_o,
  input  logic                        axi_mst_aw_ready_i,
  output logic [AxiAddrWidth-1:0]     axi_mst_aw_addr_o,
  output logic [MstIdWidth-1:0]       axi_mst_aw_id_o,
  output logic [7:0]                  axi_mst_aw_len_o,
  output logic [2:0]                  axi_mst_aw_size_o,
  output logic [1:0]                  axi_mst_aw_burst_o,
  output logic                        axi_mst_aw_lock_o,
  output logic [3:0]                  axi_mst_aw_cache_o,
  output logic[2:0]                  axi_mst_aw_prot_o,
  output logic [3:0]                  axi_mst_aw_qos_o,
  output logic [3:0]                  axi_mst_aw_region_o,
  output logic [AxiUserWidth-1:0]     axi_mst_aw_user_o,
  output logic [5:0]                  axi_mst_aw_atop_o,

  output logic                        axi_mst_w_valid_o,
  input  logic                        axi_mst_w_ready_i,
  output logic [AxiDataWidth-1:0]     axi_mst_w_data_o,
  output logic [(AxiDataWidth/8)-1:0] axi_mst_w_strb_o,
  output logic                        axi_mst_w_last_o,
  output logic [AxiUserWidth-1:0]     axi_mst_w_user_o,

  input  logic                        axi_mst_b_valid_i,
  output logic                        axi_mst_b_ready_o,
  input  logic [MstIdWidth-1:0]       axi_mst_b_id_i,
  input  logic [1:0]                  axi_mst_b_resp_i,
  input  logic [AxiUserWidth-1:0]     axi_mst_b_user_i
);

  // ==========================================================================
  // Internal Subsystem Wires
  // ==========================================================================
  
  // ICache Wires
  logic        icache_req_valid;
  logic [39:0] icache_req_paddr;
  logic        icache_resp_valid;
  logic [511:0]icache_resp_data;
  logic        icache_resp_ack;

  // UCache (BROM) Wires
  logic        brom_req_valid;
  logic [39:0] brom_req_addr;
  logic        brom_resp_valid;
  logic [511:0]brom_resp_data;

  // HPDCache Wires
  logic                 hpd_rd_req_valid;
  logic                 hpd_rd_req_ready;
  test_types_pkg::hpdcache_mem_req_t    hpd_rd_req;
  logic                 hpd_rd_resp_valid;
  logic                 hpd_rd_resp_ready;
  test_types_pkg::hpdcache_mem_resp_r_t hpd_rd_resp;

  logic                 hpd_wr_req_valid;
  logic                 hpd_wr_req_ready;
  test_types_pkg::hpdcache_mem_req_t    hpd_wr_req;
  logic                 hpd_wr_data_valid;
  logic                 hpd_wr_data_ready;
  test_types_pkg::hpdcache_mem_req_w_t  hpd_wr_data;
  logic                 hpd_wr_resp_valid;
  logic                 hpd_wr_resp_ready;
  test_types_pkg::hpdcache_mem_resp_w_t hpd_wr_resp;

  // Shared L2 Response Bus Mapping (Merging ICache and UCache responses)
  logic         io_mem_grant_valid;
  logic [511:0] io_mem_grant_bits_data;
  logic [1:0]   io_mem_grant_bits_addr_beat;

  assign io_mem_grant_valid = icache_resp_valid | brom_resp_valid;
  assign io_mem_grant_bits_data = icache_resp_valid ? icache_resp_data : brom_resp_data;
  assign io_mem_grant_bits_addr_beat = {2{icache_resp_ack}};

  // ==========================================================================
  // 1. Instantiate the Sargantana Core Top Tile
  // ==========================================================================
  top_tile #(
    .DracCfg ( DracCfg )
  ) u_core_tile (
    .clk_i                       ( clk_i ),
    .rstn_i                      ( rstn_i ),
    .soft_rstn_i                 ( soft_rstn_i ),
    .reset_addr_i                ( reset_addr_i ),
    .core_id_i                   ( core_id_i ),
    
  `ifdef INTEL_FSCAN_CTECH
    .fscan_rstbypen              ( fscan_rstbypen ),
  `endif
  `ifdef PITON_CINCORANCH
    .boot_main_id_i              ( boot_main_id_i ),
  `endif
  `ifdef EXTERNAL_HPM_EVENT_NUM
    .external_hpm_i              ( external_hpm_i ),
  `endif

    // Debug
    .debug_contr_halt_req_i      ( debug_contr_halt_req_i ),
    .debug_contr_resume_req_i    ( debug_contr_resume_req_i ),
    .debug_contr_progbuf_req_i   ( debug_contr_progbuf_req_i ),
    .debug_contr_halt_on_reset_i ( debug_contr_halt_on_reset_i ),
    .debug_reg_rnm_read_en_i     ( debug_reg_rnm_read_en_i ),
    .debug_reg_rnm_read_reg_i    ( debug_reg_rnm_read_reg_i ),
    .debug_reg_rf_en_i           ( debug_reg_rf_en_i ),
    .debug_reg_rf_preg_i         ( debug_reg_rf_preg_i ),
    .debug_reg_rf_we_i           ( debug_reg_rf_we_i ),
    .debug_reg_rf_wdata_i        ( debug_reg_rf_wdata_i ),

    .debug_contr_halt_ack_o      ( debug_contr_halt_ack_o ),
    .debug_contr_halted_o        ( debug_contr_halted_o ),
    .debug_contr_resume_ack_o    ( debug_contr_resume_ack_o ),
    .debug_contr_running_o       ( debug_contr_running_o ),
    .debug_contr_progbuf_ack_o   ( debug_contr_progbuf_ack_o ),
    .debug_contr_parked_o        ( debug_contr_parked_o ),
    .debug_contr_unavail_o       ( debug_contr_unavail_o ),
    .debug_contr_progbuf_xcpt_o  ( debug_contr_progbuf_xcpt_o ),
    .debug_contr_havereset_o     ( debug_contr_havereset_o ),
    .debug_reg_rnm_read_resp_o   ( debug_reg_rnm_read_resp_o ),
    .debug_reg_rf_rdata_o        ( debug_reg_rf_rdata_o ),
    .visa_o                      ( visa_o ),

    // PMU / Interrupts
    .io_core_pmu_l2_hit_i        ( io_core_pmu_l2_hit_i ),
    .time_irq_i                  ( time_irq_i ),
    .irq_i                       ( irq_i ),
    .soft_irq_i                  ( soft_irq_i ),
    .time_i                      ( time_i ),

  `ifdef CONF_SARGANTANA_ENABLE_PCR
    .pcr_req_ready_i             ( pcr_req_ready_i ),
    .pcr_resp_valid_i            ( pcr_resp_valid_i ),
    .pcr_resp_data_i             ( pcr_resp_data_i ),
    .pcr_resp_core_id_i          ( pcr_resp_core_id_i ),
    .pcr_req_valid_o             ( pcr_req_valid_o ),
    .pcr_req_addr_o              ( pcr_req_addr_o ),
    .pcr_req_data_o              ( pcr_req_data_o ),
    .pcr_req_we_o                ( pcr_req_we_o ),
    .pcr_req_core_id_o           ( pcr_req_core_id_o ),
  `endif

    // I-Cache Output -> To AXI Bridge
    .io_mem_acquire_valid            ( icache_req_valid ),
    .io_mem_acquire_bits_addr_block  ( icache_req_paddr ),
    
    // I-Cache & U-Cache Shared Input <- From AXI Bridge
    .io_mem_grant_valid              ( io_mem_grant_valid ),
    .io_mem_grant_bits_data          ( io_mem_grant_bits_data ),
    .io_mem_grant_bits_addr_beat     ( io_mem_grant_bits_addr_beat ),
    .io_mem_grant_inval              ( 1'b0 ),
    .io_mem_grant_inval_addr         ( 12'b0 ),

    // U-Cache Output -> To AXI Bridge
    .brom_req_valid_o                ( brom_req_valid ),
    .brom_req_address_o              ( brom_req_addr ),

    // HPDCache Outputs -> To AXI Bridge
    .mem_req_read_valid_o            ( hpd_rd_req_valid ),
    .mem_req_read_ready_i            ( hpd_rd_req_ready ),
    .mem_req_read_o                  ( hpd_rd_req ),

    .mem_resp_read_ready_o           ( hpd_rd_resp_ready ),
    .mem_resp_read_valid_i           ( hpd_rd_resp_valid ),
    .mem_resp_read_i                 ( hpd_rd_resp ),

    .mem_req_write_valid_o           ( hpd_wr_req_valid ),
    .mem_req_write_ready_i           ( hpd_wr_req_ready ),
    .mem_req_write_o                 ( hpd_wr_req ),

    .mem_req_write_data_valid_o      ( hpd_wr_data_valid ),
    .mem_req_write_data_ready_i      ( hpd_wr_data_ready ),
    .mem_req_write_data_o            ( hpd_wr_data ),

    .mem_resp_write_ready_o          ( hpd_wr_resp_ready ),
    .mem_resp_write_valid_i          ( hpd_wr_resp_valid ),
    .mem_resp_write_i                ( hpd_wr_resp )
  );

  // ==========================================================================
  // 2. Instantiate the FULL AXI Memory Subsystem Bridge (with Serializer)
  // ==========================================================================
  sargantana_soc_wrap_ids #(
    .AxiAddrWidth      ( AxiAddrWidth ),
    .AxiDataWidth      ( AxiDataWidth ),
    .AxiUserWidth      ( AxiUserWidth ),
    .SlvIdWidth        ( SlvIdWidth ),
    .MstIdWidth        ( MstIdWidth ),
    .SerMaxTxns        ( SerMaxTxns ),
    .SerMaxUniqIds     ( SerMaxUniqIds ),
    .SerMaxTxnsPerId   ( SerMaxTxnsPerId )
  ) u_axi_bridge (
    .clk_i                  ( clk_i ),
    .rst_ni                 ( rstn_i ),

    // ICache
    .icache_req_valid_i     ( icache_req_valid ),
    .icache_req_paddr_i     ( icache_req_paddr ),
    .icache_resp_valid_o    ( icache_resp_valid ),
    .icache_resp_data_o     ( icache_resp_data ),
    .icache_resp_ack_o      ( icache_resp_ack ),

    // UCache (BROM)
    .brom_req_valid_i       ( brom_req_valid ),
    .brom_req_addr_i        ( brom_req_addr ),
    .brom_resp_valid_o      ( brom_resp_valid ),
    .brom_resp_data_o       ( brom_resp_data ),

    // HPD Read
    .hpd_rd_req_valid_i     ( hpd_rd_req_valid ),
    .hpd_rd_req_ready_o     ( hpd_rd_req_ready ),
    .hpd_rd_req_i           ( hpd_rd_req ),
    .hpd_rd_resp_valid_o    ( hpd_rd_resp_valid ),
    .hpd_rd_resp_ready_i    ( hpd_rd_resp_ready ),
    .hpd_rd_resp_o          ( hpd_rd_resp ),

    // HPD Write
    .hpd_wr_req_valid_i     ( hpd_wr_req_valid ),
    .hpd_wr_req_ready_o     ( hpd_wr_req_ready ),
    .hpd_wr_req_i           ( hpd_wr_req ),
    .hpd_wr_data_valid_i    ( hpd_wr_data_valid ),
    .hpd_wr_data_ready_o    ( hpd_wr_data_ready ),
    .hpd_wr_data_i          ( hpd_wr_data ),
    .hpd_wr_resp_valid_o    ( hpd_wr_resp_valid ),
    .hpd_wr_resp_ready_i    ( hpd_wr_resp_ready ),
    .hpd_wr_resp_o          ( hpd_wr_resp ),

    // Flat AXI Master Output (Direct to Cheshire)
    .axi_mst_ar_valid_o     ( axi_mst_ar_valid_o ),
    .axi_mst_ar_ready_i     ( axi_mst_ar_ready_i ),
    .axi_mst_ar_addr_o      ( axi_mst_ar_addr_o  ),
    .axi_mst_ar_id_o        ( axi_mst_ar_id_o    ),
    .axi_mst_ar_len_o       ( axi_mst_ar_len_o   ),
    .axi_mst_ar_size_o      ( axi_mst_ar_size_o  ),
    .axi_mst_ar_burst_o     ( axi_mst_ar_burst_o ),
    .axi_mst_ar_lock_o      ( axi_mst_ar_lock_o  ),
    .axi_mst_ar_cache_o     ( axi_mst_ar_cache_o ),
    .axi_mst_ar_prot_o      ( axi_mst_ar_prot_o  ),
    .axi_mst_ar_qos_o       ( axi_mst_ar_qos_o   ),
    .axi_mst_ar_region_o    ( axi_mst_ar_region_o),
    .axi_mst_ar_user_o      ( axi_mst_ar_user_o  ),

    .axi_mst_r_valid_i      ( axi_mst_r_valid_i  ),
    .axi_mst_r_ready_o      ( axi_mst_r_ready_o  ),
    .axi_mst_r_data_i       ( axi_mst_r_data_i   ),
    .axi_mst_r_id_i         ( axi_mst_r_id_i     ),
    .axi_mst_r_last_i       ( axi_mst_r_last_i   ),
    .axi_mst_r_resp_i       ( axi_mst_r_resp_i   ),
    .axi_mst_r_user_i       ( axi_mst_r_user_i   ),

    .axi_mst_aw_valid_o     ( axi_mst_aw_valid_o ),
    .axi_mst_aw_ready_i     ( axi_mst_aw_ready_i ),
    .axi_mst_aw_addr_o      ( axi_mst_aw_addr_o  ),
    .axi_mst_aw_id_o        ( axi_mst_aw_id_o    ),
    .axi_mst_aw_len_o       ( axi_mst_aw_len_o   ),
    .axi_mst_aw_size_o      ( axi_mst_aw_size_o  ),
    .axi_mst_aw_burst_o     ( axi_mst_aw_burst_o ),
    .axi_mst_aw_lock_o      ( axi_mst_aw_lock_o  ),
    .axi_mst_aw_cache_o     ( axi_mst_aw_cache_o ),
    .axi_mst_aw_prot_o      ( axi_mst_aw_prot_o  ),
    .axi_mst_aw_qos_o       ( axi_mst_aw_qos_o   ),
    .axi_mst_aw_region_o    ( axi_mst_aw_region_o),
    .axi_mst_aw_user_o      ( axi_mst_aw_user_o  ),
    .axi_mst_aw_atop_o      ( axi_mst_aw_atop_o  ),

    .axi_mst_w_valid_o      ( axi_mst_w_valid_o  ),
    .axi_mst_w_ready_i      ( axi_mst_w_ready_i  ),
    .axi_mst_w_data_o       ( axi_mst_w_data_o   ),
    .axi_mst_w_strb_o       ( axi_mst_w_strb_o   ),
    .axi_mst_w_last_o       ( axi_mst_w_last_o   ),
    .axi_mst_w_user_o       ( axi_mst_w_user_o   ),

    .axi_mst_b_valid_i      ( axi_mst_b_valid_i  ),
    .axi_mst_b_ready_o      ( axi_mst_b_ready_o  ),
    .axi_mst_b_id_i         ( axi_mst_b_id_i     ),
    .axi_mst_b_resp_i       ( axi_mst_b_resp_i   ),
    .axi_mst_b_user_i       ( axi_mst_b_user_i   )
  );

endmodule
