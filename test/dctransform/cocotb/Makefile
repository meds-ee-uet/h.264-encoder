# Makefile

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../h264dc_transform.sv $(PWD)/../h264dc_transform_controller.sv $(PWD)/wrapper/h264dc_transform_wrapper.sv
#$(PWD)/wrapper/h264coretransform_wrapper.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = h264dc_transform_wrapper

# MODULE is the basename of the Python test file
MODULE = testbench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim


clean_files:
	rm -rf results.xml __pycache__ sim_build
