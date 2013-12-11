//-----------------------------------------------------------------------------
// Title         : verilog_math
// Project       : verilog
//-----------------------------------------------------------------------------
// File          : verilog_math.vh
// Author        : Schuyler Eldridge  <schuyler.eldridge@gmail.com>
// Created       : 2013/11/25
// Last modified : 2013/12/05
//-----------------------------------------------------------------------------
// Description :
// Helper math functions to make my Verilog coding life easier. This
// must be included INSIDE in the module/endmodule region, not
// before. This has something to do with global function defintions in
// the standard.
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
//------------------------------------------------------------------------------
// Modification history :
// 2013/11/25 : created
//-----------------------------------------------------------------------------

// A Xilinx implementation of the base 2 logarithm. This is very
// useful when assigning port widths based on parameters.
function integer lg;
  input integer          value;
  reg [31:0]             shifted;
  integer                res;
  begin
    if (value < 2)
      lg = value;
    else
      begin
        shifted = value-1;
        for (res=0; shifted>0; res=res+1)
          shifted = shifted>>1;
        lg = res;
      end
  end
endfunction

// Macro to pack a 2D array into a 1D vector based on some number of
// items each with a specified width.
//   u_src:     unpacked source
//   p_dst:     packed destination (obviously must be a wire)
//   width:     the width of one unpacked item
//   num_items: the number of items to be packed
genvar __pack_i;
`define PACK(u_src, p_dest, width, num_items) \
generate\
for (__pack_i = 0; __pack_i < (num_items); __pack_i = __pack_i + 1)\
assign p_dest[(width)*(__pack_i+1)-1:(width)*__pack_i] = u_src[__pack_i];\
endgenerate

// Macro to unpack a 1D vector into a 2D array based on some number of
// items wach with a specified width.
//   p_src:     packed source
//   u_dst:     unpacked destination (a wire)
//   width:     the width of one unpacked item
//   num_items: the number of items to be unpacked
genvar __unpack_i;
`define UNPACK(p_src, u_dest, width, num_items) \
generate\
for (__unpack_i = 0; __unpack_i < (num_items); __unpack_i = __unpack_i + 1)\
assign u_dest[__unpack_i] = p_src[(width)*(__unpack_i+1)-1:(width)*__unpack_i];\
endgenerate

// Macro to generate a random variable of some width using the $random
// function. This is obviously only suitable for testbenches...
//   f:      register you want to assign a random value to every clock cycle
//   width:  width of f
//   period: how often to change the random variable
genvar __random_width_i;
`define RANDOM_WIDTH(f, width, period) \
generate\
for (__random_width_i = 0; __random_width_i < width>>5; __random_width_i = __random_width_i + 1)\
always #period f[32*(__random_width_i+1)-1:32*__random_width_i] = $random;\
always #period f[width-1:32*(width>>5)] = $random;\
endgenerate

// Macro to generate a random varible of some width that changes with
// some delay after a clock using the $random function. This is
// intended to be used to create variable input data that does not
// violate setup/hold times (i.e. you want data that changes HOLD_TIME
// after clock rising edge).
//   f:     output
//   width: width of f
//   clk:   clock
//   delay: time after clk posedge when f changes
genvar __random_width_clk_i;
`define RANDOM_WIDTH_OFFSET(f, width, clk, delay) \
generate\
for (__random_width_clk_i = 0; __random_width_clk_i < width >> 5; __random_width_clk_i = __random_width_clk_i + 1)\
always @ (posedge clk)\
#delay f[32*(__random_width_clk_i+1)-1:32*__random_width_clk_i] = $random;\
always @ (posedge clk)\
#delay f[width-1:32*(width>>5)] = $random;\
endgenerate
