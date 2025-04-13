# Define variables
TOP_MODULE = tb_me
SRC_FILES = me.sv datapath_me.sv controller_me.sv comparator.sv mux2x1.sv mux4x1.sv pe_col.sv
SRC_FILES += pe_matrix.sv pe.sv register.sv sum.sv tb_me.sv
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
	vsim -L $(WORK_DIR) $(TOP_MODULE) -do "add wave -radix Unsigned sim:/$(TOP_MODULE)/ins_me/ins_controller_me/*; run 2000"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) transcript vsim.wlf

.PHONY: all compile simulate clean
