// See LICENSE for license details.

// Implements a series of pipeline registers specified by the input
// parameters BIT_WIDTH and NUMBER_OF_STAGES. BIT_WIDTH determines the
// size of the signal passed through each of the pipeline
// registers. NUMBER_OF_STAGES is the number of pipeline registers
// generated. This accepts values of 0 (yes, it just passes data from
// input to output...) up to however many stages specified.

`timescale 1ns / 1ps
module pipeline_registers
  #(
    parameter
    BIT_WIDTH         = 10,
    NUMBER_OF_STAGES  = 5
    )
  (
   input                      clk,
   input                      reset_n,
   input [BIT_WIDTH-1:0]      pipe_in,
   output reg [BIT_WIDTH-1:0] pipe_out
   );

  // Main generate function for conditional hardware instantiation
  generate
    genvar                                 i;
    // Pass-through case for the odd event that no pipeline stages are
    // specified.
    if (NUMBER_OF_STAGES == 0) begin
      always @ *
        pipe_out = pipe_in;
    end
    // Single flop case for a single stage pipeline
    else if (NUMBER_OF_STAGES == 1) begin
      always @ (posedge clk or negedge reset_n)
        pipe_out <= (!reset_n) ? 0 : pipe_in;
    end
    // Case for 2 or more pipeline stages
    else begin
      // Create the necessary regs
      reg [BIT_WIDTH*(NUMBER_OF_STAGES-1)-1:0] pipe_gen;
      // Create logic for the initial and final pipeline registers
      always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
          pipe_gen[BIT_WIDTH-1:0] <= 0;
          pipe_out                <= 0;
        end
        else begin
          pipe_gen[BIT_WIDTH-1:0] <= pipe_in;
          pipe_out                <= pipe_gen[BIT_WIDTH*(NUMBER_OF_STAGES-1)-1:BIT_WIDTH*(NUMBER_OF_STAGES-2)];
        end
      end
      // Create the intermediate pipeline registers if there are 3 or
      // more pipeline stages
      for (i = 1; i < NUMBER_OF_STAGES-1; i = i + 1) begin : pipeline
        always @ (posedge clk or negedge reset_n)
          pipe_gen[BIT_WIDTH*(i+1)-1:BIT_WIDTH*i] <= (!reset_n) ? 0 : pipe_gen[BIT_WIDTH*i-1:BIT_WIDTH*(i-1)];
      end
    end
  endgenerate

endmodule
