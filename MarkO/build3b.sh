#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO3B.TXT --map=COCOIO3B.MAP --symbols -o COCOIO3B.BIN COCOIODRV-3B.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO3B.TXT > COCOIO3B2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO3B.BIN
decb kill COCOIO.DSK,CIOTST3B.BAS

# Put new test binary into test disk image
decb copy COCOIO3B.BIN COCOIO.DSK,COCOIO3B.BIN -2
decb copy CIOTST3B.BAS COCOIO.DSK,CIOTST3B.BAS -0 -t

