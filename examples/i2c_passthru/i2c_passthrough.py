from machine import I2C, Pin
import time

i2c = machine.I2C(1, scl = machine.Pin(7), sda = machine.Pin(6), freq = 100000)

# Print all peripheral addresses (EEPROM and accelerometer)
print(i2c.scan())

# Initialise EEPROM for later exercise
i2c.writeto_mem(0x50, 0x12, bytes([0x51]))
time.sleep(0.01)

########### TODO #################
# Write one data byte to EEPROM at the designated address. Capture the oscillopscope screenshot.
# For example, if my zid is 5248098, I will write data 0x98 to address 0x98.


time.sleep(0.01)



########### TODO #################
# Read one data byte from EEPROM at the designated address. Capture the oscillopscope screenshot.
# For example, if my zid is 5248098, I will read data from address 0x98. My expected data should be 0x98.
