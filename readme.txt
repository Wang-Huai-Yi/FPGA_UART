

use uart_dbg.sv to use UART_and_RX_REGISTER_Wrapper:


DEFINE:


When you use vcs_simulation: +VCS_SIM
When you use vivado simulation: +FPGA_SIM
When you want synthesis on VCU128: don't need DEFINE
When you want synthesis on VHK158: +VHK_158






UART_and_RX_REGISTER_Wrapper

    input i_clk_UART : clock for UART = 100MHz
    input i_clk_MPU  : clock for MPU <= 150MHz
    input i_clk_DMA : clock for DMA <= 200MHz
    input i_rst_n_MPU : reset_n signal for MPU (default is 1'b1)
    input i_rst_n_DMA : reset_n signal for DMA (default is 1'b1)
    input i_rst_n_UART : reset_n signal for UART (default is 1'b1)
    input i_max_id_valid : valid signal for max id from MPU
    input [15:0] i_max_id_data : data for max id from MPU
    output o_max_id_ready : ready signal to MPU for max id

    output wire uart_tx : uart TX port on FPGA
    input  wire uart_rx : uart RX port on FPGA

    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_prompt_ids_data : 16-bits data prompt ids to DMA
    output o_prompt_ids_valid : valid signal for prompt ids to DMA
    input  i_prompt_ids_ready : ready signal for prompt ids from DMA

    output [10:0] o_max_sequence_buffer : max sequence length of LLM
    output [10:0] o_prompt_counter      : prompt ids number
    output o_custom_reset               : custom reset signal (ignored)



Following is the required file for CDC FIFO

FIFO_Write_Pointer
FIFO_TOP.v
FIFO_R_Pointer.v
ASYNC_FIFO_RAM.v
Sync_R2W.v
Sync_W2R.v



Test bench


VCS_SIM:
source 01_run


01_run
uart_sim.sv
uart_script.f

FPGA TEST:
XDC: uart_vhk158.xdc

FPGA Synthesis TEST:
    TX: tx_wrapper_dbg.sv, tx_test.py
    RX: rx_wrapper_dbg.sv, rx_test.py

FPGA Setting:

UART: 
ip: AXI Uartlite
name: axi_uart_lite_0
detailed setting: 
AXI Frequency: 100MHz
baud rate = 9600
Data bits: 8bits

BRAM (Block design):
name: blk_mem_gen_0

(必須將output拉出block design)

ip: Embedded Memeory Generator
detailed setting: 
single port RAM
memory_depth: 2048
write_width: 18
read latency: 1
