'timescale 1ns/1ps
module soc_apb_timer (
    // AMBA APB Bus Interface Ports
    input wire        pclk,
    input wire        presetn,   // Active-low reset
    input wire [31:0] paddr,
    input wire        psel,
    input wire        penable,
    input wire        pwrite,
    input wire [31:0] pwdata,
    output reg [31:0] prdata,
    output wire       pready
);

    // Reconstruct active-high reset for the internal timer core
    wire rst = !presetn;

    // Internal Core Interconnect Wires
    reg        timer_start;
    wire [7:0] timer_load_val;
    wire       timer_done;

    // Map lowest byte of APB write data bus directly to timer load input
    assign timer_load_val = pwdata[7:0];
    
    // Assign pready high—this wrapper registers transactions instantly
    assign pready = 1'b1;

    // Instantiate your native Timer Core (from Phase 1)
    soc_timer #(.WIDTH(8)) timer_core (
        .clk(pclk),
        .rst(rst),
        .start(timer_start),
        .load_val(timer_load_val),
        .done(timer_done)
    );

    // Register Mapping Logic (APB Bus Write Operation)
    always @(posedge pclk) begin
        if (rst) begin
            timer_start <= 1'b0;
        end else begin
            // Clear start pulse on next clock edge to ensure single-cycle trigger
            timer_start <= 1'b0;

            // APB Write Action: Accessing Register 0x0 triggers the load and start sequence
            if (psel && penable && pwrite) begin
                if (paddr[7:0] == 8'h00) begin
                    timer_start <= 1'b1;
                end
            end
        end
    end

    // Register Mapping Logic (APB Bus Read Operation)
    always @(*) begin
        prdata = 32'h0;
        if (psel && !pwrite) begin
            case (paddr[7:0])
                8'h00: prdata = {24'h0, timer_load_val}; // Echo loaded value configuration
                8'h04: prdata = {31'h0, timer_done};     // Read Status: Bit [0] indicates countdown complete
                default: prdata = 32'hDEAD_BEEF;
	endcase
        end
    end

endmodule
