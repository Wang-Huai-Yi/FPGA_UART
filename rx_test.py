import serial
import time

def send_u18_as_6bit_chunks(ser, value, delay=0.002):
    assert 0 <= value < (1 << 18)

    b0 = (value >> 0)  & 0x3F
    b1 = (value >> 6)  & 0x3F
    b2 = (value >> 12) & 0x3F

    ser.write(bytes([b0, b1, b2]))
    ser.flush()

    print(f"send: 0x{value:05X} -> [{b0:02X} {b1:02X} {b2:02X}]")
    time.sleep(delay)

port = '/dev/ttyUSB2'
baud = 9600

ser = serial.Serial(port, baudrate=baud, timeout=1)
time.sleep(1)

# =========================
# 1. 設定 max sequence
# =========================
send_u18_as_6bit_chunks(ser, 0x3FFFB)   # START
send_u18_as_6bit_chunks(ser, 556)       # max sequence
send_u18_as_6bit_chunks(ser, 0x3FFFC)   # END

time.sleep(0.1)

# =========================
# 2. 送 token stream
# =========================
send_u18_as_6bit_chunks(ser, 0x3FFFE)   # TOKENS_START

tokens = [
    # normal low tokens
    0x00001,
    0x00002,
    0x0003F,

    # boundary test
    0x00040,
    0x00100,

    # high-bit test (重點)
    0x3F001,
    0x3F002,
    0x3F010,
    0x3F03F,
    0x3F040,
    0x3F123,
    0x3F3AB,

    # max range test
    0x3FF00,
    0x3FF10,
    0x3FFAA,
]

for t in tokens:
    send_u18_as_6bit_chunks(ser, t)

send_u18_as_6bit_chunks(ser, 0x3FFFF)   # TOKENS_END

ser.close()