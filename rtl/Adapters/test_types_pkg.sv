// test_types_pkg.sv
// Concrete types for the testbench
// Widths chosen to match Sargantana DracDefaultConfig:
//   MemAddrWidth = 64
//   MemIDWidth   = 8
//   MemDataWidth = 64

package test_types_pkg;
    import hpdcache_pkg_sarg::*;
    import drac_pkg::*;

    // ----------------------------------------------------------------
    // HPDCache memory interface types
    // ----------------------------------------------------------------
    // causing the order mismatch with the one defined in hpd_pkg
    /* 
    typedef struct packed {
        logic [39:0]                mem_req_addr;
        logic [7:0]                mem_req_id;
        hpdcache_mem_len_t         mem_req_len;       // [7:0]
        hpdcache_mem_size_t        mem_req_size;      // [2:0]
        logic                      mem_req_cacheable;
        hpdcache_mem_command_e     mem_req_command;   // [1:0]
        hpdcache_mem_atomic_e      mem_req_atomic;    // [3:0]
    } hpdcache_mem_req_t;
    */

    typedef struct packed {
        logic [39:0]            mem_req_addr;
        hpdcache_mem_len_t      mem_req_len;
        hpdcache_mem_size_t     mem_req_size;
        logic [7:0]             mem_req_id;
        hpdcache_mem_command_e  mem_req_command;
        hpdcache_mem_atomic_e   mem_req_atomic;
        logic                   mem_req_cacheable;
    } hpdcache_mem_req_t;


    /* 
    typedef struct packed {
        logic [63:0]               mem_req_w_data;
        logic [7:0]                mem_req_w_be;
        logic                      mem_req_w_last;
    } hpdcache_mem_req_w_t;

    */
 
    typedef struct packed {
       logic [511:0]           mem_req_w_data;    // ? was 64, now 512
       logic [63:0]            mem_req_w_be;      // ? was 8, now 64
       logic                   mem_req_w_last;
    } hpdcache_mem_req_w_t;     
/* 
    typedef struct packed {
        hpdcache_mem_error_e       mem_resp_r_error;  // [1:0]
        logic [7:0]                mem_resp_r_id;
        logic [63:0]               mem_resp_r_data;
        logic                      mem_resp_r_last;
    } hpdcache_mem_resp_r_t;
    */

    typedef struct packed {
    hpdcache_mem_error_e    mem_resp_r_error;
        logic [7:0]             mem_resp_r_id;
        logic [511:0]           mem_resp_r_data;   // ? was 64, now 512
        logic                   mem_resp_r_last;
    } hpdcache_mem_resp_r_t;
/* 
    typedef struct packed {
        hpdcache_mem_error_e       mem_resp_w_error;  // [1:0]
        logic [7:0]                mem_resp_w_id;
        logic                      mem_resp_w_is_atomic;
    } hpdcache_mem_resp_w_t;
 */
    typedef struct packed {
        logic                   mem_resp_w_is_atomic;  // ? first
        hpdcache_mem_error_e    mem_resp_w_error;
        logic [7:0]             mem_resp_w_id;
    } hpdcache_mem_resp_w_t;
    
    // ----------------------------------------------------------------
    // AXI channel types (matching above widths)
    // ID=8, ADDR=64, DATA=64, STRB=8
    // ----------------------------------------------------------------
    typedef struct packed {
        logic [7:0]   id;
        logic [63:0]  addr;
        logic [7:0]   len;
        logic [2:0]   size;
        logic [1:0]   burst;
        logic         lock;
        logic [3:0]   cache;
        logic [2:0]   prot;
        logic [3:0]   qos;
        logic [3:0]   region;
        logic [5:0]   atop;
        logic [0:0]   user;
    } axi_aw_chan_t;

    typedef struct packed {
        logic [7:0]   id;
        logic [63:0]  addr;
        logic [7:0]   len;
        logic [2:0]   size;
        logic [1:0]   burst;
        logic         lock;
        logic [3:0]   cache;
        logic [2:0]   prot;
        logic [3:0]   qos;
        logic [3:0]   region;
        logic [0:0]   user;
    } axi_ar_chan_t;

    typedef struct packed {
        logic [63:0]  data;
        logic [7:0]   strb;
        logic         last;
        logic [0:0]   user;
    } axi_w_chan_t;

    typedef struct packed {
        logic [7:0]   id;
        logic [63:0]  data;
        logic [1:0]   resp;
        logic         last;
        logic [0:0]   user;
    } axi_r_chan_t;

    typedef struct packed {
        logic [7:0]   id;
        logic [1:0]   resp;
        logic [0:0]   user;
    } axi_b_chan_t;

endpackage
