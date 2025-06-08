TOPLEVEL_LANG = verilog
VERILOG_SOURCES = ../rtl/scalar_mul.v ../rtl/point_add.v
TOPLEVEL = scalar_mul
MODULE = test_hw_sign
PYTHONPATH := ../sw:.
SIM = questa

include $(shell cocotb-config --makefiles)/Makefile.sim
