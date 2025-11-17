// Core + support
core/riscv/riscv_defs.v
core/riscv/riscv_core.v
core/riscv/riscv_exec.v
core/riscv/riscv_fetch.v
core/riscv/riscv_issue.v
core/riscv/riscv_decode.v
core/riscv/riscv_lsu.v
core/riscv/riscv_mmu.v
core/riscv/riscv_csr.v
core/riscv/riscv_divider.v
core/riscv/riscv_multiplier.v
core/riscv/riscv_pipe_ctrl.v
core/riscv/riscv_regfile.v
core/riscv/riscv_alu.v
core/riscv/riscv_decoder.v
core/riscv/riscv_csr_regfile.v
core/riscv/telemetry_counters.sv

// TCM / AXI glue
top_tcm_axi/src_v/dport_mux.v
top_tcm_axi/src_v/dport_axi.v
top_tcm_axi/src_v/tcm_mem.v
top_tcm_axi/src_v/tcm_mem_pmem.v
top_tcm_axi/src_v/tcm_mem_ram.v
top_tcm_axi/src_v/riscv_tcm_top.v

// Testbench
core/riscv/tb_riscv_tcm_tlm.sv
