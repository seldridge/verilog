// See LICENSE for license details.

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
