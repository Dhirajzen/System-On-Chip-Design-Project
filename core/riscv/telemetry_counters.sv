// core/riscv/telemetry_counters.sv
module telemetry_counters #(
  parameter WIDTH = 64
) (
  input  logic              clk,
  input  logic              rst_n,
  input  logic              cycle_en,       // tie 1'b1 unless you have a core freeze

  // one-cycle events from the pipeline
  input  logic              retire_pulse,   // one per committed instruction
  input  logic              stall_cycle,    // high for cycles the pipe is actually stalled

  // counters out
  output logic [WIDTH-1:0]  mcycle,
  output logic [WIDTH-1:0]  minstret,
  output logic [WIDTH-1:0]  stall_cycles
);

  // free-running cycle counter
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      mcycle <= '0;
    else if (cycle_en)
      mcycle <= mcycle + 1'b1;
  end

  // retired & stall counters
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      minstret     <= '0;
      stall_cycles <= '0;
    end else if (cycle_en) begin
      if (retire_pulse)
        minstret <= minstret + 1'b1;
      if (stall_cycle)
        stall_cycles <= stall_cycles + 1'b1;
    end
  end

endmodule
