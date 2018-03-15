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

// Implements a "good" reset signal that is asserted asynchronously
// and deasserted synchronously. See Cliff Cummings work for the
// reasoning behind this:
//   Cummings, C. and Milis, D. "Synchronous Resets? Asynchronous
//     resets? I am so confused! How will I ever know which to use?"
//     Synopsys Users Group Conference, 2002.
//   Cummings, C., Millis, D., and Golson, S. "Asynchronous &
//     synchronous reset design techniques-part deux." Synopsys Users
//     Group Conference, 2003.

`include "pipeline_registers.v"
module reset
  (
   input clk,       // input clock
   input rst_n_in,  // asynchronous reset from userland
   output rst_n_out // asynchronous assert/synchronous deassert chip broadcast
   );

  // You have two DFFs in series (a two stage pipe) with the input to
  // the first DFF tied to 1. When the input active low reset is
  // deasserted this asynchronously resets the DFFs. This causes the
  // second DFF to broadcast an asynchronous reset out to the whole
  // chip. However, when the input rest is asserted, the flip flops
  // are enabled, and you get a synchronous assert of the active low
  // reset to the entire chip.

  pipeline_registers
    #(
      .BIT_WIDTH(1),
      .NUMBER_OF_STAGES(2)
      )
  reset_flops
    (
     .clk(clk),           // input clk
     .reset_n(rst_n_in),  // convert to active low
     .pipe_in(1'b1),      // input is always 1
     .pipe_out(rst_n_out) // asynchronous reset output
     );

endmodule
