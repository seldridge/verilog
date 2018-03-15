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
`include "pipeline_registers_set.v"
module t_pipeline_registers_set();
`define PERIOD_TARGET 3
`define SLACK 0
`define PERIOD (`PERIOD_TARGET-(`SLACK))
`define HALF_PERIOD (`PERIOD/2)
`define CQ_DELAY 0.100
`include "verilog_math.vh"

  localparam
    BIT_WIDTH         = 8,
    NUMBER_OF_STAGES  = 4;

  reg clk, reset_n, set;
  reg [BIT_WIDTH-1:0] pipe_in;
  reg [BIT_WIDTH-1:0] set_data_unpacked [NUMBER_OF_STAGES-1:0];
  wire [BIT_WIDTH*NUMBER_OF_STAGES-1:0] set_data;
  wire [BIT_WIDTH-1:0]                  pipe_out;

  `PACK(set_data_unpacked, set_data, BIT_WIDTH, NUMBER_OF_STAGES)

  pipeline_registers_set
    #(
      .BIT_WIDTH(BIT_WIDTH),
      .NUMBER_OF_STAGES(NUMBER_OF_STAGES)
      )
  u_pipeline_registers_set
    (
     .clk(clk),
     .reset_n(reset_n),
     .set(set),
     .set_data(set_data),
     .pipe_in(pipe_out),
     .pipe_out(pipe_out)
     );

  always
    #`HALF_PERIOD clk = ~clk;

  initial begin
    $display("---------------------------------------- starting simulation");
    $display("Period is %0.3fns (%0.0fMHz)", `PERIOD, 1/(`PERIOD)*10**3);
    set_data_unpacked[0]  = 8'h01;
    set_data_unpacked[1]  = 8'h23;
    set_data_unpacked[2]  = 8'h45;
    set_data_unpacked[3]  = 8'h67;
    #5 clk                = 0; reset_n = 0;
    #10 reset_n           = 1;
    #10 set               = 1;
    #10 set               = 0;
  end



endmodule
