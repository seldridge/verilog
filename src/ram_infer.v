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

// Infers parameterized block RAM from behavioral syntax. Based off an
// example by Eric Johnson and Prof. Derek Chiou at UT Austin (see
// http://users.ece.utexas.edu/~derek/code/BRAM.v). Tested by
// inspection of simulated RTL schematic as this successfully infers
// block RAM.

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

  genvar                  i;

  generate
    for (i=0; i<DEPTH; i=i+1) begin: gen_init
      initial begin
        ram[i]  = INIT_VAL;
      end
    end
  endgenerate

  always @(posedge clka) begin
    if (ena) begin
      if (wea)
        ram[addra] <= dina;
      douta <= ram[addra];
    end
  end

  always @(posedge clkb) begin
    if (enb) begin
      if (web)
        ram[addrb] <= dinb;
      doutb <= ram[addrb];
    end
  end

endmodule
