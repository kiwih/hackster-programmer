# Programmer port
FPGA_PORT ?= /dev/ttyACM0

# Docker command for accessing the image
DOCKER_UART = docker run -t -v .:/mount --device=$(FPGA_PORT) hackster-deps:v1

# Specify the programmer
PROGRAMMER_COMMAND ?= hackster-fpga
PROGRAMMER = $(DOCKER_UART) $(PROGRAMMER_COMMAND)
PROGRAMMER_MAC = $(PROGRAMMER_COMMAND)

# Target for using the bitstream
BITSTREAM_UNLOCKED = $(ZID)_unlocked.bin
BITSTREAM_LOCKED = $(ZID)_locked.bin

program: $(BITSTREAM_SPI)
	$(PROGRAMMER) w $(BITSTREAM_SPI) $(FPGA_PORT) 

program_mac: $(BITSTREAM_SPI)
	$(PROGRAMMER_MAC) w $(BITSTREAM_SPI) $(FPGA_PORT)

program_locked: $(BITSTREAM_LOCKED)
	$(PROGRAMMER) p $(BITSTREAM_LOCKED) $(FPGA_PORT)

program_locked_mac: $(BITSTREAM_LOCKED)
	$(PROGRAMMER_MAC) p $(BITSTREAM_LOCKED) $(FPGA_PORT)


# Programmer
run_fpga: program

# Programmer (mac)
run_fpga_mac: program_mac

# Programmer
run_fpga_locked: program_locked

# Programmer (mac)
run_fpga_locked_mac: program_locked_mac

# TODO: Other things that will be needed (at least for generating student outputs):
# Simulate and view
# run_sim: compile_sim simulate view
# Synthesize and generate the bitstream
# run_synth: timing bitstream

.PHONY: run_fpga run_fpga_locked
