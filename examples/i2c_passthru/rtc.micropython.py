from machine import Pin, I2C
import time

# PCF8563 7-bit I2C address
RTC_ADDR = 0x51

i2c = I2C(0, scl=Pin(1), sda=Pin(0), freq=100_000)

def bcd(n):
    return ((n // 10) << 4) | (n % 10)

def de_bcd(x):
    return ((x >> 4) * 10) + (x & 0x0F)

def set_pcf8563(year, month, day, weekday, hour, minute, second=0):
    yy = year % 100
    century_bit = 0   # convention here: 0 means 2000..2099

    buf = bytes([
        bcd(second) & 0x7F,                           # seconds, VL bit cleared
        bcd(minute) & 0x7F,                           # minutes
        bcd(hour) & 0x3F,                             # hours
        bcd(day) & 0x3F,                              # day
        weekday & 0x07,                               # weekday
        ((century_bit & 0x01) << 7) | (bcd(month) & 0x1F),  # month + century
        bcd(yy),                                      # year
    ])

    # Write registers 0x02..0x08 in one transaction
    i2c.writeto_mem(RTC_ADDR, 0x02, buf)

def read_pcf8563():
    # Read registers 0x02..0x08 in one transaction
    buf = i2c.readfrom_mem(RTC_ADDR, 0x02, 7)

    vl = (buf[0] >> 7) & 0x01
    second = de_bcd(buf[0] & 0x7F)
    minute = de_bcd(buf[1] & 0x7F)
    hour = de_bcd(buf[2] & 0x3F)
    day = de_bcd(buf[3] & 0x3F)
    weekday = buf[4] & 0x07
    century_bit = (buf[5] >> 7) & 0x01
    month = de_bcd(buf[5] & 0x1F)

    # Same convention as set_pcf8563()
    year = 2000 + de_bcd(buf[6]) + (100 if century_bit else 0)

    return {
        "year": year,
        "month": month,
        "day": day,
        "weekday": weekday,
        "hour": hour,
        "minute": minute,
        "second": second,
        "voltage_low_flag": vl,
    }

# Check I2C bus
devices = i2c.scan()
print("I2C devices found:", devices, [hex(d) for d in devices])

if RTC_ADDR not in devices:
    print("PCF8563 not found at 0x51")
else:
    # Set RTC to 1 January 2026, 09:00:00
    # Thursday = 4
    set_pcf8563(2026, 1, 1, 4, 9, 0, 0)
    print("RTC set to 2026-01-01 09:00:00")

    # Poll forever every 5 seconds
    while True:
        rtc_data = read_pcf8563()

        print(
            "{year:04d}-{month:02d}-{day:02d} "
            "{hour:02d}:{minute:02d}:{second:02d} "
            "weekday={weekday} VL={voltage_low_flag}".format(**rtc_data)
        )

        time.sleep(3)
