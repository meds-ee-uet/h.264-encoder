# Define variables
TOP_MODULE = testbench_file
SRC_FILES = controller.sv datapath.sv testbench_file.sv
WORK_DIR = work


# Default target
all: compile simulate

# Create a working library and compile source files
compile:
	@echo "Creating work library..."
	vlib $(WORK_DIR)
	@echo "Compiling source files..."
	vlog -work $(WORK_DIR) $(SRC_FILES)

# Run the simulation and generate WLF file
simulate:
	@echo "Running simulation..."
	vsim -L $(WORK_DIR) $(TOP_MODULE) -do "add wave -radix Unsigned sim:/$(TOP_MODULE)/uut/*; run -all"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) transcript vsim.wlf

.PHONY: all compile simulate clean
