'timescale 1ns/1ps
module soc_cpu_bus_interface (
    // Global Clock and Reset
    input wire        clk,
    input wire        rst,

    // Core Native CPU Signals
    input wire        cpu_req,        // CPU wants to perform a transfer
    input wire [31:0] cpu_addr,       // Target address from CPU
    input wire        cpu_write,      // 1 = Write transaction, 0 = Read transaction
    input wire [31:0] cpu_wdata,      // Data CPU wants to write
    output reg [31:0] cpu_rdata,      // Data returned to CPU core
    output reg        cpu_ready,      // Tells CPU the transfer is complete

    // Hardware AMBA APB Master Bus Ports
    output reg [31:0] paddr,
    output reg        psel,
    output reg        penable,
    output reg        pwrite,
    output reg [31:0] pwdata,
    input wire [31:0] prdata,
    input wire        pready
);

    // State Encoding using binary parameters
    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;

    reg [1:0] current_state, next_state;

    // FSM State Sequential Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= ST_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM Combinational Next-State Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            ST_IDLE: begin
                if (cpu_req) 
                    next_state = ST_SETUP;
                else 
                    next_state = ST_IDLE;
            end
            ST_SETUP: begin
                next_state = ST_ACCESS;
            end
            ST_ACCESS: begin
                if (pready) 
                    next_state = ST_IDLE;
                else 
                    next_state = ST_ACCESS; // Hold state if slave inserts wait states
            end
            default: next_state = ST_IDLE;
        endcase
    end

    // FSM Output Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            paddr     <= 32'h0;
            psel      <= 1'b0;
            penable   <= 1'b0;
            pwrite    <= 1'b0;
            pwdata    <= 32'h0;
            cpu_rdata <= 32'h0;
            cpu_ready <= 1'b0;
        end else begin
            cpu_ready <= 1'b0; // Default pulse constraint

            case (current_state)
                ST_IDLE: begin
                    psel    <= 1'b0;
                    penable <= 1'b0;
                    if (cpu_req) begin
                        paddr  <= cpu_addr;
                        pwrite <= cpu_write;
                        pwdata <= cpu_wdata;
                    end
                end

                ST_SETUP: begin
                    psel    <= 1'b1;
                    penable <= 1'b0;
                end

                ST_ACCESS: begin
                    penable <= 1'b1;
                    if (pready) begin
                        cpu_ready <= 1'b1;
                        if (!pwrite) begin
                            cpu_rdata <= prdata; // Sample read data
                        end
                        psel    <= 1'b0;
                        penable <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule
