# 100 MHz clock from SI570 oscillator (use Clocking Wizard to derive 100 MHz if needed)
set_property PACKAGE_PIN BH51 [get_ports clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_p]

set_property PACKAGE_PIN BJ51 [get_ports clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_n]

create_clock -name clk_100mhz -period 10.000 [get_ports clk_p]



set_property -dict {PACKAGE_PIN BM29 IOSTANDARD LVCMOS12} [get_ports reset]



set_input_delay -clock clk_100mhz -max 2 [get_ports uart_tx]
set_input_delay -clock clk_100mhz -min 1 [get_ports uart_rx]
set_output_delay -clock clk_100mhz -max 2 [get_ports uart_tx]
set_output_delay -clock clk_100mhz -min 1 [get_ports uart_rx]

# easy to confuse rxd/txd here
# uart0_txd
set_property -dict {PACKAGE_PIN BN26 IOSTANDARD LVCMOS18} [get_ports uart_tx]
# uart0_rxd
set_property -dict {PACKAGE_PIN BP26 IOSTANDARD LVCMOS18} [get_ports uart_rx]
# uart0_rts
#set_property -dict {PACKAGE_PIN BP22 IOSTANDARD LVCMOS18} [get_ports jtag_TDO]
# uart0_cts
#set_property -dict {PACKAGE_PIN BP23 IOSTANDARD LVCMOS18} [get_ports jtag_TMS]
set_property DONT_TOUCH true [get_cells u_ILA_0]
set_property DONT_TOUCH true [get_cells u_ILA_2]
set_property DONT_TOUCH true [get_cells u_ILA_3]
set_property DONT_TOUCH true [get_cells u_ILA_4]
