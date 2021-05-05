#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO2A.TXT --map=COCOIO2A.MAP --symbols -o COCOIO2A.BIN COCOIODRV-2A.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO2A.TXT > COCOIO2A2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO2A.BIN

# Put new test binary into test disk image
decb copy COCOIO2A.BIN COCOIO.DSK,COCOIO2A.BIN -2
