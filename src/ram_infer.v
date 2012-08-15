//--------------------------------------------------------------------------------
// Original Author: Schuyler Eldridge (schuyler.eldridge@gmail.com)
// File           : ram_infer.v
// Created        : 08.15.2012
// 
// Infers parameterized block RAM from behavioral syntax. Based off an
// example by Eric Johnson and Prof. Derek Chiou at UT Austin (see
// http://users.ece.utexas.edu/~derek/code/BRAM.v). Tested by
// inspection of simulated RTL schematic as this successfully infers
// block RAM. Oddly, this also adds flops at the output. I expect that
// this may be because the available block RAM has an asynchronous
// read.
// 
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
//--------------------------------------------------------------------------------
`timescale 1ns/1ps
module ram_infer
  #(
    parameter
    WIDTH = 8,
    DEPTH = 64,
    LG_DEPTH = 6,
    INIT_VAL = 8'd0
    )
  (
   input                  clka, clkb, wea, web, ena, enb,
   input [LG_DEPTH-1:0]   addra, addrb, 
   input [WIDTH-1:0]      dina, dinb, 
   output reg [WIDTH-1:0] douta, doutb
   );
  
  reg [WIDTH-1:0]         ram [DEPTH-1:0];
  reg [WIDTH-1:0]         doa, dob;

  generate
    genvar                i;
    for (i=0; i<DEPTH; i=i+1) begin: gen_init
      initial begin
        ram[i]  = INIT_VAL;
      end
    end
  endgenerate

  always @(posedge clka) begin
    if (ena) begin
      if (wea) ram[addra] <= dina;
      douta               <= ram[addra];
    end
  end

  always @(posedge clkb) begin
    if (enb) begin
      if (web) ram[addrb] <= dinb;
      doutb               <= ram[addrb];
    end
  end
  
endmodule
