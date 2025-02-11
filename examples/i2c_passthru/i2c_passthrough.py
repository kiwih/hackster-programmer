import machine

global_sda = machine.Pin(0)
global_scl = machine.Pin(1)

i2c = machine.I2C(id=0, scl=global_scl, sda=global_sda)

print(i2c.scan())