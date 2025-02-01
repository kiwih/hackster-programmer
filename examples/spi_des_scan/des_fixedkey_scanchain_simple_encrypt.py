import machine
import binascii

def main():
    ice_done = machine.Pin(3, machine.Pin.IN)

    SCK = machine.Pin(6, machine.Pin.OUT)
    RST_N = machine.Pin(7, machine.Pin.OUT)
    MOSI = machine.Pin(8, machine.Pin.OUT)
    MISO = machine.Pin(9, machine.Pin.IN)
    NORM_CS_N = machine.Pin(10, machine.Pin.OUT)
    SCAN_CS_N = machine.Pin(11, machine.Pin.OUT)
    START = machine.Pin(12, machine.Pin.OUT)
    ENCRYPT_NDECRYPT = machine.Pin(13, machine.Pin.OUT)
    BUSY = machine.Pin(14, machine.Pin.IN)

    SCK.value(0)
    RST_N.value(1)
    NORM_CS_N.value(1)
    SCAN_CS_N.value(1)
    START.value(0)
    ENCRYPT_NDECRYPT.value(1)

    spi = machine.SoftSPI(baudrate=50000, polarity=0, phase=0, bits=8, firstbit=machine.SPI.MSB, sck=SCK, mosi=MOSI, miso=MISO)

    #reset the DES core

    RST_N.value(0)
    SCK.value(1)
    SCK.value(0)
    RST_N.value(1)
    SCK.value(1)
    SCK.value(0)

    # engage the input SPI
    plaintext = bytearray([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04])
    ciphertext = bytearray([0x45, 0x4c, 0xf2, 0x6d, 0xb6, 0xca, 0x57, 0x1a])
    
    txdata = plaintext
    rxdata = bytearray(8)
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
        print("DES successfully busy")
    else:
        print("Error: DES did not go busy")
        return
    
    #run 18 clock cycles to finish the system
    # (19 clock cycles total:
    # 1 IDLE state  -                               transition IDLE->START
    # 2 START state - captures input, busy is high  transition START->ROUND
    # 3 ROUND state, count 0 -
    # 4 ROUND state, count 1
    # 5 ROUND state, count 2
    # 6 ROUND state, count 3
    # 7 ROUND state, count 4
    # 8 ROUND state, count 5
    # 9 ROUND state, count 6
    #10 ROUND state, count 7
    #11 ROUND state, count 8
    #12 ROUND state, count 9
    #13 ROUND state, count 10
    #14 ROUND state, count 11
    #15 ROUND state, count 12
    #16 ROUND state, count 13
    #17 ROUND state, count 14
    #18 LASTROUND state, count 15, requests ld_output
    #19 IDLE state, output is loaded, busy is now no longer being emitted
    for i in range(18):
        SCK.value(1)
        SCK.value(0)
          
    if(BUSY.value() == 0):
        print("DES successfully finished")
    else:
        print("Error: DES did not finish")
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
    rxdata = bytearray(8)
    NORM_CS_N.value(0)
    spi.write(txdata)
    NORM_CS_N.value(1)
    
    START.value(1)
    SCK.value(1)
    SCK.value(0)
    START.value(0)
    
    if(BUSY.value() == 1):
        print("DES successfully busy")
    else:
        print("Error: DES did not go busy")
        return
    
    for i in range(18):
        SCK.value(1)
        SCK.value(0)
        
        
    if(BUSY.value() == 0):
        print("DES successfully finished")
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
    


