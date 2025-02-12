# Makefile for the hackster
# ==============================================================================
# Configuration area:
# ==============================================================================

# List of source files
SYNTH_SOURCES = top.v \
				aes/aes_sbox_lut.v \
				aes/aes_sbox.v 

SIM_SOURCES = top_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = top.pcf

# Top-level module
SYNTH_TOP_MODULE = top
SIM_TOP_MODULE = top_tb

PROGRAMMER_COMMAND = python3 hackster-fpga-program.py
NUM_CAPTURE_POWER_BLOCKS = 4000

include ../hackster.mk