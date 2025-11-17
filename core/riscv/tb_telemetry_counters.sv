`timescale 1ns/1ps

module tb;

  // DUT interface
  logic        clk;
  logic        rst_n;
  logic        cycle_en;
  logic        retire_pulse;
  logic        stall_cycle;

  logic [63:0] mcycle;
  logic [63:0] minstret;
  logic [63:0] stall_cycles;

  // -----------------------------
  // DUT: telemetry_counters
  // -----------------------------
  telemetry_counters #(
    .WIDTH(64)
  ) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .cycle_en     (cycle_en),
    .retire_pulse (retire_pulse),
    .stall_cycle  (stall_cycle),
    .mcycle       (mcycle),
    .minstret     (minstret),
    .stall_cycles (stall_cycles)
  );

  // -----------------------------
  // Clock generation (100 MHz)
  // -----------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;  // 10 ns period

  // -----------------------------
  // Golden model (matches RTL)
  // -----------------------------
  logic [63:0] mcycle_g;
  logic [63:0] minstret_g;
  logic [63:0] stall_cycles_g;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mcycle_g       <= '0;
      minstret_g     <= '0;
      stall_cycles_g <= '0;
    end else if (cycle_en) begin
      // mcycle: every enabled cycle
      mcycle_g <= mcycle_g + 1'b1;

      // minstret: each retire_pulse
      if (retire_pulse)
        minstret_g <= minstret_g + 1'b1;

      // stall_cycles: each stall_cycle
      if (stall_cycle)
        stall_cycles_g <= stall_cycles_g + 1'b1;
    end
  end

  // Compare DUT vs golden each enabled cycle
  always_ff @(posedge clk) begin
    if (rst_n && cycle_en) begin
      if (mcycle       !== mcycle_g      ||
          minstret     !== minstret_g    ||
          stall_cycles !== stall_cycles_g) begin
        $display("[TB] MISMATCH at t=%0t", $time);
        $display("     DUT: mcycle=%0d minstret=%0d stall=%0d",
                  mcycle, minstret, stall_cycles);
        $display("     GLD: mcycle=%0d minstret=%0d stall=%0d",
                  mcycle_g, minstret_g, stall_cycles_g);
        $fatal(1, "[TB] ERROR: counters != golden model");
      end
    end
  end

  // -----------------------------
  // Helper: one cycle step
  // -----------------------------
  task automatic step_cycle(
      input logic retire,
      input logic stall
  );
  begin
    retire_pulse = retire;
    stall_cycle  = stall;
    @(posedge clk);
  end
  endtask

  // -----------------------------
  // Stimulus
  // -----------------------------
  initial begin
    // Init
    rst_n        = 1'b0;
    cycle_en     = 1'b0;
    retire_pulse = 1'b0;
    stall_cycle  = 1'b0;

    // 3 cycles in reset
    repeat (3) @(posedge clk);

    // Release reset and enable counters
    rst_n    = 1'b1;
    @(posedge clk);
    cycle_en = 1'b1;

    // Pattern:
    //   5 cycles : retire=1, stall=0  ->  5 retires
    //   4 cycles : retire=0, stall=1  ->  4 stalls
    //   3 cycles : retire=1, stall=0  ->  3 retires
    //   2 cycles : retire=0, stall=0  ->  idle/no extra count
    //
    // Totals:
    //   Enabled cycles  = 5 + 4 + 3 + 2 = 14 => mcycle = 14
    //   minstret        = 5 + 3         = 8
    //   stall_cycles    = 4

    repeat (5) step_cycle(1'b1, 1'b0); // 5 retire cycles
    repeat (4) step_cycle(1'b0, 1'b1); // 4 stall cycles
    repeat (3) step_cycle(1'b1, 1'b0); // 3 retire cycles
    repeat (2) step_cycle(1'b0, 1'b0); // 2 idle cycles

    // Stop counting and run a dummy cycle
    cycle_en = 1'b0;
    step_cycle(1'b0, 1'b0);

    // Final print
    $display("[TB] Final DUT counters:");
    $display("     mcycle       = %0d", mcycle);
    $display("     minstret     = %0d", minstret);
    $display("     stall_cycles = %0d", stall_cycles);

    // Explicit checks vs expected
    if (mcycle       !== 64'd14) $fatal(1, "[TB] mcycle expected 14.");
    if (minstret     !== 64'd8 ) $fatal(1, "[TB] minstret expected 8.");
    if (stall_cycles !== 64'd4 ) $fatal(1, "[TB] stall_cycles expected 4.");

    $display("[TB] PASS: telemetry_counters (cycle, retired, stall) OK.");
    $finish;
  end

endmodule
