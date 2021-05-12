#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO4A.TXT --map=COCOIO4A.MAP --symbols -o COCOIO4A.BIN COCOIODRV-4A.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO4A.TXT > COCOIO4A2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO4A.BIN
decb kill COCOIO.DSK,CIOTST4A.BAS

# Put new test binary into test disk image
decb copy COCOIO4A.BIN COCOIO.DSK,COCOIO4A.BIN -2
decb copy CIOTST4A.BAS COCOIO.DSK,CIOTST4A.BAS -0 -t

