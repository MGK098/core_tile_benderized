#!/bin/bash -x

# Basically reuse the upstream environment
source .github/scripts/env.sh

# Unset VERILATOR_ROOT variable as our CI image already has it setup
unset VERILATOR_ROOT