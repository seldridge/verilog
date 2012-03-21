`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Schuyler Eldridge
// button_debounce.v
// Created: 10/10/2009 
//
// Counter based debounce circuit originally written for EC551 (back
// in the day).
//////////////////////////////////////////////////////////////////////////////////
module button_debounce(
                       input  clk,
                       input  button,
                       output debounce
                       );
  
  parameter
    count_value = 25000000;
  // values of count_value correspond to max output frequency of debounce:
  // count_value (clock cycles) | debounce (Hz)|
  // ------------------------------------------|
  // 200,000,000                | 0.25         |
  // 100,000,000                | 0.50         |
  //  50,000,000                | 1.00         |
  //  25,000,000                | 2.00         |
  //  12,500,000                | 4.00         |
  //   6,250,000                | 8.00         |
  // ------------------------------------------|
  // *NOTE* This assumes a 50MHz clock
  
  reg                         count_en;
  reg                         debounce;
  reg [25:0]                  count;
  
  always @ (posedge clk) begin
    // exit counting state
    if (count >= count_value) begin
      count_en <= 0;
      count <= 0;
      debounce <= 0;
      // counting state
    end
    else if (count_en == 1) begin
      count_en <= 1;
      count <= count + 1;
      debounce <= 0;
    end
    // output generation state
    else if (button == 1) begin
      count_en <= 1;
      count <= 0;
      debounce <= 1;
    end
  end

endmodule
