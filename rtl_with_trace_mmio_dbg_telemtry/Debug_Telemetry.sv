// Debug_Telemetry.sv
// Standalone debug / telemetry block for PD:
// - Instantiates telemetry_counters (mcycle, minstret, stall_cycles)
// - Instantiates trace_buffer (PC + INSTR trace)
// - Simple trigger: after TRACE_DEPTH valid fetches
// - Provides trace readback via rd_addr

module Debug_Telemetry #(
    parameter int CNT_WIDTH      = 64,
    parameter int TRACE_DEPTH    = 64
)(
    input  wire                      clk_i,
    input  wire                      rst_i,

    // Event taps from core
    input  wire                      retire_pulse_i,
    input  wire                      stall_cycle_i,
    input  wire [31:0]               fetch_pc_i,
    input  wire [31:0]               fetch_instr_i,

    // Trace read / status interface
    input  wire [$clog2(TRACE_DEPTH)-1:0] trace_rd_addr_i,
    output wire                      trace_triggered_o,
    output wire [$clog2(TRACE_DEPTH)-1:0] trace_wr_ptr_o,
    output wire [31:0]               trace_rd_pc_o,
    output wire [31:0]               trace_rd_instr_o,

    // Performance counters out (to perf_mmio_adapter)
    output wire [CNT_WIDTH-1:0]      tlm_mcycle_o,
    output wire [CNT_WIDTH-1:0]      tlm_minstret_o,
    output wire [CNT_WIDTH-1:0]      tlm_stall_o
);

    localparam int TRACE_PTR_BITS = $clog2(TRACE_DEPTH);

    // ============================================================
    // 1) Telemetry counters
    // ============================================================
    telemetry_counters #(
        .WIDTH (CNT_WIDTH)
    ) u_tlm_cnt (
        .clk          (clk_i),
        .rst_n        (~rst_i),
        .cycle_en     (1'b1),           // always count cycles
        .retire_pulse (retire_pulse_i),
        .stall_cycle  (stall_cycle_i),
        .mcycle       (tlm_mcycle_o),
        .minstret     (tlm_minstret_o),
        .stall_cycles (tlm_stall_o)
    );

    // ============================================================
    // 2) Trace trigger logic
    //    - Count valid fetches
    //    - After TRACE_DEPTH samples, fire trigger once
    // ============================================================
    reg [15:0] trace_sample_cnt_q;
    reg        trace_trigger_q;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            trace_sample_cnt_q <= 16'd0;
            trace_trigger_q    <= 1'b0;
        end
        else begin
            if (!trace_trigger_q && retire_pulse_i) begin
                trace_sample_cnt_q <= trace_sample_cnt_q + 16'd1;
                if (trace_sample_cnt_q == TRACE_DEPTH-1)
                    trace_trigger_q <= 1'b1;
            end
        end
    end

    // ============================================================
    // 3) Trace buffer
    //    - Stores PC + INSTR for last TRACE_DEPTH valid fetches
    //    - trigger_i tells it to freeze / mark as complete (depending
    //      on your trace_buffer implementation)
    // ============================================================
    trace_buffer #(
        .DEPTH    (TRACE_DEPTH)
    ) u_trace_buf (
        .clk_i          (clk_i),
        .rst_ni         (~rst_i),

        .enable_i       (1'b1),
        .trigger_i      (trace_trigger_q),
        .retire_valid_i (retire_pulse_i),
        .pc_i           (fetch_pc_i),
        .instr_i        (fetch_instr_i),

        .triggered_o    (trace_triggered_o),
        .wr_ptr_o       (trace_wr_ptr_o),

        .rd_addr_i      (trace_rd_addr_i),
        .rd_pc_o        (trace_rd_pc_o),
        .rd_instr_o     (trace_rd_instr_o)
    );

endmodule
