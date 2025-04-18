# Define variables
TOP_MODULE = tb_me
SRC_FILES = tb_me.sv ../../rtl/inter_prediction/*.sv
WORK_DIR = work


# Default target
all: compile simulate

opengui: compile wave

# Create a working library and compile source files
compile:
	@echo "Creating work library..."
	vlib $(WORK_DIR)
	@echo "Compiling source files..."
	vlog -work $(WORK_DIR) $(SRC_FILES)

# Run the simulation and generate WLF file
wave:
	@echo "Running simulation..."
	vsim -L $(WORK_DIR) $(TOP_MODULE) -do "add wave -radix Unsigned sim:/$(TOP_MODULE)/ins_me/ins_controller_me/*; run 2000"

simulate:
	@echo "Running simulation..."
	vsim -c $(WORK_DIR) $(TOP_MODULE) -do "run -all"


# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) transcript vsim.wlf tb_me.vcd

.PHONY: all compile simulate clean
