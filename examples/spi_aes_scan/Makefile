# ==============================================================================
# Project configuration
# ==============================================================================

# List of source files
SYNTH_SOURCES = spi_aes_scan_top.v \
				scan_shift_register.v \
				scan_register.v \
				aes_core_static_128_scanchain.v \
				aes/aes_sbox_lut.v \
				aes/aes_sbox.v \
				aes/aes_ks_static_128.v \
				aes/aes_mixcolumns_inv.v \
				aes/aes_mixcolumns.v \
				aes/aes_shiftrows_inv.v \
				aes/aes_shiftrows.v \
				aes/aes_sboxes.v
SIM_SOURCES = aes_core_tb.v $(SYNTH_SOURCES)
PCF_SOURCE = spi_aes_scan.pcf

# Top-level module
SYNTH_TOP_MODULE = spi_aes_scan_top
SIM_TOP_MODULE = aes_core_tb

#SIM_SOURCES = aes_ks_static_128_tb.v $(SYNTH_SOURCES)
#SIM_TOP_MODULE = aes_ks_static_128_tb

include ../hackster.mk
