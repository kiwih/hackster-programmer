# Makefile for the hackster
# ==============================================================================
# Configuration area:
# ==============================================================================

# List of source files
SYNTH_SOURCES = top.v \
				aes_core_static_128.v \
				aes/aes_sbox_lut.v \
				aes/aes_sbox.v \
				aes/aes_ks_static_128.v \
				aes/aes_mixcolumns_inv.v \
				aes/aes_mixcolumns.v \
				aes/aes_shiftrows_inv.v \
				aes/aes_shiftrows.v \
				aes/aes_sboxes.v \
				aes/aes_sboxes4.v \
				signal_amplify.v 
SIM_SOURCES = aes_core_tb.v top_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = top.pcf

# Top-level module
SYNTH_TOP_MODULE = top
SIM_TOP_MODULE = aes_core_tb

PROGRAMMER_COMMAND = python3 hackster-fpga-program.py
NUM_CAPTURE_POWER_BLOCKS = 5000

include ../hackster.mk