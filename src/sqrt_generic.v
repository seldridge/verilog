//-----------------------------------------------------------------------------
// Title         : Generic Square Root Module
// Project       : verilog
//-----------------------------------------------------------------------------
// File          : sqrt.v
// Author        : Eldridge  <schuye@celnode06.ad.bu.edu>
// Created       : 2015/04/23
// Last modified : 2015/04/23
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Boston University This model is the confidential and
// proprietary property of Boston University and the possession or use of this
// file requires a written license from Boston University.
//------------------------------------------------------------------------------
// Modification history :
// 2015/04/23 : created
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
`include "pipeline_registers.v"
module sqrt_generic
  #(parameter
    WIDTH_INPUT = 16,
    WIDTH_OUTPUT = WIDTH_INPUT / 2 + WIDTH_INPUT % 2,
    FLAG_PIPELINE = 1 // Currently unused
    )
  (
   input                         clk,       // clock
   input                         rst_n,     // asynchronous reset
   input                         valid_in,  // optional start signal
   input [WIDTH_INPUT-1:0]       radicand,  // unsigned radicand
   output reg                    valid_out, // optional data valid signal
   output reg [WIDTH_OUTPUT-1:0] root       // unsigned root
   );

  // Pass-though pipe that sends the input valid signal to the
  // output valid signal
  pipeline_registers
    #(.BIT_WIDTH(1),
      .NUMBER_OF_STAGES(WIDTH_OUTPUT))
  pipe_valid
    (.clk(clk),
     .reset_n(rst_n),
     .pipe_in(valid_in),
     .pipe_out(valid_out)
     );

  logic [WIDTH_INPUT-1:0] root_gen [WIDTH_OUTPUT];
  logic [WIDTH_INPUT-1:0] radicand_gen [WIDTH_OUTPUT];
  logic [WIDTH_INPUT-1:0] mask_gen [WIDTH_OUTPUT];

  generate
    genvar i;
    for (i = 0; i < WIDTH_OUTPUT; i = i + 1) begin: mask
      if (i % 2)
        assign mask_gen[WIDTH_OUTPUT-i-1] = 4 << 4 * (i/2);
      else
        assign mask_gen[WIDTH_OUTPUT-i-1] = 1 << 4 * (i/2);
    end
    for (i = 0; i < WIDTH_OUTPUT; i = i + 1) begin: pipe_sqrt
      always_ff @ (posedge clk or negedge rst_n) begin
        // Not the first stage (the default case)
        if (i > 0) begin
          if (root_gen[i-1] + mask_gen[i] <= radicand_gen[i-1]) begin
            radicand_gen[i] <= radicand_gen[i-1] - mask_gen[i] - root_gen[i-1];
            root_gen[i] <= (root_gen[i-1] >> 1) + mask_gen[i];
          end
          else begin
            radicand_gen[i] <= radicand_gen[i-1];
            root_gen[i] <= root_gen[i-1] >> 1;
          end
        end

        // First stage
        if (i == 0) begin
          if (mask_gen[i] <= radicand) begin
            radicand_gen[i] <= radicand - mask_gen[i];
            root_gen[i] <= mask_gen[i];
          end
          else begin
            radicand_gen[i] <= radicand;
            root_gen[i] <= '0;
          end
        end
        // Reset condition
        if (!rst_n) begin
        end
      end
    end
  endgenerate

  assign root = root_gen[WIDTH_OUTPUT-1];

endmodule
