# design under test
DUT = h264_dctransform_tb
RTL_DIR := 
# dut parameters
ifeq ($(DUT), h264_dctransform_tb)
	SRCS := \
		$(RTL_DIR)*.sv	\
    	$(RTL_DIR)../../rtl/dctransform/*.sv	
    		
endif

all: compile sim

compile:
	vlog $(SRCS)

sim:
	vsim -c -voptargs=+acc $(DUT) -do "run -all"

clean:
	rm -rf work transcript *.wlf
	
