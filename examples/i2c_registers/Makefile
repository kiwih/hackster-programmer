# Makefile for the hackster
# ==============================================================================
# Configuration area:
# ==============================================================================

# List of source files
SYNTH_SOURCES = i2c_reg_and_pass.v i2c_simple_slave.v i2c_pin_primitives_ice40.v
SIM_SOURCES = i2c_simple_slave_tb.v i2c_simple_slave.v
PCF_SOURCE = i2c_registers.pcf

# Top-level module
SYNTH_TOP_MODULE = i2c_reg_and_pass
SIM_TOP_MODULE = i2c_simple_slave_tb

# Programmer port
FPGA_PORT ?= /dev/ttyACM1

# Chip settings
FREQUENCY = 10
PACKAGE = sg48

# Output file for the compiled simulation
SIM_OUT = $(SIM_TOP_MODULE).vvp

# GTKWave output file
WAVE_OUT = waveform.vcd

# Synthesis output files
SYNTH_OUT = $(SYNTH_TOP_MODULE).json
PNR_OUT = $(SYNTH_TOP_MODULE).asc
TIMING_OUT = $(SYNTH_TOP_MODULE).timings
BITSTREAM = $(SYNTH_TOP_MODULE).bin

# ==============================================================================
# Tools and scripts
# ==============================================================================

#### Docker commands ####
# Docker command for accessing the image
DOCKER = docker run -t -v .:/mount --device=$(FPGA_PORT) hackster-deps:v1

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
PROGRAMMER = $(DOCKER) hackster-fpga

# ==============================================================================
# Targets 
# ==============================================================================

### Simulation targets ###

# Target for compiling the Verilog source files
compile_sim: $(SIM_SOURCES)
	$(SIM) $(CFLAGS) -o $(SIM_OUT) -s $(SIM_TOP_MODULE) $(SIM_SOURCES)

# Target for running the simulation
simulate: compile_sim
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
	$(SYNTH) -p "synth_ice40 -top $(SYNTH_TOP_MODULE) -json $(SYNTH_OUT)" $(SYNTH_SOURCES)

# Target for place and route
$(PNR_OUT): $(SYNTH_OUT) $(PCF_SOURCE)
	$(PNR) --force --json $(SYNTH_OUT) --pcf $(PCF_SOURCE) --asc $(PNR_OUT) --freq $(FREQUENCY) --up5k --package $(PACKAGE)

# Target for timing analysis
timing: $(PNR_OUT)
	$(TIMING) -p $(PCF_SOURCE) -P $(PACKAGE) -r $(TIMING_OUT) -d up5k -t $(PNR_OUT)

# Target for generating the bitstream
bitstream: $(PNR_OUT)
	$(PACK) $(PNR_OUT) $(BITSTREAM)

# Clean up the generated files
clean:
	rm -f $(SIM_OUT) $(WAVE_OUT) $(SYNTH_OUT) $(PNR_OUT) $(TIMING_OUT) $(BITSTREAM)

### Programming targets ###
program: bitstream
	$(PROGRAMMER) w $(BITSTREAM) $(FPGA_PORT) 

program_power: bitstream
	$(PROGRAMMER) p $(BITSTREAM) $(FPGA_PORT)

# ==============================================================================
# Recipe area
# ==============================================================================

# Simulate and view
run_sim: compile_sim simulate view

# Synthesize and generate the bitstream
run_synth: timing bitstream

# Programmer
run_fpga: run_synth program

# Programmer and power measurement
run_fpga_power: run_synth program_power

# Phony targets for make
.PHONY: synth pnr timing bitstream run_sim run_synth run_fpga run_fpga_power
