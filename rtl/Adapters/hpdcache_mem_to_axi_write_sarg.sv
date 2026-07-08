module hpdcache_mem_to_axi_write_sarg
    import hpdcache_pkg_sarg::*;
    import axi_pkg::*;
#(
    parameter  int unsigned AXI_DATA_WIDTH = 64,
    parameter  int unsigned N_OUTSTANDING  = 4,       // must be power of 2, >= 2
    parameter  type hpdcache_mem_req_t     = logic,
    parameter  type hpdcache_mem_req_w_t   = logic,
    parameter  type hpdcache_mem_resp_w_t  = logic,
    parameter  type aw_chan_t              = logic,
    parameter  type w_chan_t               = logic,
    parameter  type b_chan_t               = logic
)(
    input  logic                  clk_i,
    input  logic                  rstn_i,

    output logic                  req_ready_o,
    input  logic                  req_valid_i,
    input  hpdcache_mem_req_t     req_i,

    output logic                  req_data_ready_o,
    input  logic                  req_data_valid_i,
    input  hpdcache_mem_req_w_t   req_data_i,

    input  logic                  resp_ready_i,
    output logic                  resp_valid_o,
    output hpdcache_mem_resp_w_t  resp_o,

    output logic                  axi_aw_valid_o,
    output aw_chan_t               axi_aw_o,
    input  logic                  axi_aw_ready_i,

    output logic                  axi_w_valid_o,
    output w_chan_t                axi_w_o,
    input  logic                  axi_w_ready_i,

    input  logic                  axi_b_valid_i,
    input  b_chan_t                axi_b_i,
    output logic                  axi_b_ready_o
);

    // ----------------------------------------------------------------
    //  Derived constants
    // ----------------------------------------------------------------
    localparam int unsigned AXI_DATA_BYTES  = AXI_DATA_WIDTH / 8;
    localparam int unsigned AXI_BYTES_LOG2  = $clog2(AXI_DATA_BYTES);
    localparam int unsigned LINE_W          = 512;
    localparam int unsigned STRB_W          = LINE_W / 8;
    localparam int unsigned NUM_WORDS       = LINE_W / AXI_DATA_WIDTH;
    localparam int unsigned WORD_IDX_WIDTH  = $clog2(NUM_WORDS);
    localparam int unsigned PTR_W           = $clog2(N_OUTSTANDING);
    localparam int unsigned ID_W            = $bits(axi_b_i.id);

    // ----------------------------------------------------------------
    //  Parameter checks
    // ----------------------------------------------------------------
    initial begin
        assert ((N_OUTSTANDING & (N_OUTSTANDING - 1)) == 0)
            else $fatal(1,
                "[write_adapter] N_OUTSTANDING=%0d must be power of 2",
                N_OUTSTANDING);
        assert (N_OUTSTANDING >= 2)
            else $fatal(1,
                "[write_adapter] N_OUTSTANDING=%0d must be >= 2",
                N_OUTSTANDING);
    end

    // ================================================================
    //  STAGING AREA
    // ================================================================

    hpdcache_mem_req_t          req_q;
    logic                       req_latched_q;
    logic [LINE_W-1:0]          tx_data_q;
    logic [STRB_W-1:0]          tx_strb_q;
    logic                       data_latched_q;
    logic [WORD_IDX_WIDTH-1:0]  word_idx_q;
    logic                       is_uc_q;

    logic both_staged;
    assign both_staged = req_latched_q & data_latched_q;

    logic [WORD_IDX_WIDTH-1:0]  data_word_idx;
    logic                       data_is_uc;

    always_comb begin : uc_detect_comb
        if (req_latched_q) begin
            data_word_idx = word_idx_q;
            data_is_uc    = is_uc_q;
        end else if (req_valid_i) begin
            data_word_idx = req_i.mem_req_addr[AXI_BYTES_LOG2 +: WORD_IDX_WIDTH];
            data_is_uc    = (req_i.mem_req_size <=
                             hpdcache_mem_size_t'(AXI_BYTES_LOG2));
        end else begin
            data_word_idx = '0;
            data_is_uc    = 1'b0;
        end
    end

    logic [7:0] axi_len;
    logic [2:0] axi_size;

    always_comb begin : len_size_comb
        if (req_q.mem_req_size >= hpdcache_mem_size_t'(AXI_BYTES_LOG2)) begin
            axi_len  = 8'((1 << (req_q.mem_req_size - AXI_BYTES_LOG2)) - 1);
            axi_size = 3'(AXI_BYTES_LOG2);
        end else begin
            axi_len  = 8'h00;
            axi_size = req_q.mem_req_size;
        end
    end

    // ================================================================
    //  FIFO TYPES AND SIGNALS
    // ================================================================

    // Data FIFO - one entry per in-flight write
    typedef struct packed {
        logic [LINE_W-1:0]  tx_data;
        logic [STRB_W-1:0]  tx_strb;
        logic [7:0]         total_beats;
    } data_entry_t;

    data_entry_t [N_OUTSTANDING-1:0]  data_fifo_q;
    logic        [PTR_W-1:0]          data_wr_ptr_q;
    logic        [PTR_W-1:0]          data_rd_ptr_q;
    logic                             data_fifo_push;
    logic                             data_fifo_pop;
    logic                             data_fifo_empty;
    logic                             data_fifo_full;

    assign data_fifo_empty = (data_wr_ptr_q == data_rd_ptr_q);
    assign data_fifo_full  = (PTR_W'(data_wr_ptr_q + 1) == data_rd_ptr_q);

    logic [N_OUTSTANDING-1:0][ID_W-1:0]  resp_fifo_q;
    logic                  [PTR_W-1:0]   resp_wr_ptr_q;
    logic                  [PTR_W-1:0]   resp_rd_ptr_q;
    logic                                resp_fifo_push;
    logic                                resp_fifo_pop;
    logic                                resp_fifo_empty;
    logic                                resp_fifo_full;

    assign resp_fifo_empty = (resp_wr_ptr_q == resp_rd_ptr_q);
    assign resp_fifo_full  = (PTR_W'(resp_wr_ptr_q + 1) == resp_rd_ptr_q);

    logic can_push;
    assign can_push = ~data_fifo_full & ~resp_fifo_full;

    assign req_ready_o      = ~req_latched_q  & can_push;
    assign req_data_ready_o = ~data_latched_q & (can_push | req_latched_q);

    // ================================================================
    //  STAGING REGISTERS
    // ================================================================
    always_ff @(posedge clk_i or negedge rstn_i) begin : staging_ff
        if (!rstn_i) begin
            req_q          <= '0;
            req_latched_q  <= 1'b0;
            tx_data_q      <= '0;
            tx_strb_q      <= '0;
            data_latched_q <= 1'b0;
            word_idx_q     <= '0;
            is_uc_q        <= 1'b0;
        end else begin

            // Accept req when ready
            // (req_ready_o = ~req_latched & can_push   mutually exclusive
            //  with the clear below since req_latched=1 when clearing)
            if (req_valid_i && req_ready_o) begin
                req_q         <= req_i;
                req_latched_q <= 1'b1;
                word_idx_q    <= req_i.mem_req_addr[AXI_BYTES_LOG2 +: WORD_IDX_WIDTH];
                is_uc_q       <= (req_i.mem_req_size <=
                                  hpdcache_mem_size_t'(AXI_BYTES_LOG2));
            end

            // Accept data when ready
            if (req_data_valid_i && req_data_ready_o) begin
                if (data_is_uc) begin
                    tx_data_q <= req_data_i.mem_req_w_data >>
                                 (data_word_idx * AXI_DATA_WIDTH);
                    tx_strb_q <= req_data_i.mem_req_w_be >>
                                 (data_word_idx * AXI_DATA_BYTES);
                end else begin
                    tx_data_q <= req_data_i.mem_req_w_data;
                    tx_strb_q <= req_data_i.mem_req_w_be;
                end
                data_latched_q <= 1'b1;
            end

            // Clear staging when AW accepted   entry pushed to FIFOs
            if (both_staged && can_push && axi_aw_ready_i) begin
                req_latched_q  <= 1'b0;
                data_latched_q <= 1'b0;
            end

        end
    end

    // ================================================================
    //  AW PATH combinational
    // ================================================================
    assign axi_aw_valid_o = both_staged & can_push;

    logic aw_fire;
    assign aw_fire        = both_staged & can_push & axi_aw_ready_i;
    assign data_fifo_push = aw_fire;
    assign resp_fifo_push = aw_fire;

    always_comb begin : aw_out_comb
        automatic logic            lock;
        automatic axi_pkg::atop_t  atop;
        automatic axi_pkg::cache_t cache;

        lock = 1'b0;
        atop = '0;
        if (req_q.mem_req_command == HPDCACHE_MEM_ATOMIC) begin
            unique case (req_q.mem_req_atomic)
                HPDCACHE_MEM_ATOMIC_STEX: lock = 1'b1;
                HPDCACHE_MEM_ATOMIC_ADD:  atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_ADD);
                HPDCACHE_MEM_ATOMIC_CLR:  atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_CLR);
                HPDCACHE_MEM_ATOMIC_SET:  atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_SET);
                HPDCACHE_MEM_ATOMIC_EOR:  atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_EOR);
                HPDCACHE_MEM_ATOMIC_SMAX: atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_SMAX);
                HPDCACHE_MEM_ATOMIC_SMIN: atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_SMIN);
                HPDCACHE_MEM_ATOMIC_UMAX: atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_UMAX);
                HPDCACHE_MEM_ATOMIC_UMIN: atop = axi_pkg::ATOP_ATOMICLOAD |
                                                 axi_pkg::atop_t'(axi_pkg::ATOP_UMIN);
                HPDCACHE_MEM_ATOMIC_SWAP: atop = axi_pkg::ATOP_ATOMICSWAP;
                default:                  atop = '0;
            endcase
        end

        cache = (req_q.mem_req_cacheable && !lock) ?
                (axi_pkg::CACHE_BUFFERABLE | axi_pkg::CACHE_MODIFIABLE |
                 axi_pkg::CACHE_RD_ALLOC   | axi_pkg::CACHE_WR_ALLOC)  :
                axi_pkg::CACHE_MODIFIABLE;

        axi_aw_o         = '0;
        axi_aw_o.id      = req_q.mem_req_id;
        axi_aw_o.addr    = req_q.mem_req_addr;
        axi_aw_o.len     = axi_len;
        axi_aw_o.size    = axi_size;
        axi_aw_o.burst   = axi_pkg::BURST_INCR;
        axi_aw_o.lock    = lock;
        axi_aw_o.cache   = cache;
        axi_aw_o.prot    = '0;
        axi_aw_o.qos     = '0;
        axi_aw_o.region  = '0;
        axi_aw_o.atop    = atop;
        axi_aw_o.user    = '0;
    end

    // ================================================================
    //  DATA FIFO
    // ================================================================
    always_ff @(posedge clk_i or negedge rstn_i) begin : data_fifo_ff
        if (!rstn_i) begin
            data_fifo_q   <= '{default: '0};
            data_wr_ptr_q <= '0;
            data_rd_ptr_q <= '0;
        end else begin
            if (data_fifo_push) begin
                data_fifo_q[data_wr_ptr_q].tx_data     <= tx_data_q;
                data_fifo_q[data_wr_ptr_q].tx_strb      <= tx_strb_q;
                data_fifo_q[data_wr_ptr_q].total_beats  <= axi_len + 1;
                data_wr_ptr_q <= PTR_W'(data_wr_ptr_q + 1);
            end
            if (data_fifo_pop) begin
                data_rd_ptr_q <= PTR_W'(data_rd_ptr_q + 1);
            end
        end
    end

    // ================================================================
    //  RESPONSE FIFO - tracks outstanding B responses
    // ================================================================
    always_ff @(posedge clk_i or negedge rstn_i) begin : resp_fifo_ff
        if (!rstn_i) begin
            resp_fifo_q   <= '{default: '0};
            resp_wr_ptr_q <= '0;
            resp_rd_ptr_q <= '0;
        end else begin
            if (resp_fifo_push) begin
                resp_fifo_q[resp_wr_ptr_q] <= req_q.mem_req_id;
                resp_wr_ptr_q <= PTR_W'(resp_wr_ptr_q + 1);
            end
            if (resp_fifo_pop) begin
                resp_rd_ptr_q <= PTR_W'(resp_rd_ptr_q + 1);
            end
        end
    end

    // ================================================================
    //  W PATH - independent 2-state FSM (W_IDLE / W_SEND)
    // ================================================================
    typedef enum logic { W_IDLE = 1'b0, W_SEND = 1'b1 } w_state_t;

    w_state_t          w_state_q;
    logic [LINE_W-1:0] w_data_q;
    logic [STRB_W-1:0] w_strb_q;
    logic [7:0]        w_total_beats_q;
    logic [7:0]        beat_q;

    // Pop data FIFO when W FSM loads a new entry
    assign data_fifo_pop = (w_state_q == W_IDLE) & ~data_fifo_empty;

    assign axi_w_valid_o = (w_state_q == W_SEND);

    always_comb begin : w_out_comb
        axi_w_o      = '0;
        axi_w_o.data = w_data_q[AXI_DATA_WIDTH-1 : 0];
        axi_w_o.strb = w_strb_q[AXI_DATA_BYTES-1 : 0];
        axi_w_o.last = (beat_q == w_total_beats_q - 1);
        axi_w_o.user = '0;
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : w_fsm_ff
        if (!rstn_i) begin
            w_state_q       <= W_IDLE;
            w_data_q        <= '0;
            w_strb_q        <= '0;
            w_total_beats_q <= '0;
            beat_q          <= '0;
        end else begin
            unique case (w_state_q)

                W_IDLE: begin
                    if (~data_fifo_empty) begin
                        // Load FIFO head into working registers (pop happens
                        // combinationally via data_fifo_pop, rd_ptr increments
                        // at the same posedge   read uses pre-increment ptr ?)
                        w_data_q        <= data_fifo_q[data_rd_ptr_q].tx_data;
                        w_strb_q        <= data_fifo_q[data_rd_ptr_q].tx_strb;
                        w_total_beats_q <= data_fifo_q[data_rd_ptr_q].total_beats;
                        beat_q          <= '0;
                        w_state_q       <= W_SEND;
                    end
                end

                W_SEND: begin
                    if (axi_w_ready_i) begin
                        w_data_q <= w_data_q >> AXI_DATA_WIDTH;
                        w_strb_q <= w_strb_q >> AXI_DATA_BYTES;
                        beat_q   <= beat_q + 1;
                        if (beat_q == w_total_beats_q - 1)
                            w_state_q <= W_IDLE;
                    end
                end

            endcase
        end
    end

    // ================================================================
    //  B PATH - independent, pops response FIFO on each B received
    // ================================================================
    assign resp_fifo_pop = ~resp_fifo_empty & axi_b_valid_i & resp_ready_i;
    assign axi_b_ready_o = ~resp_fifo_empty & resp_ready_i;
    assign resp_valid_o  = ~resp_fifo_empty & axi_b_valid_i;

    hpdcache_mem_error_e b_resp;
    always_comb begin : b_resp_comb
        unique case (axi_b_i.resp)
            axi_pkg::RESP_SLVERR,
            axi_pkg::RESP_DECERR: b_resp = HPDCACHE_MEM_RESP_NOK;
            default:              b_resp = HPDCACHE_MEM_RESP_OK;
        endcase
    end

    assign resp_o.mem_resp_w_error     = b_resp;
    assign resp_o.mem_resp_w_id        = axi_b_i.id;
    assign resp_o.mem_resp_w_is_atomic = (axi_b_i.resp == axi_pkg::RESP_EXOKAY);

    // ================================================================
    //  Concurrent assertions
    // ================================================================
`ifndef SYNTHESIS

    // AW must only fire when both staged and FIFOs have space
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        axi_aw_valid_o |-> (both_staged & can_push)
    ) else $error("[write_adapter] AW fired without both staged or FIFOs full");

    // W must only fire in W_SEND
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        axi_w_valid_o |-> (w_state_q == W_SEND)
    ) else $error("[write_adapter] W fired outside W_SEND");

    // FIFO overflow protection
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        data_fifo_push |-> ~data_fifo_full
    ) else $error("[write_adapter] data FIFO overflow");

    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        resp_fifo_push |-> ~resp_fifo_full
    ) else $error("[write_adapter] response FIFO overflow");

    // FIFO underflow protection
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        data_fifo_pop |-> ~data_fifo_empty
    ) else $error("[write_adapter] data FIFO underflow");

    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        resp_fifo_pop |-> ~resp_fifo_empty
    ) else $error("[write_adapter] response FIFO underflow");

`endif

endmodule
