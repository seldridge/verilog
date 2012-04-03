////////////////////////////////////////////////////////////////////////////////
// Original Author: Schuyler Eldridge
// Contact Point: Schuyler Eldridge (schuyler.eldridge@gmail.com)
// sqrt_pipelined.v
// Created: 4.2.2012
// Modified: 4.2.2012
//
// Implements a fixed-point parameterized pipelined square root
// operation. The number of stages in the pipeline is equal to the
// number of output bits in the computation. The input bits should be
// a "nice" number such that the output bits can be reliably
// determined using a "division" (/) operator. This operates only on
// integers and will sustain a one-cycle / output throughput. 
// Copyright (C) 2012 Schuyler Eldridge, Boston University
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
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module sqrt_pipelined
  (
   input                        clk,
   input                        start,
   input [INPUT_BITS-1:0]       radicand,
   output reg                   data_ready,
   output reg [OUTPUT_BITS-1:0] root
   );

  // WARNING!!! THESE PARAMETERS ARE INTENDED TO BE MODIFIED IN A TOP
  // LEVEL MODULE. LOCAL CHANGES HERE WILL, MOST LIKELY, BE
  // OVERWRITTEN!
  parameter
    INPUT_BITS   = 16; // number of input bits (should be power of 2)
  localparam
    OUTPUT_BITS  = INPUT_BITS / 2; // number of output bits
  
  reg [OUTPUT_BITS-1:0]         start_gen;
  reg [OUTPUT_BITS*INPUT_BITS-1:0] root_gen; // root values
  reg [OUTPUT_BITS*INPUT_BITS-1:0] radicand_gen; // radicand values
  wire [OUTPUT_BITS*INPUT_BITS-1:0] mask_gen; // mask values

  // assign the first two mask values (0x4000.... and 0x1000...)
  assign mask_gen[INPUT_BITS-1:0]  = 4 << 4 * (OUTPUT_BITS/2 - 1);
  assign mask_gen[INPUT_BITS*2-1:INPUT_BITS]  = 1 << 4 * (OUTPUT_BITS/2 - 1);

  // Main generate loop to create the masks and pipeline stages.
  generate
    genvar i;
    // Generate all the other mask values by shifting the first two
    // mask values by increasing values of 4. The end result looks
    // like:
    // 0x4000...
    // 0x1000...
    // 0x0400...
    // 0x0100...
    // ...
    for (i = 1; i < OUTPUT_BITS/2; i = i + 1) begin: mask
      assign mask_gen[INPUT_BITS*(i*2+1)-1:INPUT_BITS*(i*2)]  = mask_gen[INPUT_BITS-1:0] >> 4 * i;
      assign mask_gen[INPUT_BITS*(i*2+2)-1:INPUT_BITS*(i*2+1)]  = mask_gen[INPUT_BITS*2-1:INPUT_BITS] >> 4 * i;
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
      always @ (posedge clk) begin : pipeline_stage
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
	  root_gen[INPUT_BITS*(i+2)-1:INPUT_BITS*(i+1)] <= root_gen[INPUT_BITS*(i+1)-1:INPUT_BITS*i] >> 1;
        end
      end
    end // block: pipeline
  endgenerate

  // This is the first stage of the pipeline. The comparison is
  // simpler, but note the use of the first mask for this stage. 
  always @ (posedge clk) begin
    start_gen[0] <= start;
    if ( mask_gen[INPUT_BITS-1:0] <= radicand ) begin
      radicand_gen[INPUT_BITS-1:0] <= radicand - mask_gen[INPUT_BITS-1:0];
      root_gen[INPUT_BITS-1:0] <= 16'h4000;
    end
    else begin
      radicand_gen[INPUT_BITS-1:0] <= radicand;
      root_gen[INPUT_BITS-1:0] <= 0;
    end
  end // always @ (posedge clk)

  // This is the final stage which just implements a rounding
  // operation. This stage could be tacked on as a combinational logic
  // stage, but who cares about latency, anyway?
  always @ (posedge clk) begin
    data_ready <= start_gen[OUTPUT_BITS-1];
    if (root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS] > root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS])
      root <= root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS] + 1;
    else
      root  <= root_gen[OUTPUT_BITS*INPUT_BITS-1:OUTPUT_BITS*INPUT_BITS-INPUT_BITS];
  end

endmodule
