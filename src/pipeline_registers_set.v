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

// Extension of original pipeline_registers.v that allows for a
// synchronous set of all the internal registers.

`timescale 1ns / 1ps
module pipeline_registers_set
  #(
    parameter
    BIT_WIDTH         = 10,
    NUMBER_OF_STAGES  = 5
    )
  (
   input                                  clk,
   input                                  reset_n,
   input                                  set,
   input [BIT_WIDTH*NUMBER_OF_STAGES-1:0] set_data,
   input [BIT_WIDTH-1:0]                  pipe_in,
   output reg [BIT_WIDTH-1:0]             pipe_out
   );

  // Main generate function for conditional hardware instantiation
  generate
    genvar                                 i;
    // Pass-through case for the odd event that no pipeline stages are
    // specified.
    if (NUMBER_OF_STAGES == 0) begin
      always @ *
        pipe_out = pipe_in;
    end
    // Single flop case for a single stage pipeline
    else if (NUMBER_OF_STAGES == 1) begin
      always @ (posedge clk or negedge reset_n)
        pipe_out <= (!reset_n) ? 0 : (set) ? set_data : pipe_in;
    end
    // Case for 2 or more pipeline stages
    else begin
      // Create the necessary regs
      reg [BIT_WIDTH*(NUMBER_OF_STAGES-1)-1:0] pipe_gen;
      // Create logic for the initial and final pipeline registers
      always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
          pipe_gen[BIT_WIDTH-1:0] <= 0;
          pipe_out                <= 0;
        end
        else if (set) begin
          pipe_gen[BIT_WIDTH-1:0] <= set_data[BIT_WIDTH-1:0];
          pipe_out                <= set_data[BIT_WIDTH*NUMBER_OF_STAGES-1:BIT_WIDTH*(NUMBER_OF_STAGES-1)];
        end
        else begin
          pipe_gen[BIT_WIDTH-1:0] <= pipe_in;
          pipe_out                <= pipe_gen[BIT_WIDTH*(NUMBER_OF_STAGES-1)-1:BIT_WIDTH*(NUMBER_OF_STAGES-2)];
        end
      end
      // Create the intermediate pipeline registers if there are 3 or
      // more pipeline stages
      for (i = 1; i < NUMBER_OF_STAGES-1; i = i + 1) begin : pipeline
        always @ (posedge clk or negedge reset_n)
          pipe_gen[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i] <= (!reset_n) ? 0 : (set) ? set_data[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i] : pipe_gen[BIT_WIDTH*i-1:BIT_WIDTH*(i-1)];
      end
    end
  endgenerate

endmodule
