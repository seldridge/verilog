## Description

Repository for Verilog building blocks with a high chance of reuse
across different hardware projects (e.g. debouncers, display drivers).

Most of these modules are well tested and shouldn't have issues.
However, I'm generally allowing myself to upload things which *may*
have issues.

## Modules

* `button_debounce.v` -- Timing-based button debouncing circuit.

* `pipeline_registers.v` -- A parameterized number of pipeline
  registers of some depth and width. This is primarily useful as a
  building block for _other_ modules.

* `pipeline_registers_set.v` -- Pipeline registers (as above), but
  with the ability to _set_ the value of the registers.

* `ram_infer.v` -- Xilinx standard module that will infer RAM during
  FPGA synthesis.

* `reset.v` -- Implements a "good" reset with asynchronous assertion
  and synchronous de-assertion.

* `sign_extender.v` -- Explicit sign extender (this should be
  unnecessary in Verilog...)

* `sqrt_pipelined.v` -- A pipelined implementation of a fixed point
  square root.

* `uart_rx.v` -- UART receiver.

* `uart_tx.v` -- UART transmitter.

* `div_pipelined.v` -- Pipelined division module (**largely untested**)
