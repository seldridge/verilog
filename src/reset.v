// See LICENSE for license details.

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
