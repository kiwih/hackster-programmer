import machine

global_sda = machine.Pin(0, machine.Pin.IN)
global_scl = machine.Pin(1, machine.Pin.IN)

target = 0x42
txbuf = bytearray([0x00])

#two options either 1 or 2
method = 2

if method == 1:
    #option 1: using underlying hardware at speed

    i2c = machine.I2C(0, scl=global_scl, sda=global_sda)
    
    i2c.writeto(target, txbuf)
    
elif method == 2:
    #option 2: slower piecemeal using the components of softI2C and displaying state of internal i2c register at each phase
    addrbuf = bytearray([target << 1])
    
    i2c_state_3 = machine.Pin(11)
    i2c_state_2 = machine.Pin(10)
    i2c_state_1 = machine.Pin(9)
    i2c_state_0 = machine.Pin(8)

    i2c = machine.SoftI2C(scl=global_scl, sda=global_sda, freq=10000)

    print("State: %d%d%d%d\n" % (i2c_state_3.value(), i2c_state_2.value(), i2c_state_1.value(), i2c_state_0.value()))
    i2c.start()
    print("State: %d%d%d%d\n" % (i2c_state_3.value(), i2c_state_2.value(), i2c_state_1.value(), i2c_state_0.value()))
    num_acks = i2c.write(addrbuf)
    print("State: %d%d%d%d, acks:%d\n" % (i2c_state_3.value(), i2c_state_2.value(), i2c_state_1.value(), i2c_state_0.value(), num_acks))
    num_acks = i2c.write(txbuf)
    print("State: %d%d%d%d, acks:%d\n" % (i2c_state_3.value(), i2c_state_2.value(), i2c_state_1.value(), i2c_state_0.value(), num_acks))
    i2c.stop()
    print("State: %d%d%d%d\n" % (i2c_state_3.value(), i2c_state_2.value(), i2c_state_1.value(), i2c_state_0.value()))


