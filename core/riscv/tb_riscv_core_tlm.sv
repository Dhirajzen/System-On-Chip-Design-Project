`timescale 1ns/1ps

module tb;

  // ---------------------------------------------
  // Clock / reset
  // ---------------------------------------------
  reg clk;
  reg rst;

  initial clk = 1'b0;
  always #5 clk = ~clk;   // 100 MHz

  // ---------------------------------------------
  // RISC-V core <-> memory interfaces
  // ---------------------------------------------
  // Data port
  wire [31:0] mem_d_addr;
  wire [31:0] mem_d_data_wr;
  wire        mem_d_rd;
  wire [3:0]  mem_d_wr;
  wire        mem_d_cacheable;
  wire [10:0] mem_d_req_tag;
  wire        mem_d_invalidate;
  wire        mem_d_writeback;
  wire        mem_d_flush;

  wire [31:0] mem_d_data_rd;
  wire        mem_d_accept;
  wire        mem_d_ack;
  wire        mem_d_error;
  wire [10:0] mem_d_resp_tag;

  // Instruction port
  wire        mem_i_rd;
  wire        mem_i_flush;
  wire        mem_i_invalidate;
  wire [31:0] mem_i_pc;

  wire        mem_i_accept;
  wire        mem_i_valid;
  wire        mem_i_error;
  wire [31:0] mem_i_inst;

  // Telemetry outputs from the core
  wire [63:0] tlm_mcycle;
  wire [63:0] tlm_minstret;
  wire [63:0] tlm_stall;

  // ---------------------------------------------
  // DUT: full RISC-V core with telemetry enabled
  // ---------------------------------------------
  riscv_core #(
      .SUPPORT_MULDIV          (1),
      .SUPPORT_SUPER           (0),
      .SUPPORT_MMU             (0),                 // easier for standalone TB
      .SUPPORT_LOAD_BYPASS     (1),
      .SUPPORT_MUL_BYPASS      (1),
      .SUPPORT_REGFILE_XILINX  (0),
      .EXTRA_DECODE_STAGE      (0),
      .MEM_CACHE_ADDR_MIN      (32'h8000_0000),
      .MEM_CACHE_ADDR_MAX      (32'h8fff_ffff)
  ) dut (
      // Clock / reset
      .clk_i              (clk),
      .rst_i              (rst),

      // Data port in
      .mem_d_data_rd_i    (mem_d_data_rd),
      .mem_d_accept_i     (mem_d_accept),
      .mem_d_ack_i        (mem_d_ack),
      .mem_d_error_i      (mem_d_error),
      .mem_d_resp_tag_i   (mem_d_resp_tag),

      // Instruction port in
      .mem_i_accept_i     (mem_i_accept),
      .mem_i_valid_i      (mem_i_valid),
      .mem_i_error_i      (mem_i_error),
      .mem_i_inst_i       (mem_i_inst),

      // Interrupt / boot info
      .intr_i             (1'b0),
      .reset_vector_i     (32'h0000_2000),   // boot address
      .cpu_id_i           (32'd0),

      // Data port out
      .mem_d_addr_o       (mem_d_addr),
      .mem_d_data_wr_o    (mem_d_data_wr),
      .mem_d_rd_o         (mem_d_rd),
      .mem_d_wr_o         (mem_d_wr),
      .mem_d_cacheable_o  (mem_d_cacheable),
      .mem_d_req_tag_o    (mem_d_req_tag),
      .mem_d_invalidate_o (mem_d_invalidate),
      .mem_d_writeback_o  (mem_d_writeback),
      .mem_d_flush_o      (mem_d_flush),

      // Instruction port out
      .mem_i_rd_o         (mem_i_rd),
      .mem_i_flush_o      (mem_i_flush),
      .mem_i_invalidate_o (mem_i_invalidate),
      .mem_i_pc_o         (mem_i_pc),

      // Telemetry outputs
      .tlm_mcycle_o       (tlm_mcycle),
      .tlm_minstret_o     (tlm_minstret),
      .tlm_stall_o        (tlm_stall)
  );

  // ---------------------------------------------
  // Simple instruction "memory"
  //   - Always returns NOP: ADDI x0, x0, 0 = 0x00000013
  //   - Responds immediately when mem_i_rd is asserted
  // ---------------------------------------------
  assign mem_i_accept = 1'b1;              // always accept request
  assign mem_i_valid  = mem_i_rd;          // zero-latency response
  assign mem_i_error  = 1'b0;
  assign mem_i_inst   = 32'h0000_0013;     // NOP

  // ---------------------------------------------
  // Simple data "memory"
  //   - Always ready
  //   - Reads return 0
  //   - Writes are ignored but immediately acked
  // ---------------------------------------------
  assign mem_d_accept   = 1'b1;
  assign mem_d_ack      = mem_d_rd | (|mem_d_wr);   // ack any access
  assign mem_d_error    = 1'b0;
  assign mem_d_data_rd  = 32'h0000_0000;
  assign mem_d_resp_tag = mem_d_req_tag;

  // ---------------------------------------------
  // Test sequence
  // ---------------------------------------------
  integer i;
  initial begin
    // Reset core
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // Let the core run for N cycles
    for (i = 0; i < 100; i = i + 1) begin
      @(posedge clk);
    end

    // Print out telemetry coming from the real core
    $display("========================================");
    $display(" Telemetry from riscv_core after %0d cycles", i);
    $display("  mcycle   = %0d", tlm_mcycle);
    $display("  minstret = %0d", tlm_minstret);
    $display("  stall    = %0d", tlm_stall);
    $display("========================================");

    $finish;
  end

endmodule
