# ==============================================================================
# Project configuration
# ==============================================================================

# List of source files
SYNTH_SOURCES = spi_aes_top.v \
				shift_register.v \
				aes_core.v \
				aes/aes_ks.v \
				aes/aes_sbox_lut.v \
				aes/aes_sbox.v
SIM_SOURCES = aes_core_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = spi_aes.pcf

# Top-level module
SYNTH_TOP_MODULE = top
SIM_TOP_MODULE = aes_core_tb

include ../hackster.mk
