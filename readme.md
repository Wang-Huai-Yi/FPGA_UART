
---

# UART + TX RX Register Wrapper README

## Overview

本設計提供一個 UART-based token 接收系統，將外部傳入的 16-bit tokens 轉換為 DMA 可用資料，同時支援：

* Max sequence 設定
* Prompt token 計數
* 多時脈域 (UART / MPU / DMA) 傳輸
* CDC FIFO 保證資料正確性

主要入口模組：

* `uart_dbg.sv`
* `UART_and_RX_REGISTER_Wrapper`

---

## Verilog Define Setting

請根據使用情境設定對應的 Verilog define：

| 使用情境              | Define 設定          |
| ----------------- | ------------------ |
| VCS simulation    | `+define+VCS_SIM`  |
| Vivado simulation | `+define+FPGA_SIM` |
| VCU128 synthesis  | 不需要加入 define       |
| VHK158 synthesis  | `+define+VHK_158`  |



## Top Module

### UART_and_RX_REGISTER_Wrapper

### Clock Domain

* `i_clk_UART` : UART clock (100 MHz)
* `i_clk_MPU`  : MPU clock (<= 150 MHz)
* `i_clk_DMA`  : DMA clock (<= 200 MHz)

---

### Reset

* `i_rst_n_UART` : UART reset (active low)
* `i_rst_n_MPU`  : MPU reset (active low)
* `i_rst_n_DMA`  : DMA reset (active low)

---

### MPU Interface (Max ID)

* `i_max_id_valid` : max id valid
* `i_max_id_data[15:0]` : max id data
* `o_max_id_ready` : ready signal

---

### UART Interface

* `uart_tx` : UART transmit
* `uart_rx` : UART receive

---

### DMA Interface (Prompt IDs)

* `o_prompt_ids_data` : 18-bit token data
* `o_prompt_ids_valid` : valid signal
* `i_prompt_ids_ready` : ready signal

---

### Control Outputs

* `o_max_sequence_buffer[10:0]` : max sequence length
* `o_prompt_counter[10:0]` : received token count
* `o_custom_reset` : custom reset (currently unused)

---

## CDC FIFO (Required Files)

此設計使用非同步 FIFO 進行跨時脈域傳輸，以下檔案必須包含：

* `FIFO_TOP.v`
* `FIFO_Write_Pointer`
* `FIFO_R_Pointer.v`
* `ASYNC_FIFO_RAM.v`
* `Sync_R2W.v`
* `Sync_W2R.v`

---

## Simulation

### Run VCS Simulation

```bash
source 01_run
```

### Simulation Files

* `uart_sim.sv`
* `uart_script.f`

---

## FPGA Testing

### Constraints

* `uart_vhk158.xdc`

---

### Functional Test

#### TX Path

* RTL: `tx_wrapper_dbg.sv`
* Script: `tx_test.py`

#### RX Path

* RTL: `rx_wrapper_dbg.sv`
* Script: `rx_test.py`

---

## FPGA Synthesis / IP Setting

### UART IP

* IP: AXI UART Lite
* Instance name: `axi_uart_lite_0`

Configuration:

* AXI Frequency: 100 MHz
* Baud Rate: 9600
* Data Bits: 8 bits

---

### BRAM (Block Design)

* IP: Block Memory Generator
* Instance name: `blk_mem_gen_0`


(必須將output拉出block design)

Configuration:

* Memory Type: Single Port RAM
* Depth: 2048
* Write Width: 18 bits
* Read Latency: 1

---

## Notes

* UART 傳輸單位為 18-bit tokens
* 使用 valid/ready handshake 傳輸至 DMA
* CDC FIFO 負責跨 clock domain（UART / MPU / DMA）
* Max sequence 可透過 UART 動態更新

