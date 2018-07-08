#!/usr/bin/env python

import serial
import sys

uart = serial.Serial("/dev/ttyS0", baudrate=19200, xonxoff=0, rtscts=1)
r, g, b = map(int, sys.argv[1:4])
uart.write('!%c%c%c' % (chr(r), chr(g), chr(b)))
uart.close()
