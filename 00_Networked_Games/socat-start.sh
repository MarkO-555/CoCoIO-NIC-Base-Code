#!/bin/bash
socat TCP-LISTEN:65504 EXEC:"/home/pi/src/lwwire/src/lwwire drive=0\,/home/pi/src/nitros9-ro/level1/coco2/NOS9_6809_L1_coco2_becker.dsk drive=1\,/mnt/public/CoCo/graphics.dsk"
#socat TCP-CONNECT:192.168.10.82:23 EXEC:"/home/pi/src/lwwire/src/lwwire drive=0\,/home/pi/src/nitros9-ro/level1/coco2/NOS9_6809_L1_coco2_becker.dsk drive=1\,/mnt/public/CoCo/graphics.dsk"