#!/usr/bin/python 

import sys
sys.path = ["..", "testsuite"] + sys.path
import runtest

# A command to run
command = runtest.testtex_command ("vertgrid.tx", " --scalest 4 1 ")

# Outputs to check against references
outputs = [ "out.exr" ]

# boilerplate
ret = runtest.runtest (command, outputs)
sys.exit (ret)
