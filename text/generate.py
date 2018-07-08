#!/usr/bin/env python

MESSAGES = [
        "Waiting for Atari power on",
        "Collecting samples",
        "cycle#  VCC \xb0 RW #S4 #S5 #CCTL ADDR D. AUX \xb0 RW #S4 #S5 #CCTL ADDR D. AUX"]

with open("text.mif", "wt") as f:
    f.write("DEPTH = 256;\n")
    f.write("WIDTH = 8;\n")
    f.write("ADDRESS_RADIX = HEX;\n")
    f.write("DATA_RADIX = HEX;\n")
    f.write("CONTENT\n")
    f.write("BEGIN\n")
    i = 0
    for message in MESSAGES:
        print '%02X "%s" [%s]' % (len(message), message, " ".join(map(lambda c: "%02X" % ord(c), message)))
        f.write("%02X : %02X;\n" % (i, len(message)))
        i += 1
        for c in message:
            f.write("%02X : %02X;\n" % (i, ord(c)))
            i += 1
    while i < 256:
        f.write("%02X : 00;\n" % i)
        i += 1
    f.write("END;\n")
