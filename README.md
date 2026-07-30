
# AMBA APB-Compliant Mini-System-on-Chip (SoC)

A fully integrated, synthesizable **System-on-Chip (SoC) peripheral subsystem** built around the industry-standard **ARM AMBA 3 APB (Advanced Peripheral Bus)** protocol in Verilog HDL. 

This project features a custom CPU Bus Master Finite State Machine (FSM), a 3-way central address-decoding interconnect, and memory-mapped APB slave wrappers for a dual-purpose SRAM array, a full-duplex UART core, and a hardware timer.

---

## 🛠️ Architecture Overview

The subsystem is structured into three primary hardware layers:

1. **Master Control Layer:** 
   * **CPU Bus Interface (`soc_cpu_bus_interface.v`):** A 3-state FSM (`IDLE` → `SETUP` → `ACCESS`) converting raw CPU transaction requests into strict AMBA APB bus timing phases and managing slave wait-states (`pready`).
2. **Interconnect & Routing Layer:**
   * **3-Way APB Interconnect (`soc_apb_interconnect.v`):** Decodes master addresses and dynamically routes data/control lines to target peripherals:
     * `0x0000_0000` — UART Core
     * `0x0000_0100` — Hardware Timer
     * `0x0000_2000` — Memory Subsystem
3. **Slave Peripheral Layer:**
   * **APB Memory (`soc_apb_memory.v`):** 256x32-bit RAM/ROM block with byte-to-word address translation logic (`paddr[31:2]`).
   * **APB UART Wrapper (`soc_apb_uart.v`):** Integrates custom `soc_uart_tx` and `soc_uart_rx` IP cores with memory-mapped configuration registers.
   * **APB Timer Wrapper (`soc_apb_timer.v`):** Integrates down-counting `soc_timer` IP core for programmable software event tracking.

---

## 📁 Repository Structure

```text
amba-apb-mini-soc/
├── rtl/
│   ├── amba_mini_soc.v           # Top-level SoC module
│   ├── soc_apb_interconnect.v    # 3-way bus decoder & multiplexer
│   ├── soc_cpu_bus_interface.v   # FSM-based APB Bus Master
│   ├── soc_apb_memory.v          # APB Memory Wrapper
│   ├── soc_apb_uart.v            # APB UART Wrapper
│   ├── soc_apb_timer.v           # APB Timer Wrapper
│   ├── soc_uart_tx.v             # Core UART Transmitter
│   ├── soc_uart_rx.v             # Core UART Receiver
│   └── soc_timer.v               # Core Hardware Timer
├── tb/
│   └── amba_mini_soc_tb.v        # Master system testbench
├── scripts/
│   └── run_amba_mini_soc.sh      # Compilation & simulation script
├── README.md
