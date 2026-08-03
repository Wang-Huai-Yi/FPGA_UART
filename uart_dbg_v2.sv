`timescale 1ns / 1ps
`define PERIOD    10.0
`define RST_DELAY 2
`define MAX_CYCLE 500000

module UART_and_RX_REGISTER_Wrapper #(
  parameter TOKENS_REGISTER_DATA_WIDTH      = 18,
  parameter TOKENS_REGISTER_BANK_DEPTH      = 2048,
  parameter TOKENS_REGISTER_BANK_DEPTH_BIT  = $clog2(TOKENS_REGISTER_BANK_DEPTH),
  parameter PYTHON_END_IDS                  = 18'h3FFFF
)(

    input i_clk_UART , /// UART 
    input i_clk_MPU , /// MPU
    input i_clk_DMA , /// DMA
    input i_rst_n_MPU ,
    input i_rst_n_DMA ,
    input i_rst_n_UART ,
    input i_max_id_valid ,
    input [TOKENS_REGISTER_DATA_WIDTH-1:0] i_max_id_data ,
    output o_max_id_ready ,

    output wire uart_tx ,
    input  wire uart_rx,

    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_prompt_ids_data,
    output o_prompt_ids_valid,
    input  i_prompt_ids_ready ,

    output [10:0] o_max_sequence_buffer,
    output [10:0] o_prompt_counter,
    output o_custom_reset,
    output o_prompt_counter_valid ,

    // =========================
    // debug outputs
    // =========================
    output [3:0]  o_dbg_tokens_state,
    output        o_dbg_uart_prompt_valid,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_uart_prompt_data,
    output        o_dbg_cdc_wvalid,
    output        o_dbg_cdc_wready,
    output        o_dbg_cdc_rvalid,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_cdc_rdata,
    output        o_dbg_ctrl_fifo_valid,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_ctrl_fifo_data,
    output        o_dbg_reg_wvalid,
    output        o_dbg_reg_awvalid,
    output [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_reg_awaddr,
    output        o_dbg_reg_rvalid,
    output [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_reg_raddr ,



    output        o_dbg_bram_we,
    output        o_dbg_bram_en,
    output [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_bram_addr,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0]     o_dbg_bram_dout,
    output        o_dbg_tokreg_rvalid_in,
    output [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_tokreg_raddr_in,
    output        o_dbg_tokreg_rdata_valid ,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_bram_din
);

    wire TOKENS_CONTROL_fifo_ids_valid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_CONTROL_fifo_ids_data;
    wire TOKENS_CONTROL_fifo_ids_ready;
    wire TOKENS_CONTROL_register_wvalid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_CONTROL_register_wdata;
    wire TOKENS_CONTROL_register_awvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] TOKENS_CONTROL_register_awaddr;
    wire TOKENS_CONTROL_register_custom_reset;

    wire [10:0] TOKENS_CONTROL_prompt_counter;
    wire TOKENS_CONTROL_prompt_counter_valid ;
    wire [10:0] TOKENS_CONTROL_max_sequence_buffer;
    wire TOKENS_CONTROL_register_rvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] TOKENS_CONTROL_register_raddr;


    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_CONTROL_register_rdata ;
    wire TOKENS_CONTROL_register_rdata_valid ;
    wire TOKENS_CONTROL_prompt_ids_ready ;

    wire TOKENS_CONTROL_prompt_ids_valid ;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_CONTROL_prompt_ids_data ; 

    wire [3:0] TOKENS_CONTROL_state_dbg;

    wire TOKENS_REGISTER_wvalid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_REGISTER_wdata;
    wire TOKENS_REGISTER_awvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] TOKENS_REGISTER_awaddr;

    wire TOKENS_REGISTER_custom_reset;
    wire TOKENS_REGISTER_rvalid;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] TOKENS_REGISTER_raddr;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] TOKENS_REGISTER_rdata;
    wire TOKENS_REGISTER_rdata_valid;

    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] UART_WRAPPER_prompt_id_data;
    wire UART_WRAPPER_prompt_id_valid;
    wire UART_WRAPPER_prompt_id_ready;

    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] UART_WRAPPER_max_id_data;
    wire UART_WRAPPER_max_id_ready;
    wire UART_WRAPPER_max_id_valid;

    wire UART_RX_CDC_FIFO_wvalid;
    wire UART_RX_CDC_FIFO_wready;
    wire UART_RX_CDC_FIFO_wfull;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] UART_RX_CDC_FIFO_wdata;

    wire UART_RX_CDC_FIFO_rready;
    wire UART_RX_CDC_FIFO_rvalid;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] UART_RX_CDC_FIFO_rdata;
    wire UART_RX_CDC_FIFO_rempty;



    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] MAX_ID_CDC_FIFO_rdata;
    wire        MAX_ID_CDC_FIFO_rvalid;
    wire        MAX_ID_CDC_FIFO_rready;
    wire        MAX_ID_CDC_FIFO_rempty;

    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] MAX_ID_CDC_FIFO_wdata;
    wire        MAX_ID_CDC_FIFO_wvalid;
    wire        MAX_ID_CDC_FIFO_wready;
    wire        MAX_ID_CDC_FIFO_wfull;


    assign MAX_ID_CDC_FIFO_wdata  = i_max_id_data;
    assign MAX_ID_CDC_FIFO_wvalid = i_max_id_valid;
    assign o_max_id_ready         = MAX_ID_CDC_FIFO_wready;
    assign MAX_ID_CDC_FIFO_wready = ~MAX_ID_CDC_FIFO_wfull;

    assign UART_WRAPPER_max_id_data  = MAX_ID_CDC_FIFO_rdata;
    assign UART_WRAPPER_max_id_valid = MAX_ID_CDC_FIFO_rvalid;
    assign MAX_ID_CDC_FIFO_rready    = UART_WRAPPER_max_id_ready;
    assign MAX_ID_CDC_FIFO_rvalid    = ~MAX_ID_CDC_FIFO_rempty;




    assign o_prompt_counter       = TOKENS_CONTROL_prompt_counter;
    assign o_prompt_counter_valid = TOKENS_CONTROL_prompt_counter_valid ;
    assign o_max_sequence_buffer  = TOKENS_CONTROL_max_sequence_buffer;

    assign o_prompt_ids_data      = TOKENS_CONTROL_prompt_ids_data;
    assign o_prompt_ids_valid     = TOKENS_CONTROL_prompt_ids_valid ;
    assign o_custom_reset         = TOKENS_CONTROL_register_custom_reset;


    assign TOKENS_REGISTER_custom_reset = TOKENS_CONTROL_register_custom_reset;
    assign TOKENS_REGISTER_wdata        = TOKENS_CONTROL_register_wdata;
    assign TOKENS_REGISTER_awaddr       = TOKENS_CONTROL_register_awaddr;
    assign TOKENS_REGISTER_wvalid       = TOKENS_CONTROL_register_wvalid;
    assign TOKENS_REGISTER_awvalid      = TOKENS_CONTROL_register_awvalid;
    assign TOKENS_REGISTER_rvalid       = TOKENS_CONTROL_register_rvalid;
    assign TOKENS_REGISTER_raddr        = TOKENS_CONTROL_register_raddr;



    assign TOKENS_CONTROL_register_rdata = TOKENS_REGISTER_rdata ;
    assign TOKENS_CONTROL_register_rdata_valid = TOKENS_REGISTER_rdata_valid ;
    assign TOKENS_CONTROL_prompt_ids_ready = i_prompt_ids_ready ;



    assign UART_RX_CDC_FIFO_wready       = ~UART_RX_CDC_FIFO_wfull;
    assign UART_RX_CDC_FIFO_rvalid       = ~UART_RX_CDC_FIFO_rempty;
    assign UART_RX_CDC_FIFO_wdata        = UART_WRAPPER_prompt_id_data;
    assign UART_RX_CDC_FIFO_wvalid       = UART_WRAPPER_prompt_id_valid;
    assign UART_WRAPPER_prompt_id_ready  = UART_RX_CDC_FIFO_wready;

    assign TOKENS_CONTROL_fifo_ids_data  = UART_RX_CDC_FIFO_rdata;
    assign TOKENS_CONTROL_fifo_ids_valid = UART_RX_CDC_FIFO_rvalid;
    assign UART_RX_CDC_FIFO_rready       = TOKENS_CONTROL_fifo_ids_ready;

    // =========================
    // debug assign
    // =========================
    assign o_dbg_tokens_state      = TOKENS_CONTROL_state_dbg;
    assign o_dbg_uart_prompt_valid = UART_WRAPPER_prompt_id_valid;
    assign o_dbg_uart_prompt_data  = UART_WRAPPER_prompt_id_data;
    assign o_dbg_cdc_wvalid        = UART_RX_CDC_FIFO_wvalid;
    assign o_dbg_cdc_wready        = UART_RX_CDC_FIFO_wready;
    assign o_dbg_cdc_rvalid        = UART_RX_CDC_FIFO_rvalid;
    assign o_dbg_cdc_rdata         = UART_RX_CDC_FIFO_rdata;
    assign o_dbg_ctrl_fifo_valid   = TOKENS_CONTROL_fifo_ids_valid;
    assign o_dbg_ctrl_fifo_data    = TOKENS_CONTROL_fifo_ids_data;
    assign o_dbg_reg_wvalid        = TOKENS_CONTROL_register_wvalid;
    assign o_dbg_reg_awvalid       = TOKENS_CONTROL_register_awvalid;
    assign o_dbg_reg_awaddr        = TOKENS_CONTROL_register_awaddr;
    assign o_dbg_reg_rvalid        = TOKENS_CONTROL_register_rvalid;
    assign o_dbg_reg_raddr         = TOKENS_CONTROL_register_raddr;



    wire dbg_bram_we;
    wire dbg_bram_en;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_bram_addr;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0]     dbg_bram_dout;
    wire dbg_tokreg_rvalid_in;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] dbg_tokreg_raddr_in;
    (* mark_debug = "true" *) wire [TOKENS_REGISTER_DATA_WIDTH-1:0] dbg_bram_din;
    assign o_dbg_bram_we         = dbg_bram_we;
    assign o_dbg_bram_en         = dbg_bram_en;
    assign o_dbg_bram_addr       = dbg_bram_addr;
    assign o_dbg_bram_dout       = dbg_bram_dout;
    assign o_dbg_tokreg_rvalid_in = dbg_tokreg_rvalid_in;
    assign o_dbg_tokreg_raddr_in  = dbg_tokreg_raddr_in;
    assign o_dbg_tokreg_rdata_valid = TOKENS_REGISTER_rdata_valid;
    assign o_dbg_bram_din = dbg_bram_din;




    FIFO_TOP #(
        .ADDR_WIDTH(2),
        .DATA_WIDTH(18)
    ) MAX_ID_CDC_FIFO (
        .W_CLK   ( i_clk_MPU     ),
        .W_rst_n (  i_rst_n_MPU     ),
        .W_inc   (MAX_ID_CDC_FIFO_wvalid),
        .W_Data  (MAX_ID_CDC_FIFO_wdata),
        .Full    (MAX_ID_CDC_FIFO_wfull),

        .R_CLK   (i_clk_UART),
        .R_rst_n (i_rst_n_UART),
        .R_inc   (MAX_ID_CDC_FIFO_rready),
        .R_Data  (MAX_ID_CDC_FIFO_rdata),
        .Empty   (MAX_ID_CDC_FIFO_rempty)
    );


    FIFO_TOP #(
        .ADDR_WIDTH(2),
        .DATA_WIDTH(18)
    ) UART_RX_CDC_FIFO (
        .W_CLK (i_clk_UART),
        .W_rst_n(i_rst_n_UART),
        .W_inc (UART_RX_CDC_FIFO_wvalid),
        .W_Data(UART_RX_CDC_FIFO_wdata),
        .Full  (UART_RX_CDC_FIFO_wfull),

        .R_CLK (i_clk_DMA),
        .R_rst_n(i_rst_n_DMA),
        .R_inc (UART_RX_CDC_FIFO_rready),
        .R_Data(UART_RX_CDC_FIFO_rdata),
        .Empty (UART_RX_CDC_FIFO_rempty)
    );

    UART_WRAPPER u_UART_WRAPPER (
        .i_rst_n         (i_rst_n_UART),
        .i_clk           (i_clk_UART),
        .uart_rx         (uart_rx),
        .uart_tx         (uart_tx),
        .i_max_id_data   (UART_WRAPPER_max_id_data),
        .i_max_id_valid  (UART_WRAPPER_max_id_valid),
        .o_max_id_ready  (UART_WRAPPER_max_id_ready),
        .o_prompt_id_data(UART_WRAPPER_prompt_id_data),
        .i_prompt_id_ready(UART_WRAPPER_prompt_id_ready),
        .o_prompt_id_valid(UART_WRAPPER_prompt_id_valid)
    );

    TOKENS_CONTROL u_TOKENS_CONTROL(
        .i_rst_n                  (i_rst_n_DMA),
        .i_clk                    (i_clk_DMA),
        .i_fifo_ids_valid         (TOKENS_CONTROL_fifo_ids_valid),
        .i_fifo_ids_data          (TOKENS_CONTROL_fifo_ids_data),
        .o_fifo_ids_ready         (TOKENS_CONTROL_fifo_ids_ready),

        .o_register_wvalid        (TOKENS_CONTROL_register_wvalid),
        .o_register_wdata         (TOKENS_CONTROL_register_wdata),
        .o_register_awvalid       (TOKENS_CONTROL_register_awvalid),
        .o_register_awaddr        (TOKENS_CONTROL_register_awaddr),

        .o_register_rvalid        (TOKENS_CONTROL_register_rvalid),
        .o_register_raddr         (TOKENS_CONTROL_register_raddr),


        .o_register_custom_reset  (TOKENS_CONTROL_register_custom_reset),
        .o_prompt_counter         (TOKENS_CONTROL_prompt_counter),
        .o_prompt_counter_valid   (TOKENS_CONTROL_prompt_counter_valid),
        .o_max_sequence_buffer    (TOKENS_CONTROL_max_sequence_buffer),
        .o_prompt_ids_valid       (TOKENS_CONTROL_prompt_ids_valid ) ,
        .i_prompt_ids_ready       (TOKENS_CONTROL_prompt_ids_ready ) ,
        .o_dbg_state              (TOKENS_CONTROL_state_dbg),
        .o_prompt_ids_data        (TOKENS_CONTROL_prompt_ids_data),
        .i_register_rdata_valid   (TOKENS_CONTROL_register_rdata_valid),
        .i_register_rdata         (TOKENS_CONTROL_register_rdata)
    );





    TOKENS_REGISTER u_TOKENS_REGISTER(
        .i_rst_n         (i_rst_n_DMA),
        .i_clk           (i_clk_DMA),
        .i_wvalid        (TOKENS_REGISTER_wvalid),
        .i_wdata         (TOKENS_REGISTER_wdata),
        .i_awvalid       (TOKENS_REGISTER_awvalid),
        .i_awaddr        (TOKENS_REGISTER_awaddr),
        .i_custom_reset  (TOKENS_REGISTER_custom_reset),
        .i_rvalid        (TOKENS_REGISTER_rvalid),
        .i_raddr         (TOKENS_REGISTER_raddr),
        .o_rdata         (TOKENS_REGISTER_rdata),
        .o_rdata_valid   (TOKENS_REGISTER_rdata_valid),

        .o_dbg_bram_we   (dbg_bram_we),
        .o_dbg_bram_en   (dbg_bram_en),
        .o_dbg_bram_addr (dbg_bram_addr),
        .o_dbg_bram_dout (dbg_bram_dout),
        .o_dbg_i_rvalid  (dbg_tokreg_rvalid_in),
        .o_dbg_i_raddr   (dbg_tokreg_raddr_in),
        .o_dbg_bram_din (dbg_bram_din)
    );

endmodule

module TOKENS_CONTROL #(
    parameter TOKENS_REGISTER_BANK_NUM = 1,
    parameter TOKENS_REGISTER_DATA_WIDTH = 18,
    parameter TOKENS_REGISTER_BANK_DEPTH = 2048,
    parameter TOKENS_REGISTER_BANK_DEPTH_BIT = $clog2(TOKENS_REGISTER_BANK_DEPTH),
    parameter TOKENS_START_IDS = 18'h3FFFE,
    parameter TOKENS_END_IDS = 18'h3FFFF,
    parameter RESET_IDS = 18'h3FFFA,
    parameter CHANGE_MAXSEQUENCE_START_IDS = 18'h3FFFB,
    parameter CHANGE_MAXSEQUENCE_END_IDS = 18'h3FFFC,
    parameter DEFAULT_MAXSEQUENCE = 11'd1024
)(
    input i_clk,
    input i_rst_n,
    input i_fifo_ids_valid,
    input [TOKENS_REGISTER_DATA_WIDTH-1:0] i_fifo_ids_data,


    input [TOKENS_REGISTER_DATA_WIDTH-1:0] i_register_rdata ,
    input i_register_rdata_valid ,
    output o_fifo_ids_ready,

    output reg o_register_wvalid,
    output reg [TOKENS_REGISTER_DATA_WIDTH-1:0] o_register_wdata,
    output reg o_register_awvalid,
    output reg [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_register_awaddr,

    output reg o_register_rvalid,
    output reg [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_register_raddr,

    output o_prompt_ids_valid ,
    input  i_prompt_ids_ready ,
    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_prompt_ids_data , 

    output reg o_register_custom_reset,
    output [10:0] o_prompt_counter,
    output o_prompt_counter_valid ,
    output [10:0] o_max_sequence_buffer,

    // debug
    output [3:0] o_dbg_state
);

    parameter S_IDLE = 4'd0,
              S_TOKEN_TRANSFER = 4'd1,
              S_START_INFERRENCE = 4'd2,
              S_CLEAR = 4'd3,
              S_SEND_TOKEN = 4'd5,
              S_CHANGE_MAX_SEQUENCE_LENGTH = 4'd6;


    parameter S_READ_REGISTER = 3'd0;
    parameter S_WAIT_REGISTER = 3'd1 ; 
    parameter S_PROMPT_HANDSHAKE = 3'd2 ; 


    reg [TOKENS_REGISTER_DATA_WIDTH-1:0] prompt_ids_cache_r , prompt_ids_cache_w ;
    reg [2:0] send_prompt_state_r , send_prompt_state_w ;

    reg [3:0] state_r, state_w;
    reg [10:0] prompt_ids_counter_r, prompt_ids_counter_w;
    reg [10:0] max_sequence_buffer_r, max_sequence_buffer_w;
    reg [10:0] token_send_cnt_r, token_send_cnt_w;

    assign o_fifo_ids_ready = (state_r == S_IDLE) ||(state_r == S_TOKEN_TRANSFER) ||(state_r == S_CHANGE_MAX_SEQUENCE_LENGTH);
        
        
    
    assign o_prompt_counter      = prompt_ids_counter_r;
    assign o_max_sequence_buffer = max_sequence_buffer_r;
    assign o_dbg_state           = state_r;



    assign o_prompt_ids_data = prompt_ids_cache_r ;
    assign o_prompt_ids_valid = ( state_r ==  S_SEND_TOKEN &&  send_prompt_state_r == S_PROMPT_HANDSHAKE  ) ;

    assign o_prompt_counter_valid =
        (state_r == S_SEND_TOKEN) &&
        (send_prompt_state_r == S_PROMPT_HANDSHAKE) &&
        (token_send_cnt_r ==  prompt_ids_counter_r - 1'b1) &&
        (i_prompt_ids_ready == 1'b1);

    
    always @(*) begin
        prompt_ids_cache_w = prompt_ids_cache_r ;
        if(state_r == S_SEND_TOKEN && send_prompt_state_r == S_WAIT_REGISTER )begin
            if( i_register_rdata_valid == 1'b1  )begin
                prompt_ids_cache_w = i_register_rdata ;
            end
        end
    end
    always @(*) begin
        send_prompt_state_w = send_prompt_state_r ;
        if( state_r == S_SEND_TOKEN  )begin
            case (send_prompt_state_r)
                S_READ_REGISTER: send_prompt_state_w = S_WAIT_REGISTER ;
                S_WAIT_REGISTER: begin
                    if( i_register_rdata_valid == 1'b1  )begin
                        send_prompt_state_w =  S_PROMPT_HANDSHAKE;
                    end
                    
                end
                S_PROMPT_HANDSHAKE:begin
                    if(i_prompt_ids_ready == 1'b1)begin
                        send_prompt_state_w = S_READ_REGISTER ;
                    end
                end
            endcase
        end
        else if ( state_r == S_START_INFERRENCE)begin
            send_prompt_state_w =  S_READ_REGISTER ;
        end

    end
    always @(*) begin
        o_register_rvalid = 1'b0;
        o_register_raddr  = {TOKENS_REGISTER_BANK_DEPTH_BIT{1'b0}};
        if(state_r == S_SEND_TOKEN &&   send_prompt_state_r ==    S_READ_REGISTER )begin
            o_register_rvalid = 1'b1;
            o_register_raddr  = token_send_cnt_r;
        end
    end

    always @(*) begin
        token_send_cnt_w = token_send_cnt_r;
        if( state_r == S_SEND_TOKEN && send_prompt_state_r == S_PROMPT_HANDSHAKE && i_prompt_ids_ready== 1'b1 )begin
            token_send_cnt_w = token_send_cnt_r + 1'b1;
        end
        else if (  state_r == S_START_INFERRENCE  )begin
            token_send_cnt_w = 0;
        end
    end



    always @(*) begin
        o_register_custom_reset = 1'b0;
        if(state_r == S_CLEAR)
            o_register_custom_reset = 1'b1;
    end

    always @(*) begin
        max_sequence_buffer_w = max_sequence_buffer_r;
        case(state_r)
            S_CHANGE_MAX_SEQUENCE_LENGTH: begin
                if(i_fifo_ids_valid && o_fifo_ids_ready &&
                   (i_fifo_ids_data != CHANGE_MAXSEQUENCE_END_IDS)) begin
                    max_sequence_buffer_w = i_fifo_ids_data[10:0];
                end
            end
        endcase
    end

    always @(*) begin
        state_w = state_r;
        case(state_r)
            S_IDLE: begin
                if(i_fifo_ids_valid && o_fifo_ids_ready) begin
                    case(i_fifo_ids_data)
                        TOKENS_START_IDS:              state_w = S_TOKEN_TRANSFER;
                        CHANGE_MAXSEQUENCE_START_IDS:  state_w = S_CHANGE_MAX_SEQUENCE_LENGTH;
                        RESET_IDS:                     state_w = S_CLEAR;
                        default:                       state_w = S_IDLE;
                    endcase
                end
            end

            S_CHANGE_MAX_SEQUENCE_LENGTH: begin
                if(i_fifo_ids_valid && o_fifo_ids_ready &&
                   i_fifo_ids_data == CHANGE_MAXSEQUENCE_END_IDS)
                    state_w = S_IDLE;
            end

            S_TOKEN_TRANSFER: begin
                if(i_fifo_ids_valid && o_fifo_ids_ready &&
                   i_fifo_ids_data == TOKENS_END_IDS)
                    state_w = S_START_INFERRENCE;
            end

            S_START_INFERRENCE: begin
                state_w = S_SEND_TOKEN;
            end

            S_SEND_TOKEN: begin
                if (prompt_ids_counter_r == 0)begin
                    state_w = S_IDLE;
                end
                else if (send_prompt_state_r == S_PROMPT_HANDSHAKE &&i_prompt_ids_ready == 1'b1 && token_send_cnt_r == prompt_ids_counter_r - 1 )begin
                    state_w = S_IDLE;
                end
                else begin
                    state_w = S_SEND_TOKEN ;
                end
            end

            S_CLEAR: begin
                state_w = S_IDLE;
            end

            default: begin
                state_w = S_IDLE;
            end
        endcase
    end

    always @(*) begin
        o_register_wdata = 0;
        case(state_r)
            S_TOKEN_TRANSFER: begin
                if(i_fifo_ids_valid  == 1'b1 && o_fifo_ids_ready == 1'b1)
                    o_register_wdata = i_fifo_ids_data;
            end
        endcase
    end

    always @(*) begin
        o_register_awvalid = 1'b0;
        o_register_wvalid  = 1'b0;
        case(state_r)
            S_TOKEN_TRANSFER: begin
                if(i_fifo_ids_valid && o_fifo_ids_ready &&
                   (i_fifo_ids_data != TOKENS_END_IDS)) begin
                    o_register_awvalid = 1'b1;
                    o_register_wvalid  = 1'b1;
                end
            end
        endcase
    end

    always @(*) begin
        o_register_awaddr = 0;
        if(state_r == S_TOKEN_TRANSFER)
            o_register_awaddr = prompt_ids_counter_r;
    end

    always @(*) begin
        prompt_ids_counter_w = prompt_ids_counter_r;
        if(o_register_custom_reset) begin
            prompt_ids_counter_w = 0;
        end
        else if(state_r == S_IDLE && state_w == S_TOKEN_TRANSFER) begin
            prompt_ids_counter_w = 0;
        end
        else begin
            if(state_r == S_TOKEN_TRANSFER &&i_fifo_ids_valid && o_fifo_ids_ready &&(i_fifo_ids_data != TOKENS_END_IDS) &&(i_fifo_ids_data != TOKENS_START_IDS)) begin
                prompt_ids_counter_w = prompt_ids_counter_r + 1'b1;
            end
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            prompt_ids_counter_r  <= 0;
            state_r               <= S_IDLE;
            max_sequence_buffer_r <= DEFAULT_MAXSEQUENCE;
            token_send_cnt_r      <= 0;
            send_prompt_state_r   <= 0;
            prompt_ids_cache_r    <= 0;
        end
        else begin
            prompt_ids_counter_r  <= prompt_ids_counter_w;
            state_r               <= state_w;
            max_sequence_buffer_r <= max_sequence_buffer_w;
            token_send_cnt_r      <= token_send_cnt_w;
            send_prompt_state_r   <= send_prompt_state_w ;
            prompt_ids_cache_r    <= prompt_ids_cache_w ;
        end
    end

endmodule


/////// Has output register
module blk_mem_gen_0_vcs #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 11   // depth = 1024
)(
    input  wire                     clka,
    input  wire                     ena,
    input  wire   wea,   // byte write enable
    input  wire [ADDR_WIDTH-1:0]    addra,
    input  wire [DATA_WIDTH-1:0]    dina,
    output reg  [DATA_WIDTH-1:0]    douta
);

    // memory
    reg   [0:(1<<ADDR_WIDTH)-1][DATA_WIDTH-1:0]   mem_r , mem_w ;
    reg  [DATA_WIDTH-1:0]  dout ;

    reg  [DATA_WIDTH-1:0] dout_r ;

    wire  [DATA_WIDTH-1:0 ] dout_w ;
    reg   [DATA_WIDTH-1:0] dout_d_r ;

    wire [DATA_WIDTH-1:0] dout_d_w ;


    assign dout_w = dout ;
    assign  dout_d_w  = dout_r ;
    assign douta   =dout_r;
    always@(*)begin
        mem_w = mem_r ;
        if(ena == 1'b1  && wea == 1'b1)begin
            mem_w [addra ] = dina  ;
        end
    end


    always@(*)begin
        if(ena == 1'b1  && wea == 1'b0)begin
            dout  = mem_r [addra ] ;
        end
        else begin
            dout  = 0 ;
        end
    end

    // synchronous BRAM behavior
    always @(posedge clka) begin
        mem_r <= mem_w ;
        dout_r <= dout_w ;
        dout_d_r <= dout_d_w ;
    end




endmodule



module TOKENS_REGISTER #(
    parameter TOKENS_REGISTER_DATA_WIDTH      = 18,
    parameter TOKENS_REGISTER_BANK_DEPTH      = 2048,
    parameter TOKENS_REGISTER_BANK_DEPTH_BIT  = $clog2(TOKENS_REGISTER_BANK_DEPTH)
)(
    input  wire i_clk,
    input  wire i_rst_n,

    input  wire i_wvalid,
    input  wire [TOKENS_REGISTER_DATA_WIDTH-1:0] i_wdata,
    input  wire i_awvalid,
    input  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] i_awaddr,

    input  wire i_custom_reset,

    input  wire i_rvalid,
    input  wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] i_raddr,
    output wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_rdata,
    output wire o_rdata_valid,

    // debug
    output wire o_dbg_bram_we,
    output wire o_dbg_bram_en,
    output wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_bram_addr,
    output wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_bram_dout,
    output wire o_dbg_i_rvalid,
    output wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] o_dbg_i_raddr, 
    output wire [TOKENS_REGISTER_DATA_WIDTH-1:0] o_dbg_bram_din
);








    wire bram_we;
    reg bram_en ;
    wire [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] bram_addr;
    wire [TOKENS_REGISTER_DATA_WIDTH-1:0] bram_dout;




    reg  [TOKENS_REGISTER_BANK_DEPTH_BIT-1:0] bram_addr_r , bram_addr_w;
    reg  bram_en_r , bram_en_w; 
    reg  bram_we_r , bram_we_w ;
    
    reg  [TOKENS_REGISTER_DATA_WIDTH-1:0] wdata_r , wdata_w;



    assign bram_we = i_wvalid && i_awvalid;
    assign bram_addr = bram_we ? i_awaddr : i_raddr;

    

    assign o_rdata = bram_dout ;

    // 不做反向地址，直接正向使用
    // 有寫入時優先走寫地址，否則走讀地址
    




    reg rdata_valid ;
    reg rdata_valid_r ,  rdata_valid_w ;
    reg rdata_valid_d1_r ,  rdata_valid_d1_w ;
    reg rdata_valid_d2_r ,  rdata_valid_d2_w ;

    assign o_rdata_valid  = rdata_valid_d1_r  ;


     always@(*)begin
        wdata_w = i_wdata ;
        bram_en_w = bram_en ;
        bram_we_w = bram_we ;
        bram_addr_w  = bram_addr;
        rdata_valid_w = i_rvalid ;
        rdata_valid_d1_w = rdata_valid_r ;
        rdata_valid_d2_w = rdata_valid_d1_r ;
    end   


    assign o_dbg_bram_we   = bram_we;
    assign o_dbg_bram_en   = bram_en;
    assign o_dbg_bram_addr = bram_addr;
    assign o_dbg_bram_dout = bram_dout;
    assign o_dbg_i_rvalid  = i_rvalid;
    assign o_dbg_i_raddr   = i_raddr;
    assign o_dbg_bram_din = i_wdata;

    always@(*)begin
        if(  bram_we == 1 || i_rvalid == 1 )begin
            bram_en = 1'b1 ;
        end
        else begin
            bram_en = 1'b0 ;
        end
    end

    always@(*)begin
        if(bram_we  == 1'b1)begin
            rdata_valid = 1'b0 ;
        end
        else begin
            rdata_valid = i_rvalid  ;
        end
    end


    `ifdef VCS_SIM
        blk_mem_gen_0_vcs #(
            .DATA_WIDTH(TOKENS_REGISTER_DATA_WIDTH),
            .ADDR_WIDTH(TOKENS_REGISTER_BANK_DEPTH_BIT)
        ) u_bram (
            .clka  (i_clk),
            .wea   (bram_we_r),
            .ena   (bram_en_r) ,
            .addra (bram_addr_r),
            .dina  (wdata_r),
            .douta (bram_dout)
        );
    `elsif VHK_158
        blk_mem_gen_0 u_bram 
           (
            .BRAM_PORTA_0_addr(bram_addr_r),
            .BRAM_PORTA_0_clk(i_clk),
            .BRAM_PORTA_0_din(wdata_r),
            .BRAM_PORTA_0_dout(bram_dout),
            .BRAM_PORTA_0_en(bram_en_r),
            .BRAM_PORTA_0_rst(~ i_rst_n),
            .BRAM_PORTA_0_we(bram_we_r),
            .regcea_0 (1'b1)

            );
    `else 
        blk_mem_gen_0 u_bram (
            .clka  (i_clk),
            .wea   (bram_we_r),
            .ena   (bram_en_r) ,
            .addra (bram_addr_r),
            .dina  (wdata_r),
            .douta (bram_dout)
        );
    `endif

    always@(posedge i_clk )begin
        if(i_rst_n == 1'b0)begin
            rdata_valid_r <= 0 ;
            rdata_valid_d1_r <= 0 ;
            rdata_valid_d2_r <= 0 ;
            bram_we_r <= 0 ;
            bram_en_r <= 0 ;
            bram_addr_r <= 0 ;
            wdata_r <= 0 ;
        end
        else begin
            rdata_valid_r <= rdata_valid_w ;
            rdata_valid_d1_r <= rdata_valid_d1_w ;
            rdata_valid_d2_r <= rdata_valid_d2_w ;
            bram_we_r <= bram_we_w ;
            bram_en_r <= bram_en_w ;
            bram_addr_r <= bram_addr_w ;
            wdata_r <= wdata_w ;
        end
    end



endmodule



module UART_WRAPPER #(
    parameter UART_TX_FIFO_DATA_IN_BIT = 18 ,
    parameter UART_TX_FIFO_DATA_OUT_BIT = 6 ,
    parameter UART_RX_FIFO_DATA_IN_BIT = 6 ,
    parameter UART_RX_FIFO_DATA_OUT_BIT = 18 ,
    parameter  TOKENS_REGISTER_DATA_WIDTH = 18
    )(



    input i_clk ,
    input i_rst_n ,
    input i_max_id_valid ,
    input [TOKENS_REGISTER_DATA_WIDTH-1:0] i_max_id_data ,

    output o_max_id_ready ,

    output wire uart_tx ,    // UART TX to PC
    input wire uart_rx  ,


    output [TOKENS_REGISTER_DATA_WIDTH-1:0] o_prompt_id_data ,
    output o_prompt_id_valid ,
    input i_prompt_id_ready


    );






    wire UART_LITE_awvalid, UART_LITE_wvalid, UART_LITE_bready;
    wire UART_LITE_awready, UART_LITE_wready, UART_LITE_bvalid;
    wire [3:0] UART_LITE_awaddr;
    wire [31:0] UART_LITE_wdata;
    wire [1:0] UART_LITE_bresp;
    
    
    wire UART_LITE_arvalid, UART_LITE_rvalid;
    wire UART_LITE_arready, UART_LITE_rready;
    wire [3:0] UART_LITE_araddr;
    wire [31:0] UART_LITE_rdata;
    wire [1:0] UART_LITE_rresp ;



    wire MASTER_uart_awvalid, MASTER_uart_wvalid, MASTER_uart_bready;
    wire MASTER_uart_awready, MASTER_uart_wready, MASTER_uart_bvalid;
    wire [3:0] MASTER_uart_awaddr;
    wire [31:0] MASTER_uart_wdata;
    wire [1:0] MASTER_uart_bresp;
    
    
    wire MASTER_uart_arvalid, MASTER_uart_rvalid;
    wire MASTER_uart_arready, MASTER_uart_rready;
    wire [3:0] MASTER_uart_araddr;
    wire [31:0] MASTER_uart_rdata;
    wire [1:0] MASTER_uart_rresp ;



    wire MASTER_tx_fifo_rready ;  
    wire MASTER_tx_fifo_rvalid ;
    wire [UART_TX_FIFO_DATA_OUT_BIT-1:0] MASTER_tx_fifo_rdata ;

    wire MASTER_rx_fifo_wready ;  
    wire MASTER_rx_fifo_wvalid ;
    wire [UART_RX_FIFO_DATA_IN_BIT-1:0] MASTER_rx_fifo_wdata ;


    wire [UART_TX_FIFO_DATA_IN_BIT-1:0] UART_TX_FIFO_wdata ;
    wire [UART_TX_FIFO_DATA_OUT_BIT-1:0] UART_TX_FIFO_rdata ;
    wire UART_TX_FIFO_wvalid ;
    wire UART_TX_FIFO_wready ;
    wire UART_TX_FIFO_rvalid ;
    wire UART_TX_FIFO_rready ;


    wire [UART_RX_FIFO_DATA_IN_BIT-1:0] UART_RX_FIFO_wdata ;
    wire [UART_RX_FIFO_DATA_OUT_BIT-1:0] UART_RX_FIFO_rdata ;
    wire UART_RX_FIFO_wvalid ;
    wire UART_RX_FIFO_wready ;
    wire UART_RX_FIFO_rvalid ;
    wire UART_RX_FIFO_rready ;

    

    assign o_max_id_ready = UART_TX_FIFO_wready ;
    assign UART_TX_FIFO_wvalid = i_max_id_valid ;
    assign UART_TX_FIFO_wdata = i_max_id_data ; 


    assign  o_prompt_id_data = UART_RX_FIFO_rdata ;
    assign o_prompt_id_valid = UART_RX_FIFO_rvalid ;
    assign UART_RX_FIFO_rready  = i_prompt_id_ready ;
 

    assign UART_TX_FIFO_rready = MASTER_tx_fifo_rready ; //FIFO require tx
    assign MASTER_tx_fifo_rvalid = UART_TX_FIFO_rvalid ; 
    assign MASTER_tx_fifo_rdata = UART_TX_FIFO_rdata ;
    
    // Write Address Channel
    assign UART_LITE_awvalid = MASTER_uart_awvalid;  // M -> S
    assign UART_LITE_awaddr  = MASTER_uart_awaddr;   // M -> S
    assign MASTER_uart_awready    = UART_LITE_awready; // S -> M

    // Write Data Channel
    assign UART_LITE_wvalid  = MASTER_uart_wvalid;   // M -> S
    assign UART_LITE_wdata   = MASTER_uart_wdata;    // M -> S
    assign MASTER_uart_wready     = UART_LITE_wready;  // S -> M

    // Write Response Channel
    assign MASTER_uart_bvalid     = UART_LITE_bvalid; // S -> M
    assign MASTER_uart_bresp      = UART_LITE_bresp;  // S -> M
    assign UART_LITE_bready  = MASTER_uart_bready;    // M -> S

    // Read Address Channel
    assign UART_LITE_arvalid = MASTER_uart_arvalid; // M -> S
    assign UART_LITE_araddr  = MASTER_uart_araddr;  // M -> S
    assign MASTER_uart_arready    = UART_LITE_arready; // S -> M

    // Read Data Channel
    assign MASTER_uart_rvalid     = UART_LITE_rvalid; // S -> M
    assign MASTER_uart_rdata      = UART_LITE_rdata;  // S -> M
    assign MASTER_uart_rresp      = UART_LITE_rresp;  // S -> M
    assign UART_LITE_rready  = MASTER_uart_rready;    // M -> S



    assign UART_RX_FIFO_wdata = MASTER_rx_fifo_wdata ;
    assign UART_RX_FIFO_wvalid = MASTER_rx_fifo_wvalid ;
    assign MASTER_rx_fifo_wready = UART_RX_FIFO_wready ;
    

    `ifdef VCS_SIM
        axi_uartlite_0_fake uart_inst_0 (
            .s_axi_aclk(i_clk),
            .s_axi_aresetn(i_rst_n),

            .s_axi_awaddr(UART_LITE_awaddr),
            .s_axi_awvalid(UART_LITE_awvalid),
            .s_axi_awready(UART_LITE_awready),

            .s_axi_wdata(UART_LITE_wdata),
            .s_axi_wvalid(UART_LITE_wvalid),
            .s_axi_wready(UART_LITE_wready),

            .s_axi_bresp(UART_LITE_bresp),
            .s_axi_bvalid(UART_LITE_bvalid),
            .s_axi_bready(UART_LITE_bready),

            .s_axi_araddr(UART_LITE_araddr),
            .s_axi_arvalid(UART_LITE_arvalid),
            .s_axi_rready(UART_LITE_rready),
            .s_axi_arready(UART_LITE_arready),
            .s_axi_rdata(UART_LITE_rdata),
            .s_axi_rresp(UART_LITE_rresp),
            .s_axi_rvalid(UART_LITE_rvalid),
            
            .s_axi_wstrb(4'd0),
            // .s_axi_arprot(3'd0),
            // .s_axi_awprot(3'd0),

            .rx(uart_rx),        
            .tx(uart_tx),
            .interrupt()
        );
    `elsif FPGA_SIM
        axi_uartlite_0_fake uart_inst_0 (
            .s_axi_aclk(i_clk),
            .s_axi_aresetn(i_rst_n),

            .s_axi_awaddr(UART_LITE_awaddr),
            .s_axi_awvalid(UART_LITE_awvalid),
            .s_axi_awready(UART_LITE_awready),

            .s_axi_wdata(UART_LITE_wdata),
            .s_axi_wvalid(UART_LITE_wvalid),
            .s_axi_wready(UART_LITE_wready),

            .s_axi_bresp(UART_LITE_bresp),
            .s_axi_bvalid(UART_LITE_bvalid),
            .s_axi_bready(UART_LITE_bready),

            .s_axi_araddr(UART_LITE_araddr),
            .s_axi_arvalid(UART_LITE_arvalid),
            .s_axi_rready(UART_LITE_rready),
            .s_axi_arready(UART_LITE_arready),
            .s_axi_rdata(UART_LITE_rdata),
            .s_axi_rresp(UART_LITE_rresp),
            .s_axi_rvalid(UART_LITE_rvalid),
            
            .s_axi_wstrb(4'd0),
            // .s_axi_arprot(3'd0),
            // .s_axi_awprot(3'd0),

            .rx(uart_rx),        
            .tx(uart_tx),
            .interrupt()
        );

    `else
        axi_uartlite_0 uart_inst_0 (
            .s_axi_aclk(i_clk),
            .s_axi_aresetn(i_rst_n),

            .s_axi_awaddr(UART_LITE_awaddr),
            .s_axi_awvalid(UART_LITE_awvalid),
            .s_axi_awready(UART_LITE_awready),

            .s_axi_wdata(UART_LITE_wdata),
            .s_axi_wvalid(UART_LITE_wvalid),
            .s_axi_wready(UART_LITE_wready),

            .s_axi_bresp(UART_LITE_bresp),
            .s_axi_bvalid(UART_LITE_bvalid),
            .s_axi_bready(UART_LITE_bready),

            .s_axi_araddr(UART_LITE_araddr),
            .s_axi_arvalid(UART_LITE_arvalid),
            .s_axi_rready(UART_LITE_rready),
            .s_axi_arready(UART_LITE_arready),
            .s_axi_rdata(UART_LITE_rdata),
            .s_axi_rresp(UART_LITE_rresp),
            .s_axi_rvalid(UART_LITE_rvalid),
            
            .s_axi_wstrb(4'd0),
            // .s_axi_arprot(3'd0),
            // .s_axi_awprot(3'd0),

            .rx(uart_rx),        
            .tx(uart_tx),
            .interrupt()
        );
    `endif

    axi_uart_master u_axi_uart_master(
        .i_clk                    (i_clk),
        .i_rst_n                  (i_rst_n),
        .o_uart_rready            (MASTER_uart_rready),
        .i_uart_rvalid            (MASTER_uart_rvalid),
        .o_uart_arvalid           (MASTER_uart_arvalid),
        .i_uart_rdata             (MASTER_uart_rdata),
        .o_tx_fifo_rready         (MASTER_tx_fifo_rready),
        .o_uart_wdata             (MASTER_uart_wdata),
        .o_uart_wvalid            (MASTER_uart_wvalid),
        .i_uart_arready           (MASTER_uart_arready),

        .i_uart_wready            (MASTER_uart_wready),
        //.i_uart_wready            (1'b1),        

        .o_uart_araddr            (MASTER_uart_araddr),
        .o_uart_bready            (MASTER_uart_bready),
        .o_uart_awvalid           (MASTER_uart_awvalid),
        .i_tx_fifo_rvalid         (MASTER_tx_fifo_rvalid),

        .i_uart_bresp             (MASTER_uart_bresp),
        .i_uart_bvalid            (MASTER_uart_bvalid),
        //.i_uart_bresp             (2'd0),
        //.i_uart_bvalid            (1'b1),


        .o_uart_awaddr            (MASTER_uart_awaddr),

        .i_uart_awready           (MASTER_uart_awready),
        //.i_uart_awready           (1'b1),

        .i_tx_fifo_rdata          (MASTER_tx_fifo_rdata),
        .i_uart_rresp             (MASTER_uart_rresp) ,


        .o_rx_fifo_wdata (MASTER_rx_fifo_wdata),
        .o_rx_fifo_wvalid (MASTER_rx_fifo_wvalid),
        .i_rx_fifo_wready(MASTER_rx_fifo_wready)
        

        );

    UART_TX_FIFO u_UART_TX_FIFO(
        .i_rst_n                (i_rst_n),
        .i_clk                  (i_clk),
        .i_UART_TX_FIFO_wdata   (UART_TX_FIFO_wdata),
        .o_UART_TX_FIFO_rdata  (UART_TX_FIFO_rdata),
        .i_UART_TX_FIFO_wvalid  (UART_TX_FIFO_wvalid),
        .o_UART_TX_FIFO_wready  (UART_TX_FIFO_wready),
        .o_UART_TX_FIFO_rvalid (UART_TX_FIFO_rvalid),
        .i_UART_TX_FIFO_rready (UART_TX_FIFO_rready)

        
        );

    UART_RX_FIFO u_UART_RX_FIFO(
        .i_rst_n                (i_rst_n),
        .i_clk                  (i_clk),
        .i_UART_RX_FIFO_wdata   (UART_RX_FIFO_wdata),
        .o_UART_RX_FIFO_rdata  (UART_RX_FIFO_rdata),
        .i_UART_RX_FIFO_wvalid  (UART_RX_FIFO_wvalid),
        .o_UART_RX_FIFO_wready  (UART_RX_FIFO_wready),
        .o_UART_RX_FIFO_rvalid (UART_RX_FIFO_rvalid),
        .i_UART_RX_FIFO_rready (UART_RX_FIFO_rready)

        
        );


endmodule 





module UART_RX_FIFO #(
    parameter UART_RX_FIFO_DATA_IN_BIT = 6 ,
    parameter UART_RX_FIFO_DATA_OUT_BIT = 18,
    parameter UART_RX_FIFO_DEPTH = 4 ,
    parameter UART_RX_FIFO_BANK_NUM = 3  ,
    parameter UART_RX_FIFO_BANK_WIDTH = 6 ,
    parameter UART_RX_FIFO_IDX_ADDR_BIT = $clog2(UART_RX_FIFO_DEPTH) +1   //HAVE WRAP BIT

    )
    (

    input i_clk,
    input i_rst_n,
    input [UART_RX_FIFO_DATA_IN_BIT-1:0] i_UART_RX_FIFO_wdata ,
    output reg [UART_RX_FIFO_DATA_OUT_BIT-1:0] o_UART_RX_FIFO_rdata ,
    output reg o_UART_RX_FIFO_wready ,
    input  wire i_UART_RX_FIFO_wvalid ,
    input wire i_UART_RX_FIFO_rready ,
    output  reg o_UART_RX_FIFO_rvalid 

    );

    reg [ UART_RX_FIFO_DEPTH-1:0  ][ UART_RX_FIFO_BANK_NUM-1:0 ][UART_RX_FIFO_BANK_WIDTH-1:0] fifo_bank_r , fifo_bank_w ;
    reg  [UART_RX_FIFO_IDX_ADDR_BIT -1:0] write_idx_r , write_idx_w ;
    reg  [UART_RX_FIFO_IDX_ADDR_BIT -1:0] read_idx_r , read_idx_w ;

    reg [1:0]write_phase_r , write_phase_w ; 
    reg fifo_full ;
    reg fifo_empty ;
    always@(*)begin
        if( fifo_full == 1'b1)begin
            o_UART_RX_FIFO_wready = 1'b0 ;
        end
        else begin
            o_UART_RX_FIFO_wready = 1'b1 ;
        end
    end
    always@(*)begin
        if( fifo_empty == 1'b1)begin
            o_UART_RX_FIFO_rvalid = 1'b0 ;
        end
        else begin
            o_UART_RX_FIFO_rvalid = 1'b1 ;
        end
    end
    always@(*)begin
        if( read_idx_r ==  write_idx_r )begin // Since write will write 16 bits but read only 2 bits 
             fifo_empty = 1'b1 ;
        end
        else begin
            fifo_empty = 1'b0 ;
        end
    end
    always@(*)begin
        if(  write_phase_r == 2'd0 &&  ( read_idx_r [UART_RX_FIFO_IDX_ADDR_BIT-2:0] ==  write_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-2:0] ) &&  (read_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-1]!= write_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-1] )    )   begin // Since write will write 16 bits but read only 2 bits 
             fifo_full = 1'b1 ;
        end
        else begin
            fifo_full = 1'b0 ;
        end
    end

    always@(*)begin

    end
    always@(*)begin
        fifo_bank_w  = fifo_bank_r ;
        if(  o_UART_RX_FIFO_wready == 1'b1 &&  i_UART_RX_FIFO_wvalid == 1'b1  )begin
            case( write_idx_r[ UART_RX_FIFO_IDX_ADDR_BIT-2 : 0 ] ) // write_idx has wrap bit
                2'd0:begin
                    case(write_phase_r)
                        2'd0:fifo_bank_w[0][0] = i_UART_RX_FIFO_wdata;
                        2'd1:fifo_bank_w[0][1] = i_UART_RX_FIFO_wdata;
                        2'd2:fifo_bank_w[0][2] = i_UART_RX_FIFO_wdata;
                    endcase
                    
                end
                2'd1:begin
                    case(write_phase_r)
                        2'd0:fifo_bank_w[1][0] = i_UART_RX_FIFO_wdata;
                        2'd1:fifo_bank_w[1][1] = i_UART_RX_FIFO_wdata;
                        2'd2:fifo_bank_w[1][2] = i_UART_RX_FIFO_wdata;
                    endcase
                end
                2'd2:begin
                    case(write_phase_r)
                        2'd0:fifo_bank_w[2][0] = i_UART_RX_FIFO_wdata;
                        2'd1:fifo_bank_w[2][1] = i_UART_RX_FIFO_wdata;
                        2'd2:fifo_bank_w[2][2] = i_UART_RX_FIFO_wdata;
                    endcase
                end
                2'd3:begin
                    case(write_phase_r)
                        2'd0:fifo_bank_w[3][0] = i_UART_RX_FIFO_wdata;
                        2'd1:fifo_bank_w[3][1] = i_UART_RX_FIFO_wdata;
                        2'd2:fifo_bank_w[3][2] = i_UART_RX_FIFO_wdata;
                    endcase
                end
            endcase
        end
    end
    always@(*)begin
        o_UART_RX_FIFO_rdata = 18'd0; 
        if( !fifo_empty )begin
            o_UART_RX_FIFO_rdata[  5 -: 6]  = fifo_bank_r[read_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-2 : 0]][ 0]; 
            o_UART_RX_FIFO_rdata[ 11 -: 6]  = fifo_bank_r[read_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-2 : 0]][ 1];
            o_UART_RX_FIFO_rdata[ 17 -: 6]  = fifo_bank_r[read_idx_r[UART_RX_FIFO_IDX_ADDR_BIT-2 : 0]][ 2];
        end
    end
    always@(*)begin
        write_phase_w = write_phase_r ;
        if(  o_UART_RX_FIFO_wready == 1'b1 &&  i_UART_RX_FIFO_wvalid == 1'b1 )begin
            if(write_phase_r == 2'd2)begin
                write_phase_w = 2'd0 ;
            end
            else begin
                write_phase_w = write_phase_w + 1'b1 ;
            end

        end
    end
    always@(*)begin
       
        write_idx_w  = write_idx_r ;
        if(  o_UART_RX_FIFO_wready == 1'b1 &&  i_UART_RX_FIFO_wvalid == 1'b1 )begin
            if(write_phase_r == 2'd2)begin
               write_idx_w  = write_idx_r + 1'b1 ; //FIFO DEPTH IS POWER OF 2   
            end
        end
    end
    always@(*)begin
        read_idx_w = read_idx_r ;
        if(  i_UART_RX_FIFO_rready == 1'b1 &&  o_UART_RX_FIFO_rvalid == 1'b1  )begin
            
            read_idx_w  = read_idx_r + 1'b1 ; //FIFO DEPTH IS POWER OF 2  
           
            
        end        
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if(  i_rst_n == 1'b0 )begin
            fifo_bank_r <= 0 ;
            write_idx_r <= 0 ;
            read_idx_r <= 0 ;
            write_phase_r <= 0 ;
         end
        else begin
            fifo_bank_r <= fifo_bank_w ;
            write_idx_r <= write_idx_w ;
            read_idx_r <= read_idx_w ;
            write_phase_r <= write_phase_w ;            
        end
    end
endmodule



module UART_TX_FIFO #(
    parameter UART_TX_FIFO_DATA_IN_BIT = 18 ,
    parameter UART_TX_FIFO_DATA_OUT_BIT = 6 ,
    parameter UART_TX_FIFO_DEPTH = 4 ,
    parameter UART_TX_FIFO_BANK_NUM = 3  ,
    parameter UART_TX_FIFO_BANK_WIDTH = 6 ,
    parameter UART_TX_FIFO_IDX_ADDR_BIT = $clog2(UART_TX_FIFO_DEPTH) +1   //HAVE WRAP BIT

    )
    (

    input i_clk,
    input i_rst_n,
    input [UART_TX_FIFO_DATA_IN_BIT-1:0] i_UART_TX_FIFO_wdata ,
    output reg [UART_TX_FIFO_DATA_OUT_BIT-1:0] o_UART_TX_FIFO_rdata ,
    output reg o_UART_TX_FIFO_wready ,
    input  wire i_UART_TX_FIFO_wvalid ,
    input wire i_UART_TX_FIFO_rready ,
    output  reg o_UART_TX_FIFO_rvalid 

    );

    reg [ UART_TX_FIFO_DEPTH-1:0  ][ UART_TX_FIFO_BANK_NUM-1:0 ][UART_TX_FIFO_BANK_WIDTH-1:0] fifo_bank_r , fifo_bank_w ;
    reg  [UART_TX_FIFO_IDX_ADDR_BIT -1:0] write_idx_r , write_idx_w ;
    reg  [UART_TX_FIFO_IDX_ADDR_BIT -1:0] read_idx_r , read_idx_w ;

    reg [1:0] read_phase_r , read_phase_w ; 
    reg fifo_full ;
    reg fifo_empty ;
    always@(*)begin
        if( fifo_full == 1'b1)begin
            o_UART_TX_FIFO_wready = 1'b0 ;
        end
        else begin
            o_UART_TX_FIFO_wready = 1'b1 ;
        end
    end
    always@(*)begin
        if( fifo_empty == 1'b1)begin
            o_UART_TX_FIFO_rvalid = 1'b0 ;
        end
        else begin
            o_UART_TX_FIFO_rvalid = 1'b1 ;
        end
    end
    always@(*)begin
        if( read_idx_r ==  write_idx_r )begin // Since write will write 16 bits but read only 2 bits 
             fifo_empty = 1'b1 ;
        end
        else begin
            fifo_empty = 1'b0 ;
        end
    end
    always@(*)begin
        if( ( read_idx_r [UART_TX_FIFO_IDX_ADDR_BIT-2:0] ==  write_idx_r[UART_TX_FIFO_IDX_ADDR_BIT-2:0] ) &&  (read_idx_r[UART_TX_FIFO_IDX_ADDR_BIT-1]!= write_idx_r[UART_TX_FIFO_IDX_ADDR_BIT-1] )    )   begin // Since write will write 16 bits but read only 2 bits 
             fifo_full = 1'b1 ;
        end
        else begin
            fifo_full = 1'b0 ;
        end
    end

    always@(*)begin

    end
    always@(*)begin
        fifo_bank_w  = fifo_bank_r ;
        if(  o_UART_TX_FIFO_wready == 1'b1 &&  i_UART_TX_FIFO_wvalid == 1'b1  )begin
            case( write_idx_r[ UART_TX_FIFO_IDX_ADDR_BIT-2 : 0 ] ) // write_idx has wrap bit
                2'd0:begin
                    fifo_bank_w[0][0] = i_UART_TX_FIFO_wdata[5:0];
                    fifo_bank_w[0][1] = i_UART_TX_FIFO_wdata[11:6];
                    fifo_bank_w[0][2] = i_UART_TX_FIFO_wdata[17:12];
                end
                2'd1:begin
                    fifo_bank_w[1][0] = i_UART_TX_FIFO_wdata[5:0];
                    fifo_bank_w[1][1] = i_UART_TX_FIFO_wdata[11:6];
                    fifo_bank_w[1][2] = i_UART_TX_FIFO_wdata[17:12];
                end
                2'd2:begin
                    fifo_bank_w[2][0] = i_UART_TX_FIFO_wdata[5:0];
                    fifo_bank_w[2][1] = i_UART_TX_FIFO_wdata[11:6];
                    fifo_bank_w[2][2] = i_UART_TX_FIFO_wdata[17:12];
                end
                2'd3:begin
                    fifo_bank_w[3][0] = i_UART_TX_FIFO_wdata[5:0];
                    fifo_bank_w[3][1] = i_UART_TX_FIFO_wdata[11:6];
                    fifo_bank_w[3][2] = i_UART_TX_FIFO_wdata[17:12];
                end
            endcase
        end
    end
    always@(*)begin
        o_UART_TX_FIFO_rdata = 6'd0;
        if(  !fifo_empty )begin

            if( read_phase_r  ==2'd0 )begin
                o_UART_TX_FIFO_rdata  = fifo_bank_r[   read_idx_r[ UART_TX_FIFO_IDX_ADDR_BIT-2 : 0 ]    ][0];
            end
            else if ( read_phase_r  ==2'd1 ) begin
                o_UART_TX_FIFO_rdata  = fifo_bank_r[   read_idx_r[ UART_TX_FIFO_IDX_ADDR_BIT-2 : 0 ]    ][1] ;
            end
            else begin
                o_UART_TX_FIFO_rdata  = fifo_bank_r[   read_idx_r[ UART_TX_FIFO_IDX_ADDR_BIT-2 : 0 ]    ][2] ;
            end
        end
    end
    always@(*)begin

        write_idx_w  = write_idx_r ;
        if(  o_UART_TX_FIFO_wready == 1'b1 &&  i_UART_TX_FIFO_wvalid == 1'b1  )begin

            write_idx_w  = write_idx_r + 1'b1 ; //FIFO DEPTH IS POWER OF 2
            
        end
    end
    always@(*)begin
        read_phase_w = read_phase_r ;
        if(  i_UART_TX_FIFO_rready == 1'b1 &&  o_UART_TX_FIFO_rvalid == 1'b1  )begin
            if(read_phase_r == 3'd2)begin
                read_phase_w   = 2'd0 ; //FIFO DEPTH IS POWER OF 2  
            end
            else begin
                read_phase_w  = read_phase_r +1'b1 ;
            end
        end

    end
    always@(*)begin
        read_idx_w = read_idx_r ;
        if(  i_UART_TX_FIFO_rready == 1'b1 &&  o_UART_TX_FIFO_rvalid == 1'b1  )begin
            if(read_phase_r == 3'd2)begin
                read_idx_w  = read_idx_r + 1'b1 ; //FIFO DEPTH IS POWER OF 2  
            end
            else begin
                read_idx_w = read_idx_r ;
            end
            
        end        
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if(  i_rst_n == 1'b0 )begin
            fifo_bank_r <= 0 ;
            write_idx_r <= 0 ;
            read_idx_r <= 0 ;
            read_phase_r <= 0 ;
         end
        else begin
            fifo_bank_r <= fifo_bank_w ;
            write_idx_r <= write_idx_w ;
            read_idx_r <= read_idx_w ;
            read_phase_r <= read_phase_w ;            
        end
    end

endmodule


module axi_uart_master #(
    parameter UART_BIT = 6 ,
    
    parameter UART_TX_FIFO_DATA_OUT_BIT = 6 ,

    parameter UART_RX_FIFO_DATA_IN_BIT = 6 

    )(
    input wire i_clk,
    input wire i_rst_n,
    output  [3:0] o_uart_awaddr,
    output reg o_uart_awvalid,
    input wire i_uart_awready,
    output reg [31:0] o_uart_wdata,
    output reg o_uart_wvalid,
    input wire i_uart_wready,
    input wire [1:0] i_uart_bresp,
    input wire i_uart_bvalid,
    output reg o_uart_bready ,

    output reg  [3:0] o_uart_araddr ,
    output reg o_uart_arvalid ,
    output reg  o_uart_rready ,
    input i_uart_arready ,
    input [31:0] i_uart_rdata ,
    input [1:0]  i_uart_rresp ,
    input i_uart_rvalid , 
    
    output reg o_tx_fifo_rready ,
    input  i_tx_fifo_rvalid ,
    input [UART_TX_FIFO_DATA_OUT_BIT-1:0] i_tx_fifo_rdata ,
    


    input  i_rx_fifo_wready ,
    output  reg o_rx_fifo_wvalid ,
    output reg [UART_RX_FIFO_DATA_IN_BIT-1:0] o_rx_fifo_wdata 




);



    
    reg [3:0]  tx_state_r , tx_state_w;
    reg [3:0] rx_state_r , rx_state_w;

    reg [4:0] tx_stall_cnt_r , tx_stall_cnt_w ;


    reg [4:0] rx_stall_cnt_r , rx_stall_cnt_w ;

    reg [UART_TX_FIFO_DATA_OUT_BIT-1:0] tx_data_r , tx_data_w ; //Store data between FIFO and UART 
    reg [UART_RX_FIFO_DATA_IN_BIT-1:0] rx_data_r , rx_data_w ; //Store data between FIFO and UART 


    localparam S_TX_IDLE = 4'd0 , S_TX_DATA_FETCH_DATA_FROM_FIFO = 4'd1, S_TX_DATA_WRITE_UART = 4'd2, S_TX_BRESP = 4'd3 , S_TX_END = 4'd4 , S_TX_STALL = 4'd5;
    localparam S_RX_IDLE = 4'd0 , S_RX_STATUS_ADDRESS_SEND  = 4'd1 , S_RX_STATUS_DATA_READ = 4'd2 ,  S_RX_DATA_ADDRESS_SEND = 4'd3 ,  S_RX_DATA_DATA_READ = 4'd4 , S_RX_DATA_SEND_TO_FIFO = 4'd5, S_READ_END = 4'd6 ;
    localparam S_RX_STALL = 4'd7;
    
    assign    o_uart_awaddr = 4'd4 ;


    always@(*)begin
        rx_data_w = rx_data_r ;
        case(rx_state_r) 
            S_RX_DATA_DATA_READ:begin
                if(o_uart_rready == 1'b1 && i_uart_rvalid ==1'b1)begin
                    rx_data_w = i_uart_rdata [UART_BIT-1:0] ;
                end
            end
        endcase

    end
    always@(*)begin
        o_rx_fifo_wdata = 0 ;
        case(rx_state_r)
            
            S_RX_DATA_SEND_TO_FIFO : o_rx_fifo_wdata = rx_data_r ;
        endcase 
    end
    always@(*)begin
        o_rx_fifo_wvalid = 1'b0 ;
        case(rx_state_r)
            S_RX_DATA_SEND_TO_FIFO : o_rx_fifo_wvalid = 1'b1 ;
        endcase

    end
    always@(*)begin
        rx_stall_cnt_w = 5'd0;
        if(rx_state_r == S_RX_STALL)begin
            rx_stall_cnt_w = rx_stall_cnt_r +1'd1;
        end
    end
    always@(*)begin
        tx_data_w = tx_data_r ;
        case(tx_state_r)
            S_TX_DATA_FETCH_DATA_FROM_FIFO:begin
                if(  o_tx_fifo_rready == 1'b1 && i_tx_fifo_rvalid == 1'b1   )begin
                    tx_data_w = i_tx_fifo_rdata ;
                end
            end
        endcase
    end
    always@(*)begin
        o_uart_wdata = 32'd0 ;
        case(tx_state_r)
            S_TX_DATA_WRITE_UART : begin
                o_uart_wdata[UART_BIT-1:0]  = tx_data_r ;
                o_uart_wdata[31:8]  = 0;
            end
        endcase
    end
    always@(*)begin
        o_uart_araddr = 4'd0 ;
        case(rx_state_r)
            S_RX_STATUS_ADDRESS_SEND:o_uart_araddr = 4'd8 ;
        endcase
    end
    always@(*)begin
        o_uart_rready = 1'b0;
        case(rx_state_r) 
            S_RX_STATUS_DATA_READ:o_uart_rready = 1'b1;
            S_RX_DATA_DATA_READ:o_uart_rready = 1'b1;
        endcase
    end
    always@(*)begin
        o_uart_arvalid = 1'b0;
        case(rx_state_r) 
             S_RX_STATUS_ADDRESS_SEND: o_uart_arvalid  = 1'b1;
             S_RX_DATA_ADDRESS_SEND: o_uart_arvalid  = 1'b1;
        endcase
    end


    always@(*)begin
        rx_state_w = rx_state_r ;
        case(rx_state_r)
            S_RX_IDLE : rx_state_w =  S_RX_STATUS_ADDRESS_SEND ;
            S_RX_STALL :begin
                if(rx_stall_cnt_r == 5'd31)begin
                    rx_state_w = S_RX_STATUS_ADDRESS_SEND ;
                end
                else begin
                    rx_state_w = S_RX_STALL ;
                end
            end
            S_RX_STATUS_ADDRESS_SEND:begin
                if(i_uart_arready == 1'b1&& o_uart_arvalid==1'b1)begin
                    rx_state_w = S_RX_STATUS_DATA_READ ;
                end
                else begin
                    rx_state_w = S_RX_STATUS_ADDRESS_SEND ;
                end
            end
            S_RX_STATUS_DATA_READ:begin
                if(i_uart_rvalid==1'b1&&o_uart_rready==1'b1)begin
                    if(i_uart_rdata[0] == 1'b1)begin
                        rx_state_w =S_RX_DATA_ADDRESS_SEND;
                    end
                    else begin
                        
                        rx_state_w =S_RX_STALL;
                    end
                    
                end
                else begin
                    rx_state_w =S_RX_STALL;
                end
            end
            S_RX_DATA_ADDRESS_SEND:begin
                if(i_uart_arready == 1'b1&& o_uart_arvalid==1'b1)begin
                    rx_state_w = S_RX_DATA_DATA_READ ;
                end  
                else begin
                     rx_state_w =S_RX_DATA_ADDRESS_SEND ;
                end            
            end
            S_RX_DATA_DATA_READ:begin
                if(i_uart_rvalid==1'b1&&o_uart_rready==1'b1)begin
                    rx_state_w = S_RX_DATA_SEND_TO_FIFO ;
                end  
                else begin
                    rx_state_w = S_RX_DATA_DATA_READ ;
                end             
            end
            S_RX_DATA_SEND_TO_FIFO :begin
                if(i_rx_fifo_wready ==1'b1 && o_rx_fifo_wvalid == 1'b1 )begin
                    rx_state_w =  S_RX_STALL  ;
                end
                else begin
                    rx_state_w =  S_RX_DATA_SEND_TO_FIFO  ;
                end
            end

            S_READ_END:rx_state_w = rx_state_r ;
        endcase
    end


    always@(*)begin
        o_tx_fifo_rready = 1'b0 ;
        case(tx_state_r)
            S_TX_DATA_FETCH_DATA_FROM_FIFO:o_tx_fifo_rready = 1'b1 ;
        endcase
    end
    always @(*) begin
        tx_stall_cnt_w = 5'd0 ;
        case(tx_state_r)
            S_TX_STALL: tx_stall_cnt_w = tx_stall_cnt_r +1'b1 ;
        endcase
    end
    always @(*) begin
        o_uart_bready = 1'b0 ; //dangerous

        case(tx_state_r)
            S_TX_BRESP: o_uart_bready = 1'b1 ;
        endcase
    end
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            tx_state_r <= S_TX_IDLE;
            tx_stall_cnt_r <= 0 ;
            //read_mem_r  <= 0 ;
            rx_state_r <= S_RX_IDLE ;
            //read_byte_idx_r <= 0 ;
            tx_data_r <= 0 ;
            rx_stall_cnt_r <= 0 ;

            rx_data_r <= 0;
        end else begin
            tx_state_r <= tx_state_w;
            tx_stall_cnt_r <= tx_stall_cnt_w ;

            //read_mem_r  <= read_mem_w ;
            rx_state_r <= rx_state_w ;
            //read_byte_idx_r <= read_byte_idx_w ;
            tx_data_r <= tx_data_w ;
            rx_stall_cnt_r <= rx_stall_cnt_w;
            rx_data_r <= rx_data_w ;
        end
    end
    always @(*) begin
        tx_state_w = tx_state_r ;
        case(tx_state_r)
            // default: tx_state_w = S_TX_IDLE ;
            S_TX_IDLE: tx_state_w = S_TX_STALL ;
            S_TX_DATA_FETCH_DATA_FROM_FIFO:begin
                if(  i_tx_fifo_rvalid==1'b1 && o_tx_fifo_rready == 1'b1)begin
                    tx_state_w = S_TX_DATA_WRITE_UART ;
                end
                else begin
                    tx_state_w = tx_state_r ;
                end
            end
            S_TX_DATA_WRITE_UART:begin
                if(i_uart_awready == 1'b1 && i_uart_wready == 1'b1)begin
                     tx_state_w = S_TX_BRESP ;
                end
                else begin
                    tx_state_w = tx_state_r ;
                end
            end

            S_TX_BRESP:begin
                if(i_uart_bvalid == 1'b1 )begin
                    if(i_uart_bresp == 2'd0)begin
                        tx_state_w = S_TX_STALL ;
                    end
                    else begin
                        tx_state_w = S_TX_DATA_WRITE_UART ;
                    end
                end
                else begin
                    tx_state_w = tx_state_r ;
                end

            end
            S_TX_STALL:begin
                if(tx_stall_cnt_r == 5'd31)begin
                    tx_state_w =S_TX_DATA_FETCH_DATA_FROM_FIFO;
                end
                else begin
                    tx_state_w = S_TX_STALL ;
                end
            end
            
            S_TX_END:tx_state_w = tx_state_r ;
        endcase
    end

    always @(*) begin
        o_uart_wvalid = 1'b0 ;
        case(tx_state_r)
            S_TX_DATA_WRITE_UART: o_uart_wvalid = 1'b1 ;
        endcase
    end
    always @(*) begin
        o_uart_awvalid = 1'b0;
        case(tx_state_r)
            S_TX_DATA_WRITE_UART:begin
                o_uart_awvalid = 1'b1;
            end
        endcase
    end


endmodule



// module clk_gen (
//     output reg clk,
//     output reg rst,
//     output reg rst_n
// );

//     always #(`PERIOD / 2.0) clk = ~clk;

//     initial begin
//         clk = 1'b0;
//         rst = 1'b0; rst_n = 1'b1; #(              0.25  * `PERIOD);
//         rst = 1'b1; rst_n = 1'b0; #((`RST_DELAY - 0.25) * `PERIOD);
//         rst = 1'b0; rst_n = 1'b1; 
//         #(         `MAX_CYCLE * `PERIOD);
//         $display("Error! Runtime exceeded!");
//         $finish;
//     end
// endmodule 

