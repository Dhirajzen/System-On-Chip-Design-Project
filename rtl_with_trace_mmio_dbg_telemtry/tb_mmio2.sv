// telemetry_tb.sv

module tb_mmio2;
  // Clock and reset
  reg clk_i = 0;
  reg rst_i = 1;
  reg rst_cpu_i = 1;
  always #5 clk_i = ~clk_i;  // 100 MHz clock

  initial begin
    // Simple reset pulse
    #20;
    rst_i     = 0;
    rst_cpu_i = 0;
  end

  // --------------------------------------------------------------------------
  // Instantiate DUT
  // --------------------------------------------------------------------------
  riscv_tcm_top uut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rst_cpu_i(rst_cpu_i),

    // AXI instruction interface (tied off)
    .axi_i_awready_i(0),
    .axi_i_wready_i(0),
    .axi_i_bvalid_i(0),
    .axi_i_bresp_i(2'b00),
    .axi_i_arready_i(0),
    .axi_i_rvalid_i(0),
    .axi_i_rdata_i(32'h0),
    .axi_i_rresp_i(2'b00),

    // AXI TCM interface (tied off)
    .axi_t_awvalid_i(0),
    .axi_t_awaddr_i(32'h0),
    .axi_t_awid_i(4'h0),
    .axi_t_awlen_i(8'h0),
    .axi_t_awburst_i(2'h0),
    .axi_t_wvalid_i(0),
    .axi_t_wdata_i(32'h0),
    .axi_t_wstrb_i(4'h0),
    .axi_t_wlast_i(0),
    .axi_t_bready_i(0),
    .axi_t_arvalid_i(0),
    .axi_t_araddr_i(32'h0),
    .axi_t_arid_i(4'h0),
    .axi_t_arlen_i(8'h0),
    .axi_t_arburst_i(2'h0),
    .axi_t_rready_i(0),

    .intr_i(32'h0)
  );

  // --------------------------------------------------------------------------
  // Telemetry PERF check logic (existing)
  // --------------------------------------------------------------------------
  int perf_read_count = 0;
  reg [31:0] expected_data;
  reg        pending_perf = 0;
  reg [31:0] last_addr;

  // --------------------------------------------------------------------------
  // TRACE MMIO check logic (new)
  // --------------------------------------------------------------------------
  int trace_read_count  = 0;
  int trace_write_count = 0;
  reg        pending_trace = 0;
  reg [31:0] last_trace_addr;
  reg [31:0] expected_trace_data;

  // Convenience localparams for address ranges
  localparam [31:0] PERF_BASE  = 32'h8000_0000;
  localparam [31:0] PERF_LAST  = 32'h8000_0014;

  localparam [31:0] TRACE_BASE = 32'h8000_0020;
  localparam [31:0] TRACE_LAST = 32'h8000_0030;

  // --------------------------------------------------------------------------
  // Monitor core data bus for MMIO accesses
  // --------------------------------------------------------------------------
  always @(posedge clk_i) begin
    if (!rst_i) begin

      // --------------------------
      // Detect MMIO READ requests
      // --------------------------
      if (uut.core_d_rd_w && (uut.core_d_wr_w == 4'b0000)) begin

        // PERF region
        if (uut.core_d_addr_w >= PERF_BASE && uut.core_d_addr_w <= PERF_LAST) begin
          pending_perf <= 1'b1;
          last_addr    <= uut.core_d_addr_w;

          case (uut.core_d_addr_w)
            32'h8000_0000: expected_data <= uut.tlm_mcycle_w[31:0];
            32'h8000_0004: expected_data <= uut.tlm_mcycle_w[63:32];
            32'h8000_0008: expected_data <= uut.tlm_minstret_w[31:0];
            32'h8000_000C: expected_data <= uut.tlm_minstret_w[63:32];
            32'h8000_0010: expected_data <= uut.tlm_stall_w[31:0];
            32'h8000_0014: expected_data <= uut.tlm_stall_w[63:32];
            default:       expected_data <= 32'hDEAD_BEEF;
          endcase
        end

        // TRACE region
        else if (uut.core_d_addr_w >= TRACE_BASE && uut.core_d_addr_w <= TRACE_LAST) begin
          pending_trace   <= 1'b1;
          last_trace_addr <= uut.core_d_addr_w;

          // NOTE: adjust these signal names to match your top-level!
          case (uut.core_d_addr_w)
            32'h8000_0020: expected_trace_data <= {31'b0, uut.trace_triggered_w};
            32'h8000_0024: expected_trace_data <= { {(32-$bits(uut.trace_wr_ptr_w)){1'b0}}, uut.trace_wr_ptr_w };
            32'h8000_0028: expected_trace_data <= uut.trace_rd_pc_w;
            32'h8000_002C: expected_trace_data <= uut.trace_rd_instr_w;
            32'h8000_0030: expected_trace_data <= { {(32-$bits(uut.trace_rd_addr_w)){1'b0}}, uut.trace_rd_addr_w };
            default:       expected_trace_data <= 32'hDEAD_BEEF;
          endcase
        end
      end

      // --------------------------
      // Detect MMIO WRITE requests
      // --------------------------
      if (uut.core_d_wr_w != 4'b0000) begin
        // We only care about writes to the trace index register 0x8000_0030
        if (uut.core_d_addr_w == 32'h8000_0030) begin
          trace_write_count <= trace_write_count + 1;

          // Optional: after write/ack, check that the internal index updated.
          // We can do the check in the ack block below.
        end
      end

      // --------------------------
      // Handle MMIO READ responses
      // --------------------------
      if (uut.core_d_ack_w) begin
        // PERF region check
        if (pending_perf) begin
          if (uut.core_d_data_rd_w !== expected_data) begin
            $error("Telemetry PERF MMIO read mismatch at %h: expected %h, got %h",
                   last_addr, expected_data, uut.core_d_data_rd_w);
          end else begin
            $display("PERF: Read from %h returned %h (OK)", last_addr, uut.core_d_data_rd_w);
          end

          pending_perf    <= 0;
          perf_read_count += 1;
        end

        // TRACE region check
        if (pending_trace) begin
          if (uut.core_d_data_rd_w !== expected_trace_data) begin
            $error("TRACE MMIO read mismatch at %h: expected %h, got %h",
                   last_trace_addr, expected_trace_data, uut.core_d_data_rd_w);
          end else begin
            $display("TRACE: Read from %h returned %h (OK)", last_trace_addr, uut.core_d_data_rd_w);
          end

          pending_trace   <= 0;
          trace_read_count += 1;
        end
      end

      // ----------------------------------------------------------------------
      // Simple end-of-test condition for this specific program.hex:
      //
      //  - We expect:
      //      * 1 write to 0x8000_0030 (trace index register)
      //      * 2 reads:
      //          - 0x8000_0028 (trace_rd_pc)
      //          - 0x8000_002C (trace_rd_instr)
      // ----------------------------------------------------------------------
      if (trace_write_count >= 1 && trace_read_count >= 2) begin
        $display("-----------------------------------------------------");
        $display("TRACE MMIO test completed:");
        $display("  trace_write_count = %0d", trace_write_count);
        $display("  trace_read_count  = %0d", trace_read_count);
        $display("Final trace signals (for index %0d):", uut.trace_rd_addr_w);
        $display("  trace_triggered = %0d", uut.trace_triggered_w);
        $display("  trace_wr_ptr    = %0d", uut.trace_wr_ptr_w);
        $display("  trace_rd_pc     = 0x%08h", uut.trace_rd_pc_w);
        $display("  trace_rd_instr  = 0x%08h", uut.trace_rd_instr_w);
        $display("TEST PASSED (TRACE MMIO)");
        $finish;
      end

    end // if !rst_i
  end // always @(posedge clk_i)

endmodule

