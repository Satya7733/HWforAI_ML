lappend search_path ./src/
set target_library osu05_stdcells.db
set link_library [concat "*" $target_library]
current_design scalar_mul_serial_top

analyze -format sverilog {src/scalar_mul_serial_top.v  src/mod_add.v  src/mod_inv.v  src/mod_mul.v  src/mod_sub.v  src/point_add.v  src/scalar_mul.v}

set target_library osu05_stdcells.db
set link_library [concat "*" $target_library]
current_design scalar_mul_serial_top


elaborate scalar_mul_serial_top -architecture verilog -library work

current_design scalar_mul_serial_top

set target_library osu05_stdcells.db
set link_library [concat "*" $target_library]

link

create_clock clk -period 50 -waveform {0 25}

report_port
check_design
compile -exact_map

report_area
report_cell
report_power
report_timing

write -format Verilog -hierarchy -output scalar_mul_serial_top.netlist
write -format ddc -hierarchy -output scalar_mul_serial_top.ddc

