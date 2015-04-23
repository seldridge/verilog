//-----------------------------------------------------------------------------
// Title         : Testbench for sqrt_generic.v
// Project       : verilog
//-----------------------------------------------------------------------------
// File          : t_sqrt_generic.v
// Author        : Eldridge  <schuye@celnode06.ad.bu.edu>
// Created       : 2015/04/23
// Last modified : 2015/04/23
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (C) 2015 Schuyler Eldridge, Boston University
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//------------------------------------------------------------------------------
// Modification history :
// 2015/04/23 : created
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
`include "sqrt_generic.v"
module t_sqrt_generic();
  localparam
    WIDTH_INPUT = 16,
    WIDTH_OUTPUT = WIDTH_INPUT / 2 + WIDTH_INPUT % 2;

  logic clk, rst_n, valid_in, valid_out;
  logic [WIDTH_INPUT-1:0] radicand;
  logic [WIDTH_INPUT-1:0] radicand_d;
  logic [WIDTH_OUTPUT-1:0] root;

  sqrt_generic
    #(.WIDTH_INPUT(WIDTH_INPUT),
      .WIDTH_OUTPUT(WIDTH_OUTPUT))
  u_sqrt_generic
    (.clk(clk),
     .rst_n(rst_n),
     .valid_in(valid_in),
     .radicand(radicand),
     .valid_out(valid_out),
     .root(root));

  pipeline_registers
    #(.BIT_WIDTH(WIDTH_INPUT),
      .NUMBER_OF_STAGES(WIDTH_OUTPUT))
  u_pipe_radicand
    (.clk(clk),
     .reset_n(rst_n),
     .pipe_in(radicand),
     .pipe_out(radicand_d));


  always
    #1 clk = ~clk;

  initial begin
    clk = 0; rst_n = 0;
    #5 rst_n = 1;
  end

  always_ff @(posedge clk) begin
    radicand <= radicand + 1;
    valid_in <= 1;
    if (valid_out) begin
      $display("%4d %4d", radicand_d, root);
      if (radicand_d >= 484 && radicand_d <=528)
        assert(root == 22)
          else $error("Bad square root value for %d (found root of %d)",
                      radicand_d, root);
    end

    if (radicand_d >= 530)
      $stop;

    // Reset case
    if (!rst_n) begin
      radicand <= '0;
      valid_in <= 0;
    end
  end

endmodule
