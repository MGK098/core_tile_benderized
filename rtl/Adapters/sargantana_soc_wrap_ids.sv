
`include "axi/typedef.svh"
`include "axi/assign.svh"

module sargantana_soc_wrap_ids
  import hpdcache_pkg::*;
  import test_types_pkg::*;
#(
  parameter int unsigned AxiAddrWidth      = 64,
  parameter int unsigned AxiDataWidth      = 64,
  parameter int unsigned AxiUserWidth      = 1,
  parameter int unsigned SlvIdWidth        = 2,
  parameter int unsigned MstIdWidth        = 4,
  parameter int unsigned SerMaxTxns        = 16,
  parameter int unsigned SerMaxUniqIds     = 16,
  parameter int unsigned SerMaxTxnsPerId   = 16,
  
  // Use the structs defined in test_types_pkg
  parameter type hpdcache_mem_req_t        = test_types_pkg::hpdcache_mem_req_t,
  parameter type hpdcache_mem_req_w_t      = test_types_pkg::hpdcache_mem_req_w_t,
  parameter type hpdcache_mem_resp_r_t     = test_types_pkg::hpdcache_mem_resp_r_t,
  parameter type hpdcache_mem_resp_w_t     = test_types_pkg::hpdcache_mem_resp_w_t
)(
  input  logic clk_i,
  input  logic rst_ni,

  // ICache interface
  input  logic                     icache_req_valid_i,
  input  logic [39:0] icache_req_paddr_i,
  output logic                     icache_resp_valid_o,
  output logic [511:0]             icache_resp_data_o,
  output logic                     icache_resp_ack_o,

  // uCache / BROM interface
  input  logic                     brom_req_valid_i,
  input  logic [39:0] brom_req_addr_i,
  output logic                     brom_resp_valid_o,
  output logic [511:0]             brom_resp_data_o,

  // HPDCache read interface
  input  logic                     hpd_rd_req_valid_i,
  output logic                     hpd_rd_req_ready_o,
  input  hpdcache_mem_req_t        hpd_rd_req_i,
  output logic                     hpd_rd_resp_valid_o,
  input  logic                     hpd_rd_resp_ready_i,
  output hpdcache_mem_resp_r_t     hpd_rd_resp_o,

  // HPDCache write interface
  input  logic                     hpd_wr_req_valid_i,
  output logic                     hpd_wr_req_ready_o,
  input  hpdcache_mem_req_t        hpd_wr_req_i,
  input  logic                     hpd_wr_data_valid_i,
  output logic                     hpd_wr_data_ready_o,
  input  hpdcache_mem_req_w_t      hpd_wr_data_i,
  output logic                     hpd_wr_resp_valid_o,
  input  logic                     hpd_wr_resp_ready_i,
  output hpdcache_mem_resp_w_t     hpd_wr_resp_o,

  // AXI4 master output
  output logic                        axi_mst_ar_valid_o,
  input  logic                        axi_mst_ar_ready_i,
  output logic[AxiAddrWidth-1:0]      axi_mst_ar_addr_o,
  output logic [MstIdWidth-1:0]       axi_mst_ar_id_o,
  output logic [7:0]                  axi_mst_ar_len_o,
  output logic[2:0]                   axi_mst_ar_size_o,
  output logic [1:0]                  axi_mst_ar_burst_o,
  output logic                        axi_mst_ar_lock_o,
  output logic [3:0]                  axi_mst_ar_cache_o,
  output logic [2:0]                  axi_mst_ar_prot_o,
  output logic[3:0]                   axi_mst_ar_qos_o,
  output logic [3:0]                  axi_mst_ar_region_o,
  output logic[AxiUserWidth-1:0]     axi_mst_ar_user_o,

  input  logic                        axi_mst_r_valid_i,
  output logic                        axi_mst_r_ready_o,
  input  logic[AxiDataWidth-1:0]      axi_mst_r_data_i,
  input  logic[MstIdWidth-1:0]        axi_mst_r_id_i,
  input  logic                        axi_mst_r_last_i,
  input  logic [1:0]                  axi_mst_r_resp_i,
  input  logic[AxiUserWidth-1:0]     axi_mst_r_user_i,

  output logic                        axi_mst_aw_valid_o,
  input  logic                        axi_mst_aw_ready_i,
  output logic[AxiAddrWidth-1:0]      axi_mst_aw_addr_o,
  output logic[MstIdWidth-1:0]        axi_mst_aw_id_o,
  output logic [7:0]                  axi_mst_aw_len_o,
  output logic[2:0]                   axi_mst_aw_size_o,
  output logic [1:0]                  axi_mst_aw_burst_o,
  output logic                        axi_mst_aw_lock_o,
  output logic [3:0]                  axi_mst_aw_cache_o,
  output logic[2:0]                   axi_mst_aw_prot_o,
  output logic [3:0]                  axi_mst_aw_qos_o,
  output logic [3:0]                  axi_mst_aw_region_o,
  output logic[AxiUserWidth-1:0]     axi_mst_aw_user_o,
  output logic[5:0]                  axi_mst_aw_atop_o,

  output logic                        axi_mst_w_valid_o,
  input  logic                        axi_mst_w_ready_i,
  output logic[AxiDataWidth-1:0]      axi_mst_w_data_o,
  output logic[(AxiDataWidth/8)-1:0]  axi_mst_w_strb_o,
  output logic                        axi_mst_w_last_o,
  output logic[AxiUserWidth-1:0]     axi_mst_w_user_o,

  input  logic                        axi_mst_b_valid_i,
  output logic                        axi_mst_b_ready_o,
  input  logic[MstIdWidth-1:0]        axi_mst_b_id_i,
  input  logic [1:0]                  axi_mst_b_resp_i,
  input  logic[AxiUserWidth-1:0]      axi_mst_b_user_i
);

  // MUX ID Width calculation (SlvIdWidth + bits needed to represent 3 ports)
  localparam int unsigned MuxIdWidth = SlvIdWidth + $clog2(32'd3);

  // ---------------------------------------------------------
  // 1. AXI Type Definitions
  // ---------------------------------------------------------
  
  // Slave Layer (Raw inputs from caches)
  `AXI_TYPEDEF_AW_CHAN_T(slv_aw_t, logic[AxiAddrWidth-1:0], logic [SlvIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_W_CHAN_T (slv_w_t,  logic[AxiDataWidth-1:0], logic[(AxiDataWidth/8)-1:0], logic[AxiUserWidth-1:0])
  `AXI_TYPEDEF_B_CHAN_T (slv_b_t,  logic[SlvIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_AR_CHAN_T(slv_ar_t, logic[AxiAddrWidth-1:0], logic[SlvIdWidth-1:0], logic[AxiUserWidth-1:0])
  `AXI_TYPEDEF_R_CHAN_T (slv_r_t,  logic [AxiDataWidth-1:0], logic [SlvIdWidth-1:0], logic [AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_REQ_T    (slv_req_t,  slv_aw_t, slv_w_t, slv_ar_t)
  `AXI_TYPEDEF_RESP_T   (slv_resp_t, slv_b_t, slv_r_t)

  // Mux Layer (After arbitration, before Serializer)
  `AXI_TYPEDEF_AW_CHAN_T(mux_aw_t, logic[AxiAddrWidth-1:0], logic [MuxIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_W_CHAN_T (mux_w_t,  logic [AxiDataWidth-1:0], logic[(AxiDataWidth/8)-1:0], logic [AxiUserWidth-1:0])
  `AXI_TYPEDEF_B_CHAN_T (mux_b_t,  logic[MuxIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_AR_CHAN_T(mux_ar_t, logic[AxiAddrWidth-1:0], logic[MuxIdWidth-1:0], logic[AxiUserWidth-1:0])
  `AXI_TYPEDEF_R_CHAN_T (mux_r_t,  logic [AxiDataWidth-1:0], logic [MuxIdWidth-1:0], logic [AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_REQ_T    (mux_req_t,  mux_aw_t, mux_w_t, mux_ar_t)
  `AXI_TYPEDEF_RESP_T   (mux_resp_t, mux_b_t, mux_r_t)

  // Master Layer (Final output to Cheshire Crossbar)
  `AXI_TYPEDEF_AW_CHAN_T(mst_aw_t, logic[AxiAddrWidth-1:0], logic [MstIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_W_CHAN_T (mst_w_t,  logic [AxiDataWidth-1:0], logic[(AxiDataWidth/8)-1:0], logic [AxiUserWidth-1:0])
  `AXI_TYPEDEF_B_CHAN_T (mst_b_t,  logic[MstIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_AR_CHAN_T(mst_ar_t, logic[AxiAddrWidth-1:0], logic[MstIdWidth-1:0], logic [AxiUserWidth-1:0])
  `AXI_TYPEDEF_R_CHAN_T (mst_r_t,  logic [AxiDataWidth-1:0], logic [MstIdWidth-1:0], logic[AxiUserWidth-1:0]) 
  `AXI_TYPEDEF_REQ_T    (mst_req_t,  mst_aw_t, mst_w_t, mst_ar_t)
  `AXI_TYPEDEF_RESP_T   (mst_resp_t, mst_b_t, mst_r_t)

  // Struct Wires
  slv_req_t  [2:0] slv_req;
  slv_resp_t [2:0] slv_resp;
  
  mux_req_t        mux_req;
  mux_resp_t       mux_resp;
  
  mst_req_t        mst_req;
  mst_resp_t       mst_resp;

  // ==========================================================================
  // 1. ICache wrapper
  // ==========================================================================
  sargantana_icache_axi_wrap #(
    .PHY_ADDR_SIZE  ( 40           ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .axi_ar_chan_t  ( slv_ar_t     ),
    .axi_r_chan_t   ( slv_r_t      )
  ) u_icache (
    .clk_i,
    .rstn_i                   ( rst_ni               ),
    .icache_ifill_req_valid_i ( icache_req_valid_i   ),
    .icache_ifill_req_paddr_i ( icache_req_paddr_i   ),
    .ifill_resp_valid_o       ( icache_resp_valid_o  ),
    .ifill_resp_data_o        ( icache_resp_data_o   ),
    .ifill_resp_ack_o         ( icache_resp_ack_o    ),
    .axi_ar_valid_o           ( slv_req[0].ar_valid  ),
    .axi_ar_ready_i           ( slv_resp[0].ar_ready ),
    .axi_ar_o                 ( slv_req[0].ar        ),
    .axi_r_valid_i            ( slv_resp[0].r_valid  ),
    .axi_r_ready_o            ( slv_req[0].r_ready   ),
    .axi_r_i                  ( slv_resp[0].r        )
  );
  assign slv_req[0].aw_valid = 1'b0;
  assign slv_req[0].aw       = '0;
  assign slv_req[0].w_valid  = 1'b0;
  assign slv_req[0].w        = '0;
  assign slv_req[0].b_ready  = 1'b1;

  // ==========================================================================
  // 2. uCache / BROM wrapper
  // ==========================================================================
  sargantana_ucache_axi_wrap #(
    .PHY_ADDR_SIZE  ( 40           ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .axi_ar_chan_t  ( slv_ar_t     ),
    .axi_r_chan_t   ( slv_r_t      )
  ) u_ucache (
    .clk_i,
    .rstn_i           ( rst_ni               ),
    .brom_req_valid_i,
    .brom_req_addr_i,
    .brom_resp_valid_o,
    .brom_resp_data_o,
    .axi_ar_valid_o   ( slv_req[1].ar_valid  ),
    .axi_ar_ready_i   ( slv_resp[1].ar_ready ),
    .axi_ar_o         ( slv_req[1].ar        ),
    .axi_r_valid_i    ( slv_resp[1].r_valid  ),
    .axi_r_ready_o    ( slv_req[1].r_ready   ),
    .axi_r_i          ( slv_resp[1].r        )
  );
  assign slv_req[1].aw_valid = 1'b0;
  assign slv_req[1].aw       = '0;
  assign slv_req[1].w_valid  = 1'b0;
  assign slv_req[1].w        = '0;
  assign slv_req[1].b_ready  = 1'b1;

  // ==========================================================================
  // 3. HPDCache wrapper
  // ==========================================================================
  sargantana_hpdcache_axi_wrap #(
    .AXI_DATA_WIDTH        ( AxiDataWidth          ),
    .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
    .hpdcache_mem_req_w_t  ( hpdcache_mem_req_w_t  ),
    .hpdcache_mem_resp_r_t ( hpdcache_mem_resp_r_t ),
    .hpdcache_mem_resp_w_t ( hpdcache_mem_resp_w_t ),
    .axi_ar_chan_t         ( slv_ar_t              ),
    .axi_aw_chan_t         ( slv_aw_t              ),
    .axi_r_chan_t          ( slv_r_t               ),
    .axi_w_chan_t          ( slv_w_t               ),
    .axi_b_chan_t          ( slv_b_t               )
  ) u_hpdcache (
    .clk_i,
    .rstn_i                    ( rst_ni              ),
    .mem_req_read_valid_i      ( hpd_rd_req_valid_i  ),
    .mem_req_read_ready_o      ( hpd_rd_req_ready_o  ),
    .mem_req_read_i            ( hpd_rd_req_i        ),
    .mem_resp_read_valid_o     ( hpd_rd_resp_valid_o ),
    .mem_resp_read_ready_i     ( hpd_rd_resp_ready_i ),
    .mem_resp_read_o           ( hpd_rd_resp_o       ),
    .mem_req_write_valid_i     ( hpd_wr_req_valid_i  ),
    .mem_req_write_ready_o     ( hpd_wr_req_ready_o  ),
    .mem_req_write_i           ( hpd_wr_req_i        ),
    .mem_req_write_data_valid_i( hpd_wr_data_valid_i ),
    .mem_req_write_data_ready_o( hpd_wr_data_ready_o ),
    .mem_req_write_data_i      ( hpd_wr_data_i       ),
    .mem_resp_write_valid_o    ( hpd_wr_resp_valid_o ),
    .mem_resp_write_ready_i    ( hpd_wr_resp_ready_i ),
    .mem_resp_write_o          ( hpd_wr_resp_o       ),
    .axi_ar_valid_o            ( slv_req[2].ar_valid  ),
    .axi_ar_ready_i            ( slv_resp[2].ar_ready ),
    .axi_ar_o                  ( slv_req[2].ar        ),
    .axi_r_valid_i             ( slv_resp[2].r_valid  ),
    .axi_r_ready_o             ( slv_req[2].r_ready   ),
    .axi_r_i                   ( slv_resp[2].r        ),
    .axi_aw_valid_o            ( slv_req[2].aw_valid  ),
    .axi_aw_ready_i            ( slv_resp[2].aw_ready ),
    .axi_aw_o                  ( slv_req[2].aw        ),
    .axi_w_valid_o             ( slv_req[2].w_valid   ),
    .axi_w_ready_i             ( slv_resp[2].w_ready  ),
    .axi_w_o                   ( slv_req[2].w         ),
    .axi_b_valid_i             ( slv_resp[2].b_valid  ),
    .axi_b_ready_o             ( slv_req[2].b_ready   ),
    .axi_b_i                   ( slv_resp[2].b        )
  );

  // ==========================================================================
  // 4. AXI Mux (3 -> 1)
  // Combines 3 Cache Master ports into 1 stream. 
  // Adds 2 bits to the ID.
  // ==========================================================================
  axi_mux #(
    .SlvAxiIDWidth ( SlvIdWidth   ),
    .slv_aw_chan_t ( slv_aw_t     ),
    .mst_aw_chan_t ( mux_aw_t     ),
    .w_chan_t      ( slv_w_t      ),
    .slv_b_chan_t  ( slv_b_t      ),
    .mst_b_chan_t  ( mux_b_t      ),
    .slv_ar_chan_t ( slv_ar_t     ),
    .mst_ar_chan_t ( mux_ar_t     ),
    .slv_r_chan_t  ( slv_r_t      ),
    .mst_r_chan_t  ( mux_r_t      ),
    .slv_req_t     ( slv_req_t    ),
    .slv_resp_t    ( slv_resp_t   ),
    .mst_req_t     ( mux_req_t    ),
    .mst_resp_t    ( mux_resp_t   ),
    .NoSlvPorts    ( 32'd3        ),
    .MaxWTrans     ( SerMaxTxns   ),
    .FallThrough   ( 1'b0         ),
    .SpillAw       ( 1'b1         ),
    .SpillW        ( 1'b0         ),
    .SpillB        ( 1'b0         ),
    .SpillAr       ( 1'b1         ),
    .SpillR        ( 1'b0         )
  ) u_axi_mux (
    .clk_i,
    .rst_ni,
    .test_i      ( 1'b0     ),
    .slv_reqs_i  ( slv_req  ),
    .slv_resps_o ( slv_resp ),
    .mst_req_o   ( mux_req  ),
    .mst_resp_i  ( mux_resp )
  );

  // ==========================================================================
  // 5. AXI ID Serialize
  // Takes the MuxIdWidth and converts it to the final Cheshire MstIdWidth.
  // ==========================================================================
  axi_id_serialize #(
    .AxiSlvPortIdWidth      ( MuxIdWidth      ),
    .AxiSlvPortMaxTxns      ( SerMaxTxns      ),
    .AxiMstPortIdWidth      ( MstIdWidth      ),
    .AxiMstPortMaxUniqIds   ( SerMaxUniqIds   ),
    .AxiMstPortMaxTxnsPerId ( SerMaxTxnsPerId ),
    .AxiAddrWidth           ( AxiAddrWidth    ),
    .AxiDataWidth           ( AxiDataWidth    ),
    .AxiUserWidth           ( AxiUserWidth    ),
    .AtopSupport            ( 1'b1            ),
    .slv_req_t              ( mux_req_t       ),
    .slv_resp_t             ( mux_resp_t      ),
    .mst_req_t              ( mst_req_t       ),
    .mst_resp_t             ( mst_resp_t      )
  ) u_axi_id_serialize (
    .clk_i      ( clk_i    ),
    .rst_ni     ( rst_ni   ),
    .slv_req_i  ( mux_req  ),
    .slv_resp_o ( mux_resp ),
    .mst_req_o  ( mst_req  ),
    .mst_resp_i ( mst_resp )
  );

  // ==========================================================================
  // 6. Flat AXI Master Output Assignments
  // Assign the Serializer's output to the module's flat IOs.
  // ==========================================================================
  assign axi_mst_ar_valid_o  = mst_req.ar_valid;
  assign axi_mst_ar_addr_o   = mst_req.ar.addr;
  assign axi_mst_ar_id_o     = mst_req.ar.id;
  assign axi_mst_ar_len_o    = mst_req.ar.len;
  assign axi_mst_ar_size_o   = mst_req.ar.size;
  assign axi_mst_ar_burst_o  = mst_req.ar.burst;
  assign axi_mst_ar_lock_o   = mst_req.ar.lock;
  assign axi_mst_ar_cache_o  = mst_req.ar.cache;
  assign axi_mst_ar_prot_o   = mst_req.ar.prot;
  assign axi_mst_ar_qos_o    = mst_req.ar.qos;
  assign axi_mst_ar_region_o = mst_req.ar.region;
  assign axi_mst_ar_user_o   = mst_req.ar.user;
  assign mst_resp.ar_ready   = axi_mst_ar_ready_i;

  assign mst_resp.r_valid    = axi_mst_r_valid_i;
  assign mst_resp.r.data     = axi_mst_r_data_i;
  assign mst_resp.r.id       = axi_mst_r_id_i;
  assign mst_resp.r.last     = axi_mst_r_last_i;
  assign mst_resp.r.resp     = axi_mst_r_resp_i;
  assign mst_resp.r.user     = axi_mst_r_user_i;
  assign axi_mst_r_ready_o   = mst_req.r_ready;

  assign axi_mst_aw_valid_o  = mst_req.aw_valid;
  assign axi_mst_aw_addr_o   = mst_req.aw.addr;
  assign axi_mst_aw_id_o     = mst_req.aw.id;
  assign axi_mst_aw_len_o    = mst_req.aw.len;
  assign axi_mst_aw_size_o   = mst_req.aw.size;
  assign axi_mst_aw_burst_o  = mst_req.aw.burst;
  assign axi_mst_aw_lock_o   = mst_req.aw.lock;
  assign axi_mst_aw_cache_o  = mst_req.aw.cache;
  assign axi_mst_aw_prot_o   = mst_req.aw.prot;
  assign axi_mst_aw_qos_o    = mst_req.aw.qos;
  assign axi_mst_aw_region_o = mst_req.aw.region;
  assign axi_mst_aw_user_o   = mst_req.aw.user;
  assign axi_mst_aw_atop_o   = mst_req.aw.atop;
  assign mst_resp.aw_ready   = axi_mst_aw_ready_i;

  assign axi_mst_w_valid_o   = mst_req.w_valid;
  assign axi_mst_w_data_o    = mst_req.w.data;
  assign axi_mst_w_strb_o    = mst_req.w.strb;
  assign axi_mst_w_last_o    = mst_req.w.last;
  assign axi_mst_w_user_o    = mst_req.w.user;
  assign mst_resp.w_ready    = axi_mst_w_ready_i;

  assign mst_resp.b_valid    = axi_mst_b_valid_i;
  assign mst_resp.b.id       = axi_mst_b_id_i;
  assign mst_resp.b.resp     = axi_mst_b_resp_i;
  assign mst_resp.b.user     = axi_mst_b_user_i;
  assign axi_mst_b_ready_o   = mst_req.b_ready;

endmodule