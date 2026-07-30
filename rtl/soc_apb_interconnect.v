'timescale 1ns/1ps
module soc_apb_interconnect (
    input wire [31:0] paddr,
    input wire        psel,
    output reg [31:0] prdata,
    output reg        pready,

    // Slave Slot 0: UART
    output reg        psel_uart,
    input wire [31:0] prdata_uart,
    input wire        pready_uart,

    // Slave Slot 1: Timer
    output reg        psel_timer,
    input wire [31:0] prdata_timer,
    input wire        pready_timer,

    // Slave Slot 2: Memory Array (3rd Slot)
    output reg        psel_mem,
    input wire [31:0] prdata_mem,
    input wire        pready_mem
);

    // Address Decoding Logic
    always @(*) begin
        // Reset all select lines to default low to avoid latches
        psel_uart  = 1'b0;
        psel_timer = 1'b0;
        psel_mem   = 1'b0;

        if (psel) begin
            // Base Address 0x0000_2000 -> Memory Space
            if (paddr[31:12] == 20'h00002) begin
                psel_mem = 1'b1;
            end
            // Base Address 0x0000_0000 -> UART Space (Includes status reg at offset 0x08)
            else if ((paddr[7:0] == 8'h00) || (paddr[7:0] == 8'h08)) begin
                psel_uart = 1'b1;
            end 
            // Base Address 0x0000_0100 -> Timer Space
            else begin
                psel_timer = 1'b1;
            end
        end
    end

    // Read Data and Ready Multiplexing Matrix
    always @(*) begin
        if (psel_mem) begin
            prdata = prdata_mem;
            pready = pready_mem;
        end else if (psel_uart) begin
            prdata = prdata_uart;
            pready = pready_uart;
        end else if (psel_timer) begin
            prdata = prdata_timer;
            pready = pready_timer;
        end else begin
            prdata = 32'h0;
            pready = 1'b1; // Prevent fabric lockup on unmapped accesses
        end
    end

endmodule
