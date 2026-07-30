'timescale 1ns/1ps
module amba_mini_soc_tb;

    // Global Testbench System Signals
    reg         clk = 0;
    reg         rst = 1;

    // CPU Native Interface Stimulus Control Registers
    reg         cpu_req = 0;
    reg  [31:0] cpu_addr = 0;
    reg         cpu_write = 0;
    reg  [31:0] cpu_wdata = 0;
    wire [31:0] cpu_rdata;
    wire        cpu_ready;

    // External Device Pins
    reg         rx_serial = 1;
    wire        tx_serial;

    // Instantiate the complete integrated System-on-Chip
    amba_mini_soc uut (
        .clk(clk),
        .rst(rst),
        .cpu_req(cpu_req),
        .cpu_addr(cpu_addr),
        .cpu_write(cpu_write),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .rx_serial(rx_serial),
        .tx_serial(tx_serial)
    );

    // Clock Generator (10ns period)
    always #5 clk <= ~clk;

    // High-level task mimicking internal CPU instruction execution
    task cpu_transaction(input [31:0] addr, input write_en, input [31:0] wdata);
        begin
            @(posedge clk);
            cpu_addr  = addr;
            cpu_write = write_en;
            cpu_wdata = wdata;
            cpu_req   = 1'b1; // Trigger Master FSM cycle

            @(posedge clk);
            cpu_req   = 1'b0; // Drop request pulse immediately

            // Hold line execution until the APB Master FSM signals completion
            while (!cpu_ready) @(posedge clk);
            #10; 
        end
    endtask

    initial begin
        $dumpfile("amba_mini_soc.vcd");
        $dumpvars(0, amba_mini_soc_tb);

        // Power-On Reset Sequence
        #20;
        rst = 0;
        #20;

        // Command 1: Write data 32'hA5A55A5A to Memory Space (0x0000_2004)
        $display("[TB] Initiating CPU Write to APB Memory...");
        cpu_transaction(32'h0000_2004, 1'b1, 32'hA5A5_5A5A);

        // Command 2: Write data character 8'h55 to UART Transmitter (0x0000_0000)
        $display("[TB] Initiating CPU Write to APB UART...");
        cpu_transaction(32'h0000_0000, 1'b1, 32'h0000_0055);

        // Command 3: Write countdown value 8'h06 to Timer Control (0x0000_0100)
        $display("[TB] Initiating CPU Write to APB Timer...");
        cpu_transaction(32'h0000_0100, 1'b1, 32'h0000_0006);

        // Allow ample time for the hardware peripherals to process operations concurrently
        #1200;

        $display("[TB] System Simulation Completed Successfully.");
        $finish;
    end

endmodule
