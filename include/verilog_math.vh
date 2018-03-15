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

// Helper math functions to make my Verilog coding life easier. This
// must be included INSIDE in the module/endmodule region, not
// before. This has something to do with global function defintions in
// the standard.

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

// Function to convert a fixed point number to a real
function real fixed_to_real;
  input x, binary_point;
  real    fixed_to_real;
  fixed_to_real  = $itor(f)/2**binary_point;
endfunction

// Macro to pack a 2D array into a 1D vector based on some number of
// items each with a specified width.
//   u_src:     unpacked source
//   p_dst:     packed destination (obviously must be a wire)
//   width:     the width of one unpacked item
//   num_items: the number of items to be packed
`define PACK(u_src, p_dest, width, num_items) \
generate\
for (genvar __pack_i = 0; __pack_i < (num_items); __pack_i = __pack_i + 1) begin\
assign p_dest[(width)*(__pack_i+1)-1:(width)*__pack_i] = u_src[__pack_i]; end\
endgenerate

// Macro to unpack a 1D vector into a 2D array based on some number of
// items wach with a specified width.
//   p_src:     packed source
//   u_dst:     unpacked destination (a wire)
//   width:     the width of one unpacked item
//   num_items: the number of items to be unpacked
`define UNPACK(p_src, u_dest, width, num_items) \
generate\
for (genvar __unpack_i = 0; __unpack_i < (num_items); __unpack_i = __unpack_i + 1) begin\
assign u_dest[__unpack_i] = p_src[(width)*(__unpack_i+1)-1:(width)*__unpack_i]; end\
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
