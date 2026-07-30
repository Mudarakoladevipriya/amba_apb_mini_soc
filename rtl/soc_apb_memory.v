'timescale 1ns/1ps
module soc_apb_memory #(
    parameter ADDR_WIDTH = 8,   // 2^8 = 256 words of memory
    parameter DATA_WIDTH = 32   // 32-bit system data width
)(
    // AMBA APB Bus Interface Ports
    input wire                    pclk,
    input wire                    presetn,
    input wire [31:0]             paddr,
    input wire                    psel,
    input wire                    penable,
    input wire                    pwrite,
    input wire [DATA_WIDTH-1:0]   pwdata,
    output reg [DATA_WIDTH-1:0]   prdata,
    output wire                   pready
);

    // Core Memory Array Declaration (256 entries deep, each 32-bits wide)
    reg [DATA_WIDTH-1:0] ram_block [0:(1<<ADDR_WIDTH)-1];

    // APB transactions complete instantly in 1 cycle
    assign pready = 1'b1;

    // Word-aligned address extraction to index the array safely
    // (Ignoring lowest 2 bits paddr[1:0] because APB is byte-addressed but memory is word-addressed)
    wire [ADDR_WIDTH-1:0] word_addr = paddr[ADDR_WIDTH+1:2];

    // Memory Access Logic (Synchronous Write, Combinational Read)
    always @(posedge pclk) begin
        if (presetn) begin
            // APB Write Operation
            if (psel && penable && pwrite) begin
                ram_block[word_addr] <= pwdata;
            end
        end
    end

    always @(*) begin
        // APB Read Operation
        if (psel && !pwrite) begin
            prdata = ram_block[word_addr];
        end else begin
            prdata = {DATA_WIDTH{1'b0}};
        end
    end

endmodule
