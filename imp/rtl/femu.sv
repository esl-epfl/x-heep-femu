/*
* Copyright 2023 EPFL
* Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
*
* Author: Simone Machetti - simone.machetti@epfl.ch
*/

module femu
  import obi_pkg::*;
  import reg_pkg::*;
#(
) (
  inout logic clk_in,
  inout logic rst_i,

  output logic rst_led,

  inout logic [31:2] gpio_io,

  inout logic spi2_sck_io,
  inout logic spi2_cs_0_io,
  inout logic spi2_cs_1_io,
  inout logic spi2_sd_0_io,
  inout logic spi2_sd_1_io,
  inout logic spi2_sd_2_io,
  inout logic spi2_sd_3_io,

  inout logic i2c_scl_io,
  inout logic i2c_sda_io,

  inout wire [14:0] DDR_addr,
  inout wire [2:0] DDR_ba,
  inout wire DDR_cas_n,
  inout wire DDR_ck_n,
  inout wire DDR_ck_p,
  inout wire DDR_cke,
  inout wire DDR_cs_n,
  inout wire [3:0] DDR_dm,
  inout wire [31:0] DDR_dq,
  inout wire [3:0] DDR_dqs_n,
  inout wire [3:0] DDR_dqs_p,
  inout wire DDR_odt,
  inout wire DDR_ras_n,
  inout wire DDR_reset_n,
  inout wire DDR_we_n,
  inout wire FIXED_IO_ddr_vrn,
  inout wire FIXED_IO_ddr_vrp,
  inout wire [53:0] FIXED_IO_mio,
  inout wire FIXED_IO_ps_clk,
  inout wire FIXED_IO_ps_porb,
  inout wire FIXED_IO_ps_srstb
);

  import core_v_mini_mcu_pkg::*;

  localparam AXI_ADDR_WIDTH = 32;
  localparam AXI_DATA_WIDTH = 32;

  logic cpu_subsystem_powergate_switch;
  logic cpu_subsystem_powergate_switch_ack;
  logic cpu_subsystem_sleep;
  logic cpu_subsystem_powergate_iso;
  logic cpu_subsystem_rst_n;
  logic peripheral_subsystem_powergate_switch;
  logic peripheral_subsystem_powergate_switch_ack;
  logic peripheral_subsystem_powergate_iso;
  logic peripheral_subsystem_clkgate_en;
  logic peripheral_subsystem_rst_n;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_powergate_switch;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_powergate_switch_ack;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_powergate_iso;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_banks_set_retentive;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] memory_subsystem_clkgate_en;

  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_FLASH_araddr_sig;
  logic [1:0] AXI_M_FLASH_arburst_sig;
  logic [3:0] AXI_M_FLASH_arcache_sig;
  logic [1:0] AXI_M_FLASH_arid_sig;
  logic [7:0] AXI_M_FLASH_arlen_sig;
  logic [0:0] AXI_M_FLASH_arlock_sig;
  logic [2:0] AXI_M_FLASH_arprot_sig;
  logic [3:0] AXI_M_FLASH_arqos_sig;
  logic AXI_M_FLASH_arready_sig;
  logic [3:0] AXI_M_FLASH_arregion;
  logic [2:0] AXI_M_FLASH_arsize_sig;
  logic AXI_M_FLASH_arvalid_sig;
  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_FLASH_awaddr_sig;
  logic [1:0] AXI_M_FLASH_awburst_sig;
  logic [3:0] AXI_M_FLASH_awcache_sig;
  logic [1:0] AXI_M_FLASH_awid_sig;
  logic [7:0] AXI_M_FLASH_awlen_sig;
  logic [0:0] AXI_M_FLASH_awlock_sig;
  logic [2:0] AXI_M_FLASH_awprot_sig;
  logic [3:0] AXI_M_FLASH_awqos_sig;
  logic AXI_M_FLASH_awready_sig;
  logic [3:0] AXI_M_FLASH_awregion;
  logic [2:0] AXI_M_FLASH_awsize_sig;
  logic AXI_M_FLASH_awvalid_sig;
  logic [1:0] AXI_M_FLASH_bid_sig;
  logic AXI_M_FLASH_bready_sig;
  logic [1:0] AXI_M_FLASH_bresp_sig;
  logic AXI_M_FLASH_bvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_FLASH_rdata_sig;
  logic [1:0] AXI_M_FLASH_rid_sig;
  logic AXI_M_FLASH_rlast_sig;
  logic AXI_M_FLASH_rready_sig;
  logic [1:0] AXI_M_FLASH_rresp_sig;
  logic AXI_M_FLASH_rvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_FLASH_wdata_sig;
  logic AXI_M_FLASH_wlast_sig;
  logic AXI_M_FLASH_wready_sig;
  logic [3:0] AXI_M_FLASH_wstrb_sig;
  logic AXI_M_FLASH_wvalid_sig;

  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_ADC_araddr_sig;
  logic [1:0] AXI_M_ADC_arburst_sig;
  logic [3:0] AXI_M_ADC_arcache_sig;
  logic [1:0] AXI_M_ADC_arid_sig;
  logic [7:0] AXI_M_ADC_arlen_sig;
  logic [0:0] AXI_M_ADC_arlock_sig;
  logic [2:0] AXI_M_ADC_arprot_sig;
  logic [3:0] AXI_M_ADC_arqos_sig;
  logic AXI_M_ADC_arready_sig;
  logic [3:0] AXI_M_ADC_arregion;
  logic [2:0] AXI_M_ADC_arsize_sig;
  logic AXI_M_ADC_arvalid_sig;
  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_ADC_awaddr_sig;
  logic [1:0] AXI_M_ADC_awburst_sig;
  logic [3:0] AXI_M_ADC_awcache_sig;
  logic [1:0] AXI_M_ADC_awid_sig;
  logic [7:0] AXI_M_ADC_awlen_sig;
  logic [0:0] AXI_M_ADC_awlock_sig;
  logic [2:0] AXI_M_ADC_awprot_sig;
  logic [3:0] AXI_M_ADC_awqos_sig;
  logic AXI_M_ADC_awready_sig;
  logic [3:0] AXI_M_ADC_awregion;
  logic [2:0] AXI_M_ADC_awsize_sig;
  logic AXI_M_ADC_awvalid_sig;
  logic [1:0] AXI_M_ADC_bid_sig;
  logic AXI_M_ADC_bready_sig;
  logic [1:0] AXI_M_ADC_bresp_sig;
  logic AXI_M_ADC_bvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_ADC_rdata_sig;
  logic [1:0] AXI_M_ADC_rid_sig;
  logic AXI_M_ADC_rlast_sig;
  logic AXI_M_ADC_rready_sig;
  logic [1:0] AXI_M_ADC_rresp_sig;
  logic AXI_M_ADC_rvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_ADC_wdata_sig;
  logic AXI_M_ADC_wlast_sig;
  logic AXI_M_ADC_wready_sig;
  logic [3:0] AXI_M_ADC_wstrb_sig;
  logic AXI_M_ADC_wvalid_sig;

  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_OBI_araddr_sig;
  logic [1:0] AXI_M_OBI_arburst_sig;
  logic [3:0] AXI_M_OBI_arcache_sig;
  logic [1:0] AXI_M_OBI_arid_sig;
  logic [7:0] AXI_M_OBI_arlen_sig;
  logic [0:0] AXI_M_OBI_arlock_sig;
  logic [2:0] AXI_M_OBI_arprot_sig;
  logic [3:0] AXI_M_OBI_arqos_sig;
  logic AXI_M_OBI_arready_sig;
  logic [3:0] AXI_M_OBI_arregion;
  logic [2:0] AXI_M_OBI_arsize_sig;
  logic AXI_M_OBI_arvalid_sig;
  logic [AXI_ADDR_WIDTH - 1:0] AXI_M_OBI_awaddr_sig;
  logic [1:0] AXI_M_OBI_awburst_sig;
  logic [3:0] AXI_M_OBI_awcache_sig;
  logic [1:0] AXI_M_OBI_awid_sig;
  logic [7:0] AXI_M_OBI_awlen_sig;
  logic [0:0] AXI_M_OBI_awlock_sig;
  logic [2:0] AXI_M_OBI_awprot_sig;
  logic [3:0] AXI_M_OBI_awqos_sig;
  logic AXI_M_OBI_awready_sig;
  logic [3:0] AXI_M_OBI_awregion;
  logic [2:0] AXI_M_OBI_awsize_sig;
  logic AXI_M_OBI_awvalid_sig;
  logic [1:0] AXI_M_OBI_bid_sig;
  logic AXI_M_OBI_bready_sig;
  logic [1:0] AXI_M_OBI_bresp_sig;
  logic AXI_M_OBI_bvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_OBI_rdata_sig;
  logic [1:0] AXI_M_OBI_rid_sig;
  logic AXI_M_OBI_rlast_sig;
  logic AXI_M_OBI_rready_sig;
  logic [1:0] AXI_M_OBI_rresp_sig;
  logic AXI_M_OBI_rvalid_sig;
  logic [AXI_DATA_WIDTH - 1:0] AXI_M_OBI_wdata_sig;
  logic AXI_M_OBI_wlast_sig;
  logic AXI_M_OBI_wready_sig;
  logic [3:0] AXI_M_OBI_wstrb_sig;
  logic AXI_M_OBI_wvalid_sig;

  logic spi_test_clk_sig;
  logic spi_test_cs_sig;
  logic [3:0] spi_test_data_sig;

  logic [AXI_ADDR_WIDTH-1:0] AXI_M_FLASH_awaddr_in_sig;
  logic [AXI_ADDR_WIDTH-1:0] AXI_M_FLASH_araddr_in_sig;

  logic [AXI_ADDR_WIDTH-1:0] AXI_M_ADC_awaddr_in_sig;
  logic [AXI_ADDR_WIDTH-1:0] AXI_M_ADC_araddr_in_sig;

  logic [AXI_ADDR_WIDTH-1:0] AXI_M_OBI_awaddr_in_sig;
  logic [AXI_ADDR_WIDTH-1:0] AXI_M_OBI_araddr_in_sig;

  logic [3 : 0] AXI_S_FLASH_awaddr_sig;
  logic [2:0] AXI_S_FLASH_awprot_sig;
  logic AXI_S_FLASH_awready_sig;
  logic AXI_S_FLASH_awvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_FLASH_wdata_sig;
  logic AXI_S_FLASH_wready_sig;
  logic [(AXI_DATA_WIDTH / 8)-1 : 0] AXI_S_FLASH_wstrb_sig;
  logic AXI_S_FLASH_wvalid_sig;
  logic AXI_S_FLASH_bready_sig;
  logic [1:0] AXI_S_FLASH_bresp_sig;
  logic AXI_S_FLASH_bvalid_sig;
  logic [3 : 0] AXI_S_FLASH_araddr_sig;
  logic [2 : 0] AXI_S_FLASH_arprot_sig;
  logic AXI_S_FLASH_arready_sig;
  logic AXI_S_FLASH_arvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_FLASH_rdata_sig;
  logic AXI_S_FLASH_rready_sig;
  logic [1:0] AXI_S_FLASH_rresp_sig;
  logic AXI_S_FLASH_rvalid_sig;

  logic [3 : 0] AXI_S_OBI_awaddr_sig;
  logic [2:0] AXI_S_OBI_awprot_sig;
  logic AXI_S_OBI_awready_sig;
  logic AXI_S_OBI_awvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_OBI_wdata_sig;
  logic AXI_S_OBI_wready_sig;
  logic [(AXI_DATA_WIDTH / 8)-1 : 0] AXI_S_OBI_wstrb_sig;
  logic AXI_S_OBI_wvalid_sig;
  logic AXI_S_OBI_bready_sig;
  logic [1:0] AXI_S_OBI_bresp_sig;
  logic AXI_S_OBI_bvalid_sig;
  logic [3 : 0] AXI_S_OBI_araddr_sig;
  logic [2 : 0] AXI_S_OBI_arprot_sig;
  logic AXI_S_OBI_arready_sig;
  logic AXI_S_OBI_arvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_OBI_rdata_sig;
  logic AXI_S_OBI_rready_sig;
  logic [1:0] AXI_S_OBI_rresp_sig;
  logic AXI_S_OBI_rvalid_sig;

  logic [7 : 0] AXI_S_PERF_CNT_awaddr_sig;
  logic [2:0] AXI_S_PERF_CNT_awprot_sig;
  logic AXI_S_PERF_CNT_awready_sig;
  logic AXI_S_PERF_CNT_awvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_PERF_CNT_wdata_sig;
  logic AXI_S_PERF_CNT_wready_sig;
  logic [(AXI_DATA_WIDTH / 8)-1 : 0] AXI_S_PERF_CNT_wstrb_sig;
  logic AXI_S_PERF_CNT_wvalid_sig;
  logic AXI_S_PERF_CNT_bready_sig;
  logic [1:0] AXI_S_PERF_CNT_bresp_sig;
  logic AXI_S_PERF_CNT_bvalid_sig;
  logic [7 : 0] AXI_S_PERF_CNT_araddr_sig;
  logic [2 : 0] AXI_S_PERF_CNT_arprot_sig;
  logic AXI_S_PERF_CNT_arready_sig;
  logic AXI_S_PERF_CNT_arvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_PERF_CNT_rdata_sig;
  logic AXI_S_PERF_CNT_rready_sig;
  logic [1:0] AXI_S_PERF_CNT_rresp_sig;
  logic AXI_S_PERF_CNT_rvalid_sig;

logic [AXI_ADDR_WIDTH - 1 : 0] AXI_S_R_OBI_awaddr_sig;
  logic [2:0] AXI_S_R_OBI_awprot_sig;
  logic AXI_S_R_OBI_awready_sig;
  logic AXI_S_R_OBI_awvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_R_OBI_wdata_sig;
  logic AXI_S_R_OBI_wready_sig;
  logic [(AXI_DATA_WIDTH / 8)-1 : 0] AXI_S_R_OBI_wstrb_sig;
  logic AXI_S_R_OBI_wvalid_sig;
  logic AXI_S_R_OBI_bready_sig;
  logic [1:0] AXI_S_R_OBI_bresp_sig;
  logic AXI_S_R_OBI_bvalid_sig;
  logic [AXI_ADDR_WIDTH - 1 : 0] AXI_S_R_OBI_araddr_sig;
  logic [2 : 0] AXI_S_R_OBI_arprot_sig;
  logic AXI_S_R_OBI_arready_sig;
  logic AXI_S_R_OBI_arvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_R_OBI_rdata_sig;
  logic AXI_S_R_OBI_rready_sig;
  logic [1:0] AXI_S_R_OBI_rresp_sig;
  logic AXI_S_R_OBI_rvalid_sig;

  logic [AXI_ADDR_WIDTH - 1 : 0] AXI_S_R_OBI_BAA_awaddr_sig;
  logic [2:0] AXI_S_R_OBI_BAA_awprot_sig;
  logic AXI_S_R_OBI_BAA_awready_sig;
  logic AXI_S_R_OBI_BAA_awvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_R_OBI_BAA_wdata_sig;
  logic AXI_S_R_OBI_BAA_wready_sig;
  logic [(AXI_DATA_WIDTH / 8)-1 : 0] AXI_S_R_OBI_BAA_wstrb_sig;
  logic AXI_S_R_OBI_BAA_wvalid_sig;
  logic AXI_S_R_OBI_BAA_bready_sig;
  logic [1:0] AXI_S_R_OBI_BAA_bresp_sig;
  logic AXI_S_R_OBI_BAA_bvalid_sig;
  logic [AXI_ADDR_WIDTH - 1 : 0] AXI_S_R_OBI_BAA_araddr_sig;
  logic [2 : 0] AXI_S_R_OBI_BAA_arprot_sig;
  logic AXI_S_R_OBI_BAA_arready_sig;
  logic AXI_S_R_OBI_BAA_arvalid_sig;
  logic [AXI_DATA_WIDTH - 1 : 0] AXI_S_R_OBI_BAA_rdata_sig;
  logic AXI_S_R_OBI_BAA_rready_sig;
  logic [1:0] AXI_S_R_OBI_BAA_rresp_sig;
  logic AXI_S_R_OBI_BAA_rvalid_sig;


  reg_req_t pad_req;
  reg_rsp_t pad_resp;

  obi_req_t obi_req;
  obi_resp_t obi_resp;

  obi_req_t r_obi_req;
  obi_resp_t r_obi_resp;
  logic [AXI_ADDR_WIDTH - 1:0] r_obi_req_addr_in_sig;


  logic [core_v_mini_mcu_pkg::NUM_PAD-1:0][7:0] pad_attributes;
  logic [core_v_mini_mcu_pkg::NUM_PAD-1:0][3:0] pad_muxes;

  logic clk_in_x,clk_out_x,clk_oe_x;

  logic rst_nin_x,rst_nout_x,rst_noe_x;

  logic boot_select_in_x,boot_select_out_x,boot_select_oe_x;

  logic execute_from_flash_in_x,execute_from_flash_out_x,execute_from_flash_oe_x;

  logic jtag_tck_in_x,jtag_tck_out_x,jtag_tck_oe_x;

  logic jtag_tms_in_x,jtag_tms_out_x,jtag_tms_oe_x;

  logic jtag_trst_nin_x,jtag_trst_nout_x,jtag_trst_noe_x;

  logic jtag_tdi_in_x,jtag_tdi_out_x,jtag_tdi_oe_x;

  logic jtag_tdo_in_x,jtag_tdo_out_x,jtag_tdo_oe_x;

  logic uart_rx_in_x,uart_rx_out_x,uart_rx_oe_x;

  logic uart_tx_in_x,uart_tx_out_x,uart_tx_oe_x;

  logic exit_valid_in_x,exit_valid_out_x,exit_valid_oe_x;

  logic gpio_0_in_x,gpio_0_out_x,gpio_0_oe_x;

  logic gpio_1_in_x,gpio_1_out_x,gpio_1_oe_x;

  logic gpio_2_in_x,gpio_2_out_x,gpio_2_oe_x;

  logic gpio_3_in_x,gpio_3_out_x,gpio_3_oe_x;

  logic gpio_4_in_x,gpio_4_out_x,gpio_4_oe_x;

  logic gpio_5_in_x,gpio_5_out_x,gpio_5_oe_x;

  logic gpio_6_in_x,gpio_6_out_x,gpio_6_oe_x;

  logic gpio_7_in_x,gpio_7_out_x,gpio_7_oe_x;

  logic gpio_8_in_x,gpio_8_out_x,gpio_8_oe_x;

  logic gpio_9_in_x,gpio_9_out_x,gpio_9_oe_x;

  logic gpio_10_in_x,gpio_10_out_x,gpio_10_oe_x;

  logic gpio_11_in_x,gpio_11_out_x,gpio_11_oe_x;

  logic gpio_12_in_x,gpio_12_out_x,gpio_12_oe_x;

  logic gpio_13_in_x,gpio_13_out_x,gpio_13_oe_x;

  logic gpio_14_in_x,gpio_14_out_x,gpio_14_oe_x;

  logic gpio_15_in_x,gpio_15_out_x,gpio_15_oe_x;

  logic gpio_16_in_x,gpio_16_out_x,gpio_16_oe_x;

  logic gpio_17_in_x,gpio_17_out_x,gpio_17_oe_x;

  logic gpio_18_in_x,gpio_18_out_x,gpio_18_oe_x;

  logic gpio_19_in_x,gpio_19_out_x,gpio_19_oe_x;

  logic gpio_20_in_x,gpio_20_out_x,gpio_20_oe_x;

  logic gpio_21_in_x,gpio_21_out_x,gpio_21_oe_x;

  logic gpio_22_in_x,gpio_22_out_x,gpio_22_oe_x;

  logic gpio_23_in_x,gpio_23_out_x,gpio_23_oe_x;

  logic gpio_24_in_x,gpio_24_out_x,gpio_24_oe_x;

  logic gpio_25_in_x,gpio_25_out_x,gpio_25_oe_x;

  logic gpio_26_in_x,gpio_26_out_x,gpio_26_oe_x;

  logic gpio_27_in_x,gpio_27_out_x,gpio_27_oe_x;

  logic gpio_28_in_x,gpio_28_out_x,gpio_28_oe_x;

  logic gpio_29_in_x,gpio_29_out_x,gpio_29_oe_x;

  logic gpio_30_in_x,gpio_30_out_x,gpio_30_oe_x;

  logic gpio_31_in_x,gpio_31_out_x,gpio_31_oe_x;

  logic spi_flash_sck_in_x,spi_flash_sck_out_x,spi_flash_sck_oe_x;

  logic spi_flash_cs_0_in_x,spi_flash_cs_0_out_x,spi_flash_cs_0_oe_x;

  logic spi_flash_cs_1_in_x,spi_flash_cs_1_out_x,spi_flash_cs_1_oe_x;

  logic spi_flash_sd_0_in_x,spi_flash_sd_0_out_x,spi_flash_sd_0_oe_x;

  logic spi_flash_sd_1_in_x,spi_flash_sd_1_out_x,spi_flash_sd_1_oe_x;

  logic spi_flash_sd_2_in_x,spi_flash_sd_2_out_x,spi_flash_sd_2_oe_x;

  logic spi_flash_sd_3_in_x,spi_flash_sd_3_out_x,spi_flash_sd_3_oe_x;

  logic spi_sck_in_x,spi_sck_out_x,spi_sck_oe_x;

  logic spi_cs_0_in_x,spi_cs_0_out_x,spi_cs_0_oe_x;

  logic spi_cs_1_in_x,spi_cs_1_out_x,spi_cs_1_oe_x;

  logic spi_sd_0_in_x,spi_sd_0_out_x,spi_sd_0_oe_x;

  logic spi_sd_1_in_x,spi_sd_1_out_x,spi_sd_1_oe_x;

  logic spi_sd_2_in_x,spi_sd_2_out_x,spi_sd_2_oe_x;

  logic spi_sd_3_in_x,spi_sd_3_out_x,spi_sd_3_oe_x;

  logic spi2_cs_0_in_x,spi2_cs_0_out_x,spi2_cs_0_oe_x;

  logic spi2_cs_1_in_x,spi2_cs_1_out_x,spi2_cs_1_oe_x;

  logic spi2_sck_in_x,spi2_sck_out_x,spi2_sck_oe_x;

  logic spi2_sd_0_in_x,spi2_sd_0_out_x,spi2_sd_0_oe_x;

  logic spi2_sd_1_in_x,spi2_sd_1_out_x,spi2_sd_1_oe_x;

  logic spi2_sd_2_in_x,spi2_sd_2_out_x,spi2_sd_2_oe_x;

  logic spi2_sd_3_in_x,spi2_sd_3_out_x,spi2_sd_3_oe_x;

  logic i2c_scl_in_x,i2c_scl_out_x,i2c_scl_oe_x;

  logic i2c_sda_in_x,i2c_sda_out_x,i2c_sda_oe_x;


  wire         clk_i;
  logic [31:0] exit_value;
  wire         rst_n;

  assign rst_n   = !rst_i;
  assign rst_led = rst_n;

  assign execute_from_flash_in_x = 1'b0;
  assign boot_select_in_x = 1'b0;

  xilinx_clk_wizard_wrapper xilinx_clk_wizard_wrapper_i (
    .clk_125MHz(clk_in),
    .clk_out1_0(clk_i)
  );

  if_xif #() ext_if ();

  core_v_mini_mcu #(
.EXT_XBAR_NMASTER(1)
  ) core_v_mini_mcu_i (
    .rst_ni(rst_ngen),
    .clk_i(clk_in_x),


    .boot_select_i(boot_select_in_x),

    .execute_from_flash_i(execute_from_flash_in_x),

    .jtag_tck_i(jtag_tck_in_x),

    .jtag_tms_i(jtag_tms_in_x),

    .jtag_trst_ni(jtag_trst_nin_x),

    .jtag_tdi_i(jtag_tdi_in_x),

    .jtag_tdo_o(jtag_tdo_out_x),

    .uart_rx_i(uart_rx_in_x),

    .uart_tx_o(uart_tx_out_x),

    .exit_valid_o(exit_valid_out_x),

    .gpio_0_i(gpio_0_in_x),
    .gpio_0_o(gpio_0_out_x),
    .gpio_0_oe_o(gpio_0_oe_x),

    .gpio_1_i(gpio_1_in_x),
    .gpio_1_o(gpio_1_out_x),
    .gpio_1_oe_o(gpio_1_oe_x),

    .gpio_2_i(gpio_2_in_x),
    .gpio_2_o(gpio_2_out_x),
    .gpio_2_oe_o(gpio_2_oe_x),

    .gpio_3_i(gpio_3_in_x),
    .gpio_3_o(gpio_3_out_x),
    .gpio_3_oe_o(gpio_3_oe_x),

    .gpio_4_i(gpio_4_in_x),
    .gpio_4_o(gpio_4_out_x),
    .gpio_4_oe_o(gpio_4_oe_x),

    .gpio_5_i(gpio_5_in_x),
    .gpio_5_o(gpio_5_out_x),
    .gpio_5_oe_o(gpio_5_oe_x),

    .gpio_6_i(gpio_6_in_x),
    .gpio_6_o(gpio_6_out_x),
    .gpio_6_oe_o(gpio_6_oe_x),

    .gpio_7_i(gpio_7_in_x),
    .gpio_7_o(gpio_7_out_x),
    .gpio_7_oe_o(gpio_7_oe_x),

    .gpio_8_i(gpio_8_in_x),
    .gpio_8_o(gpio_8_out_x),
    .gpio_8_oe_o(gpio_8_oe_x),

    .gpio_9_i(gpio_9_in_x),
    .gpio_9_o(gpio_9_out_x),
    .gpio_9_oe_o(gpio_9_oe_x),

    .gpio_10_i(gpio_10_in_x),
    .gpio_10_o(gpio_10_out_x),
    .gpio_10_oe_o(gpio_10_oe_x),

    .gpio_11_i(gpio_11_in_x),
    .gpio_11_o(gpio_11_out_x),
    .gpio_11_oe_o(gpio_11_oe_x),

    .gpio_12_i(gpio_12_in_x),
    .gpio_12_o(gpio_12_out_x),
    .gpio_12_oe_o(gpio_12_oe_x),

    .gpio_13_i(gpio_13_in_x),
    .gpio_13_o(gpio_13_out_x),
    .gpio_13_oe_o(gpio_13_oe_x),

    .gpio_14_i(gpio_14_in_x),
    .gpio_14_o(gpio_14_out_x),
    .gpio_14_oe_o(gpio_14_oe_x),

    .gpio_15_i(gpio_15_in_x),
    .gpio_15_o(gpio_15_out_x),
    .gpio_15_oe_o(gpio_15_oe_x),

    .gpio_16_i(gpio_16_in_x),
    .gpio_16_o(gpio_16_out_x),
    .gpio_16_oe_o(gpio_16_oe_x),

    .gpio_17_i(gpio_17_in_x),
    .gpio_17_o(gpio_17_out_x),
    .gpio_17_oe_o(gpio_17_oe_x),

    .gpio_18_i(gpio_18_in_x),
    .gpio_18_o(gpio_18_out_x),
    .gpio_18_oe_o(gpio_18_oe_x),

    .gpio_19_i(gpio_19_in_x),
    .gpio_19_o(gpio_19_out_x),
    .gpio_19_oe_o(gpio_19_oe_x),

    .gpio_20_i(gpio_20_in_x),
    .gpio_20_o(gpio_20_out_x),
    .gpio_20_oe_o(gpio_20_oe_x),

    .gpio_21_i(gpio_21_in_x),
    .gpio_21_o(gpio_21_out_x),
    .gpio_21_oe_o(gpio_21_oe_x),

    .gpio_22_i(gpio_22_in_x),
    .gpio_22_o(gpio_22_out_x),
    .gpio_22_oe_o(gpio_22_oe_x),

    .gpio_23_i(gpio_23_in_x),
    .gpio_23_o(gpio_23_out_x),
    .gpio_23_oe_o(gpio_23_oe_x),

    .gpio_24_i(gpio_24_in_x),
    .gpio_24_o(gpio_24_out_x),
    .gpio_24_oe_o(gpio_24_oe_x),

    .gpio_25_i(gpio_25_in_x),
    .gpio_25_o(gpio_25_out_x),
    .gpio_25_oe_o(gpio_25_oe_x),

    .gpio_26_i(gpio_26_in_x),
    .gpio_26_o(gpio_26_out_x),
    .gpio_26_oe_o(gpio_26_oe_x),

    .gpio_27_i(gpio_27_in_x),
    .gpio_27_o(gpio_27_out_x),
    .gpio_27_oe_o(gpio_27_oe_x),

    .gpio_28_i(gpio_28_in_x),
    .gpio_28_o(gpio_28_out_x),
    .gpio_28_oe_o(gpio_28_oe_x),

    .gpio_29_i(gpio_29_in_x),
    .gpio_29_o(gpio_29_out_x),
    .gpio_29_oe_o(gpio_29_oe_x),

    .gpio_30_i(gpio_30_in_x),
    .gpio_30_o(gpio_30_out_x),
    .gpio_30_oe_o(gpio_30_oe_x),

    .gpio_31_i(gpio_31_in_x),
    .gpio_31_o(gpio_31_out_x),
    .gpio_31_oe_o(gpio_31_oe_x),

    .spi_flash_sck_i(spi_flash_sck_in_x),
    .spi_flash_sck_o(spi_flash_sck_out_x),
    .spi_flash_sck_oe_o(spi_flash_sck_oe_x),

    .spi_flash_cs_0_i(spi_flash_cs_0_in_x),
    .spi_flash_cs_0_o(spi_flash_cs_0_out_x),
    .spi_flash_cs_0_oe_o(spi_flash_cs_0_oe_x),

    .spi_flash_cs_1_i(spi_flash_cs_1_in_x),
    .spi_flash_cs_1_o(spi_flash_cs_1_out_x),
    .spi_flash_cs_1_oe_o(spi_flash_cs_1_oe_x),

    .spi_flash_sd_0_i(spi_flash_sd_0_in_x),
    .spi_flash_sd_0_o(spi_flash_sd_0_out_x),
    .spi_flash_sd_0_oe_o(spi_flash_sd_0_oe_x),

    .spi_flash_sd_1_i(spi_flash_sd_1_in_x),
    .spi_flash_sd_1_o(spi_flash_sd_1_out_x),
    .spi_flash_sd_1_oe_o(spi_flash_sd_1_oe_x),

    .spi_flash_sd_2_i(spi_flash_sd_2_in_x),
    .spi_flash_sd_2_o(spi_flash_sd_2_out_x),
    .spi_flash_sd_2_oe_o(spi_flash_sd_2_oe_x),

    .spi_flash_sd_3_i(spi_flash_sd_3_in_x),
    .spi_flash_sd_3_o(spi_flash_sd_3_out_x),
    .spi_flash_sd_3_oe_o(spi_flash_sd_3_oe_x),

    .spi_sck_i(spi_sck_in_x),
    .spi_sck_o(spi_sck_out_x),
    .spi_sck_oe_o(spi_sck_oe_x),

    .spi_cs_0_i(spi_cs_0_in_x),
    .spi_cs_0_o(spi_cs_0_out_x),
    .spi_cs_0_oe_o(spi_cs_0_oe_x),

    .spi_cs_1_i(spi_cs_1_in_x),
    .spi_cs_1_o(spi_cs_1_out_x),
    .spi_cs_1_oe_o(spi_cs_1_oe_x),

    .spi_sd_0_i(spi_sd_0_in_x),
    .spi_sd_0_o(spi_sd_0_out_x),
    .spi_sd_0_oe_o(spi_sd_0_oe_x),

    .spi_sd_1_i(spi_sd_1_in_x),
    .spi_sd_1_o(spi_sd_1_out_x),
    .spi_sd_1_oe_o(spi_sd_1_oe_x),

    .spi_sd_2_i(spi_sd_2_in_x),
    .spi_sd_2_o(spi_sd_2_out_x),
    .spi_sd_2_oe_o(spi_sd_2_oe_x),

    .spi_sd_3_i(spi_sd_3_in_x),
    .spi_sd_3_o(spi_sd_3_out_x),
    .spi_sd_3_oe_o(spi_sd_3_oe_x),

    .spi2_cs_0_i(spi2_cs_0_in_x),
    .spi2_cs_0_o(spi2_cs_0_out_x),
    .spi2_cs_0_oe_o(spi2_cs_0_oe_x),

    .spi2_cs_1_i(spi2_cs_1_in_x),
    .spi2_cs_1_o(spi2_cs_1_out_x),
    .spi2_cs_1_oe_o(spi2_cs_1_oe_x),

    .spi2_sck_i(spi2_sck_in_x),
    .spi2_sck_o(spi2_sck_out_x),
    .spi2_sck_oe_o(spi2_sck_oe_x),

    .spi2_sd_0_i(spi2_sd_0_in_x),
    .spi2_sd_0_o(spi2_sd_0_out_x),
    .spi2_sd_0_oe_o(spi2_sd_0_oe_x),

    .spi2_sd_1_i(spi2_sd_1_in_x),
    .spi2_sd_1_o(spi2_sd_1_out_x),
    .spi2_sd_1_oe_o(spi2_sd_1_oe_x),

    .spi2_sd_2_i(spi2_sd_2_in_x),
    .spi2_sd_2_o(spi2_sd_2_out_x),
    .spi2_sd_2_oe_o(spi2_sd_2_oe_x),

    .spi2_sd_3_i(spi2_sd_3_in_x),
    .spi2_sd_3_o(spi2_sd_3_out_x),
    .spi2_sd_3_oe_o(spi2_sd_3_oe_x),

    .i2c_scl_i(i2c_scl_in_x),
    .i2c_scl_o(i2c_scl_out_x),
    .i2c_scl_oe_o(i2c_scl_oe_x),

    .i2c_sda_i(i2c_sda_in_x),
    .i2c_sda_o(i2c_sda_out_x),
    .i2c_sda_oe_o(i2c_sda_oe_x),

    .intr_vector_ext_i('0),
    .xif_compressed_if(ext_if),
    .xif_issue_if(ext_if),
    .xif_commit_if(ext_if),
    .xif_mem_if(ext_if),
    .xif_mem_result_if(ext_if),
    .xif_result_if(ext_if),
    .ext_xbar_master_req_i(r_obi_req),
    .ext_xbar_master_resp_o(r_obi_resp),
    .ext_xbar_slave_req_o(obi_req),
    .ext_xbar_slave_resp_i(obi_resp),
    .ext_peripheral_slave_req_o(),
    .ext_peripheral_slave_resp_i('0),
    .external_subsystem_powergate_switch_o(),
    .external_subsystem_powergate_switch_ack_i(),
    .external_subsystem_powergate_iso_o(),
    .external_subsystem_rst_no(),
    .external_ram_banks_set_retentive_o(),
    .exit_value_o(exit_value),
    .pad_req_o(pad_req),
    .pad_resp_i(pad_resp),
    .cpu_subsystem_powergate_switch_o(cpu_subsystem_powergate_switch),
    .cpu_subsystem_powergate_switch_ack_i(cpu_subsystem_powergate_switch_ack),
    .cpu_subsystem_sleep_o(cpu_subsystem_sleep),
    .peripheral_subsystem_powergate_switch_o(peripheral_subsystem_powergate_switch),
    .peripheral_subsystem_powergate_switch_ack_i(peripheral_subsystem_powergate_switch_ack),
    .peripheral_subsystem_clkgate_en_o(peripheral_subsystem_clkgate_en),
    .memory_subsystem_banks_powergate_switch_o(memory_subsystem_banks_powergate_switch),
    .memory_subsystem_banks_powergate_switch_ack_i(memory_subsystem_banks_powergate_switch_ack),
    .memory_subsystem_banks_set_retentive_o(memory_subsystem_banks_set_retentive),
    .memory_subsystem_clkgate_en_o(memory_subsystem_clkgate_en)
  );

  logic gpio_2_io;
  logic gpio_3_io;
  logic gpio_4_io;
  logic gpio_5_io;
  logic gpio_6_io;
  logic gpio_7_io;
  logic gpio_8_io;
  logic gpio_9_io;
  logic gpio_10_io;
  logic gpio_11_io;
  logic gpio_12_io;
  logic gpio_13_io;
  logic gpio_14_io;
  logic gpio_15_io;
  logic gpio_16_io;
  logic gpio_17_io;
  logic gpio_18_io;
  logic gpio_19_io;
  logic gpio_20_io;
  logic gpio_21_io;
  logic gpio_22_io;
  logic gpio_23_io;
  logic gpio_24_io;
  logic gpio_25_io;
  logic gpio_26_io;
  logic gpio_27_io;
  logic gpio_28_io;
  logic gpio_29_io;
  logic gpio_30_io;
  logic gpio_31_io;

  assign gpio_io[2] = gpio_2_io;
  assign gpio_io[3] = gpio_3_io;
  assign gpio_io[4] = gpio_4_io;
  assign gpio_io[5] = gpio_5_io;
  assign gpio_io[6] = gpio_6_io;
  assign gpio_io[7] = gpio_7_io;
  assign gpio_io[8] = gpio_8_io;
  assign gpio_io[9] = gpio_9_io;
  assign gpio_io[10] = gpio_10_io;
  assign gpio_io[11] = gpio_11_io;
  assign gpio_io[12] = gpio_12_io;
  assign gpio_io[13] = gpio_13_io;
  assign gpio_io[14] = gpio_14_io;
  assign gpio_io[15] = gpio_15_io;
  assign gpio_io[16] = gpio_16_io;
  assign gpio_io[17] = gpio_17_io;
  assign gpio_io[18] = gpio_18_io;
  assign gpio_io[19] = gpio_19_io;
  assign gpio_io[20] = gpio_20_io;
  assign gpio_io[21] = gpio_21_io;
  assign gpio_io[22] = gpio_22_io;
  assign gpio_io[23] = gpio_23_io;
  assign gpio_io[24] = gpio_24_io;
  assign gpio_io[25] = gpio_25_io;
  assign gpio_io[26] = gpio_26_io;
  assign gpio_io[27] = gpio_27_io;
  assign gpio_io[28] = gpio_28_io;
  assign gpio_io[29] = gpio_29_io;
  assign gpio_io[30] = gpio_30_io;
  assign gpio_io[31] = gpio_31_io;

  processing_system_wrapper processing_system_wrapper_i (
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
    .UART_RX(uart_tx_out_x),
    .UART_TX(uart_rx_in_x),
    .gpio_jtag_tck_i(jtag_tck_in_x),
    .gpio_jtag_tms_i(jtag_tms_in_x),
    .gpio_jtag_trst_ni(jtag_trst_nin_x),
    .gpio_jtag_tdi_i(jtag_tdi_in_x),
    .gpio_jtag_tdo_o(jtag_tdo_out_x),

    .X_HEEP_CLK(clk_in_x),
    .X_HEEP_RSTN(rst_ngen),

    .AXI_M_FLASH_araddr(AXI_M_FLASH_araddr_sig),
    .AXI_M_FLASH_arburst(AXI_M_FLASH_arburst_sig),
    .AXI_M_FLASH_arcache(AXI_M_FLASH_arcache_sig),
    .AXI_M_FLASH_arid(AXI_M_FLASH_arid_sig),
    .AXI_M_FLASH_arlen(AXI_M_FLASH_arlen_sig),
    .AXI_M_FLASH_arlock(AXI_M_FLASH_arlock_sig),
    .AXI_M_FLASH_arprot(AXI_M_FLASH_arprot_sig),
    .AXI_M_FLASH_arqos(AXI_M_FLASH_arqos_sig),
    .AXI_M_FLASH_arready(AXI_M_FLASH_arready_sig),
    .AXI_M_FLASH_arregion(AXI_M_FLASH_arregion_sig),
    .AXI_M_FLASH_arsize(AXI_M_FLASH_arsize_sig),
    .AXI_M_FLASH_arvalid(AXI_M_FLASH_arvalid_sig),
    .AXI_M_FLASH_awaddr(AXI_M_FLASH_awaddr_sig),
    .AXI_M_FLASH_awburst(AXI_M_FLASH_awburst_sig),
    .AXI_M_FLASH_awcache(AXI_M_FLASH_awcache_sig),
    .AXI_M_FLASH_awid(AXI_M_FLASH_awid_sig),
    .AXI_M_FLASH_awlen(AXI_M_FLASH_awlen_sig),
    .AXI_M_FLASH_awlock(AXI_M_FLASH_awlock_sig),
    .AXI_M_FLASH_awprot(AXI_M_FLASH_awprot_sig),
    .AXI_M_FLASH_awqos(AXI_M_FLASH_awqos_sig),
    .AXI_M_FLASH_awready(AXI_M_FLASH_awready_sig),
    .AXI_M_FLASH_awregion(AXI_M_FLASH_awregion_sig),
    .AXI_M_FLASH_awsize(AXI_M_FLASH_awsize_sig),
    .AXI_M_FLASH_awvalid(AXI_M_FLASH_awvalid_sig),
    .AXI_M_FLASH_bid(AXI_M_FLASH_bid_sig),
    .AXI_M_FLASH_bready(AXI_M_FLASH_bready_sig),
    .AXI_M_FLASH_bresp(AXI_M_FLASH_bresp_sig),
    .AXI_M_FLASH_bvalid(AXI_M_FLASH_bvalid_sig),
    .AXI_M_FLASH_rdata(AXI_M_FLASH_rdata_sig),
    .AXI_M_FLASH_rid(AXI_M_FLASH_rid_sig),
    .AXI_M_FLASH_rlast(AXI_M_FLASH_rlast_sig),
    .AXI_M_FLASH_rready(AXI_M_FLASH_rready_sig),
    .AXI_M_FLASH_rresp(AXI_M_FLASH_rresp_sig),
    .AXI_M_FLASH_rvalid(AXI_M_FLASH_rvalid_sig),
    .AXI_M_FLASH_wdata(AXI_M_FLASH_wdata_sig),
    .AXI_M_FLASH_wlast(AXI_M_FLASH_wlast_sig),
    .AXI_M_FLASH_wready(AXI_M_FLASH_wready_sig),
    .AXI_M_FLASH_wstrb(AXI_M_FLASH_wstrb_sig),
    .AXI_M_FLASH_wvalid(AXI_M_FLASH_wvalid_sig),

    .AXI_M_ADC_araddr(AXI_M_ADC_araddr_sig),
    .AXI_M_ADC_arburst(AXI_M_ADC_arburst_sig),
    .AXI_M_ADC_arcache(AXI_M_ADC_arcache_sig),
    .AXI_M_ADC_arid(AXI_M_ADC_arid_sig),
    .AXI_M_ADC_arlen(AXI_M_ADC_arlen_sig),
    .AXI_M_ADC_arlock(AXI_M_ADC_arlock_sig),
    .AXI_M_ADC_arprot(AXI_M_ADC_arprot_sig),
    .AXI_M_ADC_arqos(AXI_M_ADC_arqos_sig),
    .AXI_M_ADC_arready(AXI_M_ADC_arready_sig),
    .AXI_M_ADC_arregion(AXI_M_ADC_arregion_sig),
    .AXI_M_ADC_arsize(AXI_M_ADC_arsize_sig),
    .AXI_M_ADC_arvalid(AXI_M_ADC_arvalid_sig),
    .AXI_M_ADC_awaddr(AXI_M_ADC_awaddr_sig),
    .AXI_M_ADC_awburst(AXI_M_ADC_awburst_sig),
    .AXI_M_ADC_awcache(AXI_M_ADC_awcache_sig),
    .AXI_M_ADC_awid(AXI_M_ADC_awid_sig),
    .AXI_M_ADC_awlen(AXI_M_ADC_awlen_sig),
    .AXI_M_ADC_awlock(AXI_M_ADC_awlock_sig),
    .AXI_M_ADC_awprot(AXI_M_ADC_awprot_sig),
    .AXI_M_ADC_awqos(AXI_M_ADC_awqos_sig),
    .AXI_M_ADC_awready(AXI_M_ADC_awready_sig),
    .AXI_M_ADC_awregion(AXI_M_ADC_awregion_sig),
    .AXI_M_ADC_awsize(AXI_M_ADC_awsize_sig),
    .AXI_M_ADC_awvalid(AXI_M_ADC_awvalid_sig),
    .AXI_M_ADC_bid(AXI_M_ADC_bid_sig),
    .AXI_M_ADC_bready(AXI_M_ADC_bready_sig),
    .AXI_M_ADC_bresp(AXI_M_ADC_bresp_sig),
    .AXI_M_ADC_bvalid(AXI_M_ADC_bvalid_sig),
    .AXI_M_ADC_rdata(AXI_M_ADC_rdata_sig),
    .AXI_M_ADC_rid(AXI_M_ADC_rid_sig),
    .AXI_M_ADC_rlast(AXI_M_ADC_rlast_sig),
    .AXI_M_ADC_rready(AXI_M_ADC_rready_sig),
    .AXI_M_ADC_rresp(AXI_M_ADC_rresp_sig),
    .AXI_M_ADC_rvalid(AXI_M_ADC_rvalid_sig),
    .AXI_M_ADC_wdata(AXI_M_ADC_wdata_sig),
    .AXI_M_ADC_wlast(AXI_M_ADC_wlast_sig),
    .AXI_M_ADC_wready(AXI_M_ADC_wready_sig),
    .AXI_M_ADC_wstrb(AXI_M_ADC_wstrb_sig),
    .AXI_M_ADC_wvalid(AXI_M_ADC_wvalid_sig),

    .AXI_M_OBI_araddr(AXI_M_OBI_araddr_sig),
    .AXI_M_OBI_arburst(AXI_M_OBI_arburst_sig),
    .AXI_M_OBI_arcache(AXI_M_OBI_arcache_sig),
    .AXI_M_OBI_arid(AXI_M_OBI_arid_sig),
    .AXI_M_OBI_arlen(AXI_M_OBI_arlen_sig),
    .AXI_M_OBI_arlock(AXI_M_OBI_arlock_sig),
    .AXI_M_OBI_arprot(AXI_M_OBI_arprot_sig),
    .AXI_M_OBI_arqos(AXI_M_OBI_arqos_sig),
    .AXI_M_OBI_arready(AXI_M_OBI_arready_sig),
    .AXI_M_OBI_arregion(AXI_M_OBI_arregion_sig),
    .AXI_M_OBI_arsize(AXI_M_OBI_arsize_sig),
    .AXI_M_OBI_arvalid(AXI_M_OBI_arvalid_sig),
    .AXI_M_OBI_awaddr(AXI_M_OBI_awaddr_sig),
    .AXI_M_OBI_awburst(AXI_M_OBI_awburst_sig),
    .AXI_M_OBI_awcache(AXI_M_OBI_awcache_sig),
    .AXI_M_OBI_awid(AXI_M_OBI_awid_sig),
    .AXI_M_OBI_awlen(AXI_M_OBI_awlen_sig),
    .AXI_M_OBI_awlock(AXI_M_OBI_awlock_sig),
    .AXI_M_OBI_awprot(AXI_M_OBI_awprot_sig),
    .AXI_M_OBI_awqos(AXI_M_OBI_awqos_sig),
    .AXI_M_OBI_awready(AXI_M_OBI_awready_sig),
    .AXI_M_OBI_awregion(AXI_M_OBI_awregion_sig),
    .AXI_M_OBI_awsize(AXI_M_OBI_awsize_sig),
    .AXI_M_OBI_awvalid(AXI_M_OBI_awvalid_sig),
    .AXI_M_OBI_bid(AXI_M_OBI_bid_sig),
    .AXI_M_OBI_bready(AXI_M_OBI_bready_sig),
    .AXI_M_OBI_bresp(AXI_M_OBI_bresp_sig),
    .AXI_M_OBI_bvalid(AXI_M_OBI_bvalid_sig),
    .AXI_M_OBI_rdata(AXI_M_OBI_rdata_sig),
    .AXI_M_OBI_rid(AXI_M_OBI_rid_sig),
    .AXI_M_OBI_rlast(AXI_M_OBI_rlast_sig),
    .AXI_M_OBI_rready(AXI_M_OBI_rready_sig),
    .AXI_M_OBI_rresp(AXI_M_OBI_rresp_sig),
    .AXI_M_OBI_rvalid(AXI_M_OBI_rvalid_sig),
    .AXI_M_OBI_wdata(AXI_M_OBI_wdata_sig),
    .AXI_M_OBI_wlast(AXI_M_OBI_wlast_sig),
    .AXI_M_OBI_wready(AXI_M_OBI_wready_sig),
    .AXI_M_OBI_wstrb(AXI_M_OBI_wstrb_sig),
    .AXI_M_OBI_wvalid(AXI_M_OBI_wvalid_sig),

    .AXI_S_FLASH_araddr(AXI_S_FLASH_araddr_sig),
    .AXI_S_FLASH_arprot(AXI_S_FLASH_arprot_sig),
    .AXI_S_FLASH_arready(AXI_S_FLASH_arready_sig),
    .AXI_S_FLASH_arvalid(AXI_S_FLASH_arvalid_sig),
    .AXI_S_FLASH_awaddr(AXI_S_FLASH_awaddr_sig),
    .AXI_S_FLASH_awprot(AXI_S_FLASH_awprot_sig),
    .AXI_S_FLASH_awready(AXI_S_FLASH_awready_sig),
    .AXI_S_FLASH_awvalid(AXI_S_FLASH_awvalid_sig),
    .AXI_S_FLASH_bready(AXI_S_FLASH_bready_sig),
    .AXI_S_FLASH_bresp(AXI_S_FLASH_bresp_sig),
    .AXI_S_FLASH_bvalid(AXI_S_FLASH_bvalid_sig),
    .AXI_S_FLASH_rdata(AXI_S_FLASH_rdata_sig),
    .AXI_S_FLASH_rready(AXI_S_FLASH_rready_sig),
    .AXI_S_FLASH_rresp(AXI_S_FLASH_rresp_sig),
    .AXI_S_FLASH_rvalid(AXI_S_FLASH_rvalid_sig),
    .AXI_S_FLASH_wdata(AXI_S_FLASH_wdata_sig),
    .AXI_S_FLASH_wready(AXI_S_FLASH_wready_sig),
    .AXI_S_FLASH_wstrb(AXI_S_FLASH_wstrb_sig),
    .AXI_S_FLASH_wvalid(AXI_S_FLASH_wvalid_sig),

    .AXI_S_PERF_CNT_araddr(AXI_S_PERF_CNT_araddr_sig),
    .AXI_S_PERF_CNT_arprot(AXI_S_PERF_CNT_arprot_sig),
    .AXI_S_PERF_CNT_arready(AXI_S_PERF_CNT_arready_sig),
    .AXI_S_PERF_CNT_arvalid(AXI_S_PERF_CNT_arvalid_sig),
    .AXI_S_PERF_CNT_awaddr(AXI_S_PERF_CNT_awaddr_sig),
    .AXI_S_PERF_CNT_awprot(AXI_S_PERF_CNT_awprot_sig),
    .AXI_S_PERF_CNT_awready(AXI_S_PERF_CNT_awready_sig),
    .AXI_S_PERF_CNT_awvalid(AXI_S_PERF_CNT_awvalid_sig),
    .AXI_S_PERF_CNT_bready(AXI_S_PERF_CNT_bready_sig),
    .AXI_S_PERF_CNT_bresp(AXI_S_PERF_CNT_bresp_sig),
    .AXI_S_PERF_CNT_bvalid(AXI_S_PERF_CNT_bvalid_sig),
    .AXI_S_PERF_CNT_rdata(AXI_S_PERF_CNT_rdata_sig),
    .AXI_S_PERF_CNT_rready(AXI_S_PERF_CNT_rready_sig),
    .AXI_S_PERF_CNT_rresp(AXI_S_PERF_CNT_rresp_sig),
    .AXI_S_PERF_CNT_rvalid(AXI_S_PERF_CNT_rvalid_sig),
    .AXI_S_PERF_CNT_wdata(AXI_S_PERF_CNT_wdata_sig),
    .AXI_S_PERF_CNT_wready(AXI_S_PERF_CNT_wready_sig),
    .AXI_S_PERF_CNT_wstrb(AXI_S_PERF_CNT_wstrb_sig),
    .AXI_S_PERF_CNT_wvalid(AXI_S_PERF_CNT_wvalid_sig),

    .AXI_S_OBI_araddr(AXI_S_OBI_araddr_sig),
    .AXI_S_OBI_arprot(AXI_S_OBI_arprot_sig),
    .AXI_S_OBI_arready(AXI_S_OBI_arready_sig),
    .AXI_S_OBI_arvalid(AXI_S_OBI_arvalid_sig),
    .AXI_S_OBI_awaddr(AXI_S_OBI_awaddr_sig),
    .AXI_S_OBI_awprot(AXI_S_OBI_awprot_sig),
    .AXI_S_OBI_awready(AXI_S_OBI_awready_sig),
    .AXI_S_OBI_awvalid(AXI_S_OBI_awvalid_sig),
    .AXI_S_OBI_bready(AXI_S_OBI_bready_sig),
    .AXI_S_OBI_bresp(AXI_S_OBI_bresp_sig),
    .AXI_S_OBI_bvalid(AXI_S_OBI_bvalid_sig),
    .AXI_S_OBI_rdata(AXI_S_OBI_rdata_sig),
    .AXI_S_OBI_rready(AXI_S_OBI_rready_sig),
    .AXI_S_OBI_rresp(AXI_S_OBI_rresp_sig),
    .AXI_S_OBI_rvalid(AXI_S_OBI_rvalid_sig),
    .AXI_S_OBI_wdata(AXI_S_OBI_wdata_sig),
    .AXI_S_OBI_wready(AXI_S_OBI_wready_sig),
    .AXI_S_OBI_wstrb(AXI_S_OBI_wstrb_sig),
    .AXI_S_OBI_wvalid(AXI_S_OBI_wvalid_sig),

    .AXI_S_R_OBI_BAA_araddr(AXI_S_R_OBI_BAA_araddr_sig),
    .AXI_S_R_OBI_BAA_arprot(AXI_S_R_OBI_BAA_arprot_sig),
    .AXI_S_R_OBI_BAA_arready(AXI_S_R_OBI_BAA_arready_sig),
    .AXI_S_R_OBI_BAA_arvalid(AXI_S_R_OBI_BAA_arvalid_sig),
    .AXI_S_R_OBI_BAA_awaddr(AXI_S_R_OBI_BAA_awaddr_sig),
    .AXI_S_R_OBI_BAA_awprot(AXI_S_R_OBI_BAA_awprot_sig),
    .AXI_S_R_OBI_BAA_awready(AXI_S_R_OBI_BAA_awready_sig),
    .AXI_S_R_OBI_BAA_awvalid(AXI_S_R_OBI_BAA_awvalid_sig),
    .AXI_S_R_OBI_BAA_bready(AXI_S_R_OBI_BAA_bready_sig),
    .AXI_S_R_OBI_BAA_bresp(AXI_S_R_OBI_BAA_bresp_sig),
    .AXI_S_R_OBI_BAA_bvalid(AXI_S_R_OBI_BAA_bvalid_sig),
    .AXI_S_R_OBI_BAA_rdata(AXI_S_R_OBI_BAA_rdata_sig),
    .AXI_S_R_OBI_BAA_rready(AXI_S_R_OBI_BAA_rready_sig),
    .AXI_S_R_OBI_BAA_rresp(AXI_S_R_OBI_BAA_rresp_sig),
    .AXI_S_R_OBI_BAA_rvalid(AXI_S_R_OBI_BAA_rvalid_sig),
    .AXI_S_R_OBI_BAA_wdata(AXI_S_R_OBI_BAA_wdata_sig),
    .AXI_S_R_OBI_BAA_wready(AXI_S_R_OBI_BAA_wready_sig),
    .AXI_S_R_OBI_BAA_wstrb(AXI_S_R_OBI_BAA_wstrb_sig),
    .AXI_S_R_OBI_BAA_wvalid(AXI_S_R_OBI_BAA_wvalid_sig),

    .AXI_S_R_OBI_araddr(AXI_S_R_OBI_araddr_sig),
    .AXI_S_R_OBI_arprot(AXI_S_R_OBI_arprot_sig),
    .AXI_S_R_OBI_arready(AXI_S_R_OBI_arready_sig),
    .AXI_S_R_OBI_arvalid(AXI_S_R_OBI_arvalid_sig),
    .AXI_S_R_OBI_awaddr(AXI_S_R_OBI_awaddr_sig),
    .AXI_S_R_OBI_awprot(AXI_S_R_OBI_awprot_sig),
    .AXI_S_R_OBI_awready(AXI_S_R_OBI_awready_sig),
    .AXI_S_R_OBI_awvalid(AXI_S_R_OBI_awvalid_sig),
    .AXI_S_R_OBI_bready(AXI_S_R_OBI_bready_sig),
    .AXI_S_R_OBI_bresp(AXI_S_R_OBI_bresp_sig),
    .AXI_S_R_OBI_bvalid(AXI_S_R_OBI_bvalid_sig),
    .AXI_S_R_OBI_rdata(AXI_S_R_OBI_rdata_sig),
    .AXI_S_R_OBI_rready(AXI_S_R_OBI_rready_sig),
    .AXI_S_R_OBI_rresp(AXI_S_R_OBI_rresp_sig),
    .AXI_S_R_OBI_rvalid(AXI_S_R_OBI_rvalid_sig),
    .AXI_S_R_OBI_wdata(AXI_S_R_OBI_wdata_sig),
    .AXI_S_R_OBI_wready(AXI_S_R_OBI_wready_sig),
    .AXI_S_R_OBI_wstrb(AXI_S_R_OBI_wstrb_sig),
    .AXI_S_R_OBI_wvalid(AXI_S_R_OBI_wvalid_sig)
  );

  performance_counters #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) performance_counters_i (
    .S_AXI_ACLK(clk_in_x),
    .S_AXI_ARESETN(rst_ngen),

    .S_AXI_AWADDR (AXI_S_PERF_CNT_awaddr_sig),
    .S_AXI_AWPROT (AXI_S_PERF_CNT_awprot_sig),
    .S_AXI_AWVALID(AXI_S_PERF_CNT_awvalid_sig),
    .S_AXI_AWREADY(AXI_S_PERF_CNT_awready_sig),
    .S_AXI_WDATA  (AXI_S_PERF_CNT_wdata_sig),
    .S_AXI_WSTRB  (AXI_S_PERF_CNT_wstrb_sig),
    .S_AXI_WVALID (AXI_S_PERF_CNT_wvalid_sig),
    .S_AXI_WREADY (AXI_S_PERF_CNT_wready_sig),
    .S_AXI_BRESP  (AXI_S_PERF_CNT_bresp_sig),
    .S_AXI_BVALID (AXI_S_PERF_CNT_bvalid_sig),
    .S_AXI_BREADY (AXI_S_PERF_CNT_bready_sig),
    .S_AXI_ARADDR (AXI_S_PERF_CNT_araddr_sig),
    .S_AXI_ARPROT (AXI_S_PERF_CNT_arprot_sig),
    .S_AXI_ARVALID(AXI_S_PERF_CNT_arvalid_sig),
    .S_AXI_ARREADY(AXI_S_PERF_CNT_arready_sig),
    .S_AXI_RDATA  (AXI_S_PERF_CNT_rdata_sig),
    .S_AXI_RRESP  (AXI_S_PERF_CNT_rresp_sig),
    .S_AXI_RVALID (AXI_S_PERF_CNT_rvalid_sig),
    .S_AXI_RREADY (AXI_S_PERF_CNT_rready_sig),

    .start_automatic_i(gpio_0_out_x),
    .start_manual_i(gpio_1_out_x),
    .cpu_clock_gate_i(cpu_subsystem_sleep),
    .cpu_power_gate_i(~cpu_subsystem_powergate_switch),
    .bus_ao_clock_gate_i(1'b0),
    .debug_ao_clock_gate_i(1'b0),
    .soc_ctrl_ao_clock_gate_i(1'b0),
    .boot_rom_ao_clock_gate_i(1'b0),
    .spi_flash_ao_clock_gate_i(1'b0),
    .spi_ao_clock_gate_i(1'b0),
    .power_manager_ao_clock_gate_i(1'b0),
    .timer_ao_clock_gate_i(1'b0),
    .dma_ao_clock_gate_i(1'b0),
    .fast_int_ctrl_ao_clock_gate_i(1'b0),
    .gpio_ao_clock_gate_i(1'b0),
    .uart_ao_clock_gate_i(1'b0),
    .plic_clock_gate_i(peripheral_subsystem_clkgate_en),
    .plic_power_gate_i(~peripheral_subsystem_powergate_switch),
    .gpio_clock_gate_i(peripheral_subsystem_clkgate_en),
    .gpio_power_gate_i(~peripheral_subsystem_powergate_switch),
    .i2c_clock_gate_i(peripheral_subsystem_clkgate_en),
    .i2c_power_gate_i(~peripheral_subsystem_powergate_switch),
    .timer_clock_gate_i(peripheral_subsystem_clkgate_en),
    .timer_power_gate_i(~peripheral_subsystem_powergate_switch),
    .spi_clock_gate_i(peripheral_subsystem_clkgate_en),
    .spi_power_gate_i(~peripheral_subsystem_powergate_switch),
    .ram_bank_0_clock_gate_i(memory_subsystem_clkgate_en[0]),
    .ram_bank_0_power_gate_i(~memory_subsystem_banks_powergate_switch[0]),
    .ram_bank_0_retentive_i(~memory_subsystem_banks_set_retentive[0]),
    .ram_bank_1_clock_gate_i(memory_subsystem_clkgate_en[0]),
    .ram_bank_1_power_gate_i(~memory_subsystem_banks_powergate_switch[1]),
    .ram_bank_1_retentive_i(~memory_subsystem_banks_set_retentive[1]),
    .ram_bank_2_clock_gate_i(memory_subsystem_clkgate_en[0]),
    .ram_bank_2_power_gate_i(~memory_subsystem_banks_powergate_switch[2]),
    .ram_bank_2_retentive_i(~memory_subsystem_banks_set_retentive[2]),
    .ram_bank_3_clock_gate_i(memory_subsystem_clkgate_en[0]),
    .ram_bank_3_power_gate_i(~memory_subsystem_banks_powergate_switch[3]),
    .ram_bank_3_retentive_i(~memory_subsystem_banks_set_retentive[3])
  );

  axi_address_adder #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_address_adder_virtual_flash_i (
    .axi_master_awaddr_in(AXI_M_FLASH_awaddr_in_sig),
    .axi_master_araddr_in(AXI_M_FLASH_araddr_in_sig),

    .axi_master_araddr_out(AXI_M_FLASH_araddr_sig),
    .axi_master_awaddr_out(AXI_M_FLASH_awaddr_sig),

    .S_AXI_ACLK(clk_in_x),
    .S_AXI_ARESETN(rst_ngen),

    .S_AXI_AWADDR (AXI_S_FLASH_awaddr_sig),
    .S_AXI_AWPROT (AXI_S_FLASH_awprot_sig),
    .S_AXI_AWVALID(AXI_S_FLASH_awvalid_sig),
    .S_AXI_AWREADY(AXI_S_FLASH_awready_sig),
    .S_AXI_WDATA  (AXI_S_FLASH_wdata_sig),
    .S_AXI_WSTRB  (AXI_S_FLASH_wstrb_sig),
    .S_AXI_WVALID (AXI_S_FLASH_wvalid_sig),
    .S_AXI_WREADY (AXI_S_FLASH_wready_sig),
    .S_AXI_BRESP  (AXI_S_FLASH_bresp_sig),
    .S_AXI_BVALID (AXI_S_FLASH_bvalid_sig),
    .S_AXI_BREADY (AXI_S_FLASH_bready_sig),
    .S_AXI_ARADDR (AXI_S_FLASH_araddr_sig),
    .S_AXI_ARPROT (AXI_S_FLASH_arprot_sig),
    .S_AXI_ARVALID(AXI_S_FLASH_arvalid_sig),
    .S_AXI_ARREADY(AXI_S_FLASH_arready_sig),
    .S_AXI_RDATA  (AXI_S_FLASH_rdata_sig),
    .S_AXI_RRESP  (AXI_S_FLASH_rresp_sig),
    .S_AXI_RVALID (AXI_S_FLASH_rvalid_sig),
    .S_AXI_RREADY (AXI_S_FLASH_rready_sig)
  );

  axi_spi_slave #(
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) spi2axi_bridge_virtual_flash_i (
    .axi_aclk(clk_in_x),
    .axi_aresetn(rst_ngen),

    .test_mode('0),

    .axi_master_aw_valid(AXI_M_FLASH_awvalid_sig),
    .axi_master_aw_id(AXI_M_FLASH_awid_sig),
    .axi_master_aw_prot(AXI_M_FLASH_awprot_sig),
    .axi_master_aw_qos(AXI_M_FLASH_awqos_sig),
    .axi_master_aw_cache(AXI_M_FLASH_awcache_sig),
    .axi_master_aw_lock(AXI_M_FLASH_awlock_sig),
    .axi_master_aw_burst(AXI_M_FLASH_awburst_sig),
    .axi_master_aw_size(AXI_M_FLASH_awsize_sig),
    .axi_master_aw_len(AXI_M_FLASH_awlen_sig),
    .axi_master_aw_addr(AXI_M_FLASH_awaddr_in_sig),
    .axi_master_aw_ready(AXI_M_FLASH_awready_sig),

    .axi_master_w_valid(AXI_M_FLASH_wvalid_sig),
    .axi_master_w_data (AXI_M_FLASH_wdata_sig),
    .axi_master_w_strb (AXI_M_FLASH_wstrb_sig),
    .axi_master_w_last (AXI_M_FLASH_wlast_sig),
    .axi_master_w_ready(AXI_M_FLASH_wready_sig),

    .axi_master_b_valid(AXI_M_FLASH_bvalid_sig),
    .axi_master_b_id(AXI_M_FLASH_bid_sig),
    .axi_master_b_resp(AXI_M_FLASH_bresp_sig),
    .axi_master_b_ready(AXI_M_FLASH_bready_sig),

    .axi_master_ar_valid(AXI_M_FLASH_arvalid_sig),
    .axi_master_ar_id(AXI_M_FLASH_arid_sig),
    .axi_master_ar_prot(AXI_M_FLASH_arprot_sig),
    .axi_master_ar_qos(AXI_M_FLASH_arqos_sig),
    .axi_master_ar_cache(AXI_M_FLASH_arcache_sig),
    .axi_master_ar_lock(AXI_M_FLASH_arlock_sig),
    .axi_master_ar_burst(AXI_M_FLASH_arburst_sig),
    .axi_master_ar_size(AXI_M_FLASH_arsize_sig),
    .axi_master_ar_len(AXI_M_FLASH_arlen_sig),
    .axi_master_ar_addr(AXI_M_FLASH_araddr_in_sig),
    .axi_master_ar_ready(AXI_M_FLASH_arready_sig),

    .axi_master_r_valid(AXI_M_FLASH_rvalid_sig),
    .axi_master_r_id(AXI_M_FLASH_rid_sig),
    .axi_master_r_data(AXI_M_FLASH_rdata_sig),
    .axi_master_r_resp(AXI_M_FLASH_rresp_sig),
    .axi_master_r_last(AXI_M_FLASH_rlast_sig),
    .axi_master_r_ready(AXI_M_FLASH_rready_sig),

    .spi_sclk(spi_flash_sck_out_x),
    .spi_cs  (spi_flash_cs_0_out_x),
    .spi_sdo1(spi_flash_sd_1_in_x),
    .spi_sdi0(spi_flash_sd_0_out_x),
    .spi_sdi2(spi_flash_sd_2_out_x),
    .spi_sdi3(spi_flash_sd_3_out_x)
  );

  axi_address_fix_adder #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
  ) axi_address_fix_adder_virtual_adc_i (
    .axi_master_awaddr_in(AXI_M_ADC_awaddr_in_sig),
    .axi_master_araddr_in(AXI_M_ADC_araddr_in_sig),

    .axi_master_araddr_out(AXI_M_ADC_araddr_sig),
    .axi_master_awaddr_out(AXI_M_ADC_awaddr_sig)
  );

  axi_spi_slave #(
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) spi2axi_bridge_virtual_adc_i (
    .axi_aclk(clk_in_x),
    .axi_aresetn(rst_ngen),

    .test_mode('0),

    .axi_master_aw_valid(AXI_M_ADC_awvalid_sig),
    .axi_master_aw_id(AXI_M_ADC_awid_sig),
    .axi_master_aw_prot(AXI_M_ADC_awprot_sig),
    .axi_master_aw_qos(AXI_M_ADC_awqos_sig),
    .axi_master_aw_cache(AXI_M_ADC_awcache_sig),
    .axi_master_aw_lock(AXI_M_ADC_awlock_sig),
    .axi_master_aw_burst(AXI_M_ADC_awburst_sig),
    .axi_master_aw_size(AXI_M_ADC_awsize_sig),
    .axi_master_aw_len(AXI_M_ADC_awlen_sig),
    .axi_master_aw_addr(AXI_M_ADC_awaddr_in_sig),
    .axi_master_aw_ready(AXI_M_ADC_awready_sig),

    .axi_master_w_valid(AXI_M_ADC_wvalid_sig),
    .axi_master_w_data (AXI_M_ADC_wdata_sig),
    .axi_master_w_strb (AXI_M_ADC_wstrb_sig),
    .axi_master_w_last (AXI_M_ADC_wlast_sig),
    .axi_master_w_ready(AXI_M_ADC_wready_sig),

    .axi_master_b_valid(AXI_M_ADC_bvalid_sig),
    .axi_master_b_id(AXI_M_ADC_bid_sig),
    .axi_master_b_resp(AXI_M_ADC_bresp_sig),
    .axi_master_b_ready(AXI_M_ADC_bready_sig),

    .axi_master_ar_valid(AXI_M_ADC_arvalid_sig),
    .axi_master_ar_id(AXI_M_ADC_arid_sig),
    .axi_master_ar_prot(AXI_M_ADC_arprot_sig),
    .axi_master_ar_qos(AXI_M_ADC_arqos_sig),
    .axi_master_ar_cache(AXI_M_ADC_arcache_sig),
    .axi_master_ar_lock(AXI_M_ADC_arlock_sig),
    .axi_master_ar_burst(AXI_M_ADC_arburst_sig),
    .axi_master_ar_size(AXI_M_ADC_arsize_sig),
    .axi_master_ar_len(AXI_M_ADC_arlen_sig),
    .axi_master_ar_addr(AXI_M_ADC_araddr_in_sig),
    .axi_master_ar_ready(AXI_M_ADC_arready_sig),

    .axi_master_r_valid(AXI_M_ADC_rvalid_sig),
    .axi_master_r_id(AXI_M_ADC_rid_sig),
    .axi_master_r_data(AXI_M_ADC_rdata_sig),
    .axi_master_r_resp(AXI_M_ADC_rresp_sig),
    .axi_master_r_last(AXI_M_ADC_rlast_sig),
    .axi_master_r_ready(AXI_M_ADC_rready_sig),

    .spi_sclk(spi_sck_out_x),
    .spi_cs  (spi_cs_0_out_x),
    .spi_sdo1(spi_sd_1_in_x),
    .spi_sdi0(spi_sd_0_out_x),
    .spi_sdi2(spi_sd_2_out_x),
    .spi_sdi3(spi_sd_3_out_x)
  );

  axi_address_adder #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_address_adder_virtual_obi_i (
    .axi_master_awaddr_in(32'h0FFFFFFF & AXI_M_OBI_awaddr_in_sig),
    .axi_master_araddr_in(32'h0FFFFFFF & AXI_M_OBI_araddr_in_sig),

    .axi_master_araddr_out(AXI_M_OBI_araddr_sig),
    .axi_master_awaddr_out(AXI_M_OBI_awaddr_sig),

    .S_AXI_ACLK(clk_in_x),
    .S_AXI_ARESETN(rst_ngen),

    .S_AXI_AWADDR (AXI_S_OBI_awaddr_sig),
    .S_AXI_AWPROT (AXI_S_OBI_awprot_sig),
    .S_AXI_AWVALID(AXI_S_OBI_awvalid_sig),
    .S_AXI_AWREADY(AXI_S_OBI_awready_sig),
    .S_AXI_WDATA  (AXI_S_OBI_wdata_sig),
    .S_AXI_WSTRB  (AXI_S_OBI_wstrb_sig),
    .S_AXI_WVALID (AXI_S_OBI_wvalid_sig),
    .S_AXI_WREADY (AXI_S_OBI_wready_sig),
    .S_AXI_BRESP  (AXI_S_OBI_bresp_sig),
    .S_AXI_BVALID (AXI_S_OBI_bvalid_sig),
    .S_AXI_BREADY (AXI_S_OBI_bready_sig),
    .S_AXI_ARADDR (AXI_S_OBI_araddr_sig),
    .S_AXI_ARPROT (AXI_S_OBI_arprot_sig),
    .S_AXI_ARVALID(AXI_S_OBI_arvalid_sig),
    .S_AXI_ARREADY(AXI_S_OBI_arready_sig),
    .S_AXI_RDATA  (AXI_S_OBI_rdata_sig),
    .S_AXI_RRESP  (AXI_S_OBI_rresp_sig),
    .S_AXI_RVALID (AXI_S_OBI_rvalid_sig),
    .S_AXI_RREADY (AXI_S_OBI_rready_sig)
  );

  core2axi #(
    .AXI4_WDATA_WIDTH(AXI_DATA_WIDTH),
    .AXI4_RDATA_WIDTH(AXI_DATA_WIDTH)
  ) obi2axi_bridge_virtual_obi_i (
    .clk_i(clk_in_x),
    .rst_ni(rst_ngen),

    .data_req_i(obi_req.req),
    .data_gnt_o(obi_resp.gnt),
    .data_rvalid_o(obi_resp.rvalid),
    .data_addr_i(obi_req.addr),
    .data_we_i(obi_req.we),
    .data_be_i(obi_req.be),
    .data_rdata_o(obi_resp.rdata),
    .data_wdata_i(obi_req.wdata),

    .aw_id_o(AXI_M_OBI_awid_sig),
    .aw_addr_o(AXI_M_OBI_awaddr_in_sig),
    .aw_len_o(AXI_M_OBI_awlen_sig),
    .aw_size_o(AXI_M_OBI_awsize_sig),
    .aw_burst_o(AXI_M_OBI_awburst_sig),
    .aw_lock_o(AXI_M_OBI_awlock_sig),
    .aw_cache_o(AXI_M_OBI_awcache_sig),
    .aw_prot_o(AXI_M_OBI_awprot_sig),
    .aw_region_o(AXI_M_OBI_awregion_sig),
    .aw_user_o(),
    .aw_qos_o(AXI_M_OBI_awqos_sig),
    .aw_valid_o(AXI_M_OBI_awvalid_sig),
    .aw_ready_i(AXI_M_OBI_awready_sig),

    .w_data_o(AXI_M_OBI_wdata_sig),
    .w_strb_o(AXI_M_OBI_wstrb_sig),
    .w_last_o(AXI_M_OBI_wlast_sig),
    .w_user_o(),
    .w_valid_o(AXI_M_OBI_wvalid_sig),
    .w_ready_i(AXI_M_OBI_wready_sig),

    .b_id_i(AXI_M_OBI_bid_sig),
    .b_resp_i(AXI_M_OBI_bresp_sig),
    .b_valid_i(AXI_M_OBI_bvalid_sig),
    .b_user_i('0),
    .b_ready_o(AXI_M_OBI_bready_sig),

    .ar_id_o(AXI_M_OBI_arid_sig),
    .ar_addr_o(AXI_M_OBI_araddr_in_sig),
    .ar_len_o(AXI_M_OBI_arlen_sig),
    .ar_size_o(AXI_M_OBI_arsize_sig),
    .ar_burst_o(AXI_M_OBI_arburst_sig),
    .ar_lock_o(AXI_M_OBI_arlock_sig),
    .ar_cache_o(AXI_M_OBI_arcache_sig),
    .ar_prot_o(AXI_M_OBI_arprot_sig),
    .ar_region_o(AXI_M_OBI_arregion_sig),
    .ar_user_o(),
    .ar_qos_o(AXI_M_OBI_arqos_sig),
    .ar_valid_o(AXI_M_OBI_arvalid_sig),
    .ar_ready_i(AXI_M_OBI_arready_sig),

    .r_id_i(AXI_M_OBI_rid_sig),
    .r_data_i(AXI_M_OBI_rdata_sig),
    .r_resp_i(AXI_M_OBI_rresp_sig),
    .r_last_i(AXI_M_OBI_rlast_sig),
    .r_user_i('0),
    .r_valid_i(AXI_M_OBI_rvalid_sig),
    .r_ready_o(AXI_M_OBI_rready_sig)
  );


  axi_address_adder #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_address_adder_virtual_r_obi_i (
    .axi_master_awaddr_in('0),
    .axi_master_araddr_in(32'h0000FFFF & r_obi_req_addr_in_sig),

    .axi_master_araddr_out(r_obi_req.addr),
    .axi_master_awaddr_out(),

    .S_AXI_ACLK(clk_in_x),
    .S_AXI_ARESETN(rst_ngen),

    .S_AXI_AWADDR (AXI_S_R_OBI_BAA_awaddr_sig),
    .S_AXI_AWPROT (AXI_S_R_OBI_BAA_awprot_sig),
    .S_AXI_AWVALID(AXI_S_R_OBI_BAA_awvalid_sig),
    .S_AXI_AWREADY(AXI_S_R_OBI_BAA_awready_sig),
    .S_AXI_WDATA  (AXI_S_R_OBI_BAA_wdata_sig),
    .S_AXI_WSTRB  (AXI_S_R_OBI_BAA_wstrb_sig),
    .S_AXI_WVALID (AXI_S_R_OBI_BAA_wvalid_sig),
    .S_AXI_WREADY (AXI_S_R_OBI_BAA_wready_sig),
    .S_AXI_BRESP  (AXI_S_R_OBI_BAA_bresp_sig),
    .S_AXI_BVALID (AXI_S_R_OBI_BAA_bvalid_sig),
    .S_AXI_BREADY (AXI_S_R_OBI_BAA_bready_sig),
    .S_AXI_ARADDR (AXI_S_R_OBI_BAA_araddr_sig),
    .S_AXI_ARPROT (AXI_S_R_OBI_BAA_arprot_sig),
    .S_AXI_ARVALID(AXI_S_R_OBI_BAA_arvalid_sig),
    .S_AXI_ARREADY(AXI_S_R_OBI_BAA_arready_sig),
    .S_AXI_RDATA  (AXI_S_R_OBI_BAA_rdata_sig),
    .S_AXI_RRESP  (AXI_S_R_OBI_BAA_rresp_sig),
    .S_AXI_RVALID (AXI_S_R_OBI_BAA_rvalid_sig),
    .S_AXI_RREADY (AXI_S_R_OBI_BAA_rready_sig)
  );

  axi2obi #(
    //.WordSize(),
    //.AddrSize(),
    .C_S00_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .C_S00_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)
  ) axi2obi_bridge_virtual_r_obi_i (
    .gnt_i(r_obi_resp.gnt),
    .rvalid_i(r_obi_resp.rvalid),
    .we_o(r_obi_req.we),
    .be_o(r_obi_req.be),
    .addr_o(r_obi_req_addr_in_sig),
    .wdata_o(r_obi_req.wdata),
    .rdata_i(r_obi_resp.rdata),
    .req_o(r_obi_req.req),

    .s00_axi_aclk(clk_in_x),
    .s00_axi_aresetn(rst_ngen),

    .s00_axi_araddr(AXI_S_R_OBI_araddr_sig),
    .s00_axi_arvalid(AXI_S_R_OBI_arvalid_sig),
    .s00_axi_arready(AXI_S_R_OBI_arready_sig),
    .s00_axi_arprot(AXI_S_R_OBI_arprot_sig),

    .s00_axi_rdata(AXI_S_R_OBI_rdata_sig),
    .s00_axi_rresp(AXI_S_R_OBI_rresp_sig),
    .s00_axi_rvalid(AXI_S_R_OBI_rvalid_sig),
    .s00_axi_rready(AXI_S_R_OBI_rready_sig),

    .s00_axi_awaddr(AXI_S_R_OBI_awaddr_sig),
    .s00_axi_awvalid(AXI_S_R_OBI_awvalid_sig),
    .s00_axi_awready(AXI_S_R_OBI_awready_sig),
    .s00_axi_awprot(AXI_S_R_OBI_awprot_sig),

    .s00_axi_wdata(AXI_S_R_OBI_wdata_sig),
    .s00_axi_wvalid(AXI_S_R_OBI_wvalid_sig),
    .s00_axi_wready(AXI_S_R_OBI_wready_sig),
    .s00_axi_wstrb(AXI_S_R_OBI_wstrb_sig),

    .s00_axi_bresp(AXI_S_R_OBI_bresp_sig),
    .s00_axi_bvalid(AXI_S_R_OBI_bvalid_sig),
    .s00_axi_bready(AXI_S_R_OBI_bready_sig)
  );


  pad_ring pad_ring_i (
    .clk_io(clk_i),
    .clk_o(clk_in_x),
    .rst_nio(rst_ni),
    .rst_no(rst_nin_x),












    .gpio_2_io(gpio_2_io),
    .gpio_2_o(gpio_2_in_x),
    .gpio_2_i(gpio_2_out_x),
    .gpio_2_oe_i(gpio_2_oe_x),
    .gpio_3_io(gpio_3_io),
    .gpio_3_o(gpio_3_in_x),
    .gpio_3_i(gpio_3_out_x),
    .gpio_3_oe_i(gpio_3_oe_x),
    .gpio_4_io(gpio_4_io),
    .gpio_4_o(gpio_4_in_x),
    .gpio_4_i(gpio_4_out_x),
    .gpio_4_oe_i(gpio_4_oe_x),
    .gpio_5_io(gpio_5_io),
    .gpio_5_o(gpio_5_in_x),
    .gpio_5_i(gpio_5_out_x),
    .gpio_5_oe_i(gpio_5_oe_x),
    .gpio_6_io(gpio_6_io),
    .gpio_6_o(gpio_6_in_x),
    .gpio_6_i(gpio_6_out_x),
    .gpio_6_oe_i(gpio_6_oe_x),
    .gpio_7_io(gpio_7_io),
    .gpio_7_o(gpio_7_in_x),
    .gpio_7_i(gpio_7_out_x),
    .gpio_7_oe_i(gpio_7_oe_x),
    .gpio_8_io(gpio_8_io),
    .gpio_8_o(gpio_8_in_x),
    .gpio_8_i(gpio_8_out_x),
    .gpio_8_oe_i(gpio_8_oe_x),
    .gpio_9_io(gpio_9_io),
    .gpio_9_o(gpio_9_in_x),
    .gpio_9_i(gpio_9_out_x),
    .gpio_9_oe_i(gpio_9_oe_x),
    .gpio_10_io(gpio_10_io),
    .gpio_10_o(gpio_10_in_x),
    .gpio_10_i(gpio_10_out_x),
    .gpio_10_oe_i(gpio_10_oe_x),
    .gpio_11_io(gpio_11_io),
    .gpio_11_o(gpio_11_in_x),
    .gpio_11_i(gpio_11_out_x),
    .gpio_11_oe_i(gpio_11_oe_x),
    .gpio_12_io(gpio_12_io),
    .gpio_12_o(gpio_12_in_x),
    .gpio_12_i(gpio_12_out_x),
    .gpio_12_oe_i(gpio_12_oe_x),
    .gpio_13_io(gpio_13_io),
    .gpio_13_o(gpio_13_in_x),
    .gpio_13_i(gpio_13_out_x),
    .gpio_13_oe_i(gpio_13_oe_x),
    .gpio_14_io(gpio_14_io),
    .gpio_14_o(gpio_14_in_x),
    .gpio_14_i(gpio_14_out_x),
    .gpio_14_oe_i(gpio_14_oe_x),
    .gpio_15_io(gpio_15_io),
    .gpio_15_o(gpio_15_in_x),
    .gpio_15_i(gpio_15_out_x),
    .gpio_15_oe_i(gpio_15_oe_x),
    .gpio_16_io(gpio_16_io),
    .gpio_16_o(gpio_16_in_x),
    .gpio_16_i(gpio_16_out_x),
    .gpio_16_oe_i(gpio_16_oe_x),
    .gpio_17_io(gpio_17_io),
    .gpio_17_o(gpio_17_in_x),
    .gpio_17_i(gpio_17_out_x),
    .gpio_17_oe_i(gpio_17_oe_x),
    .gpio_18_io(gpio_18_io),
    .gpio_18_o(gpio_18_in_x),
    .gpio_18_i(gpio_18_out_x),
    .gpio_18_oe_i(gpio_18_oe_x),
    .gpio_19_io(gpio_19_io),
    .gpio_19_o(gpio_19_in_x),
    .gpio_19_i(gpio_19_out_x),
    .gpio_19_oe_i(gpio_19_oe_x),
    .gpio_20_io(gpio_20_io),
    .gpio_20_o(gpio_20_in_x),
    .gpio_20_i(gpio_20_out_x),
    .gpio_20_oe_i(gpio_20_oe_x),
    .gpio_21_io(gpio_21_io),
    .gpio_21_o(gpio_21_in_x),
    .gpio_21_i(gpio_21_out_x),
    .gpio_21_oe_i(gpio_21_oe_x),
    .gpio_22_io(gpio_22_io),
    .gpio_22_o(gpio_22_in_x),
    .gpio_22_i(gpio_22_out_x),
    .gpio_22_oe_i(gpio_22_oe_x),
    .gpio_23_io(gpio_23_io),
    .gpio_23_o(gpio_23_in_x),
    .gpio_23_i(gpio_23_out_x),
    .gpio_23_oe_i(gpio_23_oe_x),
    .gpio_24_io(gpio_24_io),
    .gpio_24_o(gpio_24_in_x),
    .gpio_24_i(gpio_24_out_x),
    .gpio_24_oe_i(gpio_24_oe_x),
    .gpio_25_io(gpio_25_io),
    .gpio_25_o(gpio_25_in_x),
    .gpio_25_i(gpio_25_out_x),
    .gpio_25_oe_i(gpio_25_oe_x),
    .gpio_26_io(gpio_26_io),
    .gpio_26_o(gpio_26_in_x),
    .gpio_26_i(gpio_26_out_x),
    .gpio_26_oe_i(gpio_26_oe_x),
    .gpio_27_io(gpio_27_io),
    .gpio_27_o(gpio_27_in_x),
    .gpio_27_i(gpio_27_out_x),
    .gpio_27_oe_i(gpio_27_oe_x),
    .gpio_28_io(gpio_28_io),
    .gpio_28_o(gpio_28_in_x),
    .gpio_28_i(gpio_28_out_x),
    .gpio_28_oe_i(gpio_28_oe_x),
    .gpio_29_io(gpio_29_io),
    .gpio_29_o(gpio_29_in_x),
    .gpio_29_i(gpio_29_out_x),
    .gpio_29_oe_i(gpio_29_oe_x),
    .gpio_30_io(gpio_30_io),
    .gpio_30_o(gpio_30_in_x),
    .gpio_30_i(gpio_30_out_x),
    .gpio_30_oe_i(gpio_30_oe_x),
    .gpio_31_io(gpio_31_io),
    .gpio_31_o(gpio_31_in_x),
    .gpio_31_i(gpio_31_out_x),
    .gpio_31_oe_i(gpio_31_oe_x),














    .spi2_cs_0_io(spi2_cs_0_io),
    .spi2_cs_0_o(spi2_cs_0_in_x),
    .spi2_cs_0_i(spi2_cs_0_out_x),
    .spi2_cs_0_oe_i(spi2_cs_0_oe_x),
    .spi2_cs_1_io(spi2_cs_1_io),
    .spi2_cs_1_o(spi2_cs_1_in_x),
    .spi2_cs_1_i(spi2_cs_1_out_x),
    .spi2_cs_1_oe_i(spi2_cs_1_oe_x),
    .spi2_sck_io(spi2_sck_io),
    .spi2_sck_o(spi2_sck_in_x),
    .spi2_sck_i(spi2_sck_out_x),
    .spi2_sck_oe_i(spi2_sck_oe_x),
    .spi2_sd_0_io(spi2_sd_0_io),
    .spi2_sd_0_o(spi2_sd_0_in_x),
    .spi2_sd_0_i(spi2_sd_0_out_x),
    .spi2_sd_0_oe_i(spi2_sd_0_oe_x),
    .spi2_sd_1_io(spi2_sd_1_io),
    .spi2_sd_1_o(spi2_sd_1_in_x),
    .spi2_sd_1_i(spi2_sd_1_out_x),
    .spi2_sd_1_oe_i(spi2_sd_1_oe_x),
    .spi2_sd_2_io(spi2_sd_2_io),
    .spi2_sd_2_o(spi2_sd_2_in_x),
    .spi2_sd_2_i(spi2_sd_2_out_x),
    .spi2_sd_2_oe_i(spi2_sd_2_oe_x),
    .spi2_sd_3_io(spi2_sd_3_io),
    .spi2_sd_3_o(spi2_sd_3_in_x),
    .spi2_sd_3_i(spi2_sd_3_out_x),
    .spi2_sd_3_oe_i(spi2_sd_3_oe_x),
    .i2c_scl_io(i2c_scl_io),
    .i2c_scl_o(i2c_scl_in_x),
    .i2c_scl_i(i2c_scl_out_x),
    .i2c_scl_oe_i(i2c_scl_oe_x),
    .i2c_sda_io(i2c_sda_io),
    .i2c_sda_o(i2c_sda_in_x),
    .i2c_sda_i(i2c_sda_out_x),
    .i2c_sda_oe_i(i2c_sda_oe_x),
    .pad_attributes_i(pad_attributes)
  );

  assign clk_out_x = 1'b0;
  assign clk_oe_x = 1'b0;
  assign rst_nout_x = 1'b0;
  assign rst_noe_x = 1'b0;
  assign boot_select_out_x = 1'b0;
  assign boot_select_oe_x = 1'b0;
  assign execute_from_flash_out_x = 1'b0;
  assign execute_from_flash_oe_x = 1'b0;
  assign jtag_tck_out_x = 1'b0;
  assign jtag_tck_oe_x = 1'b0;
  assign jtag_tms_out_x = 1'b0;
  assign jtag_tms_oe_x = 1'b0;
  assign jtag_trst_nout_x = 1'b0;
  assign jtag_trst_noe_x = 1'b0;
  assign jtag_tdi_out_x = 1'b0;
  assign jtag_tdi_oe_x = 1'b0;
  assign jtag_tdo_oe_x = 1'b1;
  assign uart_rx_out_x = 1'b0;
  assign uart_rx_oe_x = 1'b0;
  assign uart_tx_oe_x = 1'b1;
  assign exit_valid_oe_x = 1'b1;




  pad_control #(
    .reg_req_t(reg_pkg::reg_req_t),
    .reg_rsp_t(reg_pkg::reg_rsp_t),
    .NUM_PAD  (core_v_mini_mcu_pkg::NUM_PAD)
  ) pad_control_i (
    .clk_i(clk_in_x),
    .rst_ni(rst_ngen),
    .reg_req_i(pad_req),
    .reg_rsp_o(pad_resp),
    .pad_attributes_o(pad_attributes),
    .pad_muxes_o(pad_muxes)
  );

  rstgen rstgen_i (
    .clk_i(clk_in_x),
    .rst_ni(rst_n),
    .test_mode_i(1'b0),
    .rst_no(rst_ngen),
    .init_no()
  );

endmodule
