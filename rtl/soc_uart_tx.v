'timescale 1ns/1ps
module soc_uart_tx #(
    parameter CLKS_PER_BIT = 8 // Small value for fast, easy simulation verification
)(
    input wire       clk,
    input wire       rst,        // Synchronous active-high reset
    input wire       tx_start,
    input wire [7:0] tx_data,
    output reg       tx_serial,
    output reg       tx_done,
    output reg       tx_active
);

    // Explicit state names to avoid overlapping definitions
    localparam TX_IDLE       = 2'b00;
    localparam TX_START_BIT  = 2'b01;
    localparam TX_DATA_BITS  = 2'b10;
    localparam TX_STOP_BIT   = 2'b11;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= TX_IDLE;
            clk_count   <= 0;
            bit_index   <= 0;
            tx_serial   <= 1'b1; // UART lines idle HIGH
            tx_active   <= 0;
            tx_done     <= 0;
            tx_data_reg <= 0;
        end else begin
            case (state)
                TX_IDLE: begin
                    tx_serial <= 1'b1;
                    tx_done   <= 1'b0;
                    tx_active <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state       <= TX_START_BIT;
                    end
                end

                TX_START_BIT: begin
                    tx_serial <= 1'b0; // Start bit is LOW
                    tx_active <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= TX_DATA_BITS;
                    end
                end

                TX_DATA_BITS: begin
                    tx_serial <= tx_data_reg[bit_index]; // Send LSB first
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= TX_STOP_BIT;
                        end
                    end
                end

                TX_STOP_BIT: begin
                    tx_serial <= 1'b1; // Stop bit is HIGH
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        tx_done   <= 1'b1;
                        tx_active <= 0;
                        state     <= TX_IDLE;
                    end
                end
                default: state <= TX_IDLE;
            endcase
        end
    end
endmodule
