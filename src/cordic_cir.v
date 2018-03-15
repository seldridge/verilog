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

// Description:
// Pipelined implementation of the CORDIC vector rotation algorithm in circular
// mode. The input is selected through an input "func" select line. Currently
// implemented functions are:
//   func select | function
//             0 | sine
//             1 | cosine
// Format is two's complement fixed point with 11 bits before the
// binary point and 12 bits after e.g.:
//   [ sign ][ 11 bits ].[ 12 bits ]

`timescale 1ns/1ps
`include "pipeline_registers.v"
module cordic_cir
  #(
    parameter
    W = 12                              // input/output width
    )
  (
   input                  clk, rst_n, start,
   input                  func,         // function to perform (see above)
   input signed [W*2-1:0] a, b,         // function inputs
   output                 valid,        // output data valid
   output reg [W-1:0]     f             // function output
   );

  localparam
    COS  = 1'd0,
    SIN  = 1'd1;
  localparam
    ROT  = 1'd0,
    VEC  = 1'd1;
  localparam
    INV_GAIN_32  = 32'h4DBA76D4,        // 0.60725293500888133000
    PI_DIV_TWO   = 32'sh6487ED51,       // 1.57079632679489660000
    TWO_DIV_PI   = 32'sh28BE60DC;       // 0.63661977236758138000

  reg                     func_pp, inv_pp;
  reg [31:0]              atan_table [31:0];
  reg [W-1:0]             sigma, mode;
  reg [W-1:0]             x_neg [W:0];
  reg [W-1:0]             y_neg [W:0];
  reg signed [W-1:0]      x [W:0];
  reg signed [W-1:0]      y [W:0];
  reg signed [W-1:0]      z [W:0];
  reg signed [W-1:0]      x_round [W:0];
  reg signed [W-1:0]      y_round [W:0];

  wire                    func_out, inv_out;
  wire signed [W*2-1:0]   inv_gain, pi_div_two, two_div_pi;
  wire signed [W*4-1:0]   q;
  wire [W*4-1:0]          d;

  initial begin                         // this is overkill, how to improve?
    atan_table[0]  = 32'hC90FDAA2;      // 0.78539816339744828000
    atan_table[1]  = 32'h76B19C16;      // 0.46364760900080609000
    atan_table[2]  = 32'h3EB6EBF2;      // 0.24497866312686414000
    atan_table[3]  = 32'h1FD5BA9B;      // 0.12435499454676144000
    atan_table[4]  = 32'h0FFAADDC;      // 0.06241880999595735000
    atan_table[5]  = 32'h07FF556F;      // 0.03123983343026827700
    atan_table[6]  = 32'h03FFEAAB;      // 0.01562372862047683100
    atan_table[7]  = 32'h01FFFD55;      // 0.00781234106010111110
    atan_table[8]  = 32'h00FFFFAB;      // 0.00390623013196697180
    atan_table[9]  = 32'h007FFFF5;      // 0.00195312251647881880
    atan_table[10] = 32'h003FFFFF;      // 0.00097656218955931946
    atan_table[11] = 32'h00200000;      // 0.00048828121119489829
    atan_table[12] = 32'h00100000;      // 0.00024414062014936177
    atan_table[13] = 32'h00080000;      // 0.00012207031189367021
    atan_table[14] = 32'h00040000;      // 0.00006103515617420877
    atan_table[15] = 32'h00020000;      // 0.00003051757811552610
    atan_table[16] = 32'h00010000;      // 0.00001525878906131576
    atan_table[17] = 32'h00008000;      // 0.00000762939453110197
    atan_table[18] = 32'h00004000;      // 0.00000381469726560650
    atan_table[19] = 32'h00002000;      // 0.00000190734863281019
    atan_table[20] = 32'h00001000;      // 0.00000095367431640596
    atan_table[21] = 32'h00000800;      // 0.00000047683715820309
    atan_table[22] = 32'h00000400;      // 0.00000023841857910156
    atan_table[23] = 32'h00000200;      // 0.00000011920928955078
    atan_table[24] = 32'h00000100;      // 0.00000005960464477539
    atan_table[25] = 32'h00000080;      // 0.00000002980232238770
    atan_table[26] = 32'h00000040;      // 0.00000001490116119385
    atan_table[27] = 32'h00000020;      // 0.00000000745058059692
    atan_table[28] = 32'h00000010;      // 0.00000000372529029846
    atan_table[29] = 32'h00000008;      // 0.00000000186264514923
    atan_table[30] = 32'h00000004;      // 0.00000000093132257462
    atan_table[31] = 32'h00000002;      // 0.00000000046566128731
  end

  assign inv_gain  = (INV_GAIN_32 >>> (32-W+1)) + INV_GAIN_32[32-W];
  assign pi_div_two  = (PI_DIV_TWO >>> (32-W*2)) + PI_DIV_TWO[32-W*2+1];
  assign two_div_pi  = (TWO_DIV_PI >>> (32-W*2)) + TWO_DIV_PI[32-W*2+1];
  assign q  = a * two_div_pi;
  assign d  = (q[33:10]+q[9]) * pi_div_two;

  always @ * begin
    case (func)
      COS: begin
        case (q[35:34])
          2'd0: begin func_pp  = COS; inv_pp = 0; end
          2'd1: begin func_pp  = SIN; inv_pp = 1; end
          2'd2: begin func_pp  = COS; inv_pp = 1; end
          2'd3: begin func_pp  = SIN; inv_pp = 0; end
        endcase
      end
      SIN: begin
        case (q[35:34])
          2'd0: begin func_pp  = SIN; inv_pp = 0; end
          2'd1: begin func_pp  = COS; inv_pp = 0; end
          2'd2: begin func_pp  = SIN; inv_pp = 1; end
          2'd3: begin func_pp  = COS; inv_pp = 1; end
        endcase
      end
    endcase
  end

  always @ (posedge clk or negedge rst_n) begin//function pre-processing
    if (!rst_n) begin
      x[0]    <= 0;
      y[0]    <= 0;
      z[0]    <= 0;
      mode[0] <= 0;
    end
    else begin
      case (func_pp)
        COS: begin
          x[0]    <= inv_gain;
          y[0]    <= 0;
          z[0]    <= {1'b0,d[W*4-2:W*4-2-10]};
          mode[0] <= ROT;
        end
        SIN: begin
          x[0]   <= inv_gain;
          y[0]   <= 0;
          z[0]   <= {1'b0,d[W*4-2:W*4-2-10]};
          mode[0] <= ROT;
        end
        default: begin
          x[0]    <= 32'bx;
          y[0]    <= 32'bx;
          z[0]    <= 32'bx;
          mode[0] <= 1'bx;
        end
      endcase
    end
  end

  generate
    genvar               i;
    for (i = 0; i < W; i = i + 1) begin : gen_stages
      always @ * begin
        x_neg[i]  = ~x[i] + 1;
        y_neg[i]  = ~y[i] + 1;
        if (i==0) begin
          x_round[i]  = x[i];
          y_round[i]  = y[i];
        end
        else begin
          x_round[i]  = (x[i][W-1]) ? ~(x_neg[i] + (x_neg[i][i-1] << i)+1) + 1 : x[i] + (x[i][i-1] << i);
          y_round[i]  = (y[i][W-1]) ? ~(y_neg[i] + (y_neg[i][i-1] << i)+1) + 1 : y[i] + (y[i][i-1] << i);
        end
      end
      always @ * begin
        case (mode[0])
          ROT: sigma[i]      = ~z[i][W-1];//z>=0
          VEC: sigma[i]      = y[i][W-1];//y<0
          default: sigma[i]  = 1'd0;
        endcase
      end
      always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          x[i+1] <= 0;
          y[i+1] <= 0;
          z[i+1] <= 0;
        end
        else begin
          x[i+1] <= (sigma[i]) ? x[i] - (y_round[i] >>> i) : x[i] + (y_round[i] >>> i);
          y[i+1] <= (sigma[i]) ? y[i] + (x_round[i] >>> i) : y[i] - (x_round[i] >>> i);
          z[i+1] <= (sigma[i]) ? z[i] - {2'b0, (atan_table[i][31:31-W+3]+atan_table[i][31-W+3-1])} :
                    z[i] + {2'b0, atan_table[i][31:31-W+3]+atan_table[i][31-W+3-1]};
        end
      end
    end
  endgenerate

  always @ (posedge clk or negedge rst_n) begin//function post-processing
    if (!rst_n)
      f <= 0;
    else begin
      case (func_out)
        COS: f <= (inv_out) ? ~x[W] + 1 : x[W];
        SIN: f <= (inv_out) ? ~y[W] + 1 : y[W];
      endcase
    end
  end

  pipeline_registers
    #(
      .BIT_WIDTH(3),
      .NUMBER_OF_STAGES(W+1)
      )
  pipe_valid
    (
     .clk(clk),
     .rst_n(rst_n),
     .pipe_in({func_pp,start,inv_pp}),
     .pipe_out({func_out,valid,inv_out})
     );

endmodule
