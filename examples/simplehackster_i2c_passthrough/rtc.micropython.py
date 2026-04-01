from machine import Pin, I2C
import time

# PCF8563 7-bit I2C address
RTC_ADDR = 0x51

# RP2040 / Pico example pins: SDA=GP2, SCL=GP3
i2c = I2C(0, scl=Pin(1), sda=Pin(0), freq=100_000)

def bcd(n):
    return ((n // 10) << 4) | (n % 10)

def de_bcd(x):
    return ((x >> 4) * 10) + (x & 0x0F)

def set_pcf8563(year, month, day, weekday, hour, minute, second=0):
    # Convention used here:
    # century bit 0 => 2000..2099
    yy = year % 100
    century_bit = 0

    # Registers 0x02..0x08:
    # 0x02 VL_seconds
    # 0x03 minutes
    # 0x04 hours
    # 0x05 days
    # 0x06 weekdays
    # 0x07 century_months
    # 0x08 years
    buf = bytes([
        bcd(second) & 0x7F,                           # clear VL bit
        bcd(minute) & 0x7F,
        bcd(hour) & 0x3F,
        bcd(day) & 0x3F,
        weekday & 0x07,
        ((century_bit & 0x01) << 7) | (bcd(month) & 0x1F),
        bcd(yy),
    ])

    # One single write access from seconds through years
    i2c.writeto_mem(RTC_ADDR, 0x02, buf)

def read_pcf8563():
    # One single read access from seconds through years
    buf = i2c.readfrom_mem(RTC_ADDR, 0x02, 7)

    vl = (buf[0] >> 7) & 0x01
    second = de_bcd(buf[0] & 0x7F)
    minute = de_bcd(buf[1] & 0x7F)
    hour = de_bcd(buf[2] & 0x3F)
    day = de_bcd(buf[3] & 0x3F)
    weekday = buf[4] & 0x07
    century_bit = (buf[5] >> 7) & 0x01
    month = de_bcd(buf[5] & 0x1F)
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

# Check that the RTC is visible
devices = i2c.scan()
print("I2C devices:", devices, [hex(d) for d in devices])

# Set to 1 January 2026, 09:00:00
# Thursday = 4 using the datasheet's weekday table
set_pcf8563(2026, 1, 1, 4, 9, 0, 0)

# Small delay, then read it back
time.sleep_ms(20)

rtc_data = read_pcf8563()
print("RTC readback:", rtc_data)

print("{year:04d}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d} weekday={weekday}".format(**rtc_data))