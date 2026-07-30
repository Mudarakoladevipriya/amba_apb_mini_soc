'timescale 1ns/1ps
module soc_timer #(
    parameter WIDTH = 8 // Width of the timer counter register
)(
    input wire               clk,       // System clock
    input wire               rst,       // Synchronous active-high reset
    input wire               start,     // Pulse to load and start countdown
    input wire [WIDTH-1:0]   load_val,  // Initial countdown value
    output reg               done       // High for 1 cycle when counter hits zero
);

    reg [WIDTH-1:0] count;
    reg             running;

    always @(posedge clk) begin
        if (rst) begin
            count   <= 0;
            running <= 0;
            done    <= 0;
        end else begin
            if (start) begin
                // Load the preset value and start counting down
                count   <= load_val;
                running <= 1'b1;
                done    <= 1'b0;
            end else if (running) begin
                if (count > 1) begin
                    count <= count - 1'b1; // Decrement counter
                end else if (count == 1) begin
                    count   <= 0;
                    running <= 1'b0;       // Stop timer
                    done    <= 1'b1;       // Raise done signal
                end
            end else begin
                done <= 1'b0;              // Clear done pulse in next cycle
            end
        end
    end
endmodule
