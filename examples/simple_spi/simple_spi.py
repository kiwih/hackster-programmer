import machine

ice_done = machine.Pin(3, machine.Pin.IN)

SCK = machine.Pin(6, machine.Pin.OUT)
RST_N = machine.Pin(7, machine.Pin.OUT)
MOSI = machine.Pin(8, machine.Pin.OUT)
MISO = machine.Pin(9, machine.Pin.IN)
NORM_CS_N = machine.Pin(10, machine.Pin.OUT)

SCK.value(0)
RST_N.value(1)
NORM_CS_N.value(1)

spi = machine.SoftSPI(baudrate=50000, polarity=0, phase=0, bits=8, firstbit=machine.SPI.MSB, sck=SCK, mosi=MOSI, miso=MISO)

# reset SPI
RST_N.value(0)
SCK.value(1)
SCK.value(0)
RST_N.value(1)
SCK.value(1)
SCK.value(0)

# engage the input SPI
txdata = bytearray([0x08])
rxdata = bytearray(1)

NORM_CS_N.value(0)
spi.write(txdata)
NORM_CS_N.value(1)

#do a test readout
NORM_CS_N.value(0)
spi.write_readinto(txdata, rxdata)
NORM_CS_N.value(1)

print(rxdata)

