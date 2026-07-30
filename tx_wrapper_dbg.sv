`timescale 1ns / 1ps

module top_vhk158_tx_only #(
    parameter integer TOKENS_REGISTER_DATA_WIDTH      = 18,
    parameter integer TOKENS_REGISTER_BANK_DEPTH      = 2048,
    parameter integer TOKENS_REGISTER_BANK_DEPTH_BIT  = $clog2(TOKENS_REGISTER_BANK_DEPTH),
    parameter [TOKENS_REGISTER_DATA_WIDTH-1:0] PYTHON_END_IDS = {TOKENS_REGISTER_DATA_WIDTH{1'b1}}
)(
    input  wire clk_p,
    input  wire clk_n,
    // input  wire reset,
    input  wire uart_rx,   // TX-only test can leave this unused, but keep the pin
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
    assign sys_rst_n = locked & ~reset;

    // ============================================================
    // TX stimulus to wrapper (MPU domain)
    // ============================================================
    wire                                  tx_test_valid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] tx_test_data;
    wire                                  tx_test_ready;

    tx_test_pattern_gen #(
        .DATA_WIDTH    (TOKENS_REGISTER_DATA_WIDTH),
        .PACKET_WORDS  (8),
        .STARTUP_CYCLES(32'd20_000_000),   // 200MHz about 100ms
        .GAP_CYCLES    (32'd200_000_000)   // 200MHz about 1s
    ) u_tx_test_pattern_gen (
        .i_clk   (clk_200mhz),
        .i_rst_n (sys_rst_n),
        .o_valid (tx_test_valid),
        .o_data  (tx_test_data),
        .i_ready (tx_test_ready)
    );

    // ============================================================
    // Unused RX-side outputs from wrapper
    // ============================================================
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] prompt_ids_data;
    wire                                  prompt_ids_valid;
    wire [10:0]                           max_sequence_buffer;
    wire [10:0]                           prompt_counter;
    wire                                  custom_reset;

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

    // ============================================================
    // DUT
    // ============================================================
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

        // TX test generator input
        .i_max_id_valid          (tx_test_valid),
        .i_max_id_data           (tx_test_data),
        .o_max_id_ready          (tx_test_ready),

        .uart_tx                 (uart_tx),
        .uart_rx                 (uart_rx),

        // RX path unused in TX-only test
        .o_prompt_ids_data       (prompt_ids_data),
        .o_prompt_ids_valid      (prompt_ids_valid),
        .i_prompt_ids_ready      (1'b1),

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
    // ILA #1 : MPU domain, valid / ready / data into wrapper
    //
    // IMPORTANT:
    //   ila_tx_gen.probe2 must be regenerated/configured as
    //   TOKENS_REGISTER_DATA_WIDTH bits.
    //   For 18-bit token mode, probe2 width = 18.
    // ============================================================
    ila_tx_gen u_ila_tx_gen (
        .clk    (clk_200mhz),
        .probe0 (tx_test_valid),
        .probe1 (tx_test_ready),
        .probe2 (tx_test_data)
    );



endmodule


module tx_test_pattern_gen #(
    parameter integer DATA_WIDTH     = 18,
    parameter integer PACKET_WORDS   = 8,
    parameter integer STARTUP_CYCLES = 32'd20_000_000,
    parameter integer GAP_CYCLES     = 32'd200_000_000
)(
    input  wire                  i_clk,
    input  wire                  i_rst_n,
    output reg                   o_valid,
    output reg [DATA_WIDTH-1:0]  o_data,
    input  wire                  i_ready
);

    localparam S_STARTUP = 2'd0;
    localparam S_SEND    = 2'd1;
    localparam S_GAP     = 2'd2;

    reg [1:0]  state_r, state_w;
    reg [31:0] cnt_r, cnt_w;
    reg [3:0]  idx_r, idx_w;

    function [DATA_WIDTH-1:0] pattern_word;
        input [3:0] idx;
        begin
            pattern_word = {DATA_WIDTH{1'b0}};
            case (idx)
                // Low-bit tests
                4'd0: pattern_word = 18'h00001;
                4'd1: pattern_word = 18'h0003F;
                4'd2: pattern_word = 18'h00040;

                // Mid/high-bit tests
                4'd3: pattern_word = 18'h01234;
                4'd4: pattern_word = 18'h2ABCD;

                // High range tests
                4'd5: pattern_word = 18'h3F123;
                4'd6: pattern_word = 18'h3FFAA;
                4'd7: pattern_word = 18'h3FFFF;

                default: pattern_word = {DATA_WIDTH{1'b0}};
            endcase
        end
    endfunction

    always @(*) begin
        state_w = state_r;
        cnt_w   = cnt_r;
        idx_w   = idx_r;

        case (state_r)
            S_STARTUP: begin
                if (cnt_r == STARTUP_CYCLES - 1) begin
                    state_w = S_SEND;
                    cnt_w   = 0;
                    idx_w   = 0;
                end else begin
                    cnt_w = cnt_r + 1'b1;
                end
            end

            S_SEND: begin
                if (o_valid && i_ready) begin
                    if (idx_r == PACKET_WORDS - 1) begin
                        state_w = S_GAP;
                        cnt_w   = 0;
                        idx_w   = 0;
                    end else begin
                        idx_w = idx_r + 1'b1;
                    end
                end
            end

            S_GAP: begin
                if (cnt_r == GAP_CYCLES - 1) begin
                    state_w = S_SEND;
                    cnt_w   = 0;
                    idx_w   = 0;
                end else begin
                    cnt_w = cnt_r + 1'b1;
                end
            end

            default: begin
                state_w = S_STARTUP;
                cnt_w   = 0;
                idx_w   = 0;
            end
        endcase
    end

    always @(*) begin
        o_valid = 1'b0;
        o_data  = {DATA_WIDTH{1'b0}};

        case (state_r)
            S_SEND: begin
                o_valid = 1'b1;
                o_data  = pattern_word(idx_r);
            end
            default: begin
                o_valid = 1'b0;
                o_data  = {DATA_WIDTH{1'b0}};
            end
        endcase
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_STARTUP;
            cnt_r   <= 0;
            idx_r   <= 0;
        end else begin
            state_r <= state_w;
            cnt_r   <= cnt_w;
            idx_r   <= idx_w;
        end
    end

endmodule
