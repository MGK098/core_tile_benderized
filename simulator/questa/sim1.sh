#!/bin/bash
set -e

BASE_DIR="$PWD"
export HPDCACHE_DIR=${BASE_DIR}/rtl/dcache

CCFLAGS="-I${BASE_DIR}/simulator/reference/riscv-isa-sim/"
LDFLAGS="-L${BASE_DIR}/simulator/reference/build/ -ldisasm -Wl,-rpath=${BASE_DIR}/simulator/reference/build/"
CYCLES=-all

echo "Generating HDL filelist from Bender..."
bender script flist -t simulation > filelist_bender.f

rm -rf lib_module
vlib lib_module
vmap work "$PWD/lib_module"

echo "Compiling with Questa..."
vlog \
  -svinputport=compat \
  +acc=rn \
  +define+SIMULATION \
  +define+SIM_COMMIT_LOG \
  +define+SIM_COMMIT_LOG_DPI \
  +define+SIM_KONATA_DUMP \
  +define+SARG_BYPASS_LSQ \
  +define+CONF_SARGANTANA_PHY_ADDR_SIZE=40 \
  +incdir+"$(bender path axi)/include" \
  +incdir+"$(bender path common_cells)/include" \
  +incdir+"${BASE_DIR}/rtl/common_cells/include" \
  +incdir+"${BASE_DIR}/rtl/core/sargantana/includes" \
  +incdir+"${BASE_DIR}/rtl/core/sargantana/rtl" \
  +incdir+"${BASE_DIR}/rtl/core/sargantana/rtl/mmu/includes" \
  +incdir+"${BASE_DIR}/rtl/icache/includes" \
  +incdir+"${BASE_DIR}/rtl/icache/rtl/memory_library/include" \
  +incdir+"${BASE_DIR}/rtl/dcache/rtl/memory_library/include" \
  +incdir+"${BASE_DIR}/rtl/dcache/rtl/include" \
  +incdir+"${BASE_DIR}/simulator/bsc-dm/common_cells/include" \
  +incdir+"${BASE_DIR}/includes" \
  -ccflags "${CCFLAGS}" \
  -f filelist_bender.f \
  "${BASE_DIR}/simulator/models/cxx/dpi_host.cpp" \
  "${BASE_DIR}/simulator/models/cxx/dpi_konata.cpp" \
  "${BASE_DIR}/simulator/models/cxx/dpi_perfect_memory.cpp" \
  "${BASE_DIR}/simulator/models/cxx/dpi_rename_checking.cpp" \
  "${BASE_DIR}/simulator/models/cxx/dpi_commit_log.cpp" \
  "${BASE_DIR}/simulator/models/cxx/loadelf.cpp" \
  "${BASE_DIR}/simulator/bsc-dm/SimJTAG/SimJTAG.cc" \
  "${BASE_DIR}/simulator/bsc-dm/SimJTAG/remote_bitbang.cc"

echo "Starting Simulation..."
vsim work.tb_sargantana_soc_axi_wrap -ldflags "$LDFLAGS" $@ -do "run $CYCLES"

