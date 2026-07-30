#!/bin/bash

# Clean up Windows hidden carriage returns to prevent terminal execution errors
sed -i 's/\r$//' amba_mini_soc.v
sed -i 's/\r$//' amba_mini_soc_tb.v
sed -i 's/\r$//' soc_apb_interconnect.v

# Step 1: Run Verilator, tracking down and linking all 8 modules across your workspace
verilator --binary -j 0 -Wall -Wno-fatal \
    amba_mini_soc.v \
    amba_mini_soc_tb.v \
    soc_apb_interconnect.v \
    ../lab10_processor_integration/soc_cpu_bus_interface.v \
    ../lab09_apb_uart_wrapper/soc_apb_uart.v \
    ../lab15_uart_core/soc_uart_tx.v \
    ../lab15_uart_rx_core/soc_uart_rx.v \
    ../lab09_apb_timer_wrapper/soc_apb_timer.v \
    ../lab15_timer_core/soc_timer.v \
    ../lab09_apb_memory_wrapper/soc_apb_memory.v \
    --top-module amba_mini_soc_tb --timing \
    --CFLAGS "-std=c++20 -fcoroutines" --trace

# Step 2: Check if obj_dir is successfully created before entering
cd obj_dir || { echo "ERROR: obj_dir not found!"; exit 1; }

# Step 3: Run the compiled master system simulation executable
./Vamba_mini_soc_tb || { echo "ERROR: Simulation executable failed!"; exit 1; }

# Step 4: View the complete system waveform configuration inside GTKWave
gtkwave amba_mini_soc.vcd
