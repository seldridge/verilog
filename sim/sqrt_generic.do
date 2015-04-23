vlog -sv +incdir+../src+../src/include ../src/t_sqrt_generic.v
vsim -voptargs=+acc work.t_sqrt_generic
run -all
