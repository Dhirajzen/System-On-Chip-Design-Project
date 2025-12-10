//-----------------------------------------------------------------
//                         RISC-V Core
//                            V1.0.1
//                     Ultra-Embedded.com
//                     Copyright 2014-2019
//
//                   admin@ultra-embedded.com
//
//                       License: BSD
//-----------------------------------------------------------------
//
// Copyright (c) 2014-2019, Ultra-Embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------

module riscv_multiplier
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_ra_idx_i
    ,input  [  4:0]  opcode_rb_idx_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input           hold_i

    // Outputs
    ,output [ 31:0]  writeback_value_o
    ,output          busy_o          // NEW: multiplier busy flag
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "riscv_defs.v"

// 2 or 3 pipeline stages for the multiplier core
localparam MULT_STAGES      = 2;
localparam MUL_PIPE_STAGES  = (MULT_STAGES == 3) ? 3 : 2;

//-------------------------------------------------------------
// Registers / Wires
//-------------------------------------------------------------
reg  [31:0]  result_e2_q;
reg  [31:0]  result_e3_q;

reg [32:0]   operand_a_e1_q;
reg [32:0]   operand_b_e1_q;
reg          mulhi_sel_e1_q;

// Valid bits for multiplier pipeline stages
reg [MUL_PIPE_STAGES-1:0] mul_valid_q;

//-------------------------------------------------------------
// Multiplier instruction detect
//-------------------------------------------------------------
wire mult_inst_w = ((opcode_opcode_i & `INST_MUL_MASK)    == `INST_MUL)    || 
                   ((opcode_opcode_i & `INST_MULH_MASK)   == `INST_MULH)   ||
                   ((opcode_opcode_i & `INST_MULHSU_MASK) == `INST_MULHSU) ||
                   ((opcode_opcode_i & `INST_MULHU_MASK)  == `INST_MULHU);

wire mul_new_valid_w = opcode_valid_i && mult_inst_w && !hold_i;

//-------------------------------------------------------------
// Operand selection
//-------------------------------------------------------------
reg [32:0] operand_a_r;
reg [32:0] operand_b_r;

// Operand A select
always @*
begin
    if ((opcode_opcode_i & `INST_MULHSU_MASK) == `INST_MULHSU)
        operand_a_r = {opcode_ra_operand_i[31], opcode_ra_operand_i[31:0]}; // signed
    else if ((opcode_opcode_i & `INST_MULH_MASK) == `INST_MULH)
        operand_a_r = {opcode_ra_operand_i[31], opcode_ra_operand_i[31:0]}; // signed
    else
        operand_a_r = {1'b0, opcode_ra_operand_i[31:0]};                     // unsigned
end

// Operand B select
always @*
begin
    if ((opcode_opcode_i & `INST_MULHSU_MASK) == `INST_MULHSU)
        operand_b_r = {1'b0, opcode_rb_operand_i[31:0]};                     // unsigned
    else if ((opcode_opcode_i & `INST_MULH_MASK) == `INST_MULH)
        operand_b_r = {opcode_rb_operand_i[31], opcode_rb_operand_i[31:0]};  // signed
    else
        operand_b_r = {1'b0, opcode_rb_operand_i[31:0]};                     // unsigned
end

//-------------------------------------------------------------
// Pipeline stage E1: register operands + hi/lo select
//-------------------------------------------------------------
always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end
else if (hold_i)
begin
    // hold pipeline
end
else if (opcode_valid_i && mult_inst_w)
begin
    operand_a_e1_q <= operand_a_r;
    operand_b_e1_q <= operand_b_r;
    // mulhi when instruction is not plain MUL (i.e. MULH, MULHSU, MULHU)
    mulhi_sel_e1_q <= ~((opcode_opcode_i & `INST_MUL_MASK) == `INST_MUL);
end
else
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end

//-------------------------------------------------------------
// Combinational multiply
//-------------------------------------------------------------
wire [64:0] mult_result_w;

assign mult_result_w = {{32{operand_a_e1_q[32]}}, operand_a_e1_q} *
                       {{32{operand_b_e1_q[32]}}, operand_b_e1_q};

reg [31:0] result_r;

always @*
begin
    // Select upper or lower 32-bits
    result_r = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];
end

//-------------------------------------------------------------
// Stage 2
//-------------------------------------------------------------
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e2_q <= 32'b0;
else if (!hold_i)
    result_e2_q <= result_r;

//-------------------------------------------------------------
// Stage 3 (optional, depending on MULT_STAGES)
//-------------------------------------------------------------
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e3_q <= 32'b0;
else if (!hold_i)
    result_e3_q <= result_e2_q;

//-------------------------------------------------------------
// Busy tracking
//-------------------------------------------------------------
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    mul_valid_q <= {MUL_PIPE_STAGES{1'b0}};
else if (hold_i)
    mul_valid_q <= mul_valid_q;   // stall pipeline
else
    mul_valid_q <= {mul_valid_q[MUL_PIPE_STAGES-2:0], mul_new_valid_w};

assign busy_o = |mul_valid_q;

//-------------------------------------------------------------
// Writeback mux
//-------------------------------------------------------------
assign writeback_value_o = (MULT_STAGES == 3) ? result_e3_q : result_e2_q;

endmodule
