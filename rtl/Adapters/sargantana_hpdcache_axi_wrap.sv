// sargantana_hpdcache_axi_wrap.sv
//
// Combined wrapper that selects between:
//   UseCustomAdapters=1 : custom _sarg adapters (64-bit AXI out, sequential FSM)
//   UseCustomAdapters=0 : CEA native adapters   (512-bit AXI out, combinational)
//
// When UseCustomAdapters=0 the caller is responsible for placing an
// axi_dw_downsizer between this wrapper and the AXI mux.

module sargantana_hpdcache_axi_wrap
    import hpdcache_pkg_sarg::*;
#(
    // ----------------------------------------------------------------
    //  Selection flag  0=CEA native, 1=custom _sarg
    // ----------------------------------------------------------------
    parameter bit          UseCustomAdapters = 1'b0,

    // AXI data width of the OUTPUT port.
    //   Custom path  : set to 64  (adapters handle beat assembly internally)
    //   CEA native   : set to 512 (caller provides axi_dw_downsizer)
    parameter int unsigned AXI_DATA_WIDTH    = 64,

    // Custom-adapter-specific parameters (ignored when UseCustomAdapters=0)
    parameter int unsigned LINE_W            = 512,  // cache-line width in bits
    parameter int unsigned META_FIFO_DEPTH   = 4,    // read meta-FIFO depth (power-of-2)
    parameter int unsigned N_OUTSTANDING     = 4,    // write outstanding entries (power-of-2)

    // HPDCache interface types (passed from top level)
    parameter type hpdcache_mem_req_t        = logic,
    parameter type hpdcache_mem_req_w_t      = logic,
    parameter type hpdcache_mem_resp_r_t     = logic,
    parameter type hpdcache_mem_resp_w_t     = logic,

    // AXI channel types (sized to AXI_DATA_WIDTH by caller)
    parameter type axi_ar_chan_t             = logic,
    parameter type axi_aw_chan_t             = logic,
    parameter type axi_r_chan_t              = logic,
    parameter type axi_w_chan_t              = logic,
    parameter type axi_b_chan_t              = logic
)(
    // Clock / reset (required by custom adapters; tie-off safe for CEA path)
    input  logic clk_i,
    input  logic rstn_i,

    // ----------------------------------------------------------------
    //  HPDCache read interface
    // ----------------------------------------------------------------
    input  logic                   mem_req_read_valid_i,
    output logic                   mem_req_read_ready_o,
    input  hpdcache_mem_req_t      mem_req_read_i,

    output logic                   mem_resp_read_valid_o,
    input  logic                   mem_resp_read_ready_i,
    output hpdcache_mem_resp_r_t   mem_resp_read_o,

    // ----------------------------------------------------------------
    //  HPDCache write interface
    // ----------------------------------------------------------------
    input  logic                   mem_req_write_valid_i,
    output logic                   mem_req_write_ready_o,
    input  hpdcache_mem_req_t      mem_req_write_i,

    input  logic                   mem_req_write_data_valid_i,
    output logic                   mem_req_write_data_ready_o,
    input  hpdcache_mem_req_w_t    mem_req_write_data_i,

    output logic                   mem_resp_write_valid_o,
    input  logic                   mem_resp_write_ready_i,
    output hpdcache_mem_resp_w_t   mem_resp_write_o,

    // ----------------------------------------------------------------
    //  AXI channels (width = AXI_DATA_WIDTH via channel types)
    // ----------------------------------------------------------------
    output logic                   axi_ar_valid_o,
    input  logic                   axi_ar_ready_i,
    output axi_ar_chan_t           axi_ar_o,

    input  logic                   axi_r_valid_i,
    output logic                   axi_r_ready_o,
    input  axi_r_chan_t            axi_r_i,

    output logic                   axi_aw_valid_o,
    input  logic                   axi_aw_ready_i,
    output axi_aw_chan_t           axi_aw_o,

    output logic                   axi_w_valid_o,
    input  logic                   axi_w_ready_i,
    output axi_w_chan_t            axi_w_o,

    input  logic                   axi_b_valid_i,
    output logic                   axi_b_ready_o,
    input  axi_b_chan_t            axi_b_i
);

    // ================================================================
    //  Generate: select adapter implementation
    // ================================================================
    generate

        // ------------------------------------------------------------
        //  PATH A  Custom _sarg adapters (64-bit, sequential FSMs)
        // ------------------------------------------------------------
        if (UseCustomAdapters) begin : gen_custom

            hpdcache_mem_to_axi_read_sarg #(
                .AXI_DATA_WIDTH        ( AXI_DATA_WIDTH        ),
                .LINE_W                ( LINE_W                ),
                .META_FIFO_DEPTH       ( META_FIFO_DEPTH       ),
                .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
                .hpdcache_mem_resp_r_t ( hpdcache_mem_resp_r_t ),
                .ar_chan_t             ( axi_ar_chan_t          ),
                .r_chan_t              ( axi_r_chan_t           )
            ) i_read_adapter (
                .clk_i          ( clk_i                   ),
                .rstn_i         ( rstn_i                  ),
                .req_valid_i    ( mem_req_read_valid_i    ),
                .req_ready_o    ( mem_req_read_ready_o    ),
                .req_i          ( mem_req_read_i          ),
                .resp_ready_i   ( mem_resp_read_ready_i   ),
                .resp_valid_o   ( mem_resp_read_valid_o   ),
                .resp_o         ( mem_resp_read_o         ),
                .axi_ar_valid_o ( axi_ar_valid_o          ),
                .axi_ar_ready_i ( axi_ar_ready_i          ),
                .axi_ar_o       ( axi_ar_o                ),
                .axi_r_valid_i  ( axi_r_valid_i           ),
                .axi_r_ready_o  ( axi_r_ready_o           ),
                .axi_r_i        ( axi_r_i                 )
            );

            hpdcache_mem_to_axi_write_sarg #(
                .AXI_DATA_WIDTH        ( AXI_DATA_WIDTH        ),
                .N_OUTSTANDING         ( N_OUTSTANDING         ),
                .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
                .hpdcache_mem_req_w_t  ( hpdcache_mem_req_w_t  ),
                .hpdcache_mem_resp_w_t ( hpdcache_mem_resp_w_t ),
                .aw_chan_t             ( axi_aw_chan_t          ),
                .w_chan_t              ( axi_w_chan_t           ),
                .b_chan_t              ( axi_b_chan_t           )
            ) i_write_adapter (
                .clk_i              ( clk_i                       ),
                .rstn_i             ( rstn_i                      ),
                .req_valid_i        ( mem_req_write_valid_i       ),
                .req_ready_o        ( mem_req_write_ready_o       ),
                .req_i              ( mem_req_write_i             ),
                .req_data_valid_i   ( mem_req_write_data_valid_i  ),
                .req_data_ready_o   ( mem_req_write_data_ready_o  ),
                .req_data_i         ( mem_req_write_data_i        ),
                .resp_ready_i       ( mem_resp_write_ready_i      ),
                .resp_valid_o       ( mem_resp_write_valid_o      ),
                .resp_o             ( mem_resp_write_o            ),
                .axi_aw_valid_o     ( axi_aw_valid_o              ),
                .axi_aw_ready_i     ( axi_aw_ready_i              ),
                .axi_aw_o           ( axi_aw_o                    ),
                .axi_w_valid_o      ( axi_w_valid_o               ),
                .axi_w_ready_i      ( axi_w_ready_i               ),
                .axi_w_o            ( axi_w_o                     ),
                .axi_b_valid_i      ( axi_b_valid_i               ),
                .axi_b_ready_o      ( axi_b_ready_o               ),
                .axi_b_i            ( axi_b_i                     )
            );

        // ------------------------------------------------------------
        //  PATH B  CEA native adapters (512-bit, combinational)
        //          Caller must place axi_dw_downsizer downstream.
        // ------------------------------------------------------------
        end else begin : gen_cea_native

            hpdcache_mem_to_axi_read #(
                .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
                .hpdcache_mem_resp_r_t ( hpdcache_mem_resp_r_t ),
                .ar_chan_t             ( axi_ar_chan_t          ),
                .r_chan_t              ( axi_r_chan_t           )
            ) i_read_adapter (
                .req_ready_o    ( mem_req_read_ready_o    ),
                .req_valid_i    ( mem_req_read_valid_i    ),
                .req_i          ( mem_req_read_i          ),
                .resp_ready_i   ( mem_resp_read_ready_i   ),
                .resp_valid_o   ( mem_resp_read_valid_o   ),
                .resp_o         ( mem_resp_read_o         ),
                .axi_ar_valid_o ( axi_ar_valid_o          ),
                .axi_ar_o       ( axi_ar_o                ),
                .axi_ar_ready_i ( axi_ar_ready_i          ),
                .axi_r_valid_i  ( axi_r_valid_i           ),
                .axi_r_i        ( axi_r_i                 ),
                .axi_r_ready_o  ( axi_r_ready_o           )
            );

            hpdcache_mem_to_axi_write #(
                .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
                .hpdcache_mem_req_w_t  ( hpdcache_mem_req_w_t  ),
                .hpdcache_mem_resp_w_t ( hpdcache_mem_resp_w_t ),
                .aw_chan_t             ( axi_aw_chan_t          ),
                .w_chan_t              ( axi_w_chan_t           ),
                .b_chan_t              ( axi_b_chan_t           )
            ) i_write_adapter (
                .req_ready_o        ( mem_req_write_ready_o      ),
                .req_valid_i        ( mem_req_write_valid_i      ),
                .req_i              ( mem_req_write_i            ),
                .req_data_ready_o   ( mem_req_write_data_ready_o ),
                .req_data_valid_i   ( mem_req_write_data_valid_i ),
                .req_data_i         ( mem_req_write_data_i       ),
                .resp_ready_i       ( mem_resp_write_ready_i     ),
                .resp_valid_o       ( mem_resp_write_valid_o     ),
                .resp_o             ( mem_resp_write_o           ),
                .axi_aw_valid_o     ( axi_aw_valid_o             ),
                .axi_aw_o           ( axi_aw_o                   ),
                .axi_aw_ready_i     ( axi_aw_ready_i             ),
                .axi_w_valid_o      ( axi_w_valid_o              ),
                .axi_w_o            ( axi_w_o                    ),
                .axi_w_ready_i      ( axi_w_ready_i              ),
                .axi_b_valid_i      ( axi_b_valid_i              ),
                .axi_b_i            ( axi_b_i                    ),
                .axi_b_ready_o      ( axi_b_ready_o              )
            );

        end

    endgenerate

endmodule


