set_units -time ns

# Define the clock
create_clock -name clk -period 50 [get_ports clk]

# Optional: Constrain input setup time for all inputs
set_input_delay 2.5 -clock clk [all_inputs]

# Optional: Constrain output delay for all outputs
set_output_delay 2.5 -clock clk [all_outputs]

# Optional (OpenLane-friendly): Set drive and load assumptions
set_drive 1 [all_inputs]
set_load 1 [all_outputs]
