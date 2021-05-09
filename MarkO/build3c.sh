#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO3C.TXT --map=COCOIO3C.MAP --symbols -o COCOIO3C.BIN COCOIODRV-3C.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO3C.TXT > COCOIO3C2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO3C.BIN
decb kill COCOIO.DSK,CIOTST3C.BAS

# Put new test binary into test disk image
decb copy COCOIO3C.BIN COCOIO.DSK,COCOIO3C.BIN -2
decb copy CIOTST3C.BAS COCOIO.DSK,CIOTST3C.BAS -0 -t

