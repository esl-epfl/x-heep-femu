# Copyright 2023 EPFL
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Author: Simone Machetti - simone.machetti@epfl.ch

femu-gen-all: femu-gen-vendor femu-gen-rtl femu-gen-vivado

femu-gen-vendor:
	cd vendor && \
	python3 vendor.py x_heep.vendor.hjson --update && \
	python3 vendor.py core2axi.vendor.hjson --update

femu-gen-rtl:
	cd vendor/x_heep && \
	make mcu-gen PAD_CFG=../../pads/pad_cfg.hjson MEMORY_BANKS=4 && \
	python3 util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg ../../pads/pad_cfg.hjson --outdir ../../rtl/ --tpl-sv ../../rtl/femu.sv.tpl

femu-gen-vivado:
	fusesoc --cores-root . run --no-export --target=femu --setup --build femu 2>&1
