// See LICENSE for license details.

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
