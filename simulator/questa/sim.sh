#!/bin/bash
set -e

# Use absolute path so Questa can find the libraries even when working in /tmp/
BASE_DIR="$PWD"

# Compiler and Linker flags for DPI/C++ files
CCFLAGS="-I${BASE_DIR}/simulator/reference/riscv-isa-sim/"
LDFLAGS="-L${BASE_DIR}/simulator/reference/build/ -ldisasm -Wl,-rpath=${BASE_DIR}/simulator/reference/build/"
VLOG_FLAGS="-svinputport=compat +acc=rn"
CYCLES=-all

export HPDCACHE_DIR=${BASE_DIR}/rtl/dcache

# 1. Generate the standard raw filelist from Bender
echo "Generating HDL filelist from Bender..."
bender script flist -t simulation > filelist_bender.f

# 2. List the C++/DPI files that Questa needs to compile
DPI_FILES="
    ${BASE_DIR}/simulator/models/cxx/dpi_host.cpp
    ${BASE_DIR}/simulator/models/cxx/dpi_konata.cpp
    ${BASE_DIR}/simulator/models/cxx/dpi_perfect_memory.cpp
    ${BASE_DIR}/simulator/models/cxx/dpi_rename_checking.cpp
    ${BASE_DIR}/simulator/models/cxx/dpi_commit_log.cpp
    ${BASE_DIR}/simulator/models/cxx/loadelf.cpp
    ${BASE_DIR}/simulator/bsc-dm/SimJTAG/SimJTAG.cc
    ${BASE_DIR}/simulator/bsc-dm/SimJTAG/remote_bitbang.cc
"

# 3. Explicitly define Include Directories for Questa
INCDIRS="
    +incdir+${BASE_DIR}/rtl/common_cells/include
    +incdir+${BASE_DIR}/rtl/core/sargantana/includes
    +incdir+${BASE_DIR}/rtl/core/sargantana/rtl
    +incdir+${BASE_DIR}/rtl/core/sargantana/rtl/mmu/includes
    +incdir+${BASE_DIR}/rtl/icache/includes
    +incdir+${BASE_DIR}/rtl/icache/rtl/memory_library/include
    +incdir+${BASE_DIR}/rtl/dcache/rtl/memory_library/include
    +incdir+${BASE_DIR}/rtl/dcache/rtl/include
    +incdir+${BASE_DIR}/simulator/bsc-dm/common_cells/include
    +incdir+${BASE_DIR}/includes
"

# 4. Explicitly add Simulation Defines
DEFINES="
    +define+SIMULATION
    +define+SIM_COMMIT_LOG
    +define+SIM_COMMIT_LOG_DPI
    +define+SIM_KONATA_DUMP
    +define+SARG_BYPASS_LSQ
"

rm -rf lib_module
vlib lib_module
vmap work $PWD/lib_module

# 5. Compile everything together
echo "Compiling with Questa..."
vlog $VLOG_FLAGS \
     $DEFINES \
     $INCDIRS \
     -ccflags "$CCFLAGS" \
     -F ${BASE_DIR}/standalone_config.f \
     -f filelist_bender.f \
     $DPI_FILES

# 6. Run the simulation
echo "Starting Simulation..."
vsim work.sim_top -ldflags "$LDFLAGS" $@ -do "run $CYCLES"
