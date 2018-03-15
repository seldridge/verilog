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

// Uart receiver module. Reads data from a serial UART line (rx) and
// outputs it over a parallel bus (data) based on the clock frequency
// of the FPGA and the anticipated UART frequency.

//`define PARITY                          // enable parity bit (not implemented)
module uart_rx
  #(
    parameter
    CLK_FREQUENCY = 66_000_000,         // fpga clock frequency
    UART_FREQUENCY = 921_600            // UART clock frequency
    )
  (
   input            clk, rst_n, rx,     // 1-bit inputs
   output reg       valid,              // signals that data is valid
   output reg [7:0] data                // output parallel data
   );

  reg [2:0]         state, next_state;  // state/next state variables
  reg [3:0]         bit_count;          // remembers the bit that we're on
  reg [7:0]         data_tmp;           // stores intermediate values for data
  reg [14:0]        tick_count;         // used to know when to read rx line

  localparam
    TICKS_PER_BIT       = CLK_FREQUENCY / UART_FREQUENCY,
    HALF_TICKS_PER_BIT  = TICKS_PER_BIT / 2,
    NUM_BITS            = 4'd8;

  localparam
    IDLE   = 3'd0,                      // wait for a transmission to come in
    START  = 3'd1,                      // start bit
    DATA   = 3'd2,                      // data bits
//    PARITY = 3'd3,                      // parity bit (not implemented)
    VALID  = 3'd4,                      // output valid data
    STOP   = 3'd5;                      // stop bit

  always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_count <= 15'b0;
      bit_count  <= 4'b0;
    end
    else begin
      case (state)
        START: begin
          tick_count <= (tick_count==HALF_TICKS_PER_BIT) ? 15'b0 : tick_count + 15'b1;
          bit_count  <= 4'b0;
        end
        DATA: begin
          tick_count <= (tick_count==TICKS_PER_BIT-1) ? 15'b0 :
                        tick_count + 15'b1;
          bit_count  <= (tick_count==TICKS_PER_BIT-1) ? bit_count + 1 :
                        bit_count;
        end
        VALID: begin
          tick_count <= tick_count + 15'b1;
        end
        STOP: begin
          tick_count <= (tick_count==TICKS_PER_BIT-1) ? 15'b0 :
                        tick_count + 15'b1;
        end
        default: begin
          tick_count <= 15'b0;
          bit_count  <= 4'b0;
        end
      endcase
    end
  end

  always @ (posedge clk or negedge rst_n)
    state <= (!rst_n) ? IDLE : next_state;

  always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data     <= 8'b0;
      data_tmp <= 8'b0;
      valid    <= 1'b0;
    end
    else begin
      data     <= 8'bx;
      data_tmp <= data_tmp;
      valid    <= 0;
      case (state)
        IDLE: data_tmp       <= 8'bx;
        START: data_tmp      <= 8'bx;
        DATA: if (tick_count == TICKS_PER_BIT-1) data_tmp[bit_count] <= rx;
        VALID: begin
          data  <= data_tmp;
          valid <= 1'b1;
        end
        STOP: data_tmp <= 8'bx;
      endcase
    end
  end

  always @ * begin
    case (state)
      IDLE: next_state     = (!rx)                              ? START : state;
      START: next_state    = (tick_count==HALF_TICKS_PER_BIT)   ? DATA : state;
      DATA: next_state     = ((tick_count==TICKS_PER_BIT - 1) &
                              (bit_count==NUM_BITS - 1))?VALID:state;
//      PARITY: next_state   = () ? : state;
      VALID: next_state    = STOP;
      STOP: next_state     = (tick_count==TICKS_PER_BIT-1)        ? IDLE : state;
      default: next_state  = IDLE;
    endcase
  end

endmodule
