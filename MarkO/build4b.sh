#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO4B.TXT --map=COCOIO4B.MAP --symbols -o COCOIO4B.BIN COCOIODRV-4B.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO4B.TXT > COCOIO4B2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO4B.BIN
decb kill COCOIO.DSK,CIOTST4B.BAS

# Put new test binary into test disk image
decb copy COCOIO4B.BIN COCOIO.DSK,COCOIO4B.BIN -2
decb copy CIOTST4B.BAS COCOIO.DSK,CIOTST4B.BAS -0 -t

