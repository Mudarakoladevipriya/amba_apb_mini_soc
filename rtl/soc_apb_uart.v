'timescale 1ns/1ps
module soc_apb_uart (
    // AMBA APB Bus Interface Ports
    input wire        pclk,
    input wire        presetn,   // Active-low asynchronous/synchronous reset
    input wire [31:0] paddr,
    input wire        psel,
    input wire        penable,
    input wire        pwrite,
    input wire [31:0] pwdata,
    output reg [31:0] prdata,
    output wire       pready,

    // External Physical Chip Pins
    input wire        rx_serial,
    output wire       tx_serial
);

    // Reconstruct active-high reset for internal cores
    wire rst = !presetn;

    // Internal Core Interconnect Wires
    reg        tx_start;
    wire [7:0] tx_data;
    wire       tx_active;
    wire       tx_done;

    wire       rx_dv;
    wire [7:0] rx_data;

    // Assign pready high—this wrapper handles transactions in a single cycle
    assign pready = 1'b1;

    // Instantiate your native UART Transmitter Core (from Phase 1)
    soc_uart_tx #(.CLKS_PER_BIT(8)) tx_core (
        .clk(pclk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(pwdata[7:0]), // Map lowest byte of APB Write Data
        .tx_active(tx_active),
        .tx_serial(tx_serial),
        .tx_done(tx_done)
    );

    // Instantiate your native UART Receiver Core (from Phase 1)
    soc_uart_rx #(.CLKS_PER_BIT(8)) rx_core (
        .clk(pclk),
        .rst(rst),
        .rx_serial(rx_serial),
        .rx_dv(rx_dv),
        .rx_data(rx_data)
    );

    // Register Mapping Logic (APB Bus Write Operation)
    always @(posedge pclk) begin
        if (rst) begin
            tx_start <= 1'b0;
        end else begin
            // Clear start pulse on next clock edge to ensure single-cycle trigger
            tx_start <= 1'b0; 

            // APB Write Setup Action: Accessing Register 0x0 triggers a transmit transaction
            if (psel && penable && pwrite) begin
                if (paddr[7:0] == 8'h00) begin
                    tx_start <= 1'b1;
                end
            end
        end
    end

    // Register Mapping Logic (APB Bus Read Operation)
    always @(*) begin
        prdata = 32'h0;
        if (psel && !pwrite) begin
            case (paddr[7:0])
                8'h00: prdata = {24'h0, pwdata[7:0]}; // Echo TX buffer context
                8'h04: prdata = {24'h0, rx_data};     // Read RX Assembled Byte Buffer
                8'h08: prdata = {30'h0, tx_active, rx_dv}; // Status Reg: [1]=TX Active, [0]=RX Data Valid
                default: prdata = 32'hDEAD_BEEF;
            endcase
        end
    end

endmodule
