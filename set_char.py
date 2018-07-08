#!/usr/bin/env python

import serial
import sys

uart = serial.Serial("/dev/ttyS0", baudrate=19200, xonxoff=0, rtscts=1)
x, y = map(int, sys.argv[1:3])
c = sys.argv[3][0]
a = 80*y + x
uart.write('L%cH%cc%c' % (chr(a & 0xff), chr((a >> 8) & 0xff), c))
uart.close()
