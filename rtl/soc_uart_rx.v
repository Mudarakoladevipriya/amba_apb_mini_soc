`timescale 1ns/1ps
module soc_uart_rx #(
    parameter CLKS_PER_BIT = 8 // Matches the simulation speed parameter used in our TX
)(
    input wire       clk,
    input wire       rst,        // Synchronous active-high reset
    input wire       rx_serial,  // Incoming serial wire pin
    output reg       rx_dv,      // Data Valid pulse (1 clock cycle when byte is fully assembled)
    output reg [7:0] rx_data     // Assembled 8-bit parallel output byte
);

    // Explicit state names to avoid overlapping definitions
    localparam RX_IDLE         = 3'b000;
    localparam RX_START_BIT    = 3'b001;
    localparam RX_DATA_BITS    = 3'b010;
    localparam RX_STOP_BIT     = 3'b011;
    localparam RX_CLEANUP      = 3'b100;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= RX_IDLE;
            clk_count   <= 0;
            bit_index   <= 0;
            rx_dv       <= 0;
            rx_data     <= 0;
            rx_data_reg <= 0;
        end else begin
            case (state)
                RX_IDLE: begin
                    rx_dv     <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    // Detect the falling edge of the Start Bit (1 down to 0)
                    if (rx_serial == 1'b0) 
                        state <= RX_START_BIT;
                end

                // Sample at the exact midpoint of the start bit to ensure it isn't noise glitch
                RX_START_BIT: begin
                    if (clk_count == (CLKS_PER_BIT / 2) - 1) begin
                        if (rx_serial == 1'b0) begin
                            clk_count <= 0; // Reset counter to align with center of upcoming data bits
                            state     <= RX_DATA_BITS;
                        end else begin
                            state     <= RX_IDLE; // False start bit detected, return to IDLE
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                // Sample data bits right in the middle of their bit durations
                RX_DATA_BITS: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_data_reg[bit_index] <= rx_serial; // Sample incoming line bit (LSB first)
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= RX_STOP_BIT;
                        end
                    end
                end

                // Verify the Stop Bit duration (should remain High)
                RX_STOP_BIT: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        rx_dv     <= 1'b1; // Pulse high indicating parallel byte is valid
                        rx_data   <= rx_data_reg;
                        clk_count <= 0;
                        state     <= RX_CLEANUP;
                    end
                end

                RX_CLEANUP: begin
                    rx_dv <= 1'b0;
                    state <= RX_IDLE;
                end

                default: state <= RX_IDLE;
            endcase
        end
    end
endmodule
