from machine import Pin, I2C
import time

i2c = I2C(0, scl=Pin(1), sda=Pin(0), freq=100_000)

# scan all I2C addresses and print any devices found
devices = i2c.scan()
print("I2C devices found:", devices, [hex(d) for d in devices])