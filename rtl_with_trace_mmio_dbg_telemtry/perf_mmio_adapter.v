// -----------------------------------------------------------------------------
// perf_mmio_adapter.v
// PARAMETERIZED VERSION
// Supports any TRACE_DEPTH and TRACE_PTR_BITS
// -----------------------------------------------------------------------------
// MMIO ranges:
//  - 0x8000_0000..0x8000_0014 : perf counters
//  - 0x8000_0020..0x8000_0030 : trace MMIO (trace addr width now param)
//  - 0x8000_0040..0x8000_0074 : histogram (currently disabled)
// -----------------------------------------------------------------------------

module perf_mmio_adapter #(
    parameter int TRACE_DEPTH    = 64,
    parameter int TRACE_PTR_BITS = $clog2(TRACE_DEPTH)
)(
    input           clk_i,
    input           rst_i,

    // ---------------- Core side ----------------
    input  [31:0]   core_addr_i,
    input  [31:0]   core_data_wr_i,
    input           core_rd_i,
    input  [ 3:0]   core_wr_i,
    input           core_cacheable_i,
    input  [10:0]   core_req_tag_i,
    input           core_invalidate_i,
    input           core_writeback_i,
    input           core_flush_i,

    output reg [31:0] core_data_rd_o,
    output reg        core_accept_o,
    output reg        core_ack_o,
    output reg        core_error_o,
    output reg [10:0] core_resp_tag_o,

    // ---------------- Bus side ----------------
    output [31:0]   bus_addr_o,
    output [31:0]   bus_data_wr_o,
    output          bus_rd_o,
    output [ 3:0]   bus_wr_o,
    output          bus_cacheable_o,
    output [10:0]   bus_req_tag_o,
    output          bus_invalidate_o,
    output          bus_writeback_o,
    output          bus_flush_o,

    input  [31:0]   bus_data_rd_i,
    input           bus_accept_i,
    input           bus_ack_i,
    input           bus_error_i,
    input  [10:0]   bus_resp_tag_i,

    // ---------------- Performance counters ----------------
    input  [63:0]   tlm_mcycle_i,
    input  [63:0]   tlm_minstret_i,
    input  [63:0]   tlm_stall_i,

    // ---------------- Trace buffer ----------------
    input                       trace_triggered_i,
    input  [TRACE_PTR_BITS-1:0] trace_wr_ptr_i,
    input  [31:0]               trace_rd_pc_i,
    input  [31:0]               trace_rd_instr_i,
    output [TRACE_PTR_BITS-1:0] trace_rd_addr_o

    // ---------------- Histogram ----------------
    // input  [63:0]   hist_alu_i,
    // input  [63:0]   hist_lsu_i,
    // input  [63:0]   hist_branch_i,
    // input  [63:0]   hist_jump_i,
    // input  [63:0]   hist_muldiv_i,
    // input  [63:0]   hist_csr_i,
    // input  [63:0]   hist_other_i
);

    // -------------------------------------------------------------------------
    // MMIO ranges
    // -------------------------------------------------------------------------
    localparam [31:0] PERF_BASE = 32'h8000_0000;
    localparam [31:0] PERF_LAST = 32'h8000_0014;

    localparam [31:0] TRACE_BASE = 32'h8000_0020;
    localparam [31:0] TRACE_LAST = 32'h8000_0030;

    // Histogram base/last kept for future use (currently unused):
    // localparam [31:0] HIST_BASE  = 32'h8000_0040;
    // localparam [31:0] HIST_LAST  = 32'h8000_0074;

    // -------------------------------------------------------------------------
    // Decode MMIO regions
    // -------------------------------------------------------------------------
    wire perf_hit_w  = (core_addr_i >= PERF_BASE)  && (core_addr_i <= PERF_LAST);
    wire trace_hit_w = (core_addr_i >= TRACE_BASE) && (core_addr_i <= TRACE_LAST);
    // wire hist_hit_w  = (core_addr_i >= HIST_BASE)  && (core_addr_i <= HIST_LAST);
    wire mmio_hit_w  = perf_hit_w || trace_hit_w; // || hist_hit_w;

    wire is_read_w   = core_rd_i && (core_wr_i == 4'b0000);
    wire is_write_w  = (core_wr_i != 4'b0000);

    // Word offsets
    wire [5:0] perf_word_off_w  = (core_addr_i - PERF_BASE ) >> 2;
    wire [5:0] trace_word_off_w = (core_addr_i - TRACE_BASE) >> 2;
    // wire [5:0] hist_word_off_w  = (core_addr_i - HIST_BASE ) >> 2;

    // -------------------------------------------------------------------------
    // Readback state
    // -------------------------------------------------------------------------
    reg         mmio_pending_q;
    reg [31:0]  mmio_rdata_q;
    reg [10:0]  mmio_tag_q;

    // Trace read address register — parameterized width
    reg [TRACE_PTR_BITS-1:0] trace_rd_addr_q;
    assign trace_rd_addr_o = trace_rd_addr_q;

    // -------------------------------------------------------------------------
    // Pass-through signals
    // -------------------------------------------------------------------------
    assign bus_addr_o       = core_addr_i;
    assign bus_data_wr_o    = core_data_wr_i;
    assign bus_cacheable_o  = core_cacheable_i;
    assign bus_req_tag_o    = core_req_tag_i;

    assign bus_rd_o         = mmio_hit_w ? 1'b0    : core_rd_i;
    assign bus_wr_o         = mmio_hit_w ? 4'b0000 : core_wr_i;
    assign bus_invalidate_o = mmio_hit_w ? 1'b0    : core_invalidate_i;
    assign bus_writeback_o  = mmio_hit_w ? 1'b0    : core_writeback_i;
    assign bus_flush_o      = mmio_hit_w ? 1'b0    : core_flush_i;

    // -------------------------------------------------------------------------
    // Main MMIO FSM
    // -------------------------------------------------------------------------
    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i)
        begin
            core_data_rd_o  <= 32'b0;
            core_accept_o   <= 1'b0;
            core_ack_o      <= 1'b0;
            core_error_o    <= 1'b0;
            core_resp_tag_o <= 11'b0;

            mmio_pending_q  <= 1'b0;
            mmio_rdata_q    <= 32'b0;
            mmio_tag_q      <= 11'b0;

            trace_rd_addr_q <= {TRACE_PTR_BITS{1'b0}};
        end
        else
        begin
            core_accept_o <= 1'b0;
            core_ack_o    <= 1'b0;
            core_error_o  <= 1'b0;

            // ---------------------------------------------
            // MMIO read/write phase 1
            // ---------------------------------------------
            if (!mmio_pending_q)
            begin
                if (mmio_hit_w)
                begin
                    if (is_read_w)
                    begin
                        core_accept_o  <= 1'b1;
                        mmio_pending_q <= 1'b1;
                        mmio_tag_q     <= core_req_tag_i;

                        // ---------------- PERF ----------------
                        if (perf_hit_w)
                        begin
                            case (perf_word_off_w)
                                0: mmio_rdata_q <= tlm_mcycle_i[31:0];
                                1: mmio_rdata_q <= tlm_mcycle_i[63:32];
                                2: mmio_rdata_q <= tlm_minstret_i[31:0];
                                3: mmio_rdata_q <= tlm_minstret_i[63:32];
                                4: mmio_rdata_q <= tlm_stall_i[31:0];
                                5: mmio_rdata_q <= tlm_stall_i[63:32];
                                default: mmio_rdata_q <= 32'hDEAD_BEEF;
                            endcase
                        end

                        // ---------------- TRACE ----------------
                        else if (trace_hit_w)
                        begin
                            case (trace_word_off_w)
                                // 0x8000_0020
                                0: mmio_rdata_q <= {31'b0, trace_triggered_i};
                                // 0x8000_0024
                                1: mmio_rdata_q <= {{(32-TRACE_PTR_BITS){1'b0}}, trace_wr_ptr_i};
                                // 0x8000_0028
                                2: mmio_rdata_q <= trace_rd_pc_i;
                                // 0x8000_002C
                                3: mmio_rdata_q <= trace_rd_instr_i;
                                // 0x8000_0030 : R/W index register
                                4: mmio_rdata_q <= {{(32-TRACE_PTR_BITS){1'b0}}, trace_rd_addr_q};
                                default: mmio_rdata_q <= 32'hDEAD_BEEF;
                            endcase
                        end

                        // ---------------- HISTOGRAM (disabled) ----------------
                        // else if (hist_hit_w)
                        // begin
                        //     case (hist_word_off_w)
                        //         0:  mmio_rdata_q <= hist_alu_i[31:0];
                        //         1:  mmio_rdata_q <= hist_alu_i[63:32];
                        //         2:  mmio_rdata_q <= hist_lsu_i[31:0];
                        //         3:  mmio_rdata_q <= hist_lsu_i[63:32];
                        //         4:  mmio_rdata_q <= hist_branch_i[31:0];
                        //         5:  mmio_rdata_q <= hist_branch_i[63:32];
                        //         6:  mmio_rdata_q <= hist_jump_i[31:0];
                        //         7:  mmio_rdata_q <= hist_jump_i[63:32];
                        //         8:  mmio_rdata_q <= hist_muldiv_i[31:0];
                        //         9:  mmio_rdata_q <= hist_muldiv_i[63:32];
                        //         10: mmio_rdata_q <= hist_csr_i[31:0];
                        //         11: mmio_rdata_q <= hist_csr_i[63:32];
                        //         12: mmio_rdata_q <= hist_other_i[31:0];
                        //         13: mmio_rdata_q <= hist_other_i[63:32];
                        //         default: mmio_rdata_q <= 32'hDEAD_BEEF;
                        //     endcase
                        // end
                    end

                    // ---------------- MMIO WRITE ----------------
                    else if (is_write_w)
                    begin
                        core_accept_o   <= 1'b1;
                        core_ack_o      <= 1'b1;
                        core_resp_tag_o <= core_req_tag_i;

                        // Only TRACE word 4 (0x8000_0030) is writable:
                        if (trace_hit_w && trace_word_off_w == 4)
                            trace_rd_addr_q <= core_data_wr_i[TRACE_PTR_BITS-1:0];
                    end
                end
                else
                begin
                    // Normal bus transaction passthrough
                    core_accept_o   <= bus_accept_i;
                    core_ack_o      <= bus_ack_i;
                    core_error_o    <= bus_error_i;
                    core_data_rd_o  <= bus_data_rd_i;
                    core_resp_tag_o <= bus_resp_tag_i;
                end
            end

            // ---------------------------------------------
            // MMIO read phase 2: return data
            // ---------------------------------------------
            else
            begin
                core_ack_o      <= 1'b1;
                core_data_rd_o  <= mmio_rdata_q;
                core_resp_tag_o <= mmio_tag_q;
                mmio_pending_q  <= 1'b0;
            end
        end
    end

endmodule

