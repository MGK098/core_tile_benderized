module sargantana_icache_axi_wrap #(
    parameter int unsigned PHY_ADDR_SIZE  = 40,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned AXI_ADDR_WIDTH = 64,

    parameter type axi_ar_chan_t = logic,
    parameter type axi_r_chan_t  = logic
)(
    input  logic clk_i,
    input  logic rstn_i,

    // FROM sargantana_top_icache (miss request)
    input  logic                     icache_ifill_req_valid_i,
    input  logic [PHY_ADDR_SIZE-1:0] icache_ifill_req_paddr_i,

    // TO sargantana_top_icache (refill response)
    output logic                     ifill_resp_valid_o,
    output logic [511:0]             ifill_resp_data_o,
    output logic                     ifill_resp_ack_o,

    // TO AXI crossbar (read address channel)
    output logic                     axi_ar_valid_o,
    input  logic                     axi_ar_ready_i,
    output axi_ar_chan_t             axi_ar_o,

    // FROM AXI crossbar (read data channel)
    input  logic                     axi_r_valid_i,
    output logic                     axi_r_ready_o,
    input  axi_r_chan_t              axi_r_i
);

    localparam int unsigned AXI_BEATS = 512 / AXI_DATA_WIDTH;  // 8
    localparam logic [7:0]  AXI_LEN   = AXI_BEATS - 1;         // 7
    localparam logic [2:0]  AXI_SIZE  = 3'b011;                 // 8 bytes

    typedef enum logic [1:0] {
        IDLE,
        SEND_AR,
        RECEIVING,
        DELIVER        // holds fully assembled line for one cycle
    } state_t;

    state_t                   state_q, state_d;
    logic [PHY_ADDR_SIZE-1:0] addr_q;
    logic [511:0]             line_q;

    always_comb begin
        state_d = state_q;
        case (state_q)
            IDLE:      if (icache_ifill_req_valid_i)
                           state_d = axi_ar_ready_i ? RECEIVING : SEND_AR;
            SEND_AR:   if (axi_ar_ready_i)                state_d = RECEIVING;
            RECEIVING: if (axi_r_valid_i && axi_r_i.last) state_d = DELIVER;
            DELIVER:                                       state_d = IDLE;
            default:   state_d = IDLE;
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_q <= IDLE;
            addr_q  <= '0;
            line_q  <= '0;
        end else begin
            state_q <= state_d;
            case (state_q)
                IDLE: begin
                    if (icache_ifill_req_valid_i) begin
                        addr_q <= icache_ifill_req_paddr_i;
                        line_q <= '0;
                    end
                end
                RECEIVING: begin
                    if (axi_r_valid_i) begin
                        line_q <= {axi_r_i.data, line_q[511 : AXI_DATA_WIDTH]};
                    end
                end
                default: begin
                    addr_q <= addr_q;
                    line_q <= line_q;
                end
            endcase
        end
    end
    
    always_comb begin
        axi_ar_valid_o = (state_q == SEND_AR)
                       || (state_q == IDLE && icache_ifill_req_valid_i);
        axi_ar_o        = '0;
        axi_ar_o.addr   = {{(AXI_ADDR_WIDTH-PHY_ADDR_SIZE){1'b0}},
                           (state_q == IDLE) ? icache_ifill_req_paddr_i : addr_q};
        axi_ar_o.len    = AXI_LEN;
        axi_ar_o.size   = AXI_SIZE;
        axi_ar_o.burst  = 2'b01;    // INCR
        axi_ar_o.cache  = 4'b1011;  // Read-Allocate, Modifiable, Bufferable
    end

    assign axi_r_ready_o = (state_q == RECEIVING);

    assign ifill_resp_valid_o = (state_q == DELIVER);
    assign ifill_resp_data_o  = line_q;
    assign ifill_resp_ack_o   = (state_q == DELIVER);

endmodule
