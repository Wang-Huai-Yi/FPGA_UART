
`timescale 1ns/1ps

module tb_uart_system_70tokens;

  localparam int TOKENS_REGISTER_DATA_WIDTH     = 18;
  localparam int UART_CHUNK_BIT                 = 6;
  localparam int UART_CHUNKS_PER_TOKEN          = TOKENS_REGISTER_DATA_WIDTH / UART_CHUNK_BIT;

  localparam int TOKENS_REGISTER_BANK_DEPTH     = 2048;
  localparam int TOKENS_REGISTER_BANK_DEPTH_BIT = $clog2(TOKENS_REGISTER_BANK_DEPTH);

  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] RESET_IDS                    = 18'h3FFFA;
  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] CHANGE_MAXSEQUENCE_START_IDS = 18'h3FFFB;
  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] CHANGE_MAXSEQUENCE_END_IDS   = 18'h3FFFC;
  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_START_IDS             = 18'h3FFFE;
  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_END_IDS               = 18'h3FFFF;

  localparam int NUM_TOKENS = 70;
  localparam logic [TOKENS_REGISTER_DATA_WIDTH-1:0] HIGH_TOKEN_BASE = 18'h3F000;

  // RX script:
  //   RESET_IDS
  //   CHANGE_MAXSEQUENCE_START_IDS, 70, CHANGE_MAXSEQUENCE_END_IDS
  //   TOKENS_START_IDS
  //   1 ~ 70
  //   TOKENS_END_IDS
  localparam int RX_TOKEN_COUNT = 1 + 3 + 1 + NUM_TOKENS + 1;
  localparam int RX_ROM_BYTES   = RX_TOKEN_COUNT * UART_CHUNKS_PER_TOKEN;

  // =========================================================
  // clocks / reset
  // =========================================================
  logic i_clk_UART;
  logic i_clk_MPU;
  logic i_clk_DMA;

  logic i_rst_n_UART;
  logic i_rst_n_MPU;
  logic i_rst_n_DMA;

  // =========================================================
  // DUT I/O
  // =========================================================
  logic                                  i_max_id_valid;
  logic [TOKENS_REGISTER_DATA_WIDTH-1:0] i_max_id_data;
  wire                                   o_max_id_ready;

  wire uart_tx;
  logic uart_rx;

  wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_prompt_ids_data;
  wire                                  o_prompt_ids_valid;
  logic                                 i_prompt_ids_ready;

  wire [10:0]                           o_max_sequence_buffer;
  wire [10:0]                           o_prompt_counter;
  wire                                  o_custom_reset;

  // debug outputs
  wire [3:0]  o_dbg_tokens_state;
  wire        o_dbg_uart_prompt_valid;
  wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_uart_prompt_data;
  wire        o_dbg_cdc_wvalid;
  wire        o_dbg_cdc_wready;
  wire        o_dbg_cdc_rvalid;
  wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_cdc_rdata;
  wire        o_dbg_ctrl_fifo_valid;
  wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_ctrl_fifo_data;
  wire        o_dbg_reg_wvalid;
  wire        o_dbg_reg_awvalid;
  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_reg_awaddr;
  wire        o_dbg_reg_rvalid;
  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_reg_raddr;

  wire        o_dbg_bram_we;
  wire        o_dbg_bram_en;
  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_bram_addr;
  wire [TOKENS_REGISTER_DATA_WIDTH-1:0]     o_dbg_bram_dout;
  wire        o_dbg_tokreg_rvalid_in;
  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_tokreg_raddr_in;
  wire        o_dbg_tokreg_rdata_valid;
  wire [TOKENS_REGISTER_DATA_WIDTH-1:0]     o_dbg_bram_din;

  integer tx_tok_cnt;
  reg [TOKENS_REGISTER_DATA_WIDTH-1:0] expected_token;

  `ifdef VCS_SIM
    initial begin
      $fsdbDumpfile("tb_uart_system_70tokens_18bit.fsdb");
      $fsdbDumpvars(0, tb_uart_system_70tokens);
      $fsdbDumpMDA();
    end
  `endif

  // =========================================================
  // DUT
  // =========================================================
  UART_and_RX_REGISTER_Wrapper #(
    .TOKENS_REGISTER_DATA_WIDTH     (TOKENS_REGISTER_DATA_WIDTH),
    .TOKENS_REGISTER_BANK_DEPTH     (TOKENS_REGISTER_BANK_DEPTH),
    .TOKENS_REGISTER_BANK_DEPTH_BIT (TOKENS_REGISTER_BANK_DEPTH_BIT),
    .PYTHON_END_IDS                 (TOKENS_END_IDS)
  ) dut (
    .i_clk_UART              (i_clk_UART),
    .i_clk_MPU               (i_clk_MPU),
    .i_clk_DMA               (i_clk_DMA),

    .i_rst_n_MPU             (i_rst_n_MPU),
    .i_rst_n_DMA             (i_rst_n_DMA),
    .i_rst_n_UART            (i_rst_n_UART),

    .i_max_id_valid          (i_max_id_valid),
    .i_max_id_data           (i_max_id_data),
    .o_max_id_ready          (o_max_id_ready),

    .uart_tx                 (uart_tx),
    .uart_rx                 (uart_rx),

    .o_prompt_ids_data       (o_prompt_ids_data),
    .o_prompt_ids_valid      (o_prompt_ids_valid),
    .i_prompt_ids_ready      (i_prompt_ids_ready),

    .o_max_sequence_buffer   (o_max_sequence_buffer),
    .o_prompt_counter        (o_prompt_counter),
    .o_custom_reset          (o_custom_reset),

    .o_dbg_tokens_state      (o_dbg_tokens_state),
    .o_dbg_uart_prompt_valid (o_dbg_uart_prompt_valid),
    .o_dbg_uart_prompt_data  (o_dbg_uart_prompt_data),
    .o_dbg_cdc_wvalid        (o_dbg_cdc_wvalid),
    .o_dbg_cdc_wready        (o_dbg_cdc_wready),
    .o_dbg_cdc_rvalid        (o_dbg_cdc_rvalid),
    .o_dbg_cdc_rdata         (o_dbg_cdc_rdata),
    .o_dbg_ctrl_fifo_valid   (o_dbg_ctrl_fifo_valid),
    .o_dbg_ctrl_fifo_data    (o_dbg_ctrl_fifo_data),
    .o_dbg_reg_wvalid        (o_dbg_reg_wvalid),
    .o_dbg_reg_awvalid       (o_dbg_reg_awvalid),
    .o_dbg_reg_awaddr        (o_dbg_reg_awaddr),
    .o_dbg_reg_rvalid        (o_dbg_reg_rvalid),
    .o_dbg_reg_raddr         (o_dbg_reg_raddr),

    .o_dbg_bram_we           (o_dbg_bram_we),
    .o_dbg_bram_en           (o_dbg_bram_en),
    .o_dbg_bram_addr         (o_dbg_bram_addr),
    .o_dbg_bram_dout         (o_dbg_bram_dout),
    .o_dbg_tokreg_rvalid_in  (o_dbg_tokreg_rvalid_in),
    .o_dbg_tokreg_raddr_in   (o_dbg_tokreg_raddr_in),
    .o_dbg_tokreg_rdata_valid(o_dbg_tokreg_rdata_valid),
    .o_dbg_bram_din          (o_dbg_bram_din)
  );

  // =========================================================
  // clock generation
  // =========================================================
  initial i_clk_UART = 1'b0;
  always #5 i_clk_UART = ~i_clk_UART;   // 100MHz

  initial i_clk_MPU = 1'b0;
  always #2 i_clk_MPU = ~i_clk_MPU;

  initial i_clk_DMA = 1'b0;
  always #1 i_clk_DMA = ~i_clk_DMA;

  // =========================================================
  // reset / init
  // =========================================================
  initial begin
    uart_rx = 1'b1;

    i_max_id_valid     = 1'b0;
    i_max_id_data      = '0;
    i_prompt_ids_ready = 1'b1;

    i_rst_n_UART = 1'b0;
    i_rst_n_MPU  = 1'b0;
    i_rst_n_DMA  = 1'b0;

    tx_tok_cnt      = 0;
    expected_token  = HIGH_TOKEN_BASE + 18'd1;

    #100;
    i_rst_n_UART = 1'b1;
    i_rst_n_MPU  = 1'b1;
    i_rst_n_DMA  = 1'b1;
  end

  // =========================================================
  // TX helper
  // =========================================================
  task automatic send_max_id(input logic [TOKENS_REGISTER_DATA_WIDTH-1:0] data);
    begin
      @(posedge i_clk_MPU);
      wait (o_max_id_ready === 1'b1);
      i_max_id_data  <= data;
      i_max_id_valid <= 1'b1;
      @(posedge i_clk_MPU);
      i_max_id_valid <= 1'b0;
      $display("[%0t] TB send max_id = 0x%05h", $time, data);
    end
  endtask

  // =========================================================
  // monitor
  // =========================================================
  always @(posedge i_clk_DMA) begin
    if (o_custom_reset)
      $display("[%0t] INFO: o_custom_reset pulse", $time);
  end

  // =========================================================
  // output token checker
  // =========================================================
  always @(posedge i_clk_DMA) begin
    if (!i_rst_n_DMA) begin
      tx_tok_cnt     <= 0;
      expected_token <= HIGH_TOKEN_BASE + 18'd1;
    end
    else begin
      if (o_prompt_ids_valid && i_prompt_ids_ready) begin
        $display("[%0t] OUTPUT TOKEN[%0d] = %05h (expect %05h)",
                 $time, tx_tok_cnt, o_prompt_ids_data, expected_token);

        if (o_prompt_ids_data !== expected_token) begin
          $error("Output token mismatch: idx=%0d expected=%05h got=%05h",
                 tx_tok_cnt, expected_token, o_prompt_ids_data);
        end

        tx_tok_cnt     <= tx_tok_cnt + 1;
        expected_token <= expected_token + 1'b1;
      end
    end
  end

  // =========================================================
  // main test
  // =========================================================
  initial begin
    wait(i_rst_n_UART && i_rst_n_MPU && i_rst_n_DMA);

    // 等 RX path / token write / control FSM 跑完
    repeat(96000) @(posedge i_clk_DMA);

    $display("====================================================");
    $display("CHECK RX SYSTEM RESULT: 70 HIGH-BIT TOKENS, 18-BIT TOKEN, 6-BIT UART CHUNKS");
    $display("====================================================");
    $display("o_prompt_counter      = %0d", o_prompt_counter);
    $display("o_max_sequence_buffer = %0d", o_max_sequence_buffer);

    if (o_max_sequence_buffer !== 11'd70) begin
      $error("max_sequence_buffer mismatch. expected=70 got=%0d", o_max_sequence_buffer);
    end

    if (o_prompt_counter !== 11'd70) begin
      $error("prompt_counter mismatch. expected=70 got=%0d", o_prompt_counter);
    end

    // 等 token 逐個送出
    wait(tx_tok_cnt == NUM_TOKENS);

    $display("====================================================");
    $display("CHECK SINGLE-TOKEN OUTPUT RESULT");
    $display("====================================================");
    $display("Captured output token count = %0d", tx_tok_cnt);

    if (tx_tok_cnt !== NUM_TOKENS) begin
      $error("Output token count mismatch. expected=%0d got=%0d", NUM_TOKENS, tx_tok_cnt);
    end
    else begin
      $display("PASS: all %0d output tokens are correct.", NUM_TOKENS);
    end

    $display("====================================================");
    $display("CHECK TX SYSTEM RESULT");
    $display("====================================================");

    send_max_id(18'h3F123);
    send_max_id(18'h3ABCD);

    repeat(1000) @(posedge i_clk_UART);

    $display("====================================================");
    $display("Simulation done");
    $display("====================================================");
    #100;
    $finish;
  end

endmodule


// ============================================================
// Simulation-only axi_uartlite_0
//
// For 18-bit token + 6-bit UART chunks:
//   token[5:0]   -> first UART byte low 6 bits
//   token[11:6]  -> second UART byte low 6 bits
//   token[17:12] -> third UART byte low 6 bits
//
// RX script token sequence:
//   3FFFA
//   3FFFB 00046 3FFFC
//   3FFFE
//   3F001 ~ 3F046
//   3FFFF
// ============================================================
module axi_uartlite_0_fake (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [3:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [3:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    input  wire        s_axi_rready,
    output reg         s_axi_arready,
    output reg [31:0]  s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,

    input  wire [3:0]  s_axi_wstrb,

    input  wire        rx,
    output wire        tx,
    output wire        interrupt
);

    localparam int TOKEN_W        = 18;
    localparam int UART_CHUNK_BIT = 6;
    localparam int CHUNKS_PER_TOKEN = TOKEN_W / UART_CHUNK_BIT;
    localparam int NUM_TOKENS_FAKE = 70;
    localparam logic [TOKEN_W-1:0] HIGH_TOKEN_BASE_FAKE = 18'h3F000;
    localparam int RX_TOKEN_COUNT_FAKE = 1 + 3 + 1 + NUM_TOKENS_FAKE + 1;
    localparam int RX_ROM_BYTES_FAKE   = RX_TOKEN_COUNT_FAKE * CHUNKS_PER_TOKEN;

    localparam logic [TOKEN_W-1:0] RESET_IDS_FAKE                    = 18'h3FFFA;
    localparam logic [TOKEN_W-1:0] CHANGE_MAXSEQUENCE_START_IDS_FAKE = 18'h3FFFB;
    localparam logic [TOKEN_W-1:0] CHANGE_MAXSEQUENCE_END_IDS_FAKE   = 18'h3FFFC;
    localparam logic [TOKEN_W-1:0] TOKENS_START_IDS_FAKE             = 18'h3FFFE;
    localparam logic [TOKEN_W-1:0] TOKENS_END_IDS_FAKE               = 18'h3FFFF;

    reg [3:0] rx_state_r, rx_state_w;
    reg [3:0] tx_state_r, tx_state_w;
    reg [9:0] rom_idx_r, rom_idx_w;

    localparam S_RX_READ_STALL  = 4'd0;
    localparam S_RX_READ_STATUS = 4'd1;
    localparam S_RX_READ_DATA   = 4'd2;

    localparam S_TX_WRITE = 4'd0;
    localparam S_TX_BRESP = 4'd1;

    assign s_axi_rresp = 2'd0;
    assign tx = 1'b1;
    assign interrupt = 1'b0;

    function automatic [TOKEN_W-1:0] rx_token_rom(input int token_idx);
      int prompt_tok;
      begin
        rx_token_rom = '0;

        if (token_idx == 0) begin
          rx_token_rom = RESET_IDS_FAKE;
        end
        else if (token_idx == 1) begin
          rx_token_rom = CHANGE_MAXSEQUENCE_START_IDS_FAKE;
        end
        else if (token_idx == 2) begin
          rx_token_rom = 18'd70;
        end
        else if (token_idx == 3) begin
          rx_token_rom = CHANGE_MAXSEQUENCE_END_IDS_FAKE;
        end
        else if (token_idx == 4) begin
          rx_token_rom = TOKENS_START_IDS_FAKE;
        end
        else if (token_idx >= 5 && token_idx < 5 + NUM_TOKENS_FAKE) begin
          prompt_tok = token_idx - 5 + 1;
          rx_token_rom = HIGH_TOKEN_BASE_FAKE + prompt_tok[TOKEN_W-1:0];
        end
        else if (token_idx == 5 + NUM_TOKENS_FAKE) begin
          rx_token_rom = TOKENS_END_IDS_FAKE;
        end
      end
    endfunction

    function automatic [7:0] rx_rom(input [9:0] idx);
      int token_idx;
      int chunk_idx;
      logic [TOKEN_W-1:0] token;
      begin
        token_idx = idx / CHUNKS_PER_TOKEN;
        chunk_idx = idx % CHUNKS_PER_TOKEN;
        token = rx_token_rom(token_idx);

        rx_rom = 8'h00;
        case (chunk_idx)
          0: rx_rom = {2'b00, token[5:0]};
          1: rx_rom = {2'b00, token[11:6]};
          2: rx_rom = {2'b00, token[17:12]};
          default: rx_rom = 8'h00;
        endcase
      end
    endfunction

    wire rx_has_data;
    assign rx_has_data = (rom_idx_r < RX_ROM_BYTES_FAKE[9:0]);

    // ---------------- TX channel ----------------
    always @(*) begin
      tx_state_w = tx_state_r;
      case (tx_state_r)
        S_TX_WRITE: begin
          if (s_axi_wready && s_axi_wvalid && s_axi_awvalid && s_axi_awready)
            tx_state_w = S_TX_BRESP;
        end
        S_TX_BRESP: begin
          if (s_axi_bvalid && s_axi_bready)
            tx_state_w = S_TX_WRITE;
        end
      endcase
    end

    always @(*) begin
      s_axi_bvalid = 1'b0;
      s_axi_bresp  = 2'b00;
      if (tx_state_r == S_TX_BRESP) begin
        s_axi_bvalid = 1'b1;
        s_axi_bresp  = 2'b00;
      end
    end

    always @(*) begin
      s_axi_wready  = (tx_state_r == S_TX_WRITE);
      s_axi_awready = (tx_state_r == S_TX_WRITE);
    end

    always @(*) begin
      if (tx_state_r == S_TX_WRITE &&
          s_axi_wvalid && s_axi_wready &&
          s_axi_awvalid && s_axi_awready) begin
        $display("[%0t] UART TX WRITE CHUNK = %02x low6=%02x",
                 $time, s_axi_wdata[7:0], s_axi_wdata[5:0]);
      end
    end

    // ---------------- RX channel ----------------
    always @(*) begin
      s_axi_arready = 1'b0;
      if (rx_state_r == S_RX_READ_STALL)
        s_axi_arready = 1'b1;
    end

    always @(*) begin
      rx_state_w = rx_state_r;
      case (rx_state_r)
        S_RX_READ_STALL: begin
          if (s_axi_arvalid && s_axi_arready) begin
            if (s_axi_araddr == 4'h8)
              rx_state_w = S_RX_READ_STATUS;
            else if (s_axi_araddr == 4'h0)
              rx_state_w = S_RX_READ_DATA;
          end
        end
        S_RX_READ_STATUS: begin
          if (s_axi_rready && s_axi_rvalid)
            rx_state_w = S_RX_READ_STALL;
        end
        S_RX_READ_DATA: begin
          if (s_axi_rready && s_axi_rvalid)
            rx_state_w = S_RX_READ_STALL;
        end
      endcase
    end

    always @(*) begin
      s_axi_rvalid = 1'b0;
      s_axi_rdata  = 32'b0;
      case (rx_state_r)
        S_RX_READ_STATUS: begin
          s_axi_rdata  = {31'd0, rx_has_data};
          s_axi_rvalid = 1'b1;
        end
        S_RX_READ_DATA: begin
          s_axi_rdata  = {24'd0, rx_rom(rom_idx_r)};
          s_axi_rvalid = 1'b1;
        end
      endcase
    end

    always @(*) begin
      rom_idx_w = rom_idx_r;
      if (rx_state_r == S_RX_READ_DATA && s_axi_rready && s_axi_rvalid && rx_has_data)
        rom_idx_w = rom_idx_r + 1'b1;
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
      if (!s_axi_aresetn) begin
        rom_idx_r  <= 10'd0;
        rx_state_r <= S_RX_READ_STALL;
        tx_state_r <= S_TX_WRITE;
      end else begin
        rom_idx_r  <= rom_idx_w;
        rx_state_r <= rx_state_w;
        tx_state_r <= tx_state_w;
      end
    end

endmodule
