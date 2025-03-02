# ==============================================================================
# Hackster Makefile
# include this from a project Makefile
# ==============================================================================
# example:
# # List of source files
# SYNTH_SOURCES = rgb_demo.v
# SIM_SOURCES = rgb_demo_tb.v $(SYNTH_SOURCES)
# PCF_SOURCE = rgb_demo.pcf

# # Top-level module
# SYNTH_TOP_MODULE = rgb_demo
# SIM_TOP_MODULE = rgb_demo_tb

# include ../hackster.mk
# 
# end example
# ==============================================================================

# Programmer port
FPGA_PORT ?= /dev/ttyACM0

# Chip settings
FREQUENCY = 25
PACKAGE = sg48

# Output file for the compiled simulation
SIM_OUT = $(SIM_TOP_MODULE).vvp

# GTKWave output file
WAVE_OUT = waveform.vcd

OUTPUTNAME_ROOT ?= $(SYNTH_TOP_MODULE)

# Synthesis output files
SYNTH_OUT = $(OUTPUTNAME_ROOT).json
PNR_OUT = $(OUTPUTNAME_ROOT).asc
TIMING_OUT = $(OUTPUTNAME_ROOT).timings
BITSTREAM = $(OUTPUTNAME_ROOT).bin

# ==============================================================================
# Tools and scripts
# ==============================================================================

#### Docker commands ####
# Docker command for accessing the image
DOCKER = docker run -t -v .:/mount --user $$(id -u):$$(id -g) hackster-deps:v1 
DOCKER_UART = docker run -t -v .:/mount --device=$(FPGA_PORT) hackster-deps:v1

#### Simulation tools/settings ####
# Specify the simulator
SIM = $(DOCKER) iverilog
# Specify the VVP (Icarus Verilog simulation runtime) for running the simulation
VVP = $(DOCKER) vvp
# Specify the viewer
VIEWER = gtkwave
# Compilation flags
CFLAGS = -g2012


#### Synthesis tools/settings ####
# Specify the synthesizer
SYNTH = $(DOCKER) yosys
# Specify the place and route tool
PNR = $(DOCKER) nextpnr-ice40
# Specify the timing analysis tool
TIMING = $(DOCKER) icetime
# Specify the bitstream packer
PACK = $(DOCKER) icepack

##### Programming tools/settings ####
# Specify the programmer
PROGRAMMER_COMMAND ?= hackster-fpga
PROGRAMMER = $(DOCKER_UART) $(PROGRAMMER_COMMAND)
PROGRAMMER_MAC = python3 ../../hackster-fpga-program.py
NUM_CAPTURE_POWER_BLOCKS ?= 4

# ==============================================================================
# Targets 
# ==============================================================================

### Simulation targets ###

# Target for compiling the Verilog source files
$(SIM_OUT): $(SIM_SOURCES)
	$(SIM) $(CFLAGS) -o $(SIM_OUT) -s $(SIM_TOP_MODULE) $(SIM_SOURCES)

# Target for running the simulation
simulate: $(SIM_OUT)
	$(VVP) $(SIM_OUT)

# Target for viewing the waveform using GTKWave
view: $(WAVE_OUT)
	$(VIEWER) $(WAVE_OUT)

# Target for generating the waveform
$(WAVE_OUT): simulate
	# Assumes the testbench generates a VCD file named 'waveform.vcd' i.e. $(WAVE_OUT)

### Synthesis targets ###

# Target for synthesizing the design
$(SYNTH_OUT): $(SYNTH_SOURCES)
	$(SYNTH) -p "verilog_defines $(SYNTH_DEFINES); read -vlog2k $(SYNTH_SOURCES); synth_ice40 -top $(SYNTH_TOP_MODULE) -json $(SYNTH_OUT); verilog_defines -list"

# Target for place and route
$(PNR_OUT): $(SYNTH_OUT)
	$(PNR) --force --json $(SYNTH_OUT) --pcf $(PCF_SOURCE) --asc $(PNR_OUT) --freq $(FREQUENCY) --up5k --package $(PACKAGE)

# Target for timing analysis
$(TIMING_OUT): $(PNR_OUT)
	$(TIMING) -p $(PCF_SOURCE) -P $(PACKAGE) -r $(TIMING_OUT) -d up5k -t $(PNR_OUT)

# Target for generating the bitstream
$(BITSTREAM): $(PNR_OUT)
	$(PACK) $(PNR_OUT) $(BITSTREAM)

# Clean up the generated files
clean:
	rm -f $(SIM_OUT) $(WAVE_OUT) $(SYNTH_OUT) $(PNR_OUT) $(TIMING_OUT) $(BITSTREAM)

clean_all:
	rm -f *.vvp *.vcd *.json *.asc *.timings *.bin

### Programming targets ###
program: $(BITSTREAM)
	$(PROGRAMMER) w $(BITSTREAM) $(FPGA_PORT) 

program_mac: $(BITSTREAM)
	$(PROGRAMMER_MAC) w $(BITSTREAM) $(FPGA_PORT)

start: $(BITSTREAM)
	$(PROGRAMMER) s $(BITSTREAM) $(FPGA_PORT)

start_mac: $(BITSTREAM)
	$(PROGRAMMER_MAC) s $(BITSTREAM) $(FPGA_PORT)

program_power: $(BITSTREAM)
	$(PROGRAMMER) p $(BITSTREAM) $(FPGA_PORT) power_data.txt $(NUM_CAPTURE_POWER_BLOCKS)

program_power_mac: $(BITSTREAM)
	$(PROGRAMMER_MAC) p $(BITSTREAM) $(FPGA_PORT) power_data.txt $(NUM_CAPTURE_POWER_BLOCKS)

$(SYNTH_OUT).svg: $(SYNTH_SOURCES)
	$(SYNTH) -p "read -sv $(SYNTH_SOURCES); hierarchy -top $(SYNTH_TOP_MODULE); proc; opt; show -format svg -viewer none -prefix $(SYNTH_OUT); write_json simple.$(SYNTH_OUT)"


# ==============================================================================
# Recipe area
# ==============================================================================

# Simulate and view
run_sim: $(SIM_OUT) simulate view

# Synthesize and generate the bitstream
run_synth: $(TIMING_OUT) $(BITSTREAM)

# Programmer
run_fpga: run_synth program

# Programmer (mac)
run_fpga_mac: run_synth program_mac

# start the FPGA
start_fpga: start

# start the FPGA (mac)
start_fpga_mac: start_mac

# Programmer and power measurement
run_fpga_power: run_synth program_power

# Programmer and power measurement
run_fpga_mac_power: run_synth program_power_mac

# visualization: 
visualize: $(SYNTH_OUT).svg

# Phony targets for make
.PHONY: timing run_sim run_synth run_fpga run_fpga_power start_fpga run_fpga_mac run_fpga_mac_power start_fpga_mac visualize