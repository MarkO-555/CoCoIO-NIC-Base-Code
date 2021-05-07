#!/bin/bash

# Build the DECB binary, listing, and map
lwasm --unicorns --list=COCOIO3A.TXT --map=COCOIO3A.MAP --symbols -o COCOIO3A.BIN COCOIODRV-3A.asm

# Strip column 16-55 out of listing for personal readability
cut -c 16-55 --complement COCOIO3A.TXT > COCOIO3A2.TXT

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,COCOIO3A.BIN
decb kill COCOIO.DSK,CIOTST3A.BAS

# Put new test binary into test disk image
decb copy COCOIO3A.BIN COCOIO.DSK,COCOIO3A.BIN -2
decb copy CIOTST3A.BAS COCOIO.DSK,CIOTST3A.BAS -0 -t

