import machine
import binascii

def main():
    ice_done = machine.Pin(3, machine.Pin.IN)

    SCK = machine.Pin(6, machine.Pin.OUT)
    RST_N = machine.Pin(7, machine.Pin.OUT)
    MOSI = machine.Pin(8, machine.Pin.OUT)
    MISO = machine.Pin(9, machine.Pin.IN)
    NORM_CS_N = machine.Pin(10, machine.Pin.OUT)
    START = machine.Pin(12, machine.Pin.OUT)
    ENCRYPT_NDECRYPT = machine.Pin(13, machine.Pin.OUT)
    BUSY = machine.Pin(14, machine.Pin.IN)

    SCK.value(0)
    RST_N.value(1)
    NORM_CS_N.value(1)
    START.value(0)
    ENCRYPT_NDECRYPT.value(1)

    spi = machine.SoftSPI(baudrate=50000, polarity=0, phase=0, bits=8, firstbit=machine.SPI.MSB, sck=SCK, mosi=MOSI, miso=MISO)

    #reset the AES core

    RST_N.value(0)
    SCK.value(1)
    SCK.value(0)
    RST_N.value(1)
    SCK.value(1)
    SCK.value(0)

    # engage the input SPI
    plaintext = bytearray([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    #for key FE F9 54 5B B7 A4 5D FD
    ciphertext = bytearray([0xbb, 0x54, 0x32, 0x94, 0xc6, 0x36, 0xda, 0x27, 0xe6, 0x70, 0x1c, 0x7e, 0x66, 0x81, 0x4a, 0x19])
    
    txdata = plaintext
    rxdata = bytearray(16)
    NORM_CS_N.value(0)
    spi.write(txdata)
    NORM_CS_N.value(1)

    #do a test readout
    NORM_CS_N.value(0)
    spi.write_readinto(txdata, rxdata)
    NORM_CS_N.value(1)

    if txdata == rxdata:
        print("SPI functional test pass")
    else:
        print("Error: SPI error")
        return
       
    START.value(1)
    SCK.value(1)
    SCK.value(0)
    START.value(0)
    
    if(BUSY.value() == 1):
        print("AES successfully busy")
    else:
        print("Error: AES did not go busy")
        return
    
    
    
    
    
    #run 12 clock cycles to finish the system
    # (13 clock cycles total:
    # 1 IDLE state                                
    # 2 INIT state 
    # 3-12 ROUND state
    # 13 IDLE state, output is loaded, busy is now no longer being emitted
    for i in range(12):
        SCK.value(1)
        SCK.value(0)
          
    if(BUSY.value() == 0):
        print("AES successfully finished")
    else:
        print("Error: AES did not finish")
        return
    
    #do the readout
    NORM_CS_N.value(0)
    spi.write_readinto(txdata, rxdata)
    NORM_CS_N.value(1)
    if rxdata != ciphertext:
        print("Encryption failed, got", binascii.hexlify(rxdata), "expected", binascii.hexlify(ciphertext))
    else:
        print("Encryption value correct:", binascii.hexlify(rxdata))
    
    #now do decryption
    ENCRYPT_NDECRYPT.value(0)
    txdata = ciphertext
    rxdata = bytearray(16)
    NORM_CS_N.value(0)
    spi.write(txdata)
    NORM_CS_N.value(1)
    
    START.value(1)
    SCK.value(1)
    SCK.value(0)
    START.value(0)
    
    if(BUSY.value() == 1):
        print("AES successfully busy")
    else:
        print("Error: AES did not go busy")
        return
    
    for i in range(12):
        SCK.value(1)
        SCK.value(0)
        
        
    if(BUSY.value() == 0):
        print("AES successfully finished")
    else:
        print("Error: DES did not finish")
        return
    
    #do the readout
    NORM_CS_N.value(0)
    spi.write_readinto(txdata, rxdata)
    NORM_CS_N.value(1)
    if rxdata != plaintext:
        print("Decryption failed, got", binascii.hexlify(rxdata), "expected", binascii.hexlify(plaintext))
    else:
        print("Decryption value correct:", binascii.hexlify(rxdata))

main()
    



