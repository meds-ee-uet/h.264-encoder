# Define variables
MODULE_PATH = ../../rtl/inter_mc
TOP_MODULE = tb_mc
SRC_FILES = $(MODULE_PATH)/*.sv *.sv
WORK_DIR = work


# Default target
all: compile wave

# opengui: compile wave

# Create a working library and compile source files
compile:
	@echo "Creating work library..."
	vlib $(WORK_DIR)
	@echo "Compiling source files..."
	vlog -work $(WORK_DIR) $(SRC_FILES)

# Run the simulation and generate WLF file
wave: compile
	@echo "Running simulation..."
	vsim -L $(WORK_DIR) $(TOP_MODULE) -do "add wave -radix Unsigned sim:/$(TOP_MODULE)/*; run 2000"

simulate: compile
	@echo "Running simulation..."
	vsim -c $(WORK_DIR) $(TOP_MODULE) -do "run -all"


# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) transcript vsim.wlf tb_me.vcd

.PHONY: all compile simulate clean
