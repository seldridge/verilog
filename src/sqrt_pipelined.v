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

// Implements a fixed-point parameterized pipelined square root
// operation on an unsigned input of any bit length. The number of
// stages in the pipeline is equal to the number of output bits in the
// computation. This pipelien sustains a throughput of one computation
// per clock cycle.

`timescale 1ns / 1ps
module sqrt_pipelined
  #(
    parameter
    INPUT_BITS   = 16, // number of input bits (any integer)
    OUTPUT_BITS  = INPUT_BITS / 2 + INPUT_BITS % 2 // number of output bits
    )
  (
   input                        clk,        // clock
   input                        reset_n,    // asynchronous reset
   input                        start,      // optional start signal
   input [INPUT_BITS-1:0]       radicand,   // unsigned radicand
   output reg                   data_valid, // optional data valid signal
   output reg [OUTPUT_BITS-1:0] root        // unsigned root
   );

  reg [OUTPUT_BITS-1:0]         start_gen; // valid data propagation
  reg [OUTPUT_BITS*INPUT_BITS-1:0] root_gen; // root values
  reg [OUTPUT_BITS*INPUT_BITS-1:0] radicand_gen; // radicand values
  wire [OUTPUT_BITS*INPUT_BITS-1:0] mask_gen; // mask values

  // This is the first stage of the pipeline.
  always @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      start_gen[0]                 <= 0;
      radicand_gen[INPUT_BITS-1:0] <= 0;
      root_gen[INPUT_BITS-1:0]     <= 0;
    end
    else begin
      start_gen[0] <= start;
      if ( mask_gen[INPUT_BITS-1:0] <= radicand ) begin
        radicand_gen[INPUT_BITS-1:0] <= radicand - mask_gen[INPUT_BITS-1:0];
        root_gen[INPUT_BITS-1:0] <= mask_gen[INPUT_BITS-1:0];
      end
      else begin
        radicand_gen[INPUT_BITS-1:0] <= radicand;
        root_gen[INPUT_BITS-1:0] <= 0;
      end
    end
  end

  // Main generate loop to create the masks and pipeline stages.
  generate
    genvar i;
    // Generate all the mask values. These are built up in the
    // following fashion:
    // LAST MASK:  0x00...001
    //             0x00...004  Increasing # OUTPUT_BITS
    //             0x00...010          |
    //             0x00...040          v
    //                 ...
    // FIRST MASK: 0x10...000  # masks == # OUTPUT_BITS
    //
    // Note that the first mask used can either be of the 0x1... or
    // 0x4... variety. This is purely determined by the number of
    // computation stages. However, the last mask used will always be
    // 0x1 and the second to last mask used will always be 0x4.
    for (i = 0; i < OUTPUT_BITS; i = i + 1) begin: mask_4
      if (i % 2) // i is odd, this is a 4 mask
        assign mask_gen[INPUT_BITS*(OUTPUT_BITS-i)-1:INPUT_BITS*(OUTPUT_BITS-i-1)]  = 4 << 4 * (i/2);
      else // i is even, this is a 1 mask
        assign mask_gen[INPUT_BITS*(OUTPUT_BITS-i)-1:INPUT_BITS*(OUTPUT_BITS-i-1)]  = 1 << 4 * (i/2);
    end
    // Generate all the pipeline stages to compute the square root of
    // the input radicand stream. The general approach is to compare
    // the current values of the root plus the mask to the
    // radicand. If root/mask sum is greater than the radicand,
    // subtract the mask and the root from the radicand and store the
    // radicand for the next stage. Additionally, the root is
    // increased by the value of the mask and stored for the next
    // stage. If this test fails, then the radicand and the root
    // retain their value through to the next stage. The one weird
    // thing is that the mask indices appear to be incremented by one
    // additional position. This is not the case, however, because the
    // first mask is used in the first stage (always block after the
    // generate statement).
    for (i = 0; i < OUTPUT_BITS - 1; i = i + 1) begin: pipeline
      always @ (posedge clk or negedge reset_n) begin : pipeline_stage
        if (!reset_n) begin
          start_gen[i+1]                                    <= 0;
          radicand_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] <= 0;
          root_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)]     <= 0;
        end
        else begin
          start_gen[i+1] <= start_gen[i];
          if ((root_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i] +
               mask_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)]) <= radicand_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i]) begin
	    radicand_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] <= radicand_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i] -
                                                                 mask_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] -
                                                                 root_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i];
	    root_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] <= (root_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i] >> 1) +
                                                             mask_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)];
          end
          else begin
	    radicand_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] <= radicand_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i];
	    root_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)]     <= root_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i] >> 1;
          end
        end
      end
    end
  endgenerate

  // This is the final stage which just implements a rounding
  // operation. This stage could be tacked on as a combinational logic
  // stage, but who cares about latency, anyway? This is NOT a true
  // rounding stage. In order to add convergent rounding, you need to
  // increase the input bit width by 2 (increase the number of
  // pipeline stages by 1) and implement rounding in the module that
  // instantiates this one.
  always @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_valid <= 0;
      root       <= 0;
    end
    else begin
      data_valid <= start_gen[OUTPUT_BITS-1];
      if (root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS] > root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS])
        root <= root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS] + 1;
      else
        root  <= root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS];
    end
  end

endmodule
