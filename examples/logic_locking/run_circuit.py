import machine
import time


ice_done = machine.Pin(3, machine.Pin.IN) #always include this line

# input signals to FPGA
app_in = [
    machine.Pin(8, machine.Pin.OUT),
    machine.Pin(9, machine.Pin.OUT),
    machine.Pin(11, machine.Pin.OUT),
    machine.Pin(12, machine.Pin.OUT)
]

# key signals
app_key = [
    machine.Pin(13, machine.Pin.OUT),
    machine.Pin(14, machine.Pin.OUT),
    machine.Pin(15, machine.Pin.OUT)
]

# output signals
app_out = [
    machine.Pin(16, machine.Pin.IN),
    machine.Pin(17, machine.Pin.IN)
]

# leds
led1 = machine.Pin(18, machine.Pin.OUT) #signals to RP2040 LEDs
led2 = machine.Pin(19, machine.Pin.OUT)

led1.value(0)
led2.value(0)


while True:
    # Count from 0b0000 -> 0b1111
    for i in range(1 << 4):
        print("current input[3:0]:", ((i >> 3) & 1), ((i >> 2) & 1), ((i >> 1) & 1), (i & 1))
        app_in[3].value((i >> 3) & 1)
        app_in[2].value((i >> 2) & 1)
        app_in[1].value((i >> 1) & 1)
        app_in[0].value(i & 1)
        led1.value(app_out[0])
        led2.value(app_out[1])
        time.sleep(1)