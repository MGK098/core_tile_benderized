onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/visa_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_reg_rnm_read_resp_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_reg_rf_rdata_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_unavail_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_running_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_resume_ack_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_progbuf_xcpt_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_progbuf_ack_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_parked_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_havereset_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_halted_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/debug_contr_halt_ack_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_valid_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_user_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_strb_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_last_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_data_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_ready_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_b_ready_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_valid_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_user_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_size_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_region_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_qos_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_prot_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_lock_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_len_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_id_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_cache_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_burst_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_atop_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_addr_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_valid_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_user_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_size_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_region_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_qos_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_prot_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_lock_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_len_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_id_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_cache_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_burst_o
add wave -noupdate -expand -group TOP_OUT /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_addr_o
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/time_irq_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/time_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/soft_rstn_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/soft_irq_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/rstn_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/reset_addr_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/irq_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/io_core_pmu_l2_hit_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rnm_read_reg_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rnm_read_en_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rf_we_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rf_wdata_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rf_preg_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_reg_rf_en_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_contr_resume_req_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_contr_progbuf_req_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_contr_halt_req_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/debug_contr_halt_on_reset_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/core_id_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/clk_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_w_ready_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_valid_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_user_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_resp_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_last_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_id_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_r_data_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_b_valid_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_b_user_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_b_resp_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_b_id_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_aw_ready_i
add wave -noupdate -expand -group TOP_INP /tb_sargantana_soc_axi_wrap/dut/axi_mst_ar_ready_i
add wave -noupdate -expand -group MUX_2_IDSERIL -expand -subitemconfig {{/tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/slv_req[0]} -expand {/tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/slv_req[0].ar} -expand} /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/slv_req
add wave -noupdate -expand -group MUX_2_IDSERIL /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/slv_resp
add wave -noupdate -expand -group MUX_2_IDSERIL /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/mux_req
add wave -noupdate -expand -group MUX_2_IDSERIL /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/mux_resp
add wave -noupdate -expand -group MUX_2_IDSERIL /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/mst_req
add wave -noupdate -expand -group MUX_2_IDSERIL /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/mst_resp
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_b_user_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_b_resp_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_b_id_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_b_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_ready_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_ready_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_user_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_resp_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_last_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_id_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_data_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_ready_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_resp_ready_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_data_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_data_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_req_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_req_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_resp_ready_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_req_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_req_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/brom_req_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/brom_req_addr_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/icache_req_paddr_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/icache_req_valid_i
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/rst_ni
add wave -noupdate -expand -group MEM_SUBSYS_INP /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/clk_i
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_b_ready_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_user_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_last_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_strb_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_data_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_w_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_atop_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_user_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_region_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_qos_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_prot_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_cache_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_lock_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_burst_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_size_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_len_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_id_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_addr_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_aw_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_r_ready_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_user_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_region_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_qos_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_prot_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_cache_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_lock_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_burst_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_size_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_len_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_id_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_addr_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/axi_mst_ar_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_resp_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_resp_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_data_ready_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_wr_req_ready_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_resp_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_resp_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/hpd_rd_req_ready_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/brom_resp_data_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/brom_resp_valid_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/icache_resp_ack_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/icache_resp_data_o
add wave -noupdate -group MEM_SUBSYS_OUT /tb_sargantana_soc_axi_wrap/dut/u_axi_bridge/icache_resp_valid_o
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/time_irq_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/time_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/soft_rstn_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/soft_irq_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/rstn_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/reset_addr_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_write_valid_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_write_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_read_valid_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_read_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_ready_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_data_ready_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_read_ready_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/irq_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_grant_valid
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_grant_inval_addr
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_grant_inval
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_grant_bits_data
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_grant_bits_addr_beat
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_core_pmu_l2_hit_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rnm_read_reg_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rnm_read_en_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rf_we_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rf_wdata_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rf_preg_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rf_en_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_resume_req_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_progbuf_req_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_halt_req_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_halt_on_reset_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/core_id_i
add wave -noupdate -expand -group Core_INP /tb_sargantana_soc_axi_wrap/dut/u_core_tile/clk_i
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/visa_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_write_ready_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_resp_read_ready_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_valid_o
add wave -noupdate -expand -group Core_OUT -expand /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_data_valid_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_write_data_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_read_valid_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/mem_req_read_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_acquire_valid
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/io_mem_acquire_bits_addr_block
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rnm_read_resp_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_reg_rf_rdata_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_unavail_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_running_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_resume_ack_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_progbuf_xcpt_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_progbuf_ack_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_parked_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_havereset_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_halted_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/debug_contr_halt_ack_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/brom_req_valid_o
add wave -noupdate -expand -group Core_OUT /tb_sargantana_soc_axi_wrap/dut/u_core_tile/brom_req_address_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {185000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 286
configure wave -valuecolwidth 386
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {147755 ps} {565137 ps}
