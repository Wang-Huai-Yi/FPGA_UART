

`timescale 1ns / 1ps

module top_vhk158_rx_only #(
    parameter integer TOKENS_REGISTER_DATA_WIDTH      = 18,
    parameter integer TOKENS_REGISTER_BANK_DEPTH      = 2048,
    parameter integer TOKENS_REGISTER_BANK_DEPTH_BIT  = $clog2(TOKENS_REGISTER_BANK_DEPTH),
    parameter [TOKENS_REGISTER_DATA_WIDTH-1:0] PYTHON_END_IDS = {TOKENS_REGISTER_DATA_WIDTH{1'b1}}
)(
    input  wire clk_p,
    input  wire clk_n,
    // input  wire reset,
    input  wire uart_rx,
    output wire uart_tx
);

    wire reset;
    assign reset = 1'b0;

    wire clk_default;
    wire sys_clk;
    wire sys_rst_n;

    wire clk_100mhz;
    wire clk_200mhz;
    wire clk_400mhz;

    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] prompt_ids_data;
    wire                                  prompt_ids_valid;
    wire [10:0]                           max_sequence_buffer;
    wire [10:0]                           prompt_counter;
    wire                                  custom_reset;
    wire                                  max_id_ready;

    // =========================
    // debug wires
    // =========================
    wire [3:0]  dbg_tokens_state;
    wire        dbg_uart_prompt_valid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] dbg_uart_prompt_data;
    wire        dbg_cdc_wvalid;
    wire        dbg_cdc_wready;
    wire        dbg_cdc_rvalid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] dbg_cdc_rdata;
    wire        dbg_ctrl_fifo_valid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] dbg_ctrl_fifo_data;
    wire        dbg_reg_wvalid;
    wire        dbg_reg_awvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_reg_awaddr;
    wire        dbg_reg_rvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_reg_raddr;

    wire        dbg_bram_we;
    wire        dbg_bram_en;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_bram_addr;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0]     dbg_bram_dout;
    wire        dbg_tokreg_rvalid_in;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_tokreg_raddr_in;
    wire        dbg_tokreg_rdata_valid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0]     dbg_bram_din;

    wire locked;

    wire CIPS_pl0_ref_clk_0;
    wire CIPS_pmc_iro_clk_0;

    `ifdef VHK_158
        CIPS u_CIPS (
            .pl0_ref_clk_0(CIPS_pl0_ref_clk_0),
            .pmc_iro_clk_0(CIPS_pmc_iro_clk_0)
        );
    `endif

    `ifdef VHK_158
        clk_wiz_0 u_clk_wiz_0 (
            .clk_out1(clk_100mhz),
            .clk_out2(clk_200mhz),
            .clk_out3(clk_400mhz),

            .clk_in1_p(clk_p),
            .clk_in1_n(clk_n),
            .reset(reset),
            .locked(locked)
        );
    `else
        IBUFDS u_ibufds_clk (
            .I (clk_p),
            .IB(clk_n),
            .O (clk_default)
        );

        clk_wiz_0 u_clk_wiz_0 (
            .clk_out1(clk_100mhz),
            .clk_out2(clk_200mhz),
            .clk_out3(clk_400mhz),
            .reset(reset),
            .locked(locked),
            .clk_in1(clk_default)
        );
    `endif

    assign sys_clk   = clk_100mhz;

    // Use clock wizard lock as reset release condition.
    // If you intentionally do not want this, replace with: assign sys_rst_n = ~reset;
    assign sys_rst_n = locked & ~reset;

    UART_and_RX_REGISTER_Wrapper #(
        .TOKENS_REGISTER_DATA_WIDTH     (TOKENS_REGISTER_DATA_WIDTH),
        .TOKENS_REGISTER_BANK_DEPTH     (TOKENS_REGISTER_BANK_DEPTH),
        .TOKENS_REGISTER_BANK_DEPTH_BIT (TOKENS_REGISTER_BANK_DEPTH_BIT),
        .PYTHON_END_IDS                 (PYTHON_END_IDS)
    ) u_dut (
        .i_clk_UART              (clk_100mhz),
        .i_clk_MPU               (clk_200mhz),
        .i_clk_DMA               (clk_400mhz),

        .i_rst_n_MPU             (sys_rst_n),
        .i_rst_n_DMA             (sys_rst_n),
        .i_rst_n_UART            (sys_rst_n),

        .i_max_id_valid          (1'b0),
        .i_max_id_data           ({TOKENS_REGISTER_DATA_WIDTH{1'b0}}),
        .o_max_id_ready          (max_id_ready),

        .uart_tx                 (uart_tx),
        .uart_rx                 (uart_rx),

        .o_prompt_ids_data       (prompt_ids_data),
        .o_prompt_ids_valid      (prompt_ids_valid),
        .i_prompt_ids_ready      (1'b1),   // FPGA test: always consume prompt output

        .o_max_sequence_buffer   (max_sequence_buffer),
        .o_prompt_counter        (prompt_counter),
        .o_custom_reset          (custom_reset),

        .o_dbg_tokens_state      (dbg_tokens_state),
        .o_dbg_uart_prompt_valid (dbg_uart_prompt_valid),
        .o_dbg_uart_prompt_data  (dbg_uart_prompt_data),
        .o_dbg_cdc_wvalid        (dbg_cdc_wvalid),
        .o_dbg_cdc_wready        (dbg_cdc_wready),
        .o_dbg_cdc_rvalid        (dbg_cdc_rvalid),
        .o_dbg_cdc_rdata         (dbg_cdc_rdata),
        .o_dbg_ctrl_fifo_valid   (dbg_ctrl_fifo_valid),
        .o_dbg_ctrl_fifo_data    (dbg_ctrl_fifo_data),
        .o_dbg_reg_wvalid        (dbg_reg_wvalid),
        .o_dbg_reg_awvalid       (dbg_reg_awvalid),
        .o_dbg_reg_awaddr        (dbg_reg_awaddr),
        .o_dbg_reg_rvalid        (dbg_reg_rvalid),
        .o_dbg_reg_raddr         (dbg_reg_raddr),

        .o_dbg_bram_we           (dbg_bram_we),
        .o_dbg_bram_en           (dbg_bram_en),
        .o_dbg_bram_addr         (dbg_bram_addr),
        .o_dbg_bram_dout         (dbg_bram_dout),
        .o_dbg_tokreg_rvalid_in  (dbg_tokreg_rvalid_in),
        .o_dbg_tokreg_raddr_in   (dbg_tokreg_raddr_in),
        .o_dbg_tokreg_rdata_valid(dbg_tokreg_rdata_valid),
        .o_dbg_bram_din          (dbg_bram_din)
    );

    // ============================================================
    // ILA #1 : UART domain (100 MHz)
    //
    // IMPORTANT:
    //   probe3 must be regenerated/configured as TOKENS_REGISTER_DATA_WIDTH bits.
    //   For 18-bit token mode, probe3 width = 18.
    // ============================================================
    ila_uart u_ila_uart (
        .clk    (clk_100mhz),

        .probe0 (uart_rx),
        .probe1 (uart_tx),
        .probe2 (dbg_uart_prompt_valid),
        .probe3 (dbg_uart_prompt_data),
        .probe4 (dbg_cdc_wvalid),
        .probe5 (dbg_cdc_wready)
    );

    // ============================================================
    // ILA #2 : DMA domain (400 MHz)
    //
    // IMPORTANT:
    //   The following probes must be regenerated/configured as 18 bits:
    //     probe0  prompt_ids_data
    //     probe7  dbg_cdc_rdata
    //     probe9  dbg_ctrl_fifo_data
    //     probe18 dbg_bram_dout
    //     probe22 dbg_bram_din
    //
    //   Address probes remain TOKENS_REGISTER_BANK_DEPTH_BIT bits.
    // ============================================================
    ila_dma u_ila_dma (
        .clk    (clk_400mhz),

        .probe0  (prompt_ids_data),
        .probe1  (prompt_ids_valid),
        .probe2  (prompt_counter),
        .probe3  (max_sequence_buffer),
        .probe4  (custom_reset),
        .probe5  (dbg_tokens_state),

        .probe6  (dbg_cdc_rvalid),
        .probe7  (dbg_cdc_rdata),
        .probe8  (dbg_ctrl_fifo_valid),
        .probe9  (dbg_ctrl_fifo_data),

        .probe10 (dbg_reg_wvalid),
        .probe11 (dbg_reg_awvalid),
        .probe12 (dbg_reg_awaddr),
        .probe13 (dbg_reg_rvalid),
        .probe14 (dbg_reg_raddr),

        .probe15 (dbg_bram_we),
        .probe16 (dbg_bram_en),
        .probe17 (dbg_bram_addr),
        .probe18 (dbg_bram_dout),
        .probe19 (dbg_tokreg_rvalid_in),
        .probe20 (dbg_tokreg_raddr_in),
        .probe21 (dbg_tokreg_rdata_valid),
        .probe22 (dbg_bram_din)
    );

endmodule
