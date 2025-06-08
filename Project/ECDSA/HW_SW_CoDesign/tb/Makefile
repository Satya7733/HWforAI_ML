TOPLEVEL_LANG = verilog

# All required Verilog source files
VERILOG_SOURCES = ../src/mod_add.v \
                  ../src/mod_inv.v \
                  ../src/mod_mul.v \
                  ../src/mod_sub.v \
                  ../src/point_add.v \
                  ../src/scalar_mul.v

# Top-level Verilog module
TOPLEVEL = scalar_mul

# Python testbench (file: test_hw_sign.py)
MODULE = test_hw_sign

# Python search path to find ecdsa_host.py
PYTHONPATH := ../sw:.

# Simulation tool
SIM = questa

# Include standard cocotb rules
include $(shell cocotb-config --makefiles)/Makefile.sim
