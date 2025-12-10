//-----------------------------------------------------------------chal pls yar
// 32KB Single-Port TCM using 32 x 1KB TSMC SRAM macros
//   - Logical size: 8k x 32-bit = 32KB
//   - Built from TS1N16ADFPCLLLVTA128X64M4SWSHOD (128 x 64-bit)
//   - SIM_TCM_BEHAV: simple behavioral RAM + $readmemh
//-----------------------------------------------------------------
module tcm_sram32k_sp
(
    input         clk_i,        // Clock
    input  [12:0] addr_i,       // Word address (8k x 32)
    input  [31:0] wdata_i,      // Write data
    input  [3:0]  wstrb_i,      // Byte write strobes (active high)
    input         we_i,         // Write enable (any byte)
    output reg [31:0] rdata_o   // Read data (1-cycle latency)
);

`ifdef SIM_TCM_BEHAV
    //-------------------------------------------------------------
    // Simple behavioral model for simulation
    //   - 8k x 32-bit = 32KB
    //   - Preloaded from program.hex
    //-------------------------------------------------------------
    localparam integer DEPTH_WORDS = 8192; // 32KB / 4

    reg [31:0] mem [0:DEPTH_WORDS-1];
    integer j;

    initial begin
        $display("tcm_sram32k_sp (SIM): Preloading ITCM from program.hex");

        // Optional: init to RISC-V NOP = 0x00000013
        for (j = 0; j < DEPTH_WORDS; j = j + 1)
            mem[j] = 32'h00000013;

        // Load program
        $readmemh("program.hex", mem);

        // Quick sanity check
        if (^mem[0] === 1'bX)
            $display("tcm_sram32k_sp (SIM) WARNING: mem[0] is X after readmemh - check program.hex path/format");
        else
            $display("tcm_sram32k_sp (SIM): mem[0]=0x%08x mem[1]=0x%08x", mem[0], mem[1]);
    end

    // 1-cycle read, byte-write enable
    always @(posedge clk_i) begin
        // Read
        rdata_o <= mem[addr_i];

        // Write
        if (we_i) begin
            if (wstrb_i[0]) mem[addr_i][7:0]   <= wdata_i[7:0];
            if (wstrb_i[1]) mem[addr_i][15:8]  <= wdata_i[15:8];
            if (wstrb_i[2]) mem[addr_i][23:16] <= wdata_i[23:16];
            if (wstrb_i[3]) mem[addr_i][31:24] <= wdata_i[31:24];
        end
    end

`else
    //-------------------------------------------------------------
    // ORIGINAL: 32 banks x 1KB = 32KB implemented with TSMC SRAM
    //-------------------------------------------------------------
    localparam NUM_BANKS = 32;

    //-------------------------------------------------------------
    // Address decode: bank, row, word-half
    //-------------------------------------------------------------
    wire [4:0] bank_sel = addr_i[12:8];   // 0..31
    wire [7:0] word_idx = addr_i[7:0];    // 0..255

    wire [6:0] row_addr = word_idx[7:1];  // 0..127 (macro row)
    wire       word_sel = word_idx[0];    // 0 = lower 32 bits, 1 = upper 32 bits

    //-------------------------------------------------------------
    // Macro port signals for each bank
    //-------------------------------------------------------------
    // Active-low chip enable / write enable per bank
    reg  [NUM_BANKS-1:0] ceb_n_q;
    reg  [NUM_BANKS-1:0] web_n_q;

    // Data and write mask buses (per bank)
    reg  [63:0] D_bus    [0:NUM_BANKS-1];
    reg  [63:0] BWEB_bus [0:NUM_BANKS-1];
    wire [63:0] Q_bus    [0:NUM_BANKS-1];

    integer i;

    //-------------------------------------------------------------
    // Control + write-data generation
    //-------------------------------------------------------------
    always @* begin
        // Defaults: all banks disabled, no writes
        for (i = 0; i < NUM_BANKS; i = i + 1) begin
            ceb_n_q[i]  = 1'b1;          // disabled
            web_n_q[i]  = 1'b1;          // read
            D_bus[i]    = 64'd0;
            BWEB_bus[i] = {64{1'b1}};    // no bit written (active low)
        end

        // Selected bank
        ceb_n_q[bank_sel] = 1'b0;          // enable selected bank

        // READ by default (WEB=1)
        web_n_q[bank_sel] = 1'b1;

        if (we_i) begin
            // WRITE on selected bank
            web_n_q[bank_sel] = 1'b0;

            if (word_sel == 1'b0) begin
                // lower 32 bits of 64-bit word
                D_bus[bank_sel][31:0] = wdata_i;

                // Map 4 byte strobes to 8 bits each in BWEB (active low)
                BWEB_bus[bank_sel][7:0]    = wstrb_i[0] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][15:8]   = wstrb_i[1] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][23:16]  = wstrb_i[2] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][31:24]  = wstrb_i[3] ? 8'h00 : 8'hFF;

                // Upper 32 bits unchanged
            end
            else begin
                // upper 32 bits of 64-bit word
                D_bus[bank_sel][63:32] = wdata_i;

                // Map to upper half of BWEB
                BWEB_bus[bank_sel][39:32] = wstrb_i[0] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][47:40] = wstrb_i[1] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][55:48] = wstrb_i[2] ? 8'h00 : 8'hFF;
                BWEB_bus[bank_sel][63:56] = wstrb_i[3] ? 8'h00 : 8'hFF;
            end
        end
    end

    //-------------------------------------------------------------
    // Instantiate 32 x TSMC 1KB SRAM macros
    //-------------------------------------------------------------
    genvar g;
    generate
        for (g = 0; g < NUM_BANKS; g = g + 1) begin : g_sram
            TS1N16ADFPCLLLVTA128X64M4SWSHOD u_sram (
                // Low-power / test pins
                .SLP    (1'b0),
                .DSLP   (1'b0),
                .SD     (1'b0),
                .PUDELAY(),

                // Main port
                .CLK    (clk_i),
                .CEB    (ceb_n_q[g]), // 0 = enable
                .WEB    (web_n_q[g]), // 0 = write, 1 = read
                .A      (row_addr),   // [6:0]
                .D      (D_bus[g]),   // [63:0]
                .BWEB   (BWEB_bus[g]),// [63:0] active low

                // Test mode selects – use normal segment/mux config
                .RTSEL  (2'b01),
                .WTSEL  (2'b01),

                .Q      (Q_bus[g])    // [63:0]
            );
        end
    endgenerate

    //-------------------------------------------------------------
    // Read data mux + 1-cycle latency
    //-------------------------------------------------------------
    wire [63:0] rdata_64 = Q_bus[bank_sel];
    wire [31:0] rdata_32 = word_sel ? rdata_64[63:32] : rdata_64[31:0];

    always @(posedge clk_i) begin
        rdata_o <= rdata_32;
    end

`endif // SIM_TCM_BEHAV

endmodule