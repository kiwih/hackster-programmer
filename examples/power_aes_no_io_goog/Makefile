# Makefile for the hackster
# ==============================================================================
# Configuration area:
# ==============================================================================

# List of source files
SYNTH_SOURCES = top.v aes_core.v aes_ks.v aes_sbox_lut.v aes_sbox.v
SIM_SOURCES = top_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = top.pcf

# Top-level module
SYNTH_TOP_MODULE = top
SIM_TOP_MODULE = top_tb

include ../hackster.mk