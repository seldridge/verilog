vlib work
vlog -vlog01compat +incdir+../src+../include t_sqrt_generic.v
vsim -voptargs=+acc work.t_sqrt_generic
run -all
