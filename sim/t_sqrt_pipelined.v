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

`timescale 1ns / 1ps
module t_sqrt_pipelined();

  parameter
    INPUT_BITS  = 4;
  localparam
    OUTPUT_BITS  = INPUT_BITS / 2 + INPUT_BITS % 2;

  reg [INPUT_BITS-1:0] radicand;
  reg                  clk, start, reset_n;

  wire [OUTPUT_BITS-1:0] root;
  wire                   data_valid;
//  wire [7:0] root_good;

  sqrt_pipelined
    #(
      .INPUT_BITS(INPUT_BITS)
      )
    sqrt_pipelined
      (
       .clk(clk),
       .reset_n(reset_n),
       .start(start),
       .radicand(radicand),
       .data_valid(data_valid),
       .root(root)
       );

  initial begin
    radicand     = 16'bx; clk = 1'bx; start = 1'bx; reset_n = 1'bx;;
    #10 reset_n  = 0; clk = 0;
    #50 reset_n  = 1; radicand = 0;
//    #40 radicand  = 81; start = 1;
//    #10 radicand  = 16'bx; start = 0;
    #10000 $finish;
  end

  always
    #5 clk = ~clk;

  always begin
    #10 radicand  = radicand + 1; start = 1;
    #10 start     = 0;
  end


//  always begin
//    #80 start  = 1;
//    #10 start  = 0;
//  end

endmodule
