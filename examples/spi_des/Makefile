# ==============================================================================
# Project configuration
# ==============================================================================

# List of source files
SYNTH_SOURCES = spi_des_top.v \
				des_fixedkey_fsm.v \
				des_fixedkey.v \
				generic_register.v \
				shift_register.v \
				des/des_e.v \
				des/des_f.v \
				des/des_ip_inv.v \
				des/des_ip.v \
				des/des_keyrotate.v \
				des/des_p.v \
				des/des_pc1.v \
				des/des_pc2.v \
				des/des_roundkey_rom.v \
				des/des_s1.v \
				des/des_s2.v \
				des/des_s3.v \
				des/des_s4.v \
				des/des_s5.v \
				des/des_s6.v \
				des/des_s7.v \
				des/des_s8.v

SIM_SOURCES = $(SYNTH_SOURCES) des_fixedkey_tb.v
PCF_SOURCE = spi_des.pcf

# Top-level module
SYNTH_TOP_MODULE = spi_des_top
SIM_TOP_MODULE = des_fixedkey_tb

include ../hackster.mk
