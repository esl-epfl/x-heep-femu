# Copyright 2023 EPFL
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Author: Simone Machetti - simone.machetti@epfl.ch

set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk_in]

set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports rst_led]

set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {spi2_sck_io}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {spi2_cs_0_io}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {spi2_cs_1_io}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {spi2_sd_0_io}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {spi2_sd_1_io}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {spi2_sd_2_io}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {spi2_sd_3_io}]

set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {i2c_sda_io}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {i2c_scl_io}]
