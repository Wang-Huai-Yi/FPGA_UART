# =========================================================
# Differential clock input
# Use available clock pins from VHK158 config
# ddr4_dimm0_sma_clk_p/n : AW6 / AY6 , LVDS15
# =========================================================
set_property PACKAGE_PIN AW6 [get_ports clk_p]
set_property PACKAGE_PIN AY6 [get_ports clk_n]
set_property IOSTANDARD LVDS15 [get_ports {clk_p clk_n}]
# =========================================================
# Reset button
# Use gpio_pb_0 as reset
# gpio_pb_0 : BT29 , LVCMOS15
# =========================================================

# =========================================================
# UART1 (bank706)
# uart1_bank706_tx -> BG28
# uart1_bank706_rx -> BG29
# =========================================================
set_property PACKAGE_PIN BG28 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS15 [get_ports uart_tx]

set_property PACKAGE_PIN BG29 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS15 [get_ports uart_rx]

# =========================================================
# Do not use set_input_delay / set_output_delay for async UART
# unless you have a defined external timing model
# =========================================================

# =========================================================
# ILA keep
# =========================================================
