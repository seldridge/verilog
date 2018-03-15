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

// Pipelined implementation of the CORDIC vector rotation algorithm in
// hyperbolic mode.
//
// functions (governed by input func):
//   1'd0: exp
//   1'd1: ln
//
// The formats for inputs and outputs are as follows:
//   --------------------------------------------
//   | function |         input |        output |
//   --------------------------------------------
//   |      exp | s0.9876543210 | s10.876543210 |
//   |       ln | s3210.6543210 | [s][.876543210 |
//   --------------------------------------------
// >>>>> actually: [sign][11 bits].[12 bits]

`include "pipeline_registers.v"
`include "sign_extender.v"
module cordic_hyp
  #(
    parameter
    W = 12                              // input/output width/# stages
    )
  (
   input                  clk, rst_n, start,
   input                  func,         // function to perform (see above)
   input signed [W*2-1:0] a, b,         // function inputs
   output                 valid,        // output data valid
   output reg [W*2-1:0]   f             // function output
   );

  localparam
    EXP  = 1'd0,
    LN   = 1'd1;
  localparam
    ROT  = 1'd0,
    VEC  = 1'd1;
  localparam
    INV_GAIN_32  = 32'sh9A8F4390,       // 1.20749706776307210000
    LN_2         = 32'sh2C5C85FE,       // 0.69314718055994529000
    LN_2_INV     = 32'sh5C551D95;       // 1.44269504088896340000
  localparam                            // account for repeated stages
    STAGES  = W+(W>=4)+(W>=13)+(W>=40)+(W>=121)+(W>=364)+(W>=1093);

  reg [4:0]           first_bit;
  reg [STAGES:0]      mode;
  reg [31:0]          atanh_table [31:0];
  reg [STAGES-1:0]    sigma;
  reg [W-1:0]         x_neg [STAGES:0];
  reg [W-1:0]         y_neg [STAGES:0];
  reg signed [W-1:0]  x [STAGES:0];
  reg signed [W-1:0]  y [STAGES:0];
  reg signed [W-1:0]  z [STAGES:0];
  reg signed [W-1:0]  x_round [STAGES:0];
  reg signed [W-1:0]  y_round [STAGES:0];

  wire                func_out;
  wire [W-1:0]        inv_gain, e_exp, e_exp_out;
  wire [W*2-1:0]      m, d;
  wire [W*3-1:0]      q;
  wire signed [4:0]   e, e_out;
  wire signed [W-1:0] ln_2, ln_2_inv;
  wire signed [W+5-1:0] e_out_mul_ln_2;
  wire signed [W*2-1:0] z_se, e_out_mul_ln_2_se;

  initial begin                         // this is overkill, how to improve?
    atanh_table[0]  = 32'h8C9F53D5;     // 0.54930614433405478000
    atanh_table[1]  = 32'h4162BBEA;     // 0.25541281188299536000
    atanh_table[2]  = 32'h202B1239;     // 0.12565721414045303000
    atanh_table[3]  = 32'h1005588B;     // 0.06258157147700300900
    atanh_table[4]  = 32'h0800AAC4;     // 0.03126017849066699300
    atanh_table[5]  = 32'h04001556;     // 0.01562627175205220900
    atanh_table[6]  = 32'h020002AB;     // 0.00781265895154042120
    atanh_table[7]  = 32'h01000055;     // 0.00390626986839682620
    atanh_table[8]  = 32'h0080000B;     // 0.00195312748353254980
    atanh_table[9]  = 32'h00400001;     // 0.00097656281044103594
    atanh_table[10] = 32'h00200000;     // 0.00048828128880511277
    atanh_table[11] = 32'h00100000;     // 0.00024414062985063861
    atanh_table[12] = 32'h00080000;     // 0.00012207031310632982
    atanh_table[13] = 32'h00040000;     // 0.00006103515632579122
    atanh_table[14] = 32'h00020000;     // 0.00003051757813447390
    atanh_table[15] = 32'h00010000;     // 0.00001525878906368424
    atanh_table[16] = 32'h00008000;     // 0.00000762939453139803
    atanh_table[17] = 32'h00004000;     // 0.00000381469726564350
    atanh_table[18] = 32'h00002000;     // 0.00000190734863281481
    atanh_table[19] = 32'h00001000;     // 0.00000095367431640654
    atanh_table[20] = 32'h00000800;     // 0.00000047683715820316
    atanh_table[21] = 32'h00000400;     // 0.00000023841857910157
    atanh_table[22] = 32'h00000200;     // 0.00000011920928955078
    atanh_table[23] = 32'h00000100;     // 0.00000005960464477539
    atanh_table[24] = 32'h00000080;     // 0.00000002980232238770
    atanh_table[25] = 32'h00000040;     // 0.00000001490116119385
    atanh_table[26] = 32'h00000020;     // 0.00000000745058059692
    atanh_table[27] = 32'h00000010;     // 0.00000000372529029846
    atanh_table[28] = 32'h00000008;     // 0.00000000186264514923
    atanh_table[29] = 32'h00000004;     // 0.00000000093132257462
    atanh_table[30] = 32'h00000002;     // 0.00000000046566128731
    atanh_table[31] = 32'h00000001;     // 0.00000000023283064365
    end

  assign ln_2  = (LN_2[31:31-W+1] + LN_2[31-W]);
  assign ln_2_inv  = (LN_2_INV[31:31-W+1] + LN_2_INV[31-W]);
  assign inv_gain  = (INV_GAIN_32 >> (32-W+1)) + INV_GAIN_32[32-W];
  assign m  = (first_bit > 11) ? a >> (first_bit-11) : a << (11-first_bit);
  assign e  = first_bit - 11;
  assign e_out_mul_ln_2  = e_out * ln_2;
  assign q  = a * ln_2_inv;
  assign d  = (q[21:21-W+1]+q[21-W]) * ln_2;
  assign e_exp  = q[W*3-3:W*2-2];

  always @ * begin
    casex(a)
      24'b1_xxxxxxxxxxx_xxxxxxxxxxxx: first_bit  = 23;
      24'b0_1xxxxxxxxxx_xxxxxxxxxxxx: first_bit  = 22;
      24'b0_01xxxxxxxxx_xxxxxxxxxxxx: first_bit  = 21;
      24'b0_001xxxxxxxx_xxxxxxxxxxxx: first_bit  = 20;
      24'b0_0001xxxxxxx_xxxxxxxxxxxx: first_bit  = 19;
      24'b0_00001xxxxxx_xxxxxxxxxxxx: first_bit  = 18;
      24'b0_000001xxxxx_xxxxxxxxxxxx: first_bit  = 17;
      24'b0_0000001xxxx_xxxxxxxxxxxx: first_bit  = 16;
      24'b0_00000001xxx_xxxxxxxxxxxx: first_bit  = 15;
      24'b0_000000001xx_xxxxxxxxxxxx: first_bit  = 14;
      24'b0_0000000001x_xxxxxxxxxxxx: first_bit  = 13;
      24'b0_00000000001_xxxxxxxxxxxx: first_bit  = 12;
      24'b0_00000000000_1xxxxxxxxxxx: first_bit  = 11;
      24'b0_00000000000_01xxxxxxxxxx: first_bit  = 10;
      24'b0_00000000000_001xxxxxxxxx: first_bit  = 9;
      24'b0_00000000000_0001xxxxxxxx: first_bit  = 8;
      24'b0_00000000000_00001xxxxxxx: first_bit  = 7;
      24'b0_00000000000_000001xxxxxx: first_bit  = 6;
      24'b0_00000000000_0000001xxxxx: first_bit  = 5;
      24'b0_00000000000_00000001xxxx: first_bit  = 4;
      24'b0_00000000000_000000001xxx: first_bit  = 3;
      24'b0_00000000000_0000000001xx: first_bit  = 2;
      24'b0_00000000000_00000000001x: first_bit  = 1;
      24'b0_00000000000_000000000001: first_bit  = 0;
      default: first_bit                         = 0;
    endcase
  end

  always @ (posedge clk or negedge rst_n) begin//function pre-processing
    if (!rst_n) begin
      x[0]    <= 0;
      y[0]    <= 0;
      z[0]    <= 0;
      mode[0] <= ROT;
    end
    else begin
      case (func)
        EXP: begin
          x[0]    <= inv_gain;
          y[0]    <= 0;
          z[0]    <= d[W*2-1:W];
          mode[0] <= ROT;
        end
        LN: begin
          x[0]    <= {2'b0,m[11:2]} + 12'b0100_0000_0000;//not rounded
          y[0]    <= {2'b0,m[11:2]} - 12'b0100_0000_0000;//not rounded
          z[0]    <= 0;
          mode[0] <= VEC;
        end
        default: begin
          x[0]    <= 32'bx;
          y[0]    <= 32'bx;
          z[0]    <= 32'bx;
          mode[0] <= ROT;
        end
      endcase
    end
  end

  generate
    genvar               i;
    for (i = 0; i < STAGES; i = i + 1) begin : gen_stages
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
        case (mode[i])
          ROT: sigma[i]      = ~z[i][W-1];//z>=0
          VEC: sigma[i]      = y[i][W-1];//y<0
          default: sigma[i]  = 1'd0;
        endcase
      end
      always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          x[i+1]    <= 0;
          y[i+1]    <= 0;
          z[i+1]    <= 0;
          mode[i+1] <= 0;
        end
        else begin
          x[i+1] <= (sigma[i]) ?
                    x[i] + (y_round[i] >>> i+1-(i>4)-(i>13)-(i>40)-(i>121)-(i>364)-(i>1093)) :
                    x[i] - (y_round[i] >>> i+1-(i>4)-(i>13)-(i>40)-(i>121)-(i>364)-(i>1093));
          y[i+1] <= (sigma[i]) ?
                    y[i] + (x_round[i] >>> i+1-(i>4)-(i>13)-(i>40)-(i>121)-(i>364)-(i>1093)) :
                    y[i] - (x_round[i] >>> i+1-(i>4)-(i>13)-(i>40)-(i>121)-(i>364)-(i>1093));
          z[i+1] <= (sigma[i]) ?
                    z[i] - {2'b0,(atanh_table[i-(i>4)-(i>13)-(i>40)-(i>121)-
                                              (i>364)-(i>1093)][31:31-W+3] +
                                  atanh_table[i-(i>4)-(i>13)-(i>40)-(i>121)-
                                              (i>364)-(i>1093)][31-W+3-1])} :
                    z[i] + {2'b0,(atanh_table[i-(i>4)-(i>13)-(i>40)-(i>121)-
                                              (i>364)-(i>1093)][31:31-W+3] +
                            atanh_table[i-(i>4)-(i>13)-(i>40)-(i>121)-(i>364)-
                                        (i>1093)][31-W+3-1])};
          mode[i+1] <= mode[i];
        end
      end
    end
  endgenerate

  always @ (posedge clk or negedge rst_n) begin//function post-processing
    if (!rst_n)
      f <= 0;
    else begin
      case (func_out)
        EXP: f <= (e_exp_out[W-1]) ?
                  (x[STAGES] + y[STAGES]) >> (~e_exp_out+12'b1) :
                  (x[STAGES] + y[STAGES]) << e_exp_out;
        LN:  f <= (z_se * 2 + e_out_mul_ln_2_se) * 4;
      endcase
    end
  end

  sign_extender
    #(
      .INPUT_WIDTH(W),
      .OUTPUT_WIDTH(W*2)
      )
  sign_extender_z
    (
     .original(z[STAGES]),
     .sign_extended_original(z_se)
     );

  sign_extender
    #(
      .INPUT_WIDTH(W+5),
      .OUTPUT_WIDTH(W*2)
      )
  sign_extender_e_out_mul_LN_2
    (
     .original(e_out_mul_ln_2),
     .sign_extended_original(e_out_mul_ln_2_se)
     );

  pipeline_registers
    #(
      .BIT_WIDTH(1),
      .NUMBER_OF_STAGES(W+3)
      )
  pipe_valid
    (
     .clk(clk),
     .rst_n(rst_n),
     .pipe_in(start),
     .pipe_out(valid)
     );

  pipeline_registers
    #(
      .BIT_WIDTH(1+5+12),
      .NUMBER_OF_STAGES(W+2)
      )
  pipe_func_e_exp
    (
     .clk(clk),
     .rst_n(rst_n),
     .pipe_in({func,e,e_exp}),
     .pipe_out({func_out,e_out,e_exp_out})
     );

endmodule
