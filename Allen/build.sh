#!/bin/bash
lwasm --unicorns --list=COCOIO.TXT --map=COCOIO.MAP --symbols -o COCOIO.BIN COCOIODRV.asm
cut -c 16-55 --complement COCOIO.TXT > COCOIO2.TXT
