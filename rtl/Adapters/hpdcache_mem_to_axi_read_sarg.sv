/*
 *  HPDcache memory read adapter AXI4 AR / R channels
 *
 *  AR path : purely combinational pass-through  (req_i ? axi_ar_o)
 *            req_ready fires the same cycle axi_ar_ready is high,
 *            subject to the metadata FIFO not being full.
 *            Zero latency no FSM, no latching on the request path.
 *
 *  R  path : 2-state sequential FSM, assembles AXI_DATA_WIDTH-bit
 *            beats into a LINE_W-bit cache line and delivers to core.
 *
 *  AR / R decoupling
 *    AR and R are fully independent.  New AR requests can be accepted
 *    while the R assembler is still delivering a previous response.
 *    A small metadata FIFO (META_FIFO_DEPTH entries, must be power-of-2)
 *    bridges the two paths: per-transaction context (is_uc, word_idx)
 *    is pushed when an AR is accepted and popped when the last R beat
 *    is received.  req_ready_o is gated by ~meta_full to prevent
 *    overflow  hardware protection not just an assertion.
 *
 *  UC vs cacheable handling
 *    Cacheable (mem_req_size > AXI_BYTES_LOG2) :
 *      8-beat burst  shift-in LSB-first, beat-0 lands at [63:0].
 *    Uncacheable (mem_req_size <= AXI_BYTES_LOG2) :
 *      Single beat  placed at the correct 64-bit word slot inside
 *      the 512-bit response word using the captured address offset.
 *    Boundary: mem_req_size == AXI_BYTES_LOG2 (= 3 for 64-bit AXI)
 *      produces axi_len=0 (single beat) and is_uc=true  consistent.
 *      The hpdcache UC handler never issues cacheable requests at this
 *      size, so the boundary is safe.
 *
 *  Assumptions
 *    - hpdcache holds req_valid + req_i stable until req_ready
 *      (standard valid/ready protocol).
 *    - axi_id_serialize downstream ensures R beats for different
 *      transactions do not interleave on this interface.
 *    - META_FIFO_DEPTH must be a power of 2 (enforced below).
 *      4 is sufficient for the Sargantana/Cheshire pipeline depth
 *      (AR?SpillAR?xbar?LLC?R  12-15 cycles; miss handler issues
 *      at most ~1 AR per 2 cycles ? at most ~6 in flight).
 */
module hpdcache_mem_to_axi_read_sarg
    import hpdcache_pkg_sarg::*;
    import axi_pkg::*;
#(
    parameter  int unsigned AXI_DATA_WIDTH  = 64,
    parameter  int unsigned LINE_W          = 512,
    parameter  int unsigned META_FIFO_DEPTH = 16,         // must be power of 2
    parameter  type         hpdcache_mem_req_t    = logic,
    parameter  type         hpdcache_mem_resp_r_t = logic,
    parameter  type         ar_chan_t             = logic,
    parameter  type         r_chan_t              = logic
)(
    input  logic                  clk_i,
    input  logic                  rstn_i,

    //  Core / hpdcache request side
    output logic                  req_ready_o,
    input  logic                  req_valid_i,
    input  hpdcache_mem_req_t     req_i,

    //  Core / hpdcache response side
    input  logic                  resp_ready_i,
    output logic                  resp_valid_o,
    output hpdcache_mem_resp_r_t  resp_o,

    //  AXI AR channel
    output logic                  axi_ar_valid_o,
    output ar_chan_t               axi_ar_o,
    input  logic                  axi_ar_ready_i,

    //  AXI R channel
    input  logic                  axi_r_valid_i,
    input  r_chan_t                axi_r_i,
    output logic                  axi_r_ready_o
);

    // ----------------------------------------------------------------
    //  Derived constants
    // ----------------------------------------------------------------
    localparam int unsigned AXI_DATA_BYTES  = AXI_DATA_WIDTH / 8;
    localparam int unsigned AXI_BYTES_LOG2  = $clog2(AXI_DATA_BYTES);
    localparam int unsigned LINE_BYTES      = LINE_W / 8;
    localparam int unsigned LINE_BYTES_LOG2 = $clog2(LINE_BYTES);
    localparam int unsigned WORD_IDX_W      = LINE_BYTES_LOG2 - AXI_BYTES_LOG2;
    localparam int unsigned PTR_W           = $clog2(META_FIFO_DEPTH);

    // ----------------------------------------------------------------
    //  Issue 3 fix enforce META_FIFO_DEPTH is a power of 2
    //  Pointer wrap  PTR_W'(ptr + 1)  is only correct when depth is
    //  a power of 2; catch misconfiguration at elaboration time.
    // ----------------------------------------------------------------
    initial begin
        assert ((META_FIFO_DEPTH & (META_FIFO_DEPTH - 1)) == 0)
            else $fatal(1,
                "[read_adapter] META_FIFO_DEPTH=%0d must be a power of 2",
                META_FIFO_DEPTH);
    end


    // ================================================================
    //  AR PATH  purely combinational
    // ================================================================

    //  len / size derived combinationally from req_i
    logic [7:0] axi_len;
    logic [2:0] axi_size;

    always_comb begin : ar_len_size_comb
        if (req_i.mem_req_size >= hpdcache_mem_size_t'(AXI_BYTES_LOG2)) begin
            axi_len  = 8'((1 << (req_i.mem_req_size - AXI_BYTES_LOG2)) - 1);
            axi_size = 3'(AXI_BYTES_LOG2);
        end else begin
            axi_len  = 8'h00;
            axi_size = req_i.mem_req_size;
        end
    end

    //  AR channel output  all fields combinationally from req_i
    always_comb begin : ar_out_comb
        automatic logic            lock;
        automatic axi_pkg::cache_t cache;

        lock  = (req_i.mem_req_command == HPDCACHE_MEM_ATOMIC) &&
                (req_i.mem_req_atomic  == HPDCACHE_MEM_ATOMIC_LDEX);

        cache = req_i.mem_req_cacheable             ?
                (CACHE_BUFFERABLE | CACHE_MODIFIABLE |
                 CACHE_RD_ALLOC   | CACHE_WR_ALLOC)  :
                CACHE_MODIFIABLE;

        axi_ar_o         = '0;
        axi_ar_o.id      = req_i.mem_req_id;
        axi_ar_o.addr    = req_i.mem_req_addr;
        axi_ar_o.len     = axi_len;
        axi_ar_o.size    = axi_size;
        axi_ar_o.burst   = BURST_INCR;
        axi_ar_o.lock    = lock;
        axi_ar_o.cache   = cache;
        axi_ar_o.prot    = '0;
        axi_ar_o.qos     = '0;
        axi_ar_o.region  = '0;
        axi_ar_o.user    = '0;
    end

    assign axi_ar_valid_o = req_valid_i;


    // ================================================================
    //  AR METADATA FIFO
    //
    //  Captures per-transaction context when AR is accepted and
    //  delivers it to the R assembler when that transaction's beats
    //  arrive.  Circular buffer with power-of-2 pointer wrap.
    //
    //  is_uc     transaction is uncacheable (single beat)
    //  word_idx  which 64-bit slot in the 512-bit line for UC data
    // ================================================================

    typedef struct packed {
        logic                   is_uc;
        logic [WORD_IDX_W-1:0]  word_idx;
    } ar_meta_t;

    ar_meta_t [META_FIFO_DEPTH-1:0]  meta_q;
    logic     [PTR_W-1:0]            meta_wr_ptr_q;
    logic     [PTR_W-1:0]            meta_rd_ptr_q;

    logic  meta_push;
    logic  meta_pop;
    logic  meta_full;

    //  Issue 1 fix  full flag gates req_ready_o in hardware
    assign meta_full = (PTR_W'(meta_wr_ptr_q + 1) == meta_rd_ptr_q);

    //  Issue 1 fix  req_ready gated by ~meta_full; AR only accepted
    //  when both the AXI slave and the metadata FIFO have space
    assign req_ready_o = axi_ar_ready_i & ~meta_full;

    assign meta_push   = req_valid_i & axi_ar_ready_i & ~meta_full;

    always_ff @(posedge clk_i or negedge rstn_i) begin : meta_fifo_ff
        if (!rstn_i) begin
            meta_q        <= '{default: '0};
            meta_wr_ptr_q <= '0;
            meta_rd_ptr_q <= '0;
        end else begin
            if (meta_push) begin
                //  Issue 2  boundary: size == AXI_BYTES_LOG2 gives
                //  axi_len=0 (single beat) and is_uc=true  correct.
                meta_q[meta_wr_ptr_q].is_uc   <=
                    (req_i.mem_req_size <= hpdcache_mem_size_t'(AXI_BYTES_LOG2));
                meta_q[meta_wr_ptr_q].word_idx <=
                    req_i.mem_req_addr[LINE_BYTES_LOG2-1 : AXI_BYTES_LOG2];
                meta_wr_ptr_q <= PTR_W'(meta_wr_ptr_q + 1);
            end
            if (meta_pop) begin
                //  Issue 5  simultaneous push+pop is valid: both
                //  pointers advance together in the same cycle,
                //  keeping the occupancy count constant.
                meta_rd_ptr_q <= PTR_W'(meta_rd_ptr_q + 1);
            end
        end
    end

    //  Head of FIFO  context for the transaction currently assembling
    ar_meta_t cur_meta;
    assign cur_meta = meta_q[meta_rd_ptr_q];


    // ================================================================
    //  R PATH  2-state sequential FSM
    //
    //  R_ASSEMBLE : accepting AXI R beats, building cache line
    //  R_DELIVER  : presenting assembled line to core
    // ================================================================

    typedef enum logic {
        R_ASSEMBLE = 1'b0,
        R_DELIVER  = 1'b1
    } r_state_t;

    r_state_t                          r_state_q;
    logic     [LINE_W-1:0]             line_q;
    hpdcache_mem_error_e               err_q;
    logic     [$bits(axi_r_i.id)-1:0]  resp_id_q;

    //  Pop metadata on last beat -same clock edge as R_ASSEMBLE?R_DELIVER
    assign meta_pop      = (r_state_q == R_ASSEMBLE) & axi_r_valid_i & axi_r_i.last;

    //  Accept R beats only while assembling
    assign axi_r_ready_o = (r_state_q == R_ASSEMBLE);

    //  Response to core
    assign resp_valid_o            = (r_state_q == R_DELIVER);
    assign resp_o.mem_resp_r_data  = line_q;
    assign resp_o.mem_resp_r_id    = resp_id_q;
    assign resp_o.mem_resp_r_last  = 1'b1;
    assign resp_o.mem_resp_r_error = err_q;

    //  Issue 4 fix  gate line_next on valid R beat in ASSEMBLE state.
    //  Default holds line_q  eliminates X-propagation from axi_r_i.data
    //  when the R channel is idle or in R_DELIVER.
    logic [LINE_W-1:0] line_next;

    always_comb begin : line_next_comb
        line_next = line_q;    // default: hold current value
        if (axi_r_valid_i && (r_state_q == R_ASSEMBLE)) begin
            if (cur_meta.is_uc)
                //  UC: zero-extend beat, shift to correct 64-bit word slot
                line_next = LINE_W'(axi_r_i.data) <<
                            (int'(cur_meta.word_idx) * AXI_DATA_WIDTH);
            else
                //  Cacheable: shift-in LSB-first  beat-0 at [63:0]
                line_next = {axi_r_i.data, line_q[LINE_W-1 : AXI_DATA_WIDTH]};
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : r_fsm_ff
        if (!rstn_i) begin
            r_state_q <= R_ASSEMBLE;
            line_q    <= '0;
            err_q     <= HPDCACHE_MEM_RESP_OK;
            resp_id_q <= '0;
        end else begin
            unique case (r_state_q)

                R_ASSEMBLE: begin
                    if (axi_r_valid_i) begin
                        line_q <= line_next;

                        //  Track worst-case error across all beats
                        if (axi_r_i.resp inside {RESP_SLVERR, RESP_DECERR})
                            err_q <= HPDCACHE_MEM_RESP_NOK;

                        if (axi_r_i.last) begin
                            resp_id_q <= axi_r_i.id;
                            r_state_q <= R_DELIVER;
                        end
                    end
                end

                R_DELIVER: begin
                    if (resp_ready_i) begin
                        r_state_q <= R_ASSEMBLE;
                        line_q    <= '0;
                        err_q     <= HPDCACHE_MEM_RESP_OK;
                    end
                end

            endcase
        end
    end


    // ================================================================
    //  Concurrent assertions
    // ================================================================
`ifndef SYNTHESIS

    //  R beat must only arrive while assembling
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        (axi_r_valid_i && axi_r_ready_o) |-> (r_state_q == R_ASSEMBLE)
    ) else $error("[read_adapter] R beat received outside R_ASSEMBLE");

    //  Last beat must transition to R_DELIVER
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        (axi_r_valid_i && axi_r_ready_o && axi_r_i.last)
        |=> (r_state_q == R_DELIVER)
    ) else $error("[read_adapter] last beat did not transition to R_DELIVER");

    //  Metadata FIFO must not overflow  hardware gating on req_ready_o
    //  makes this unreachable in normal operation; assertion as safety net
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        meta_push |-> (PTR_W'(meta_wr_ptr_q + 1) != meta_rd_ptr_q)
    ) else $error("[read_adapter] metadata FIFO overflow  increase META_FIFO_DEPTH");

    //  Metadata FIFO must not underflow
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        meta_pop |-> (meta_wr_ptr_q != meta_rd_ptr_q)
    ) else $error("[read_adapter] metadata FIFO underflow");

    //  AR must not be accepted when FIFO is full
    assert property (
        @(posedge clk_i) disable iff (!rstn_i)
        meta_full |-> ~req_ready_o
    ) else $error("[read_adapter] req_ready asserted while metadata FIFO full");

`endif

endmodule

