//-----------------------------------------------------------------
//                         RISC-V Top
//                            V0.6
//                     Ultra-Embedded.com
//                     Copyright 2014-2019
//
//                   admin@ultra-embedded.com
//
//                       License: BSD
//-----------------------------------------------------------------
//
// Copyright (c) 2014, Ultra-Embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------

//-----------------------------------------------------------------
//                          Generated File
//-----------------------------------------------------------------
module riscv_tcm_top
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter BOOT_VECTOR        = 32'h00000000   // <--- changed from 0x00002000
    ,parameter CORE_ID            = 0
    ,parameter TCM_MEM_BASE       = 0
    ,parameter MEM_CACHE_ADDR_MIN = 0
    ,parameter MEM_CACHE_ADDR_MAX = 32'hffffffff
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           rst_cpu_i
    ,input           axi_i_awready_i
    ,input           axi_i_wready_i
    ,input           axi_i_bvalid_i
    ,input  [  1:0]  axi_i_bresp_i
    ,input           axi_i_arready_i
    ,input           axi_i_rvalid_i
    ,input  [ 31:0]  axi_i_rdata_i
    ,input  [  1:0]  axi_i_rresp_i
    ,input           axi_t_awvalid_i
    ,input  [ 31:0]  axi_t_awaddr_i
    ,input  [  3:0]  axi_t_awid_i
    ,input  [  7:0]  axi_t_awlen_i
    ,input  [  1:0]  axi_t_awburst_i
    ,input           axi_t_wvalid_i
    ,input  [ 31:0]  axi_t_wdata_i
    ,input  [  3:0]  axi_t_wstrb_i
    ,input           axi_t_wlast_i
    ,input           axi_t_bready_i
    ,input           axi_t_arvalid_i
    ,input  [ 31:0]  axi_t_araddr_i
    ,input  [  3:0]  axi_t_arid_i
    ,input  [  7:0]  axi_t_arlen_i
    ,input  [  1:0]  axi_t_arburst_i
    ,input           axi_t_rready_i
    ,input  [ 31:0]  intr_i

    // Outputs
    ,output          axi_i_awvalid_o
    ,output [ 31:0]  axi_i_awaddr_o
    ,output          axi_i_wvalid_o
    ,output [ 31:0]  axi_i_wdata_o
    ,output [  3:0]  axi_i_wstrb_o
    ,output          axi_i_bready_o
    ,output          axi_i_arvalid_o
    ,output [ 31:0]  axi_i_araddr_o
    ,output          axi_i_rready_o
    ,output          axi_t_awready_o
    ,output          axi_t_wready_o
    ,output          axi_t_bvalid_o
    ,output [  1:0]  axi_t_bresp_o
    ,output [  3:0]  axi_t_bid_o
    ,output          axi_t_arready_o
    ,output          axi_t_rvalid_o
    ,output [ 31:0]  axi_t_rdata_o
    ,output [  1:0]  axi_t_rresp_o
    ,output [  3:0]  axi_t_rid_o
    ,output          axi_t_rlast_o

    // -------- Trace buffer external ports (optional) --------
    // ,output          trace_triggered_o
    // ,output [5:0]    trace_wr_ptr_o
    // ,input  [5:0]    trace_rd_addr_i
    // ,output [63:0]   trace_rd_data_o
);

//-----------------------------------------------------------------
// Wires
//-----------------------------------------------------------------
wire  [ 31:0]  ifetch_pc_w;
wire  [ 31:0]  dport_tcm_data_rd_w;
wire           dport_tcm_cacheable_w;
wire           dport_flush_w;
wire  [  3:0]  dport_tcm_wr_w;
wire           ifetch_rd_w;
wire           dport_axi_accept_w;
wire           dport_cacheable_w;
wire           dport_tcm_flush_w;
wire  [ 10:0]  dport_resp_tag_w;
wire  [ 10:0]  dport_axi_resp_tag_w;
wire           ifetch_accept_w;
wire  [ 31:0]  dport_data_rd_w;
wire           dport_tcm_invalidate_w;
wire           dport_ack_w;
wire  [ 10:0]  dport_axi_req_tag_w;
wire  [ 31:0]  dport_data_wr_w;
wire           dport_invalidate_w;
wire  [ 10:0]  dport_tcm_req_tag_w;
wire  [ 31:0]  dport_tcm_addr_w;
wire           dport_axi_error_w;
wire           dport_tcm_ack_w;
wire           dport_tcm_rd_w;
wire  [ 10:0]  dport_tcm_resp_tag_w;
wire           dport_writeback_w;
wire  [ 31:0]  cpu_id_w = CORE_ID;
wire           dport_rd_w;
wire           dport_axi_ack_w;
wire           dport_axi_rd_w;
wire  [ 31:0]  dport_axi_data_rd_w;
wire           dport_axi_invalidate_w;
wire  [ 31:0]  boot_vector_w = BOOT_VECTOR;
wire  [ 31:0]  dport_addr_w;
wire           ifetch_error_w;
wire  [ 31:0]  dport_tcm_data_wr_w;
wire           ifetch_flush_w;
wire  [ 31:0]  dport_axi_addr_w;
wire           dport_error_w;
wire           dport_tcm_accept_w;
wire           ifetch_invalidate_w;
wire           dport_axi_writeback_w;
wire  [  3:0]  dport_wr_w;
wire           ifetch_valid_w;
wire  [ 31:0]  dport_axi_data_wr_w;
wire  [ 10:0]  dport_req_tag_w;
wire  [ 31:0]  ifetch_inst_w;
wire           dport_axi_cacheable_w;
wire           dport_tcm_writeback_w;
wire  [  3:0]  dport_axi_wr_w;
wire           dport_axi_flush_w;
wire           dport_tcm_error_w;
wire           dport_accept_w;

//-----------------------------------------------------------------
// New: core-side data bus wires
//-----------------------------------------------------------------
wire [31:0] core_d_addr_w;
wire [31:0] core_d_data_wr_w;
wire        core_d_rd_w;
wire [ 3:0] core_d_wr_w;
wire        core_d_cacheable_w;
wire [10:0] core_d_req_tag_w;
wire        core_d_invalidate_w;
wire        core_d_writeback_w;
wire        core_d_flush_w;

wire [31:0] core_d_data_rd_w;
wire        core_d_accept_w;
wire        core_d_ack_w;
wire        core_d_error_w;
wire [10:0] core_d_resp_tag_w;

// bus-side signals
wire [31:0] bus_addr_w;
wire [31:0] bus_data_wr_w;
wire        bus_rd_w;
wire [ 3:0] bus_wr_w;
wire        bus_cacheable_w;
wire [10:0] bus_req_tag_w;
wire        bus_invalidate_w;
wire        bus_writeback_w;
wire        bus_flush_w;

wire [31:0] bus_data_rd_w;
wire        bus_accept_w;
wire        bus_ack_w;
wire        bus_error_w;
wire [10:0] bus_resp_tag_w;

//-----------------------------------------------------------------
// Telemetry wires (between Debug_Telemetry and perf_mmio_adapter)
//-----------------------------------------------------------------
wire [63:0] tlm_mcycle_w;
wire [63:0] tlm_minstret_w;
wire [63:0] tlm_stall_w;

//-----------------------------------------------------------------
// Debug / telemetry taps from core
//-----------------------------------------------------------------
wire         dbg_retire_pulse_w;
wire         dbg_stall_cycle_w;
wire         dbg_fetch_valid_w;
wire [31:0]  dbg_fetch_pc_w;
wire [31:0]  dbg_fetch_instr_w;

//-----------------------------------------------------------------
// Trace buffer wires (between Debug_Telemetry and perf_mmio_adapter)
//-----------------------------------------------------------------
wire        trace_triggered_w;
wire [5:0]  trace_wr_ptr_w;
wire [5:0]  trace_rd_addr_w;
wire [31:0] trace_rd_pc_w;
wire [31:0] trace_rd_instr_w;

//-----------------------------------------------------------------
// Core
//-----------------------------------------------------------------
riscv_core
#(
     .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN)
    ,.MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
)
u_core
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_cpu_i)

    // Data memory inputs (from perf MMIO adapter)
    ,.mem_d_data_rd_i(core_d_data_rd_w)
    ,.mem_d_accept_i(core_d_accept_w)
    ,.mem_d_ack_i(core_d_ack_w)
    ,.mem_d_error_i(core_d_error_w)
    ,.mem_d_resp_tag_i(core_d_resp_tag_w)

    // Instruction memory inputs
    ,.mem_i_accept_i(ifetch_accept_w)
    ,.mem_i_valid_i(ifetch_valid_w)
    ,.mem_i_error_i(ifetch_error_w)
    ,.mem_i_inst_i(ifetch_inst_w)

    ,.intr_i(intr_i[0:0])
    ,.reset_vector_i(boot_vector_w)
    ,.cpu_id_i(cpu_id_w)

    // Outputs - data memory (to perf MMIO adapter)
    ,.mem_d_addr_o(core_d_addr_w)
    ,.mem_d_data_wr_o(core_d_data_wr_w)
    ,.mem_d_rd_o(core_d_rd_w)
    ,.mem_d_wr_o(core_d_wr_w)
    ,.mem_d_cacheable_o(core_d_cacheable_w)
    ,.mem_d_req_tag_o(core_d_req_tag_w)
    ,.mem_d_invalidate_o(core_d_invalidate_w)
    ,.mem_d_writeback_o(core_d_writeback_w)
    ,.mem_d_flush_o(core_d_flush_w)

    // Outputs - instruction memory
    ,.mem_i_rd_o(ifetch_rd_w)
    ,.mem_i_flush_o(ifetch_flush_w)
    ,.mem_i_invalidate_o(ifetch_invalidate_w)
    ,.mem_i_pc_o(ifetch_pc_w)

    // Debug / telemetry taps to Debug_Telemetry block
    ,.dbg_retire_pulse_o (dbg_retire_pulse_w)
    ,.dbg_stall_cycle_o  (dbg_stall_cycle_w)
    ,.dbg_fetch_valid_o  (dbg_fetch_valid_w)
    ,.dbg_fetch_pc_o     (dbg_fetch_pc_w)
    ,.dbg_fetch_instr_o  (dbg_fetch_instr_w)
);

// Optional external export of trace bundle, if you want later:
// assign trace_triggered_o = trace_triggered_w;
// assign trace_wr_ptr_o    = trace_wr_ptr_w;
// assign trace_rd_data_o   = {trace_rd_pc_w, trace_rd_instr_w};

//-----------------------------------------------------------------
// Debug / Telemetry block: counters + trace buffer
//-----------------------------------------------------------------
Debug_Telemetry
#(
    .CNT_WIDTH      (64),
    .TRACE_DEPTH    (64)
)
u_debug_telemetry
(
    .clk_i           (clk_i),
    .rst_i           (rst_i),

    // Event taps from core
    .retire_pulse_i  (dbg_retire_pulse_w),
    .stall_cycle_i   (dbg_stall_cycle_w),
    .fetch_pc_i      (dbg_fetch_pc_w),
    .fetch_instr_i   (dbg_fetch_instr_w),

    // Trace read / status
    .trace_rd_addr_i (trace_rd_addr_w),
    .trace_triggered_o(trace_triggered_w),
    .trace_wr_ptr_o  (trace_wr_ptr_w),
    .trace_rd_pc_o   (trace_rd_pc_w),
    .trace_rd_instr_o(trace_rd_instr_w),

    // Performance counters out to perf_mmio_adapter
    .tlm_mcycle_o    (tlm_mcycle_w),
    .tlm_minstret_o  (tlm_minstret_w),
    .tlm_stall_o     (tlm_stall_w)
);

//-----------------------------------------------------------------
// Perf MMIO adapter between core and dport_mux
//-----------------------------------------------------------------
perf_mmio_adapter 
#(
    .TRACE_DEPTH    (64)
)u_perf_mmio
(
    .clk_i           (clk_i),
    .rst_i           (rst_i),

    // Core side
    .core_addr_i      (core_d_addr_w),
    .core_data_wr_i   (core_d_data_wr_w),
    .core_rd_i        (core_d_rd_w),
    .core_wr_i        (core_d_wr_w),
    .core_cacheable_i (core_d_cacheable_w),
    .core_req_tag_i   (core_d_req_tag_w),
    .core_invalidate_i(core_d_invalidate_w),
    .core_writeback_i (core_d_writeback_w),
    .core_flush_i     (core_d_flush_w),

    .core_data_rd_o   (core_d_data_rd_w),
    .core_accept_o    (core_d_accept_w),
    .core_ack_o       (core_d_ack_w),
    .core_error_o     (core_d_error_w),
    .core_resp_tag_o  (core_d_resp_tag_w),

    // bus side
    .bus_addr_o       (bus_addr_w),
    .bus_data_wr_o    (bus_data_wr_w),
    .bus_rd_o         (bus_rd_w),
    .bus_wr_o         (bus_wr_w),
    .bus_cacheable_o  (bus_cacheable_w),
    .bus_req_tag_o    (bus_req_tag_w),
    .bus_invalidate_o (bus_invalidate_w),
    .bus_writeback_o  (bus_writeback_w),
    .bus_flush_o      (bus_flush_w),

    .bus_data_rd_i    (bus_data_rd_w),
    .bus_accept_i     (bus_accept_w),
    .bus_ack_i        (bus_ack_w),
    .bus_error_i      (bus_error_w),
    .bus_resp_tag_i   (bus_resp_tag_w),

    // Performance counters (from Debug_Telemetry)
    .tlm_mcycle_i     (tlm_mcycle_w),
    .tlm_minstret_i   (tlm_minstret_w),
    .tlm_stall_i      (tlm_stall_w),

    // Trace buffer signals (from Debug_Telemetry)
    .trace_triggered_i(trace_triggered_w),
    .trace_wr_ptr_i   (trace_wr_ptr_w),
    .trace_rd_pc_i    (trace_rd_pc_w),
    .trace_rd_instr_i (trace_rd_instr_w),
    .trace_rd_addr_o  (trace_rd_addr_w)
);

//-----------------------------------------------------------------
// dport_mux
//-----------------------------------------------------------------
dport_mux
#(
     .TCM_MEM_BASE(TCM_MEM_BASE)
)
u_dmux
(
    // Inputs from perf_mmio_adapter (bus side)
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.mem_addr_i(bus_addr_w)
    ,.mem_data_wr_i(bus_data_wr_w)
    ,.mem_rd_i(bus_rd_w)
    ,.mem_wr_i(bus_wr_w)
    ,.mem_cacheable_i(bus_cacheable_w)
    ,.mem_req_tag_i(bus_req_tag_w)
    ,.mem_invalidate_i(bus_invalidate_w)
    ,.mem_writeback_i(bus_writeback_w)
    ,.mem_flush_i(bus_flush_w)

    // TCM memory responses
    ,.mem_tcm_data_rd_i(dport_tcm_data_rd_w)
    ,.mem_tcm_accept_i(dport_tcm_accept_w)
    ,.mem_tcm_ack_i(dport_tcm_ack_w)
    ,.mem_tcm_error_i(dport_tcm_error_w)
    ,.mem_tcm_resp_tag_i(dport_tcm_resp_tag_w)

    // External AXI responses
    ,.mem_ext_data_rd_i(dport_axi_data_rd_w)
    ,.mem_ext_accept_i(dport_axi_accept_w)
    ,.mem_ext_ack_i(dport_axi_ack_w)
    ,.mem_ext_error_i(dport_axi_error_w)
    ,.mem_ext_resp_tag_i(dport_axi_resp_tag_w)

    // Outputs back to perf_mmio_adapter
    ,.mem_data_rd_o(bus_data_rd_w)
    ,.mem_accept_o(bus_accept_w)
    ,.mem_ack_o(bus_ack_w)
    ,.mem_error_o(bus_error_w)
    ,.mem_resp_tag_o(bus_resp_tag_w)

    // Outputs to TCM
    ,.mem_tcm_addr_o(dport_tcm_addr_w)
    ,.mem_tcm_data_wr_o(dport_tcm_data_wr_w)
    ,.mem_tcm_rd_o(dport_tcm_rd_w)
    ,.mem_tcm_wr_o(dport_tcm_wr_w)
    ,.mem_tcm_cacheable_o(dport_tcm_cacheable_w)
    ,.mem_tcm_req_tag_o(dport_tcm_req_tag_w)
    ,.mem_tcm_invalidate_o(dport_tcm_invalidate_w)
    ,.mem_tcm_writeback_o(dport_tcm_writeback_w)
    ,.mem_tcm_flush_o(dport_tcm_flush_w)

    // Outputs to AXI side
    ,.mem_ext_addr_o(dport_axi_addr_w)
    ,.mem_ext_data_wr_o(dport_axi_data_wr_w)
    ,.mem_ext_rd_o(dport_axi_rd_w)
    ,.mem_ext_wr_o(dport_axi_wr_w)
    ,.mem_ext_cacheable_o(dport_axi_cacheable_w)
    ,.mem_ext_req_tag_o(dport_axi_req_tag_w)
    ,.mem_ext_invalidate_o(dport_axi_invalidate_w)
    ,.mem_ext_writeback_o(dport_axi_writeback_w)
    ,.mem_ext_flush_o(dport_axi_flush_w)
);

//-----------------------------------------------------------------
// TCM memory
//-----------------------------------------------------------------
tcm_mem
u_tcm
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_i_rd_i(ifetch_rd_w)
    ,.mem_i_flush_i(ifetch_flush_w)
    ,.mem_i_invalidate_i(ifetch_invalidate_w)
    ,.mem_i_pc_i(ifetch_pc_w)
    ,.mem_d_addr_i(dport_tcm_addr_w)
    ,.mem_d_data_wr_i(dport_tcm_data_wr_w)
    ,.mem_d_rd_i(dport_tcm_rd_w)
    ,.mem_d_wr_i(dport_tcm_wr_w)
    ,.mem_d_cacheable_i(dport_tcm_cacheable_w)
    ,.mem_d_req_tag_i(dport_tcm_req_tag_w)
    ,.mem_d_invalidate_i(dport_tcm_invalidate_w)
    ,.mem_d_writeback_i(dport_tcm_writeback_w)
    ,.mem_d_flush_i(dport_tcm_flush_w)
    ,.axi_awvalid_i(axi_t_awvalid_i)
    ,.axi_awaddr_i(axi_t_awaddr_i)
    ,.axi_awid_i(axi_t_awid_i)
    ,.axi_awlen_i(axi_t_awlen_i)
    ,.axi_awburst_i(axi_t_awburst_i)
    ,.axi_wvalid_i(axi_t_wvalid_i)
    ,.axi_wdata_i(axi_t_wdata_i)
    ,.axi_wstrb_i(axi_t_wstrb_i)
    ,.axi_wlast_i(axi_t_wlast_i)
    ,.axi_bready_i(axi_t_bready_i)
    ,.axi_arvalid_i(axi_t_arvalid_i)
    ,.axi_araddr_i(axi_t_araddr_i)
    ,.axi_arid_i(axi_t_arid_i)
    ,.axi_arlen_i(axi_t_arlen_i)
    ,.axi_arburst_i(axi_t_arburst_i)
    ,.axi_rready_i(axi_t_rready_i)

    // Outputs
    ,.mem_i_accept_o(ifetch_accept_w)
    ,.mem_i_valid_o(ifetch_valid_w)
    ,.mem_i_error_o(ifetch_error_w)
    ,.mem_i_inst_o(ifetch_inst_w)
    ,.mem_d_data_rd_o(dport_tcm_data_rd_w)
    ,.mem_d_accept_o(dport_tcm_accept_w)
    ,.mem_d_ack_o(dport_tcm_ack_w)
    ,.mem_d_error_o(dport_tcm_error_w)
    ,.mem_d_resp_tag_o(dport_tcm_resp_tag_w)
    ,.axi_awready_o(axi_t_awready_o)
    ,.axi_wready_o(axi_t_wready_o)
    ,.axi_bvalid_o(axi_t_bvalid_o)
    ,.axi_bresp_o(axi_t_bresp_o)
    ,.axi_bid_o(axi_t_bid_o)
    ,.axi_arready_o(axi_t_arready_o)
    ,.axi_rvalid_o(axi_t_rvalid_o)
    ,.axi_rdata_o(axi_t_rdata_o)
    ,.axi_rresp_o(axi_t_rresp_o)
    ,.axi_rid_o(axi_t_rid_o)
    ,.axi_rlast_o(axi_t_rlast_o)
);

//-----------------------------------------------------------------
// External AXI bridge
//-----------------------------------------------------------------
dport_axi
u_axi
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_addr_i(dport_axi_addr_w)
    ,.mem_data_wr_i(dport_axi_data_wr_w)
    ,.mem_rd_i(dport_axi_rd_w)
    ,.mem_wr_i(dport_axi_wr_w)
    ,.mem_cacheable_i(dport_axi_cacheable_w)
    ,.mem_req_tag_i(dport_axi_req_tag_w)
    ,.mem_invalidate_i(dport_axi_invalidate_w)
    ,.mem_writeback_i(dport_axi_writeback_w)
    ,.mem_flush_i(dport_axi_flush_w)
    ,.axi_awready_i(axi_i_awready_i)
    ,.axi_wready_i(axi_i_wready_i)
    ,.axi_bvalid_i(axi_i_bvalid_i)
    ,.axi_bresp_i(axi_i_bresp_i)
    ,.axi_arready_i(axi_i_arready_i)
    ,.axi_rvalid_i(axi_i_rvalid_i)
    ,.axi_rdata_i(axi_i_rdata_i)
    ,.axi_rresp_i(axi_i_rresp_i)

    // Outputs
    ,.mem_data_rd_o(dport_axi_data_rd_w)
    ,.mem_accept_o(dport_axi_accept_w)
    ,.mem_ack_o(dport_axi_ack_w)
    ,.mem_error_o(dport_axi_error_w)
    ,.mem_resp_tag_o(dport_axi_resp_tag_w)
    ,.axi_awvalid_o(axi_i_awvalid_o)
    ,.axi_awaddr_o(axi_i_awaddr_o)
    ,.axi_wvalid_o(axi_i_wvalid_o)
    ,.axi_wdata_o(axi_i_wdata_o)
    ,.axi_wstrb_o(axi_i_wstrb_o)
    ,.axi_bready_o(axi_i_bready_o)
    ,.axi_arvalid_o(axi_i_arvalid_o)
    ,.axi_araddr_o(axi_i_araddr_o)
    ,.axi_rready_o(axi_i_rready_o)
);

endmodule
