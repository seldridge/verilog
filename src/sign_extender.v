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

// Generic sign extension module

`timescale 1ns/1ps
module sign_extender
  #(
    parameter
    INPUT_WIDTH = 8,
    OUTPUT_WIDTH = 16
    )
  (
   input [INPUT_WIDTH-1:0] original,
   output reg [OUTPUT_WIDTH-1:0] sign_extended_original
   );

  wire [OUTPUT_WIDTH-INPUT_WIDTH-1:0] sign_extend;

  generate
    genvar                           i;
    for (i = 0; i < OUTPUT_WIDTH-INPUT_WIDTH; i = i + 1) begin : gen_sign_extend
      assign sign_extend[i]  = (original[INPUT_WIDTH-1]) ? 1'b1 : 1'b0;
    end
  endgenerate

  always @ * begin
    sign_extended_original  = {sign_extend,original};
  end

endmodule
