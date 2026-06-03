onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/SlvIdWidth
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/SerMaxUniqIds
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/AxiUserWidth
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/SerMaxTxnsPerId
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/SerMaxTxns
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/MstIdWidth
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/AxiDataWidth
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/AxiAddrWidth
add wave -noupdate -group Internal /tb_sargantana_soc_wrap_ids/dut/MuxIdWidth
add wave -noupdate -expand -subitemconfig {{/tb_sargantana_soc_wrap_ids/dut/slv_req[1]} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_req[1].ar} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_req[0]} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_req[0].ar} -expand} /tb_sargantana_soc_wrap_ids/dut/slv_req
add wave -noupdate -expand -subitemconfig {{/tb_sargantana_soc_wrap_ids/dut/slv_resp[2]} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_resp[2].r} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_resp[1]} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_resp[1].r} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_resp[0]} -expand {/tb_sargantana_soc_wrap_ids/dut/slv_resp[0].r} -expand} /tb_sargantana_soc_wrap_ids/dut/slv_resp
add wave -noupdate -expand -subitemconfig {/tb_sargantana_soc_wrap_ids/dut/mux_req.ar -expand} /tb_sargantana_soc_wrap_ids/dut/mux_req
add wave -noupdate -expand -subitemconfig {/tb_sargantana_soc_wrap_ids/dut/mux_resp.r -expand} /tb_sargantana_soc_wrap_ids/dut/mux_resp
add wave -noupdate -expand -subitemconfig {/tb_sargantana_soc_wrap_ids/dut/mst_req.ar -expand} /tb_sargantana_soc_wrap_ids/dut/mst_req
add wave -noupdate -expand -subitemconfig {/tb_sargantana_soc_wrap_ids/dut/mst_resp.r -expand} /tb_sargantana_soc_wrap_ids/dut/mst_resp
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/clk_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/rst_ni
add wave -noupdate -expand -group Input -expand -group Ucache_REQ /tb_sargantana_soc_wrap_ids/dut/brom_req_valid_i
add wave -noupdate -expand -group Input -expand -group Ucache_REQ /tb_sargantana_soc_wrap_ids/dut/brom_req_addr_i
add wave -noupdate -expand -group Input -expand -group Icache_REQ /tb_sargantana_soc_wrap_ids/dut/icache_req_valid_i
add wave -noupdate -expand -group Input -expand -group Icache_REQ /tb_sargantana_soc_wrap_ids/dut/icache_req_paddr_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ /tb_sargantana_soc_wrap_ids/dut/hpd_wr_resp_ready_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ /tb_sargantana_soc_wrap_ids/dut/hpd_wr_req_valid_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ -expand /tb_sargantana_soc_wrap_ids/dut/hpd_wr_req_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ /tb_sargantana_soc_wrap_ids/dut/hpd_wr_data_valid_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ -expand /tb_sargantana_soc_wrap_ids/dut/hpd_wr_data_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ /tb_sargantana_soc_wrap_ids/dut/hpd_rd_resp_ready_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ /tb_sargantana_soc_wrap_ids/dut/hpd_rd_req_valid_i
add wave -noupdate -expand -group Input -expand -group HPD_REQ -expand /tb_sargantana_soc_wrap_ids/dut/hpd_rd_req_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_ready_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_valid_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_user_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_resp_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_last_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_id_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_data_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_b_valid_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_b_user_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_b_resp_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_b_id_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_ready_i
add wave -noupdate -expand -group Input /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_ready_i
add wave -noupdate -expand -group Output -expand -group Icache_RESP /tb_sargantana_soc_wrap_ids/dut/icache_resp_valid_o
add wave -noupdate -expand -group Output -expand -group Icache_RESP /tb_sargantana_soc_wrap_ids/dut/icache_resp_data_o
add wave -noupdate -expand -group Output -expand -group Icache_RESP /tb_sargantana_soc_wrap_ids/dut/icache_resp_ack_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_wr_resp_valid_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_wr_resp_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_wr_req_ready_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_wr_data_ready_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_rd_resp_valid_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_rd_resp_o
add wave -noupdate -expand -group Output -expand -group HPD_RESP /tb_sargantana_soc_wrap_ids/dut/hpd_rd_req_ready_o
add wave -noupdate -expand -group Output -expand -group Ucache_RESP /tb_sargantana_soc_wrap_ids/dut/brom_resp_valid_o
add wave -noupdate -expand -group Output -expand -group Ucache_RESP /tb_sargantana_soc_wrap_ids/dut/brom_resp_data_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_valid_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_user_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_strb_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_last_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_w_data_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_r_ready_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_b_ready_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_valid_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_user_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_size_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_region_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_qos_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_prot_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_lock_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_len_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_id_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_cache_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_burst_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_atop_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_aw_addr_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_valid_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_user_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_size_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_region_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_qos_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_prot_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_lock_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_len_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_id_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_cache_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_burst_o
add wave -noupdate -expand -group Output /tb_sargantana_soc_wrap_ids/dut/axi_mst_ar_addr_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {255000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 229
configure wave -valuecolwidth 471
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
configure wave -timelineunits ns
update
WaveRestoreZoom {290769 ps} {351295 ps}
