`timescale 1ns/1ps

module tb;

  // ------------------------------------------------------------
  // Clocks / resets
  // ------------------------------------------------------------
  reg clk     = 1'b0;
  reg rst     = 1'b1;
  reg rst_cpu = 1'b1;

  // 100 MHz clock (10 ns period)
  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // DUT: RISC-V core + TCM + telemetry
  // ------------------------------------------------------------
  // BOOT_VECTOR forced to 0 so PC starts at 0x0000_0000,
  // where we will load program.hex into TCM RAM.
  riscv_tcm_top #(
      .BOOT_VECTOR(32'h0000_0000)
  ) dut (
      // Clocks / reset
      .clk_i      (clk),
      .rst_i      (rst),
      .rst_cpu_i  (rst_cpu),

      // AXI master (instruction/data to external memory)
      // -> Tie off as "always ready, no data" since we only use TCM.
      .axi_i_awready_i (1'b1),
      .axi_i_wready_i  (1'b1),
      .axi_i_bvalid_i  (1'b0),
      .axi_i_bresp_i   (2'b00),
      .axi_i_arready_i (1'b1),
      .axi_i_rvalid_i  (1'b0),
      .axi_i_rdata_i   (32'b0),
      .axi_i_rresp_i   (2'b00),

      // AXI slave (to write TCM via AXI) - unused in this TB
      .axi_t_awvalid_i (1'b0),
      .axi_t_awaddr_i  (32'b0),
      .axi_t_awid_i    (4'b0),
      .axi_t_awlen_i   (8'b0),
      .axi_t_awburst_i (2'b01),
      .axi_t_wvalid_i  (1'b0),
      .axi_t_wdata_i   (32'b0),
      .axi_t_wstrb_i   (4'b0),
      .axi_t_wlast_i   (1'b0),
      .axi_t_bready_i  (1'b0),
      .axi_t_arvalid_i (1'b0),
      .axi_t_araddr_i  (32'b0),
      .axi_t_arid_i    (4'b0),
      .axi_t_arlen_i   (8'b0),
      .axi_t_arburst_i (2'b01),
      .axi_t_rready_i  (1'b0),

      // No external interrupts
      .intr_i          (32'b0),

      // AXI master outputs (ignored in TB)
      .axi_i_awvalid_o (),
      .axi_i_awaddr_o  (),
      .axi_i_wvalid_o  (),
      .axi_i_wdata_o   (),
      .axi_i_wstrb_o   (),
      .axi_i_bready_o  (),
      .axi_i_arvalid_o (),
      .axi_i_araddr_o  (),
      .axi_i_rready_o  (),

      // AXI slave outputs (ignored in TB)
      .axi_t_awready_o (),
      .axi_t_wready_o  (),
      .axi_t_bvalid_o  (),
      .axi_t_bresp_o   (),
      .axi_t_bid_o     (),
      .axi_t_arready_o (),
      .axi_t_rvalid_o  (),
      .axi_t_rdata_o   (),
      .axi_t_rresp_o   (),
      .axi_t_rid_o     (),
      .axi_t_rlast_o   ()
  );

  // ------------------------------------------------------------
  // Initial block: load program + reset sequence + dump telemetry
  // ------------------------------------------------------------
  initial begin
    // 1) Load program into TCM RAM
    //    tcm_mem instantiates tcm_mem_ram as u_ram with array "ram"
    //    so hierarchy = dut.u_tcm.u_ram.ram
    $display("[TB] Loading program.hex into TCM...");
    $readmemh("program.hex", dut.u_tcm.u_ram.ram);

    // 2) Reset sequence
    rst     = 1'b1;
    rst_cpu = 1'b1;
    #100;
    rst     = 1'b0;
    #50;
    rst_cpu = 1'b0;

    // 3) Let the core run for some cycles
    repeat (1000) @(posedge clk);

    // 4) Print telemetry (internal wires in riscv_tcm_top)
    $display("========================================");
    $display(" Telemetry from riscv_tcm_top");
    $display("  mcycle   = %0d", dut.tlm_mcycle_w);
    $display("  minstret = %0d", dut.tlm_minstret_w);
    $display("  stall    = %0d", dut.tlm_stall_w);
    $display("========================================");

    $finish;
  end

endmodule
