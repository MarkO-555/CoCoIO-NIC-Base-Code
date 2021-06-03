#!/bin/bash

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,5100HTTC.BAS

# Put new test binary into test disk image
decb copy 5100HTTC.BAS COCOIO.DSK,5100HTTC.BAS -0 -t

