#!/usr/bin/env python

import serial
import sys

uart = serial.Serial("/dev/ttyS0", baudrate=19200, xonxoff=0, rtscts=1)
x, y, p = map(int, sys.argv[1:4])
a = 80*y + x
uart.write('L%cH%cp%c' % (chr(a & 0xff), chr((a >> 8) & 0xff), chr(p)))
uart.close()
