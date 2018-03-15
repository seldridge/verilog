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
`include "pipeline_registers.v"
module sqrt_generic
  #(parameter
    WIDTH_INPUT = 16,
    WIDTH_OUTPUT = WIDTH_INPUT / 2 + WIDTH_INPUT % 2,
    FLAG_PIPELINE = 1 // Currently unused
    )
  (
   input                      clk,       // clock
   input                      rst_n,     // asynchronous reset
   input                      valid_in,  // optional start signal
   input [WIDTH_INPUT-1:0]    radicand,  // unsigned radicand
   output                     valid_out, // optional data valid signal
   output  [WIDTH_OUTPUT-1:0] root       // unsigned root
   );

  // Pass-though pipe that sends the input valid signal to the
  // output valid signal
  pipeline_registers
    #(.BIT_WIDTH(1),
      .NUMBER_OF_STAGES(WIDTH_OUTPUT))
  pipe_valid
    (.clk(clk),
     .reset_n(rst_n),
     .pipe_in(valid_in),
     .pipe_out(valid_out)
     );

  reg [WIDTH_INPUT-1:0] root_gen [WIDTH_OUTPUT-1:0];
  reg [WIDTH_INPUT-1:0] radicand_gen [WIDTH_OUTPUT-1:0];
  wire [WIDTH_INPUT-1:0] mask_gen [WIDTH_OUTPUT-1:0];

  generate
    genvar i;
    // Generate all the masks
    for (i = 0; i < WIDTH_OUTPUT; i = i + 1) begin: mask
      if (i % 2)
        assign mask_gen[WIDTH_OUTPUT-i-1] = 4 << 4 * (i/2);
      else
        assign mask_gen[WIDTH_OUTPUT-i-1] = 1 << 4 * (i/2);
    end

    // Handle the operations of each pipeline stage
    for (i = 0; i < WIDTH_OUTPUT; i = i + 1) begin: pipe_sqrt
      always @ (posedge clk or negedge rst_n) begin: pipe_stage
        // Reset condition
        if (!rst_n) begin
          radicand_gen[i] <= 0;
          root_gen[i] <= 0;
        end
        else begin
          // Logic for any stage which is not the first stage
          if (i > 0) begin
            if (root_gen[i-1] + mask_gen[i] <= radicand_gen[i-1]) begin
              radicand_gen[i] <= radicand_gen[i-1] - mask_gen[i] - root_gen[i-1];
              root_gen[i] <= (root_gen[i-1] >> 1) + mask_gen[i];
            end
            else begin
              radicand_gen[i] <= radicand_gen[i-1];
              root_gen[i] <= root_gen[i-1] >> 1;
            end
          end

          // Logic specific to the first stage
          if (i == 0) begin
            if (mask_gen[i] <= radicand) begin
              radicand_gen[i] <= radicand - mask_gen[i];
              root_gen[i] <= mask_gen[i];
            end
            else begin
              radicand_gen[i] <= radicand;
              root_gen[i] <= 0;
            end
          end
        end
      end
    end
  endgenerate

  assign root = root_gen[WIDTH_OUTPUT-1];

endmodule
