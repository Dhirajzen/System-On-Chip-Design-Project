// ---------------------------------------------------------------------
// Simple instruction trace buffer
//   - Captures {PC, INSTR} on each retired instruction
//   - Circular buffer with configurable DEPTH
//   - Freezes when 'trigger_i' goes high (e.g. on interrupt/exception)
// ---------------------------------------------------------------------

module trace_buffer #(
    parameter int DEPTH    = 64
)(
    // Clock / reset
    input  logic                 clk_i,
    input  logic                 rst_ni,          // active-low reset

    // Control
    input  logic                 enable_i,        // overall enable
    input  logic                 trigger_i,       // freeze trace when 1
    input  logic                 retire_valid_i,  // retired instr pulse

    // Data from core
    input  logic [31:0]          pc_i,
    input  logic [31:0]          instr_i,

    // Status
    output logic                 triggered_o,     // went through trigger
    output logic [$clog2(DEPTH)-1:0]  wr_ptr_o,        // last write pointer

    // Read-out interface (for testbench or future MMIO)
    input  logic [$clog2(DEPTH)-1:0]  rd_addr_i,
    output logic [31:0]          rd_pc_o,
    output logic [31:0]          rd_instr_o
);


    // Derived parameter: NOT user-configurable
    localparam int PTR_BITS = $clog2(DEPTH);
    // -----------------------------------------------------------------
    // Storage: DEPTH entries of {PC[31:0], INSTR[31:0]}
    // -----------------------------------------------------------------
    logic [63:0] mem [0:DEPTH-1];

    // Write pointer & trigger flag
    logic [PTR_BITS-1:0] wr_ptr_q;
    logic                triggered_q;

    // -----------------------------------------------------------------
    // Write side (capture retired instructions)
    // -----------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr_q    <= '0;
            triggered_q <= 1'b0;
        end
        else begin
            // Latch trigger: once triggered, stay triggered
            if (trigger_i)
                triggered_q <= 1'b1;

            // Only write while enabled and NOT yet triggered
            if (enable_i && retire_valid_i && !triggered_q) begin
                mem[wr_ptr_q] <= {pc_i, instr_i};
                wr_ptr_q      <= wr_ptr_q + {{(PTR_BITS-1){1'b0}},1'b1};
            end
        end
    end

    assign triggered_o = triggered_q;
    assign wr_ptr_o    = wr_ptr_q;

    // -----------------------------------------------------------------
    // Read side (combinational read for now)
    // -----------------------------------------------------------------
    logic [63:0] rd_word;

    always_comb begin
        rd_word = mem[rd_addr_i];
        rd_pc_o    = rd_word[63:32];
        rd_instr_o = rd_word[31:0];
    end

endmodule
