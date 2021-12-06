#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO4C.TXT --map=COCOIO4C.MAP --symbols -o COCOIO4C.BIN COCOIODRV-4C.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO4C.TXT > COCOIO4C2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO4C.BIN
decb kill COCOIO.DSK,CIOTST4C.BAS

# Put new test binary into test disk image
decb copy COCOIO4C.BIN COCOIO.DSK,COCOIO4C.BIN -2
decb copy CIOTST4C.BAS COCOIO.DSK,CIOTST4C.BAS -0 -t

