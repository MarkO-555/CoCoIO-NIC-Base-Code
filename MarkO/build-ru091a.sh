#!/bin/bash

# Get rid of old binary from test disk image
decb kill COCOIO.DSK,5100HTTD.BAS

# Put new test binary into test disk image
decb copy 5100HTTD.BAS COCOIO.DSK,5100HTTD.BAS -0 -t

