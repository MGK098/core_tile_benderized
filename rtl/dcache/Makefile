export HPDCACHE_DIR    = $(abspath $(shell dirname $(lastword $(MAKEFILE_LIST))))
export VERIF_DIR       = ${HPDCACHE_DIR}/verif
export PROJECT_DIR     = ${VERIF_DIR}
export CV_DV_UTILS_DIR = ${VERIF_DIR}/modules/dv_utils/lib/cv_dv_utils
export QUESTA_PATH     = $(shell dirname $(shell dirname $(shell which vsim)))
export PATH           := $(PATH):${VERIF_DIR}/scripts

VERIF_REPO    ?= https://github.com/openhwgroup/cv-hpdcache-verif.git
DV_UTILS_REPO ?= https://github.com/openhwgroup/core-v-verif.git

HPDC_CONFIG      ?= CONFIG1_HPC
NUM_TRANSACTIONS ?= 5000

PATCHED_FILE = ${CV_DV_UTILS_DIR}/uvm/.patched

run_regression: ${PATCHED_FILE}
		cd ${VERIF_DIR}/testbench/simu && python3 ${VERIF_DIR}/scripts/sim/run_reg.py --cfg ${HPDC_CONFIG} --nthreads 1 --ntxns ${NUM_TRANSACTIONS}

compile: ${PATCHED_FILE}
		cd ${VERIF_DIR}/testbench/simu && python3 ${VERIF_DIR}/scripts/sim/compile.py --cfg ${HPDC_CONFIG}

clone_verif: ${PATCHED_FILE}

${PATCHED_FILE}: ${VERIF_DIR}
# Patch the Files.f file which contains inexisting files
		$(eval TMP := $(shell mktemp))
		head -n -3 ${CV_DV_UTILS_DIR}/uvm/Files.f > $(TMP) && mv $(TMP) ${CV_DV_UTILS_DIR}/uvm/Files.f
		touch ${CV_DV_UTILS_DIR}/uvm/.patched

${VERIF_DIR}: 
		git clone --depth=1 ${VERIF_REPO} ${VERIF_DIR}
		git clone --depth=1 ${DV_UTILS_REPO} ${VERIF_DIR}/modules/dv_utils

clean_verif:
		rm -rf ${VERIF_DIR}

clean: clean_verif
