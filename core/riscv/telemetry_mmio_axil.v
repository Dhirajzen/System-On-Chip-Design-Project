// rtl/telemetry/telemetry_mmio_axil.v
module telemetry_mmio_axil #(
  parameter BASE_ADDR = 32'h8000_1000
)(
  input  wire         clk,
  input  wire         rstn,

  input  wire [63:0]  mcycle_i,
  input  wire [63:0]  minstret_i,
  input  wire [63:0]  stall_i,

  // AXI4-Lite slave (names kept short; map in top)
  input  wire [31:0]  s_awaddr,
  input  wire         s_awvalid,
  output wire         s_awready,

  input  wire [31:0]  s_wdata,
  input  wire [3:0]   s_wstrb,
  input  wire         s_wvalid,
  output wire         s_wready,

  output wire [1:0]   s_bresp,
  output wire         s_bvalid,
  input  wire         s_bready,

  input  wire [31:0]  s_araddr,
  input  wire         s_arvalid,
  output wire         s_arready,

  output reg  [31:0]  s_rdata,
  output wire [1:0]   s_rresp,
  output reg          s_rvalid,
  input  wire         s_rready
);

  assign s_awready = 1'b1;
  assign s_wready  = 1'b1;
  assign s_bresp   = 2'b00; // OKAY
  assign s_bvalid  = s_awvalid & s_wvalid; // writes ignored (RO)

  assign s_arready = 1'b1;
  assign s_rresp   = 2'b00; // OKAY

  // Map:
  // +0x00 mcycle[31:0]
  // +0x04 mcycle[63:32]
  // +0x08 minstret[31:0]
  // +0x0C minstret[63:32]
  // +0x10 stall[31:0]
  // +0x14 stall[63:32]
  wire [31:0] off = s_araddr - BASE_ADDR;
  always @* begin
    case (off[5:0]) // 64B window
      6'h00: s_rdata = mcycle_i[31:0];
      6'h04: s_rdata = mcycle_i[63:32];
      6'h08: s_rdata = minstret_i[31:0];
      6'h0C: s_rdata = minstret_i[63:32];
      6'h10: s_rdata = stall_i[31:0];
      6'h14: s_rdata = stall_i[63:32];
      default: s_rdata = 32'h0;
    endcase
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) s_rvalid <= 1'b0;
    else begin
      if (s_arvalid && !s_rvalid) s_rvalid <= 1'b1;
      else if (s_rvalid && s_rready) s_rvalid <= 1'b0;
    end
  end

endmodule
