module sargantana_hpdcache_axi_wrap
import hpdcache_pkg_sarg::*;
#(
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    parameter type hpdcache_mem_req_t        = logic,
    parameter type hpdcache_mem_req_w_t      = logic,
    parameter type hpdcache_mem_resp_r_t     = logic,
    parameter type hpdcache_mem_resp_w_t     = logic,
    parameter type axi_ar_chan_t             = logic,
    parameter type axi_aw_chan_t             = logic,
    parameter type axi_r_chan_t              = logic,
    parameter type axi_w_chan_t              = logic,
    parameter type axi_b_chan_t              = logic
)(
    input  logic                   clk_i,
    input  logic                   rstn_i,

    input  logic                   mem_req_read_valid_i,
    output logic                   mem_req_read_ready_o,
    input  hpdcache_mem_req_t      mem_req_read_i,

    output logic                   mem_resp_read_valid_o,
    input  logic                   mem_resp_read_ready_i,
    output hpdcache_mem_resp_r_t   mem_resp_read_o,

    input  logic                   mem_req_write_valid_i,
    output logic                   mem_req_write_ready_o,
    input  hpdcache_mem_req_t      mem_req_write_i,

    input  logic                   mem_req_write_data_valid_i,
    output logic                   mem_req_write_data_ready_o,
    input  hpdcache_mem_req_w_t    mem_req_write_data_i,

    output logic                   mem_resp_write_valid_o,
    input  logic                   mem_resp_write_ready_i,
    output hpdcache_mem_resp_w_t   mem_resp_write_o,

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

    hpdcache_mem_to_axi_read_sarg #(
        .AXI_DATA_WIDTH        ( AXI_DATA_WIDTH        ),
        .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
        .hpdcache_mem_resp_r_t ( hpdcache_mem_resp_r_t ),
        .ar_chan_t             ( axi_ar_chan_t         ),
        .r_chan_t              ( axi_r_chan_t          )
    ) i_read_adapter (
        .clk_i          ( clk_i                 ),
        .rstn_i         ( rstn_i                ),
        .req_valid_i    ( mem_req_read_valid_i  ),
        .req_ready_o    ( mem_req_read_ready_o  ),
        .req_i          ( mem_req_read_i        ),
        .resp_ready_i   ( mem_resp_read_ready_i ),
        .resp_valid_o   ( mem_resp_read_valid_o ),
        .resp_o         ( mem_resp_read_o       ),
        .axi_ar_valid_o ( axi_ar_valid_o        ),
        .axi_ar_ready_i ( axi_ar_ready_i        ),
        .axi_ar_o       ( axi_ar_o              ),
        .axi_r_valid_i  ( axi_r_valid_i         ),
        .axi_r_ready_o  ( axi_r_ready_o         ),
        .axi_r_i        ( axi_r_i               )
    );

    hpdcache_mem_to_axi_write_sarg #(
        .AXI_DATA_WIDTH        ( AXI_DATA_WIDTH        ),
        .hpdcache_mem_req_t    ( hpdcache_mem_req_t    ),
        .hpdcache_mem_req_w_t  ( hpdcache_mem_req_w_t  ),
        .hpdcache_mem_resp_w_t ( hpdcache_mem_resp_w_t ),
        .aw_chan_t             ( axi_aw_chan_t         ),
        .w_chan_t              ( axi_w_chan_t          ),
        .b_chan_t              ( axi_b_chan_t          )
    ) i_write_adapter (
        .clk_i              ( clk_i                      ),
        .rstn_i             ( rstn_i                     ),
        .req_valid_i        ( mem_req_write_valid_i      ),
        .req_ready_o        ( mem_req_write_ready_o      ),
        .req_i              ( mem_req_write_i            ),
        .req_data_valid_i   ( mem_req_write_data_valid_i ),
        .req_data_ready_o   ( mem_req_write_data_ready_o ),
        .req_data_i         ( mem_req_write_data_i       ),
        .resp_ready_i       ( mem_resp_write_ready_i     ),
        .resp_valid_o       ( mem_resp_write_valid_o     ),
        .resp_o             ( mem_resp_write_o           ),
        .axi_aw_valid_o     ( axi_aw_valid_o             ),
        .axi_aw_ready_i     ( axi_aw_ready_i             ),
        .axi_aw_o           ( axi_aw_o                   ),
        .axi_w_valid_o      ( axi_w_valid_o              ),
        .axi_w_ready_i      ( axi_w_ready_i              ),
        .axi_w_o            ( axi_w_o                    ),
        .axi_b_valid_i      ( axi_b_valid_i              ),
        .axi_b_ready_o      ( axi_b_ready_o              ),
        .axi_b_i            ( axi_b_i                    )
    );

endmodule
