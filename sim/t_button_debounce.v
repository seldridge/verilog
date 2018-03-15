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

`timescale 1ns / 1ps
module t_button_debounce();

  parameter
    CLK_FREQUENCY  = 10_000_000,
    DEBOUNCE_HZ    = 2;

  reg clk, reset_n, button;
  wire debounce;

  button_debounce
    #(
      .CLK_FREQUENCY(CLK_FREQUENCY),
      .DEBOUNCE_HZ(DEBOUNCE_HZ)
      )
  button_debounce
    (
     .clk(clk),
     .reset_n(reset_n),
     .button(button),
     .debounce(debounce)
     );

  initial begin
    clk          = 1'bx; reset_n = 1'bx; button = 1'bx;
    #10 reset_n  = 1;
    #10 reset_n  = 0; clk = 0;
    #10 reset_n  = 1;
    #10 button   = 0;
  end

  always
    #5 clk  = ~clk;

  always begin
    #100 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
    #0.1 button  = ~button;
  end

endmodule
