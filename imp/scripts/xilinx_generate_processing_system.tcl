# Copyright 2023 EPFL
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Author: Simone Machetti - simone.machetti@epfl.ch

# Select board
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

# Create block design
create_bd_design "processing_system"

# Add Zynq Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {20} CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {0} CONFIG.PCW_SD0_PERIPHERAL_ENABLE {0} CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} CONFIG.PCW_UART1_UART1_IO {EMIO} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} CONFIG.PCW_GPIO_EMIO_GPIO_IO {8} CONFIG.PCW_USE_M_AXI_GP1 {1} CONFIG.PCW_USE_S_AXI_HP1 {1}] [get_bd_cells processing_system7_0]

# Add AXI Interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {5} CONFIG.NUM_MI {8}] [get_bd_cells axi_interconnect_0]

# Add Constants
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_WIDTH {2} CONFIG.CONST_VAL {0b11}] [get_bd_cells xlconstant_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0b1}] [get_bd_cells xlconstant_1]

# Add Concatenation
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list CONFIG.IN0_WIDTH.VALUE_SRC USER CONFIG.IN1_WIDTH.VALUE_SRC USER CONFIG.IN2_WIDTH.VALUE_SRC USER CONFIG.IN3_WIDTH.VALUE_SRC USER CONFIG.IN4_WIDTH.VALUE_SRC USER] [get_bd_cells xlconcat_0]
set_property -dict [list CONFIG.NUM_PORTS {5} CONFIG.IN0_WIDTH {2} CONFIG.IN2_WIDTH {2} CONFIG.IN4_WIDTH {2}] [get_bd_cells xlconcat_0]

# Add Slices
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_6
set_property -dict [list CONFIG.DIN_TO {3} CONFIG.DIN_FROM {3} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_0]
set_property -dict [list CONFIG.DIN_TO {4} CONFIG.DIN_FROM {4} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_1]
set_property -dict [list CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_2]
set_property -dict [list CONFIG.DIN_TO {0} CONFIG.DIN_FROM {0} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_3]
set_property -dict [list CONFIG.DIN_TO {5} CONFIG.DIN_FROM {5} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_4]
set_property -dict [list CONFIG.DIN_TO {6} CONFIG.DIN_FROM {6} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_5]
set_property -dict [list CONFIG.DIN_TO {7} CONFIG.DIN_FROM {7} CONFIG.DIN_WIDTH {8} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_6]

# Create port gpio_jtag_tdo_o
make_bd_pins_external [get_bd_pins xlconcat_0/In1]
set_property name gpio_jtag_tdo_o [get_bd_ports In1_0]

# Connect Constants and Concatenation
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconstant_0/dout]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/GPIO_I]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins xlconcat_0/In3]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins xlconcat_0/In4]

# Create port gpio_jtag_tdi_i
make_bd_pins_external [get_bd_pins xlslice_0/Dout]
set_property name gpio_jtag_tdi_i [get_bd_ports Dout_0]

# Create port gpio_jtag_tck_i
make_bd_pins_external [get_bd_pins xlslice_1/Dout]
set_property name gpio_jtag_tck_i [get_bd_ports Dout_0]

# Create port gpio_jtag_tms_i
make_bd_pins_external [get_bd_pins xlslice_2/Dout]
set_property name gpio_jtag_tms_i [get_bd_ports Dout_0]

# Create port gpio_jtag_trst_ni
make_bd_pins_external [get_bd_pins xlslice_3/Dout]
set_property name gpio_jtag_trst_ni [get_bd_ports Dout_0]

# Create port gpio_reset_i
make_bd_pins_external [get_bd_pins xlslice_4/Dout]
set_property name gpio_reset_i [get_bd_ports Dout_0]

# Create port gpio_boot_select_i
make_bd_pins_external [get_bd_pins xlslice_5/Dout]
set_property name gpio_boot_select_i [get_bd_ports Dout_0]

# Create port gpio_execute_from_flash_i
make_bd_pins_external [get_bd_pins xlslice_6/Dout]
set_property name gpio_execute_from_flash_i [get_bd_ports Dout_0]

# Connect Slices
connect_bd_net [get_bd_pins xlslice_0/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_1/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_2/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_3/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_4/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_5/Din] [get_bd_pins processing_system7_0/GPIO_O]
connect_bd_net [get_bd_pins xlslice_6/Din] [get_bd_pins processing_system7_0/GPIO_O]

# Create port UART_RX
create_bd_port -dir I -type data UART_RX

# Create port UART_TX
create_bd_port -dir O -type data UART_TX

# Create port AXI_M_FLASH
make_bd_intf_pins_external [get_bd_intf_pins axi_interconnect_0/S00_AXI]
set_property name AXI_M_FLASH [get_bd_intf_ports S00_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_M_FLASH]

# Create port AXI_M_ADC
make_bd_intf_pins_external [get_bd_intf_pins axi_interconnect_0/S01_AXI]
set_property name AXI_M_ADC [get_bd_intf_ports S01_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_M_ADC]

# Create port AXI_M_OBI
make_bd_intf_pins_external [get_bd_intf_pins axi_interconnect_0/S03_AXI]
set_property name AXI_M_OBI [get_bd_intf_ports S03_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_M_OBI]

# Create port AXI_S_FLASH
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M00_AXI]
set_property name AXI_S_FLASH [get_bd_intf_ports M00_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_S_FLASH]
set_property -dict [list CONFIG.PROTOCOL AXI4LITE] [get_bd_intf_ports AXI_S_FLASH]

# Create port AXI_S_PERF_CNT
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M01_AXI]
set_property name AXI_S_PERF_CNT [get_bd_intf_ports M01_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_S_PERF_CNT]
set_property -dict [list CONFIG.PROTOCOL AXI4LITE] [get_bd_intf_ports AXI_S_PERF_CNT]

# Create port AXI_S_OBI
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M04_AXI]
set_property name AXI_S_OBI [get_bd_intf_ports M04_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_S_OBI]
set_property -dict [list CONFIG.PROTOCOL AXI4LITE] [get_bd_intf_ports AXI_S_OBI]

# Create port AXI_S_R_OBI
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M06_AXI]
set_property name AXI_S_R_OBI [get_bd_intf_ports M06_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_S_R_OBI]
set_property -dict [list CONFIG.PROTOCOL AXI4LITE] [get_bd_intf_ports AXI_S_R_OBI]

# Create port AXI_S_R_OBI_BAA
make_bd_intf_pins_external  [get_bd_intf_pins axi_interconnect_0/M07_AXI]
set_property name AXI_S_R_OBI_BAA [get_bd_intf_ports M07_AXI_0]
set_property -dict [list CONFIG.FREQ_HZ {20000000}] [get_bd_intf_ports AXI_S_R_OBI_BAA]
set_property -dict [list CONFIG.PROTOCOL AXI4LITE] [get_bd_intf_ports AXI_S_R_OBI_BAA]

# Create port X_HEEP_CLK
create_bd_port -dir I -type clk -freq_hz 20000000 X_HEEP_CLK

# Create port X_HEEP_RSTN
create_bd_port -dir I -type rst X_HEEP_RSTN
set_property CONFIG.ASSOCIATED_RESET {X_HEEP_RSTN} [get_bd_ports /X_HEEP_CLK]

# Connect AXI Interconnect and Zynq Processing System
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP1] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S04_AXI]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP1]

# Create Block RAM
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0

# Create Block RAM controller
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property CONFIG.SINGLE_PORT_BRAM {1} [get_bd_cells axi_bram_ctrl_0]

# Connect Block RAM controller
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M02_AXI]

# Connect UART_RX
create_bd_cell -type ip -vlnv xilinx.com:ip:xpm_cdc_gen:1.0 xpm_cdc_gen_0
set_property -dict [list CONFIG.CDC_TYPE {xpm_cdc_single} CONFIG.DEST_SYNC_FF {3}] [get_bd_cells xpm_cdc_gen_0]
connect_bd_net [get_bd_ports X_HEEP_CLK] [get_bd_pins xpm_cdc_gen_0/src_clk]
connect_bd_net [get_bd_pins xpm_cdc_gen_0/dest_clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_ports UART_RX] [get_bd_pins xpm_cdc_gen_0/src_in]
connect_bd_net [get_bd_pins xpm_cdc_gen_0/dest_out] [get_bd_pins processing_system7_0/UART1_RX]

# Connect UART_TX
create_bd_cell -type ip -vlnv xilinx.com:ip:xpm_cdc_gen:1.0 xpm_cdc_gen_1
set_property -dict [list CONFIG.CDC_TYPE {xpm_cdc_single} CONFIG.DEST_SYNC_FF {3}] [get_bd_cells xpm_cdc_gen_1]
connect_bd_net [get_bd_pins xpm_cdc_gen_1/src_clk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_ports X_HEEP_CLK] [get_bd_pins xpm_cdc_gen_1/dest_clk]
connect_bd_net [get_bd_pins xpm_cdc_gen_1/src_in] [get_bd_pins processing_system7_0/UART1_TX]
connect_bd_net [get_bd_ports UART_TX] [get_bd_pins xpm_cdc_gen_1/dest_out]

# Connect clock and reset
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins axi_interconnect_0/ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (20 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins processing_system7_0/S_AXI_HP1_ACLK]

connect_bd_net [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/S03_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M06_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M07_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] -boundary_type upper
connect_bd_net [get_bd_ports X_HEEP_CLK] [get_bd_pins axi_interconnect_0/S00_ACLK]

connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M06_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_pins axi_interconnect_0/M07_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_ports X_HEEP_RSTN] [get_bd_pins axi_interconnect_0/S00_ARESETN]

# Assign addresses
assign_bd_address

# Validate design
validate_bd_design

# Save design
save_bd_design

# Close design
close_bd_design [get_bd_designs processing_system]

# Make wrapper
set wrapper_path [ make_wrapper -fileset sources_1 -files [ get_files -norecurse processing_system.bd ] -top ]
add_files -norecurse -fileset sources_1 $wrapper_path
