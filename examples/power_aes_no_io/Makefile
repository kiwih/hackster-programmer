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
				aes/aes_sboxes.v
SIM_SOURCES = top_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = top.pcf

# Top-level module
SYNTH_TOP_MODULE = top
SIM_TOP_MODULE = top_tb

include ../hackster.mk