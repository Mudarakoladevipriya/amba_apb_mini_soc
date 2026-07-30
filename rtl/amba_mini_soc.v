'timescale 1ns/1ps
module amba_mini_soc (
    input wire        clk,
    input wire        rst,

    // Core Native CPU Control Ports (Exposed for Master Testbench Execution)
    input wire        cpu_req,
    input wire [31:0] cpu_addr,
    input wire        cpu_write,
    input wire [31:0] cpu_wdata,
    output wire [31:0] cpu_rdata,
    output wire        cpu_ready,

    // External Physical Chip Pins
    input wire        rx_serial,
    output wire       tx_serial
);

    // Global AMBA APB Master Bus Interconnect Wires
    wire [31:0] paddr;
    wire        psel;
    wire        penable;
    wire        pwrite;
    wire [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;

    // Slave Decoded Select Wires
    wire        psel_uart;
    wire        psel_timer;
    wire        psel_mem;

    // Slave Individual Data Bus Return Wires
    wire [31:0] prdata_uart;
    wire [31:0] prdata_timer;
    wire [31:0] prdata_mem;

    // Slave Individual Ready Return Wires
    wire        pready_uart;
    wire        pready_timer;
    wire        pready_mem;

    // Active-Low Reset conversion for the APB Slaves
    wire presetn = !rst;

    // 1. Instantiate the CPU Bus Master FSM Interface
    soc_cpu_bus_interface cpu_bus_master (
        .clk(clk),
        .rst(rst),
        .cpu_req(cpu_req),
        .cpu_addr(cpu_addr),
        .cpu_write(cpu_write),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .paddr(paddr),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready)
    );

    // 2. Instantiate the Modified 3-Way APB Interconnect Decoder
    // (Maps: Memory -> 0x0000_2000, UART -> 0x0000_0000, Timer -> 0x0000_0100)
    soc_apb_interconnect interconnect_inst (
        .paddr(paddr),
        .psel(psel),
        .prdata(prdata),
        .pready(pready),

        .psel_uart(psel_uart),
        .prdata_uart(prdata_uart),
        .pready_uart(pready_uart),

        .psel_timer(psel_timer),
        .prdata_timer(prdata_timer),
        .pready_timer(pready_timer),

        // Route third slot channels directly to the Memory block
        .psel_mem(psel_mem),
        .prdata_mem(prdata_mem),
        .pready_mem(pready_mem)
    );

    // 3. Instantiate the APB Memory Slave Wrapper
    soc_apb_memory #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) memory_inst (
        .pclk(clk),
        .presetn(presetn),
        .paddr(paddr),
        .psel(psel_mem),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata_mem),
        .pready(pready_mem)
    );

    // 4. Instantiate the APB UART Slave Wrapper
    soc_apb_uart uart_inst (
        .pclk(clk),
        .presetn(presetn),
        .paddr(paddr),
        .psel(psel_uart),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata_uart),
        .pready(pready_uart),
        .rx_serial(rx_serial),
        .tx_serial(tx_serial)
    );

    // 5. Instantiate the APB Timer Slave Wrapper
    soc_apb_timer timer_inst (
        .pclk(clk),
        .presetn(presetn),
        .paddr(paddr),
        .psel(psel_timer),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata_timer),
        .pready(pready_timer)
    );

endmodule
