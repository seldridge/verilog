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
  square root. **Deprecated due to complexity and incorrect rounding**.

* `sqrt_generic.v` -- A refactor of `sqrt_pipelined.v` into a cleaner
  syntax. This uses implicit truncation rounding and will show a
  resulting bias towards negative infinity.

* `uart_rx.v` -- UART receiver.

* `uart_tx.v` -- UART transmitter.

* `div_pipelined.v` -- Pipelined division module (**largely untested**)

## Submodules

In an attempt at modularity, I'm now including a submodules directory
which is intended to contain other repositories (of mine most likely,
but not restricted as such) that are useful. These can be pulled in
with:

```
git submodule init
git submodule update
```

And recursively updated with:

```
git submodule foreach git pull origin master
```

* [hdl-tools](https://github.com/ibm/hdl-tools) --
  Basically, a dumping ground of scripts I've written that make
  working with HDLs easier. For example, `addWavesRecursive.tcl` will
  populate a GTKWave configuration with the module hierarchy found in
  a VCD file.
