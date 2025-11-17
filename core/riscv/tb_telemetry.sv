`timescale 1ns/1ps

module tb_telemetry;

  // --- Clock / Reset ---
  logic clk = 0;
  logic rst = 1;

  // 100MHz
  always #5 clk = ~clk;

  // --- DUT ---
  // NOTE: if your top module name or ports differ, adjust here.
  riscv_tcm_top dut (
    .clk_i (clk),
    .rst_i (rst)

    // If your top has extra external ports (UART, GPIO, AXI-lite pins),
    // tie them off as needed; for this test we don't touch external periphs.
  );

  // --- Reset sequence ---
  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst = 0;
  end

  // --- Run for a while, then report ---
  // The program spins once it has stored counters into TCM at 0x0000_FF00.
  initial begin
    // Let it run ~2000 cycles (more than enough for program + DIV stalls)
    repeat (2000) @(posedge clk);

    // 1) Print live 64-bit counters inside the top (hierarchical probes).
    // If your wire names differ, search in riscv_tcm_top.v for tlm_* wires and update here.
    $display("\n=== LIVE TELEMETRY (hierarchical) ===");
    $display("mcycle   = 0x%016h", dut.tlm_mcycle_w);
    $display("minstret = 0x%016h", dut.tlm_minstret_w);
    $display("stall    = 0x%016h\n", dut.tlm_stall_w);

    // 2) Print the words the program stored into TCM RAM at 0x0000_FF00..
    // This requires hierarchical access to the RAM array.
    //
    // OPEN tcm_mem_ram.v and find the array name.
    // It's commonly something like:  reg [31:0] ram [0:DEPTH-1];
    // Then figure out which *instance path* it sits under in your top.
    // Typical path (example): dut.u_dmem.u_ram.ram[...]
    //
    // ----> EDIT THE PATH BELOW <---- to match your actual hierarchy.
    //
    int base_word_addr = 'hFF00 >> 2; // 0x0000_FF00 as word index
    $display("=== STORED TELEMETRY (TCM @ 0x0000_FF00) ===");
    $display("mcycle[31:0]   = 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 0]);
    $display("mcycle[63:32]  = 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 1]);
    $display("minstret[31:0] = 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 2]);
    $display("minstret[63:32]= 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 3]);
    $display("stall[31:0]    = 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 4]);
    $display("stall[63:32]   = 0x%08h", dut.u_dmem.u_ram.ram[base_word_addr + 5]);

    // Optional sanity checks:
    longint unsigned mcycle   = {dut.u_dmem.u_ram.ram[base_word_addr + 1],
                                 dut.u_dmem.u_ram.ram[base_word_addr + 0]};
    longint unsigned minstret = {dut.u_dmem.u_ram.ram[base_word_addr + 3],
                                 dut.u_dmem.u_ram.ram[base_word_addr + 2]};
    longint unsigned stall    = {dut.u_dmem.u_ram.ram[base_word_addr + 5],
                                 dut.u_dmem.u_ram.ram[base_word_addr + 4]};

    $display("\n=== DERIVED ===");
    $display("mcycle   (64) = %0d", mcycle);
    $display("minstret (64) = %0d", minstret);
    $display("stall    (64) = %0d", stall);
    $display("Check: mcycle >= minstret, stall = mcycle - minstret (± a few init cycles)\n");

    // Graceful finish
    #50 $finish;
  end

endmodule
