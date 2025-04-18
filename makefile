# design under test
#DUT = h264topsim
#RTL_DIR := rtl
## dut parameters
#ifeq ($(DUT), h264topsim)
#	SRCS := \
#		$(RTL_DIR)/*/*.sv	\
#    	$(RTL_DIR)/*.sv	
#    		
#endif
#
#all: compile sim
#
#compile:
#	vlog $(SRCS)
#
#sim:
#	vsim -c -voptargs=+acc $(DUT) -do "run -all"
#
#clean:
#	rm -rf work transcript *.wlf
#
#*********************************************************************
#  * Filename :    Makefile
#  * Date     :    18-04-2025
#  * Author   :    Moazzam Ali
#  *
#  * Description:  Makefile for simulating and testing UETRV_PCORE
#  *********************************************************************

verilator   ?= verilator
ver-library ?= ver_work
WORK_DIR    ?= work
defines     ?= 
RTL_DIR 	:= rtl
top 		?= h264topsim
top_vsim    ?= tb

# default command line argument
max_cycles ?= 100000000000
vcd        ?= 0

src := 	bench/*.sv							\
		$(wildcard $(RTL_DIR)/*.sv) 		\
       	$(wildcard $(RTL_DIR)/*/*.sv)


#=======================================================================================================
#---------------------------------------Verilator Part--------------------------------------------------
#=======================================================================================================
verilate_command := $(verilator) +define+$(defines)	--cc $(src) --top-module $(top) -Wall -Wno-TIMESCALEMOD 			\
					-Wno-MULTIDRIVEN -Wno-CASEOVERLAP -Wno-WIDTH -Wno-UNOPTFLAT -Wno-IMPLICIT -Wno-PINMISSING -Wno-fatal \
					--timing --Mdir $(ver-library) --exe bench/h264topsim.cpp --trace-structs --trace				
verilate:
	@echo "Building verilator model"
	$(verilate_command)
	cd $(ver-library) && $(MAKE) -f Vh264topsim.mk

sim-verilate: verilate
	@echo
	@echo "simulation is started....."
	@echo
	$(ver-library)/Vh264topsim +vcd=$(vcd)

#=======================================================================================================
#-------------------------------------------Vsim  Part--------------------------------------------------
#=======================================================================================================
sim_vsim: 		compile simulate
opengui_vsim: 	compile wave

compile:
	@echo "Creating work library..."
	@echo "Compiling source files..."
	vlog $(src)
wave:
	@echo "Running simulation and Wave..."
	vsim -L -voptargs=+acc $(top_vsim) -do "add wave -radix Unsigned sim:/$(top_vsim)/*; run 2000"
simulate:
	@echo "Running simulation..."
	vsim -c -voptargs=+acc $(top_vsim) -do "run -all"

#=======================================================================================================
#------------------------------------------- Clean up generated files--------------------------------------------------
#=======================================================================================================
clean:
	@echo "Cleaning up..."
	rm -rf ver_work/  *.vcd work transcript *.wlf $(WORK_DIR)

.PHONY: all compile simulate clean verilate sim-verilate

	
