// Copyright 2018 Schuyler Eldridge
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`timescale 1ns/1ps
`include "sqrt_generic.v"
module t_sqrt_generic();
  localparam
    WIDTH_INPUT = 16,
    WIDTH_OUTPUT = WIDTH_INPUT / 2 + WIDTH_INPUT % 2;

  reg clk, rst_n, valid_in;
  wire valid_out;
  reg [WIDTH_INPUT-1:0] radicand;
  wire [WIDTH_INPUT-1:0] radicand_d;
  wire [WIDTH_OUTPUT-1:0] root;

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

  always @(posedge clk) begin
    radicand <= radicand + 1;
    valid_in <= 1;
    if (valid_out) begin
      if ($itor(root) - $floor($itor(radicand_d)) > 0)
        $error("Bad square root value:\n  sqrt(%0d) = %0d (correct: %0.0f)",
                 radicand_d, root, $floor($itor(radicand_d)));
      // $display("%8d %8d", root, radicand_d);
    end

    if (radicand_d >= (1 << WIDTH_INPUT) - 1) begin
      $stop;
    end

    // Reset case
    if (!rst_n) begin
      radicand <= '0;
      valid_in <= 0;
    end
  end

endmodule
