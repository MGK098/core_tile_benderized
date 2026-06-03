/*
 * sargantana_ucache_axi_wrap.sv
 *
 * Adapter for uncacheable fetch requests (bootrom / debug buffer).
 *
 * top_tile sends:  brom_req_valid + brom_req_address (40 bits)
 * We send:         AXI AR single beat (uncacheable, len=0)
 * Cheshire returns:AXI R single beat (64 bits)
 * We return:       io_mem_grant_valid + 512-bit data (padded)
 *                  nc_icache_buffer only uses [63:0]
 *
 * Once tested, instantiated inside top_tile alongside
 * sargantana_icache_axi_wrap. Both feed into same io_mem_grant
 * port via a MUX in the top wrapper.
 */
// best  working abd achieved 2.605 CM/MHZ
module sargantana_ucache_axi_wrap #(
    parameter int unsigned PHY_ADDR_SIZE  = drac_pkg::PHY_ADDR_SIZE,
    parameter int unsigned AXI_ADDR_WIDTH = 64,

    parameter type axi_ar_chan_t = logic,
    parameter type axi_r_chan_t  = logic
)(
    input  logic clk_i,
    input  logic rstn_i,

    // ----------------------------------------------------------------
    // FROM top_tile (nc_icache_buffer drives these)
    // ----------------------------------------------------------------
    input  logic                     brom_req_valid_i,   // one cycle pulse
    input  logic [PHY_ADDR_SIZE-1:0]              brom_req_addr_i,    // stable in register

    // ----------------------------------------------------------------
    // TO top_tile (feeds into io_mem_grant - shared with icache)
    // nc_icache_buffer only uses [63:0] of the 512-bit data
    // ----------------------------------------------------------------
    output logic                     brom_resp_valid_o,
    output logic [511:0]             brom_resp_data_o,   // padded to 512 bits

    // ----------------------------------------------------------------
    // TO Cheshire AXI crossbar
    // ----------------------------------------------------------------
    output logic                     axi_ar_valid_o,
    input  logic                     axi_ar_ready_i,
    output axi_ar_chan_t             axi_ar_o,

    // ----------------------------------------------------------------
    // FROM Cheshire AXI crossbar
    // ----------------------------------------------------------------
    input  logic                     axi_r_valid_i,
    output logic                     axi_r_ready_o,
    input  axi_r_chan_t              axi_r_i
);

    // ----------------------------------------------------------------
    // FSM states
    // ----------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE,       // waiting for bootrom request
        WAIT_AR,    // AR sent, waiting for Cheshire to accept
        WAIT_R      // waiting for Cheshire to return data
    } state_t;

    state_t state_q, state_d;

    // ----------------------------------------------------------------
    // Address register
    // nc_icache_buffer holds address stable in paddr_infly_q
    // but we save it too for safety
    // ----------------------------------------------------------------
    logic [PHY_ADDR_SIZE-1:0] addr_q;

    // ----------------------------------------------------------------
    // FSM next state
    // ----------------------------------------------------------------
    always_comb begin
        state_d = state_q;
        case (state_q)

            IDLE:
                if (brom_req_valid_i)
                    // if Cheshire already ready skip WAIT_AR
                    state_d = axi_ar_ready_i ? WAIT_R : WAIT_AR;

            WAIT_AR:
                // hold AR valid until Cheshire accepts
                if (axi_ar_ready_i)
                    state_d = WAIT_R;

            WAIT_R:
                // wait for single R beat
                if (axi_r_valid_i)
                    state_d = IDLE;

            default:
                state_d = IDLE;

        endcase
    end

    // ----------------------------------------------------------------
    // Registers
    // ----------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_q <= IDLE;
            addr_q  <= '0;
        end else begin
            state_q <= state_d;
            // save address when request arrives
            if (state_q == IDLE && brom_req_valid_i)
                addr_q <= brom_req_addr_i;
        end
    end

    // ----------------------------------------------------------------
    // AXI AR output
    // Single beat, uncacheable
    // Hold valid until Cheshire accepts (IDLE or WAIT_AR)
    // ----------------------------------------------------------------
    always_comb begin
        axi_ar_valid_o  = (state_q == IDLE && brom_req_valid_i)
                         || (state_q == WAIT_AR);
        axi_ar_o        = '0;
        // use saved address in WAIT_AR, live address in IDLE
        axi_ar_o.addr   = {{(AXI_ADDR_WIDTH-PHY_ADDR_SIZE){1'b0}},
                           (state_q == WAIT_AR) ? addr_q : brom_req_addr_i};
        axi_ar_o.len    = 8'd0;    // single beat
        axi_ar_o.size   = 3'b011;  // 8 bytes = 64 bits
        axi_ar_o.burst  = 2'b01;   // INCR
        axi_ar_o.cache  = 4'b0000; // uncacheable
        axi_ar_o.prot   = '0;
        axi_ar_o.lock   = '0;
        axi_ar_o.qos    = '0;
        axi_ar_o.region = '0;
        axi_ar_o.user   = '0;
        axi_ar_o.id     = '0;
    end

    // ----------------------------------------------------------------
    // AXI R ready
    // Accept the single R beat when in WAIT_R
    // ----------------------------------------------------------------
    assign axi_r_ready_o = (state_q == WAIT_R);

    // ----------------------------------------------------------------
    // Response back to top_tile
    //
    // Valid pulses once when R beat arrives
    // Data is padded to 512 bits - nc_icache_buffer uses [63:0] only
    // ----------------------------------------------------------------
    assign brom_resp_valid_o = (state_q == WAIT_R) && axi_r_valid_i;
    assign brom_resp_data_o  = {{448{1'b0}}, axi_r_i.data};

endmodule
