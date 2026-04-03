# ==============================================================================
# Configuration area:
# ==============================================================================


######### Builds for Step 3 ############
SYNTH_SOURCES = i2c_read_write_rtc.v i2c_master.v i2c_pin_primitives_ice40.v
SIM_SOURCES = i2c_master_tb.v i2c_master.v ../i2c_registers/i2c_simple_slave.v
PCF_SOURCE = i2c_trojan.pcf
SYNTH_TOP_MODULE = i2c_read_write_rtc
SIM_TOP_MODULE = i2c_master_tb

# ######### Builds for Step 4 ############
# SYNTH_SOURCES = i2c_trojan_rtc.v i2c_master.v i2c_simple_slave.v i2c_pin_primitives_ice40.v
# PCF_SOURCE = i2c_trojan.pcf
# SYNTH_TOP_MODULE = i2c_trojan_rtc


include ../hackster.mk