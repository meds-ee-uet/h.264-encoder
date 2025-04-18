# design under test
DUT = h264intra4x4_tb
RTL_DIR := 
# dut parameters
ifeq ($(DUT), h264intra4x4_tb)
	SRCS := \
		$(RTL_DIR)*.sv	\
		$(RTL_DIR)../../rtl/intra4x4/*.sv
endif

all: compile sim
simulation: compile wave

compile:
	vlog $(SRCS)

sim:
	vsim -c -voptargs=+acc $(DUT) -do "run -all"

wave:
	vsim -L -voptargs=+acc $(DUT) -do "add wave sim:/$(DUT)/UUT/* ;run -all"

clean:
	rm -rf work transcript *.wlf
