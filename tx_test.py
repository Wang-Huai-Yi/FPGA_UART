import serial
import time

port = '/dev/ttyUSB2'
baud = 9600

TOKENS_END = 0x3FFFF

def recv_u18_from_6bit_chunks(ser, timeout_msg=True):
    data = ser.read(3)
    if len(data) != 3:
        if timeout_msg:
            print("timeout / not enough data")
        return None

    b0 = data[0] & 0x3F
    b1 = data[1] & 0x3F
    b2 = data[2] & 0x3F

    value = b0 | (b1 << 6) | (b2 << 12)

    print(
        f"recv: 0x{value:05X} "
        f"<- raw [{data[0]:02X} {data[1]:02X} {data[2]:02X}], "
        f"low6 [{b0:02X} {b1:02X} {b2:02X}]"
    )

    return value

ser = serial.Serial(port, baudrate=baud, timeout=1)
time.sleep(1)

print("start receiving 18-bit tokens...")

packet = []

try:
    while True:
        value = recv_u18_from_6bit_chunks(ser)
        if value is None:
            continue

        packet.append(value)

        if value == TOKENS_END:
            print("packet end")
            print("packet =", [f"0x{x:05X}" for x in packet])
            print("-" * 40)
            packet = []

except KeyboardInterrupt:
    print("stop")

ser.close()