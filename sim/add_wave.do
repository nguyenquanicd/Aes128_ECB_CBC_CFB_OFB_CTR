onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 23 <NULL>
add wave -noupdate /testTop/dut_top/pclk_1
add wave -noupdate /testTop/dut_top/psel_1
add wave -noupdate /testTop/dut_top/penable_1
add wave -noupdate -divider -height 23 {UART TX}
add wave -noupdate /testTop/dut_top/pclk_0
add wave -noupdate /testTop/dut_top/preset_n_0
add wave -noupdate /testTop/dut_top/pwrite_0
add wave -noupdate /testTop/dut_top/psel_0
add wave -noupdate /testTop/dut_top/penable_0
add wave -noupdate /testTop/dut_top/paddr_0
add wave -noupdate /testTop/dut_top/pwdata_0
add wave -noupdate /testTop/dut_top/pstrb_0
add wave -noupdate /testTop/dut_top/prdata_0
add wave -noupdate /testTop/dut_top/pready_0
add wave -noupdate /testTop/dut_top/pslverr_0
add wave -noupdate /testTop/dut_top/ctrl_if_0
add wave -noupdate /testTop/dut_top/uart_0/apb_if/tx_nf
add wave -noupdate /testTop/dut_top/uart_0/apb_if/tx_busy
add wave -noupdate /testTop/dut_top/uart_0/apb_if/tx_txe
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_ne
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_busy
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_rxf
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_ov
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_pe
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_fe
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_data
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_en
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_tx_en
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_d9
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_ep
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_shift_rx
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_shift_tx
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_txt
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_rxt
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_data_rd
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_data
add wave -noupdate /testTop/dut_top/uart_0/apb_if/prdata
add wave -noupdate /testTop/dut_top/uart_0/apb_if/pslverr
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_if
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_tif
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_rif
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_oif
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_pif
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_fif
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ctrl_busy
add wave -noupdate /testTop/dut_top/uart_0/apb_if/reg_sel
add wave -noupdate /testTop/dut_top/uart_0/apb_if/reg_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/reg_re
add wave -noupdate /testTop/dut_top/uart_0/apb_if/con_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/se_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/br_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/dt_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ie_we
add wave -noupdate /testTop/dut_top/uart_0/apb_if/con_reg
add wave -noupdate /testTop/dut_top/uart_0/apb_if/se_reg
add wave -noupdate /testTop/dut_top/uart_0/apb_if/br_reg
add wave -noupdate /testTop/dut_top/uart_0/apb_if/ie_reg
add wave -noupdate /testTop/dut_top/uart_0/apb_if/rx_counter
add wave -noupdate /testTop/dut_top/uart_0/apb_if/tx_counter
add wave -noupdate /testTop/dut_top/uart_0/apb_if/err_condition
add wave -noupdate /testTop/dut_top/uart_0/apb_if/pready
add wave -noupdate -divider -height 23 {UART RX}
add wave -noupdate /testTop/dut_top/pclk_1
add wave -noupdate /testTop/dut_top/preset_n_1
add wave -noupdate /testTop/dut_top/pwrite_1
add wave -noupdate /testTop/dut_top/psel_1
add wave -noupdate /testTop/dut_top/penable_1
add wave -noupdate /testTop/dut_top/paddr_1
add wave -noupdate /testTop/dut_top/pwdata_1
add wave -noupdate /testTop/dut_top/pstrb_1
add wave -noupdate /testTop/dut_top/prdata_1
add wave -noupdate /testTop/dut_top/pready_1
add wave -noupdate /testTop/dut_top/pslverr_1
add wave -noupdate /testTop/dut_top/ctrl_if_1
add wave -noupdate /testTop/dut_top/uart_0to1
add wave -noupdate /testTop/dut_top/uart_1to0
add wave -noupdate /testTop/dut_top/uart_1/apb_if/tx_nf
add wave -noupdate /testTop/dut_top/uart_1/apb_if/tx_busy
add wave -noupdate /testTop/dut_top/uart_1/apb_if/tx_txe
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_ne
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_busy
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_rxf
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_ov
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_pe
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_fe
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_data
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_en
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_tx_en
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_d9
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_ep
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_shift_rx
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_shift_tx
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_txt
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_rxt
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_data_rd
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_data
add wave -noupdate /testTop/dut_top/uart_1/apb_if/prdata
add wave -noupdate /testTop/dut_top/uart_1/apb_if/pready
add wave -noupdate /testTop/dut_top/uart_1/apb_if/pslverr
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_if
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_tif
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_rif
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_oif
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_pif
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_fif
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ctrl_busy
add wave -noupdate /testTop/dut_top/uart_1/apb_if/reg_sel
add wave -noupdate /testTop/dut_top/uart_1/apb_if/reg_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/reg_re
add wave -noupdate /testTop/dut_top/uart_1/apb_if/con_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/se_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/br_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/dt_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ie_we
add wave -noupdate /testTop/dut_top/uart_1/apb_if/con_reg
add wave -noupdate /testTop/dut_top/uart_1/apb_if/se_reg
add wave -noupdate /testTop/dut_top/uart_1/apb_if/br_reg
add wave -noupdate /testTop/dut_top/uart_1/apb_if/ie_reg
add wave -noupdate /testTop/dut_top/uart_1/apb_if/rx_counter
add wave -noupdate /testTop/dut_top/uart_1/apb_if/tx_counter
add wave -noupdate /testTop/dut_top/uart_1/apb_if/err_condition
add wave -noupdate -divider {APB checker 0}
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pclk
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/preset_n
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pwrite
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/psel
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/penable
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/paddr
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pwdata
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pstrb
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/prdata
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pready
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pslverr
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/apb_state
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/apb_next_state
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/paddr_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pwdata_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pstrb_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/prdata_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pwrite_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/paddr_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pwdata_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pstrb_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb0_chk/pselReg
add wave -noupdate -divider -height 23 {APB checker 1}
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pclk
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/preset_n
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pwrite
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/psel
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/penable
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/paddr
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pwdata
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pstrb
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/prdata
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pready
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pslverr
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/apb_state
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/apb_next_state
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/paddr_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pwdata_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pstrb_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/prdata_or
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pwrite_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/paddr_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pwdata_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pstrb_pre
add wave -noupdate /testTop/apb_protocol_checker_top/apb1_chk/pselReg
add wave -noupdate -divider -height 23 {UART check 0}
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/pclk
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/preset_n
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/pwrite
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/psel
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/penable
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/paddr
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/pwdata
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/pstrb
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/uart_net
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/apb_chk_se_info
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/apb_chk_br_info
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/bit_width
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/chk_uart_state
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/frame_start
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/frame_end
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/bit_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/next_bit
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/uart_net_sync
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/uart_net_falling
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/uart_net_rising
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/uart_bit_num
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/count_result
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/reg_sel
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/reg_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/se_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/br_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/bit_count_clr
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/bit_count_inc
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/clr_width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/inc_width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart0_chk/baud_rate_error
add wave -noupdate -divider -height 23 {UART check 1}
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/pclk
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/preset_n
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/pwrite
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/psel
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/penable
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/paddr
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/pwdata
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/pstrb
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/uart_net
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/apb_chk_se_info
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/apb_chk_br_info
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/bit_width
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/chk_uart_state
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/frame_start
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/frame_end
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/bit_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/next_bit
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/uart_net_sync
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/uart_net_falling
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/uart_net_rising
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/uart_bit_num
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/count_result
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/reg_sel
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/reg_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/se_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/br_we
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/bit_count_clr
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/bit_count_inc
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/clr_width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/inc_width_count
add wave -noupdate /testTop/uart_protocol_checker_top/uart1_chk/baud_rate_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {925 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 145
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
WaveRestoreZoom {0 ns} {1050 ns}
