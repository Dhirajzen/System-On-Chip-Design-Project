`timescale 1ns/1ps

module tb_mmio;

    // ----------------------------------------------------------------
    // Parameters new with golden
    // ----------------------------------------------------------------
    localparam int TRACE_DEPTH    = 64;
    localparam int TRACE_PTR_BITS = 6;

    // ----------------------------------------------------------------
    // Clock & Reset
    // ----------------------------------------------------------------
    reg clk;
    reg rst_i;
    reg rst_cpu_i;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // ----------------------------------------------------------------
    // AXI (external memory side) – currently unused, tie off
    // ----------------------------------------------------------------
    reg           axi_i_awready_i;
    reg           axi_i_wready_i;
    reg           axi_i_bvalid_i;
    reg  [1:0]    axi_i_bresp_i;
    reg           axi_i_arready_i;
    reg           axi_i_rvalid_i;
    reg  [31:0]   axi_i_rdata_i;
    reg  [1:0]    axi_i_rresp_i;

    wire          axi_i_awvalid_o;
    wire [31:0]   axi_i_awaddr_o;
    wire          axi_i_wvalid_o;
    wire [31:0]   axi_i_wdata_o;
    wire [3:0]    axi_i_wstrb_o;
    wire          axi_i_bready_o;
    wire          axi_i_arvalid_o;
    wire [31:0]   axi_i_araddr_o;
    wire          axi_i_rready_o;

    // ----------------------------------------------------------------
    // AXI (TCM programming side) – currently idle
    // ----------------------------------------------------------------
    reg           axi_t_awvalid_i;
    reg  [31:0]   axi_t_awaddr_i;
    reg  [3:0]    axi_t_awid_i;
    reg  [7:0]    axi_t_awlen_i;
    reg  [1:0]    axi_t_awburst_i;
    reg           axi_t_wvalid_i;
    reg  [31:0]   axi_t_wdata_i;
    reg  [3:0]    axi_t_wstrb_i;
    reg           axi_t_wlast_i;
    reg           axi_t_bready_i;
    reg           axi_t_arvalid_i;
    reg  [31:0]   axi_t_araddr_i;
    reg  [3:0]    axi_t_arid_i;
    reg  [7:0]    axi_t_arlen_i;
    reg  [1:0]    axi_t_arburst_i;
    reg           axi_t_rready_i;

    wire          axi_t_awready_o;
    wire          axi_t_wready_o;
    wire          axi_t_bvalid_o;
    wire [1:0]    axi_t_bresp_o;
    wire [3:0]    axi_t_bid_o;
    wire          axi_t_arready_o;
    wire          axi_t_rvalid_o;
    wire [31:0]   axi_t_rdata_o;
    wire [1:0]    axi_t_rresp_o;
    wire [3:0]    axi_t_rid_o;
    wire          axi_t_rlast_o;

    // ----------------------------------------------------------------
    // Interrupts
    // ----------------------------------------------------------------
    reg  [31:0]   intr_i;

    // ----------------------------------------------------------------
    // DUT: riscv_tcm_top
    // ----------------------------------------------------------------
    riscv_tcm_top #(
        .BOOT_VECTOR        (32'h0000_0000),
        .CORE_ID            (0),
        .TCM_MEM_BASE       (32'h0000_0000),
        .MEM_CACHE_ADDR_MIN (32'h8000_0000),
        .MEM_CACHE_ADDR_MAX (32'h8fff_ffff)
    ) u_dut (
        .clk_i           (clk),
        .rst_i           (rst_i),
        .rst_cpu_i       (rst_cpu_i),

        .axi_i_awready_i (axi_i_awready_i),
        .axi_i_wready_i  (axi_i_wready_i),
        .axi_i_bvalid_i  (axi_i_bvalid_i),
        .axi_i_bresp_i   (axi_i_bresp_i),
        .axi_i_arready_i (axi_i_arready_i),
        .axi_i_rvalid_i  (axi_i_rvalid_i),
        .axi_i_rdata_i   (axi_i_rdata_i),
        .axi_i_rresp_i   (axi_i_rresp_i),

        .axi_i_awvalid_o (axi_i_awvalid_o),
        .axi_i_awaddr_o  (axi_i_awaddr_o),
        .axi_i_wvalid_o  (axi_i_wvalid_o),
        .axi_i_wdata_o   (axi_i_wdata_o),
        .axi_i_wstrb_o   (axi_i_wstrb_o),
        .axi_i_bready_o  (axi_i_bready_o),
        .axi_i_arvalid_o (axi_i_arvalid_o),
        .axi_i_araddr_o  (axi_i_araddr_o),
        .axi_i_rready_o  (axi_i_rready_o),

        .axi_t_awvalid_i (axi_t_awvalid_i),
        .axi_t_awaddr_i  (axi_t_awaddr_i),
        .axi_t_awid_i    (axi_t_awid_i),
        .axi_t_awlen_i   (axi_t_awlen_i),
        .axi_t_awburst_i (axi_t_awburst_i),
        .axi_t_wvalid_i  (axi_t_wvalid_i),
        .axi_t_wdata_i   (axi_t_wdata_i),
        .axi_t_wstrb_i   (axi_t_wstrb_i),
        .axi_t_wlast_i   (axi_t_wlast_i),
        .axi_t_bready_i  (axi_t_bready_i),
        .axi_t_arvalid_i (axi_t_arvalid_i),
        .axi_t_araddr_i  (axi_t_araddr_i),
        .axi_t_arid_i    (axi_t_arid_i),
        .axi_t_arlen_i   (axi_t_arlen_i),
        .axi_t_arburst_i (axi_t_arburst_i),
        .axi_t_rready_i  (axi_t_rready_i),

        .axi_t_awready_o (axi_t_awready_o),
        .axi_t_wready_o  (axi_t_wready_o),
        .axi_t_bvalid_o  (axi_t_bvalid_o),
        .axi_t_bresp_o   (axi_t_bresp_o),
        .axi_t_bid_o     (axi_t_bid_o),
        .axi_t_arready_o (axi_t_arready_o),
        .axi_t_rvalid_o  (axi_t_rvalid_o),
        .axi_t_rdata_o   (axi_t_rdata_o),
        .axi_t_rresp_o   (axi_t_rresp_o),
        .axi_t_rid_o     (axi_t_rid_o),
        .axi_t_rlast_o   (axi_t_rlast_o),

        .intr_i          (intr_i)
    );

    // ----------------------------------------------------------------
    // Default AXI behaviour: always-ready, no external memory
    // ----------------------------------------------------------------
    initial begin
        // External AXI side
        axi_i_awready_i = 1'b1;
        axi_i_wready_i  = 1'b1;
        axi_i_bvalid_i  = 1'b0;
        axi_i_bresp_i   = 2'b00;
        axi_i_arready_i = 1'b1;
        axi_i_rvalid_i  = 1'b0;
        axi_i_rdata_i   = 32'h0000_0000;
        axi_i_rresp_i   = 2'b00;

        // TCM AXI interface (not used in this test)
        axi_t_awvalid_i = 1'b0;
        axi_t_awaddr_i  = 32'd0;
        axi_t_awid_i    = 4'd0;
        axi_t_awlen_i   = 8'd0;
        axi_t_awburst_i = 2'b01;
        axi_t_wvalid_i  = 1'b0;
        axi_t_wdata_i   = 32'd0;
        axi_t_wstrb_i   = 4'd0;
        axi_t_wlast_i   = 1'b0;
        axi_t_bready_i  = 1'b1;
        axi_t_arvalid_i = 1'b0;
        axi_t_araddr_i  = 32'd0;
        axi_t_arid_i    = 4'd0;
        axi_t_arlen_i   = 8'd0;
        axi_t_arburst_i = 2'b01;
        axi_t_rready_i  = 1'b1;
    end

    // ----------------------------------------------------------------
    // Reset + run
    // ----------------------------------------------------------------
    initial begin
        rst_i     = 1'b1;
        rst_cpu_i = 1'b1;
        intr_i    = 32'd0;

        // Hold reset for a few cycles
        repeat (10) @(posedge clk);
        rst_i     = 1'b0;
        rst_cpu_i = 1'b0;
        $display("[%0t] Reset deasserted", $time);

        // Let the core run for some cycles (stress)
        repeat (20) @(posedge clk);

        dump_telemetry_and_trace();
        $finish;
    end

    // ----------------------------------------------------------------
    // Telemetry taps (from riscv_tcm_top)
    // ----------------------------------------------------------------
    wire [63:0] tlm_mcycle   = u_dut.tlm_mcycle_w;
    wire [63:0] tlm_minstret = u_dut.tlm_minstret_w;
    wire [63:0] tlm_stall    = u_dut.tlm_stall_w;

    // ----------------------------------------------------------------
    // Trace taps (from riscv_tcm_top)
    // ----------------------------------------------------------------
    wire        trace_triggered = u_dut.trace_triggered_w;
    wire [5:0]  trace_wr_ptr    = u_dut.trace_wr_ptr_w;
    wire [31:0] trace_rd_pc     = u_dut.trace_rd_pc_w;
    wire [31:0] trace_rd_instr  = u_dut.trace_rd_instr_w;

    // TB-controlled read address for the trace buffer
    reg  [TRACE_PTR_BITS-1:0] tb_trace_rd_addr;

    // Override the DUT's internal trace read address with ours
    initial begin
        force u_dut.trace_rd_addr_w = tb_trace_rd_addr;
    end

    // ----------------------------------------------------------------
    // Fetch-stage taps for golden logging (inside core)
    // ----------------------------------------------------------------
    wire        fetch_valid = u_dut.u_core.retire_pulse_w;
    wire [31:0] fetch_pc    = u_dut.u_core.fetch_pc_w;
    wire [31:0] fetch_instr = u_dut.u_core.fetch_instr_w;

    // ----------------------------------------------------------------
    // Golden reference arrays for trace buffer checking
    // ----------------------------------------------------------------
    reg [31:0] golden_pc    [0:TRACE_DEPTH-1];
    reg [31:0] golden_instr [0:TRACE_DEPTH-1];
    integer    golden_cnt;

    initial begin
        golden_cnt = 0;
    end

    // Record the first TRACE_DEPTH valid fetches
    always @(posedge clk) begin
        if (!rst_i && fetch_valid && golden_cnt < TRACE_DEPTH) begin
            golden_pc[golden_cnt]    <= fetch_pc;
            golden_instr[golden_cnt] <= fetch_instr;
            golden_cnt               <= golden_cnt + 1;
        end
    end

    // ----------------------------------------------------------------
    // Dump task: telemetry + full 64-entry trace + compare to golden
    // ----------------------------------------------------------------
    task dump_telemetry_and_trace;
        integer i;
        begin
            $display("============== Telemetry ==============");
            $display("MCYCLE   = %0d (0x%016h)", tlm_mcycle,   tlm_mcycle);
            $display("MINSTRET = %0d (0x%016h)", tlm_minstret, tlm_minstret);
            $display("STALL    = %0d (0x%016h)", tlm_stall,    tlm_stall);

            $display("============== Trace (full dump) ======");
            $display("triggered = %0d, wr_ptr = %0d, golden_cnt = %0d",
                     trace_triggered, trace_wr_ptr, golden_cnt);

            for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
                tb_trace_rd_addr = i[TRACE_PTR_BITS-1:0];
                @(posedge clk);

                $display("TRACE[%02d]: PC=0x%08x INSTR=0x%08x  | GOLDEN: PC=0x%08x INSTR=0x%08x",
                         i, trace_rd_pc, trace_rd_instr,
                         golden_pc[i], golden_instr[i]);

                if (trace_rd_pc   !== golden_pc[i] ||
                    trace_rd_instr !== golden_instr[i]) begin
                    $display("** MISMATCH at index %0d! **", i);
                end
            end

            $display("=======================================");
        end
    endtask

endmodule
