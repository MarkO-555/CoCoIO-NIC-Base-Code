#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO.TXT --map=COCOIO.MAP --symbols -o COCOIO.BIN COCOIODRV.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO.TXT > COCOIO2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO.BIN

# Put new test binary into test disk image
decb copy COCOIO.BIN COCOIO.DSK,COCOIO.BIN -2
