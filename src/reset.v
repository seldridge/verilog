//-----------------------------------------------------------------------------
// Title         : reset
// Project       : verilog
//-----------------------------------------------------------------------------
// File          : reset.v
// Author        : Schuyler Eldridge  <schuyler.eldridge@gmail.com>
// Created       : 2013/12/10
// Last modified : 2013/12/10
//-----------------------------------------------------------------------------
// Description :
// Implements a "good" reset signal that is asserted asynchronously
// and deasserted synchronously. See Cliff Cummings work for the
// reasoning behind this:
//   Cummings, C. and Milis, D. "Synchronous Resets? Asynchronous
//     resets? I am so confused! How will I ever know which to use?"
//     Synopsys Users Group Conference, 2002.
//   Cummings, C., Millis, D., and Golson, S. "Asynchronous &
//     synchronous reset design techniques-part deux." Synopsys Users
//     Group Conference, 2003.
//-----------------------------------------------------------------------------
// Copyright (C) 2013 Schuyler Eldridge, Boston University
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
//-----------------------------------------------------------------------------
// Modification history :
// 2013/12/10 : created
//-----------------------------------------------------------------------------
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
