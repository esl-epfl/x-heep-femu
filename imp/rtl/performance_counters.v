/*
* Copyright 2023 EPFL
* Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
*
* Author: Simone Machetti - simone.machetti@epfl.ch
*/

module performance_counters #
(
  parameter integer AXI_ADDR_WIDTH = 32,
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 8
)(

  /////////////////////////////////////////
  // AXI-Lite slave interface
  /////////////////////////////////////////

  // Clock and reset
  input wire S_AXI_ACLK,
  input wire S_AXI_ARESETN,

  // Write address
  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
  input wire [2 : 0] S_AXI_AWPROT,
  input wire S_AXI_AWVALID,
  output wire S_AXI_AWREADY,

  // Write data
  input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
  input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
  input wire S_AXI_WVALID,
  output wire S_AXI_WREADY,

  // Write response
  output wire [1 : 0] S_AXI_BRESP,
  output wire S_AXI_BVALID,
  input wire S_AXI_BREADY,

  // Read address
  input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
  input wire [2 : 0] S_AXI_ARPROT,
  input wire S_AXI_ARVALID,
  output wire S_AXI_ARREADY,

  // Read data
  output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
  output wire [1 : 0] S_AXI_RRESP,
  output wire S_AXI_RVALID,
  input wire S_AXI_RREADY,

  /////////////////////////////////////////
  // Performance interface
  /////////////////////////////////////////

  // Start perf cnt in automatic mode
  input wire start_automatic_i,

  // Start perf cnt in manual mode
  input wire start_manual_i,

  // cpu
  input wire cpu_clock_gate_i,
  input wire cpu_power_gate_i,

  // bus ao
  input wire bus_ao_clock_gate_i, // unconnected

  // debug ao
  input wire debug_ao_clock_gate_i, // unconnected

  // soc ctrl ao
  input wire soc_ctrl_ao_clock_gate_i, // unconnected

  // boot rom ao
  input wire boot_rom_ao_clock_gate_i, // unconnected

  // spi flash ao
  input wire spi_flash_ao_clock_gate_i, // unconnected

  // spi ao
  input wire spi_ao_clock_gate_i, // unconnected

  // power manager ao
  input wire power_manager_ao_clock_gate_i, // unconnected

  // timer ao
  input wire timer_ao_clock_gate_i, // unconnected

  // dma ao
  input wire dma_ao_clock_gate_i, // unconnected

  // fast int ctrl ao
  input wire fast_int_ctrl_ao_clock_gate_i, // unconnected

  // gpio ao
  input wire gpio_ao_clock_gate_i, // unconnected

  // uart ao
  input wire uart_ao_clock_gate_i, // unconnected

  // plic
  input wire plic_clock_gate_i,
  input wire plic_power_gate_i,

  // gpio
  input wire gpio_clock_gate_i,
  input wire gpio_power_gate_i,

  // i2c
  input wire i2c_clock_gate_i,
  input wire i2c_power_gate_i,

  // timer
  input wire timer_clock_gate_i,
  input wire timer_power_gate_i,

  // spi
  input wire spi_clock_gate_i,
  input wire spi_power_gate_i,

  // ram bank 0
  input wire ram_bank_0_clock_gate_i,
  input wire ram_bank_0_power_gate_i,
  input wire ram_bank_0_retentive_i,

  // ram bank 1
  input wire ram_bank_1_clock_gate_i,
  input wire ram_bank_1_power_gate_i,
  input wire ram_bank_1_retentive_i,

  // ram bank 2
  input wire ram_bank_2_clock_gate_i,
  input wire ram_bank_2_power_gate_i,
  input wire ram_bank_2_retentive_i,

  // ram bank 3
  input wire ram_bank_3_clock_gate_i,
  input wire ram_bank_3_power_gate_i,
  input wire ram_bank_3_retentive_i
);

  reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
  reg axi_awready;
  reg axi_wready;
  reg [1 : 0] axi_bresp;
  reg axi_bvalid;
  reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
  reg axi_arready;
  reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
  reg [1 : 0] axi_rresp;
  reg axi_rvalid;

  localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
  localparam integer OPT_MEM_ADDR_BITS = 5;

  /////////////////////////////////////////
  // Registers
  /////////////////////////////////////////

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // control register    -    (0) - reset active high
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // control register    -  (1:0) - stop: 00 - start automatic mode: 01 - start manual mode: 10

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  // performance counter - (31:0) - total cycles

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // performance counter - (31:0) - active cycles     - cpu
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;  // performance counter - (31:0) - clock-gate cycles - cpu
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;  // performance counter - (31:0) - power-gate cycles - cpu

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;  // performance counter - (31:0) - active cycles     - bus ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;  // performance counter - (31:0) - clock-gate cycles - bus ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8;  // performance counter - (31:0) - active cycles     - debug ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg9;  // performance counter - (31:0) - clock-gate cycles - debug ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg10; // performance counter - (31:0) - active cycles     - soc ctrl ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg11; // performance counter - (31:0) - clock-gate cycles - soc ctrl ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg12; // performance counter - (31:0) - active cycles     - boot rom ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg13; // performance counter - (31:0) - clock-gate cycles - boot rom ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg14; // performance counter - (31:0) - active cycles     - spi flash ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg15; // performance counter - (31:0) - clock-gate cycles - spi flash ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg16; // performance counter - (31:0) - active cycles     - spi ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg17; // performance counter - (31:0) - clock-gate cycles - spi ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg18; // performance counter - (31:0) - active cycles     - power manager ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg19; // performance counter - (31:0) - clock-gate cycles - power manager ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg20; // performance counter - (31:0) - active cycles     - timer ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg21; // performance counter - (31:0) - clock-gate cycles - timer ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg22; // performance counter - (31:0) - active cycles     - dma ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg23; // performance counter - (31:0) - clock-gate cycles - dma ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg24; // performance counter - (31:0) - active cycles     - fast int ctrl ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg25; // performance counter - (31:0) - clock-gate cycles - fast int ctrl ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg26; // performance counter - (31:0) - active cycles     - gpio ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg27; // performance counter - (31:0) - clock-gate cycles - gpio ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg28; // performance counter - (31:0) - active cycles     - uart ao
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg29; // performance counter - (31:0) - clock-gate cycles - uart ao - not implemented

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg30; // performance counter - (31:0) - active cycles     - plic
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg31; // performance counter - (31:0) - clock-gate cycles - plic
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg32; // performance counter - (31:0) - power-gate cycles - plic

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg33; // performance counter - (31:0) - active cycles     - gpio
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg34; // performance counter - (31:0) - clock-gate cycles - gpio
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg35; // performance counter - (31:0) - power-gate cycles - gpio

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg36; // performance counter - (31:0) - active cycles     - i2c
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg37; // performance counter - (31:0) - clock-gate cycles - i2c
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg38; // performance counter - (31:0) - power-gate cycles - i2c

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg39; // performance counter - (31:0) - active cycles     - timer
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg40; // performance counter - (31:0) - clock-gate cycles - timer
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg41; // performance counter - (31:0) - power-gate cycles - timer

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg42; // performance counter - (31:0) - active cycles     - spi
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg43; // performance counter - (31:0) - clock-gate cycles - spi
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg44; // performance counter - (31:0) - power-gate cycles - spi

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg45; // performance counter - (31:0) - active cycles     - ram bank 0
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg46; // performance counter - (31:0) - clock-gate cycles - ram bank 0
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg47; // performance counter - (31:0) - power-gate cycles - ram bank 0
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg48; // performance counter - (31:0) - retentive cycles  - ram bank 0

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg49; // performance counter - (31:0) - active cycles     - ram bank 1
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg50; // performance counter - (31:0) - clock-gate cycles - ram bank 1
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg51; // performance counter - (31:0) - power-gate cycles - ram bank 1
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg52; // performance counter - (31:0) - retentive cycles  - ram bank 1

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg53; // performance counter - (31:0) - active cycles     - ram bank 2
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg54; // performance counter - (31:0) - clock-gate cycles - ram bank 2
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg55; // performance counter - (31:0) - power-gate cycles - ram bank 2
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg56; // performance counter - (31:0) - retentive cycles  - ram bank 2

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg57; // performance counter - (31:0) - active cycles     - ram bank 3
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg58; // performance counter - (31:0) - clock-gate cycles - ram bank 3
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg59; // performance counter - (31:0) - power-gate cycles - ram bank 3
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg60; // performance counter - (31:0) - retentive cycles  - ram bank 3

  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg61; // unused
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg62; // unused
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg63; // unused

  wire slv_reg_rden;
  wire slv_reg_wren;
  reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
  integer byte_index;
  reg aw_en;

  assign S_AXI_AWREADY = axi_awready;
  assign S_AXI_WREADY  = axi_wready;
  assign S_AXI_BRESP   = axi_bresp;
  assign S_AXI_BVALID  = axi_bvalid;
  assign S_AXI_ARREADY = axi_arready;
  assign S_AXI_RDATA   = axi_rdata;
  assign S_AXI_RRESP   = axi_rresp;
  assign S_AXI_RVALID  = axi_rvalid;

  /////////////////////////////////////////
  // Performance counters
  /////////////////////////////////////////

  // Total cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg2 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) )
            begin
              slv_reg2 <= slv_reg2 + 32'd1;
            end
        end
    end

  // cpu - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg3 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && cpu_clock_gate_i == 1'b0 && cpu_power_gate_i == 1'b0 )
            begin
              slv_reg3 <= slv_reg3 + 32'd1;
            end
        end
    end

  // cpu - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg4 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && cpu_clock_gate_i == 1'b1 && cpu_power_gate_i == 1'b0 )
            begin
              slv_reg4 <= slv_reg4 + 32'd1;
            end
        end
    end

  // cpu - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg5 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && cpu_power_gate_i == 1'b1 && cpu_clock_gate_i == 1'b1 )
            begin
              slv_reg5 <= slv_reg5 + 32'd1;
            end
        end
    end

  // bus ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg6 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && bus_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg6 <= slv_reg6 + 32'd1;
            end
        end
    end

  // bus ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg7 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && bus_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg7 <= slv_reg7 + 32'd1;
            end
        end
    end

  // debug ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg8 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && debug_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg8 <= slv_reg8 + 32'd1;
            end
        end
    end

  // debug ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg9 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && debug_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg9 <= slv_reg9 + 32'd1;
            end
        end
    end

  // soc ctrl ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg10 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && soc_ctrl_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg10 <= slv_reg10 + 32'd1;
            end
        end
    end

  // soc ctrl ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg11 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && soc_ctrl_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg11 <= slv_reg11 + 32'd1;
            end
        end
    end

  // boot rom ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg12 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && boot_rom_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg12 <= slv_reg12 + 32'd1;
            end
        end
    end

  // boot rom ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg13 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && boot_rom_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg13 <= slv_reg13 + 32'd1;
            end
        end
    end

  // spi flash ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg14 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_flash_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg14 <= slv_reg14 + 32'd1;
            end
        end
    end

  // spi flash ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg15 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_flash_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg15 <= slv_reg15 + 32'd1;
            end
        end
    end

  // spi ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg16 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg16 <= slv_reg16 + 32'd1;
            end
        end
    end

  // spi ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg17 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg17 <= slv_reg17 + 32'd1;
            end
        end
    end

  // power manager ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg18 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && power_manager_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg18 <= slv_reg18 + 32'd1;
            end
        end
    end

  // power manager ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg19 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && power_manager_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg19 <= slv_reg19 + 32'd1;
            end
        end
    end

  // timer ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg20 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && timer_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg20 <= slv_reg20 + 32'd1;
            end
        end
    end

  // timer ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg21 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && timer_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg21 <= slv_reg21 + 32'd1;
            end
        end
    end

  // dma ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg22 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && dma_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg22 <= slv_reg22 + 32'd1;
            end
        end
    end

  // dma ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg23 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && dma_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg23 <= slv_reg23 + 32'd1;
            end
        end
    end

  // fast int ctrl ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg24 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && fast_int_ctrl_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg24 <= slv_reg24 + 32'd1;
            end
        end
    end

  // fast int ctrl - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg25 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && fast_int_ctrl_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg25 <= slv_reg25 + 32'd1;
            end
        end
    end

// gpio ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg26 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && gpio_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg26 <= slv_reg26 + 32'd1;
            end
        end
    end

  // gpio ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg27 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && gpio_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg27 <= slv_reg27 + 32'd1;
            end
        end
    end

  // uart ao - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg28 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && uart_ao_clock_gate_i == 1'b0 )
            begin
              slv_reg28 <= slv_reg28 + 32'd1;
            end
        end
    end

  // uart ao - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg29 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && uart_ao_clock_gate_i == 1'b1 )
            begin
              slv_reg29 <= slv_reg29 + 32'd1;
            end
        end
    end

  // plic - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg30 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && plic_clock_gate_i == 1'b0 && plic_power_gate_i == 1'b0 )
            begin
              slv_reg30 <= slv_reg30 + 32'd1;
            end
        end
    end

  // plic - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg31 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && plic_clock_gate_i == 1'b1 && plic_power_gate_i == 1'b0 )
            begin
              slv_reg31 <= slv_reg31 + 32'd1;
            end
        end
    end

  // plic - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg32 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && plic_power_gate_i == 1'b1)
            begin
              slv_reg32 <= slv_reg32 + 32'd1;
            end
        end
    end

  // gpio - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg33 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && gpio_clock_gate_i == 1'b0 && gpio_power_gate_i == 1'b0 )
            begin
              slv_reg33 <= slv_reg33 + 32'd1;
            end
        end
    end

  // gpio - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg34 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && gpio_clock_gate_i == 1'b1 && gpio_power_gate_i == 1'b0 )
            begin
              slv_reg34 <= slv_reg34 + 32'd1;
            end
        end
    end

  // gpio - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg35 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && gpio_power_gate_i == 1'b1 )
            begin
              slv_reg35 <= slv_reg35 + 32'd1;
            end
        end
    end

  // i2c - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg36 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && i2c_clock_gate_i == 1'b0 && i2c_power_gate_i == 1'b0 )
            begin
              slv_reg36 <= slv_reg36 + 32'd1;
            end
        end
    end

  // i2c - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg37 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && i2c_clock_gate_i == 1'b1 && i2c_power_gate_i == 1'b0 )
            begin
              slv_reg37 <= slv_reg37 + 32'd1;
            end
        end
    end

  // i2c - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg38 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && i2c_power_gate_i == 1'b1 )
            begin
              slv_reg38 <= slv_reg38 + 32'd1;
            end
        end
    end

  // timer - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg39 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && timer_clock_gate_i == 1'b0 && timer_power_gate_i == 1'b0 )
            begin
              slv_reg39 <= slv_reg39 + 32'd1;
            end
        end
    end

  // timer - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg40 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && timer_clock_gate_i == 1'b1 && timer_power_gate_i == 1'b0 )
            begin
              slv_reg40 <= slv_reg40 + 32'd1;
            end
        end
    end

  // timer - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg41 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && timer_power_gate_i == 1'b1 )
            begin
              slv_reg41 <= slv_reg41 + 32'd1;
            end
        end
    end

  // spi - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg42 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_clock_gate_i == 1'b0 && spi_power_gate_i == 1'b0 )
            begin
              slv_reg42 <= slv_reg42 + 32'd1;
            end
        end
    end

  // spi - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg43 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_clock_gate_i == 1'b1 && spi_power_gate_i == 1'b0 )
            begin
              slv_reg43 <= slv_reg43 + 32'd1;
            end
        end
    end

  // spi - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg44 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && spi_power_gate_i == 1'b1 )
            begin
              slv_reg44 <= slv_reg44 + 32'd1;
            end
        end
    end

  // ram bank 0 - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg45 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_0_clock_gate_i == 1'b0 && ram_bank_0_power_gate_i == 1'b0 && ram_bank_0_retentive_i == 1'b0 )
            begin
              slv_reg45 <= slv_reg45 + 32'd1;
            end
        end
    end

  // ram bank 0 - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg46 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_0_clock_gate_i == 1'b1 && ram_bank_0_power_gate_i == 1'b0  && ram_bank_0_retentive_i == 1'b0 )
            begin
              slv_reg46 <= slv_reg46 + 32'd1;
            end
        end
    end

  // ram bank 0 - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg47 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_0_power_gate_i == 1'b1 )
            begin
              slv_reg47 <= slv_reg47 + 32'd1;
            end
        end
    end

  // ram bank 0 - retentive cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg48 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_0_retentive_i == 1'b1 && ram_bank_0_power_gate_i == 1'b0 )
            begin
              slv_reg48 <= slv_reg48 + 32'd1;
            end
        end
    end

  // ram bank 1 - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg49 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_1_clock_gate_i == 1'b0 && ram_bank_1_power_gate_i == 1'b0 && ram_bank_1_retentive_i == 1'b0 )
            begin
              slv_reg49 <= slv_reg49 + 32'd1;
            end
        end
    end

  // ram bank 1 - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg50 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_1_clock_gate_i == 1'b1 && ram_bank_1_power_gate_i == 1'b0  && ram_bank_1_retentive_i == 1'b0 )
            begin
              slv_reg50 <= slv_reg50 + 32'd1;
            end
        end
    end

  // ram bank 1 - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg51 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_1_power_gate_i == 1'b1 )
            begin
              slv_reg51 <= slv_reg51 + 32'd1;
            end
        end
    end

  // ram bank 1 - retentive cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg52 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_1_retentive_i == 1'b1 && ram_bank_1_power_gate_i == 1'b0 )
            begin
              slv_reg52 <= slv_reg52 + 32'd1;
            end
        end
    end

  // ram bank 2 - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg53 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_2_clock_gate_i == 1'b0 && ram_bank_2_power_gate_i == 1'b0 && ram_bank_2_retentive_i == 1'b0 )
            begin
              slv_reg53 <= slv_reg53 + 32'd1;
            end
        end
    end

  // ram bank 2 - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg54 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_2_clock_gate_i == 1'b1 && ram_bank_2_power_gate_i == 1'b0  && ram_bank_2_retentive_i == 1'b0 )
            begin
              slv_reg54 <= slv_reg54 + 32'd1;
            end
        end
    end

  // ram bank 2 - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg55 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_2_power_gate_i == 1'b1 )
            begin
              slv_reg55 <= slv_reg55 + 32'd1;
            end
        end
    end

  // ram bank 2 - retentive cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg56 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_2_retentive_i == 1'b1 && ram_bank_2_power_gate_i == 1'b0 )
            begin
              slv_reg56 <= slv_reg56 + 32'd1;
            end
        end
    end

  // ram bank 3 - active cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg57 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_3_clock_gate_i == 1'b0 && ram_bank_3_power_gate_i == 1'b0 && ram_bank_3_retentive_i == 1'b0 )
            begin
              slv_reg57 <= slv_reg57 + 32'd1;
            end
        end
    end

  // ram bank 3 - clock-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg58 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_3_clock_gate_i == 1'b1 && ram_bank_3_power_gate_i == 1'b0  && ram_bank_3_retentive_i == 1'b0 )
            begin
              slv_reg58 <= slv_reg58 + 32'd1;
            end
        end
    end

  // ram bank 3 - power-gate cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg59 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_3_power_gate_i == 1'b1 )
            begin
              slv_reg59 <= slv_reg59 + 32'd1;
            end
        end
    end

  // ram bank 3 - retentive cycles
  always @( posedge S_AXI_ACLK )
    begin
      if ( slv_reg0[0] == 1'b1 || S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg60 <= 32'd0;
        end
      else
        begin
          if ( ( ( slv_reg1[1:0] == 2'b01 && start_automatic_i == 1'b1 ) || ( slv_reg1[1:0] == 2'b10 && start_manual_i == 1'b1 ) ) && ram_bank_3_retentive_i == 1'b1 && ram_bank_3_power_gate_i == 1'b0 )
            begin
              slv_reg60 <= slv_reg60 + 32'd1;
            end
        end
    end

  // Implement axi_awready generation
  // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
  // de-asserted when reset is low.
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_awready <= 1'b0;
        aw_en <= 1'b1;
      end
    else
      begin
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
          begin
            axi_awready <= 1'b1;
            aw_en <= 1'b0;
          end
          else if (S_AXI_BREADY && axi_bvalid)
              begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
              end
        else
          begin
            axi_awready <= 1'b0;
          end
      end
  end

  // Implement axi_awaddr latching
  // This process is used to latch the address when both
  // S_AXI_AWVALID and S_AXI_WVALID are valid.
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_awaddr <= 0;
      end
    else
      begin
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
          begin
            axi_awaddr <= S_AXI_AWADDR;
          end
      end
  end

  // Implement axi_wready generation
  // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
  // de-asserted when reset is low.
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_wready <= 1'b0;
      end
    else
      begin
        if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
          begin
            axi_wready <= 1'b1;
          end
        else
          begin
            axi_wready <= 1'b0;
          end
      end
  end

  // Implement memory mapped register select and write logic generation
  // The write data is accepted and written to memory mapped registers when
  // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  // select byte enables of slave registers while writing.
  // These registers are cleared when reset (active low) is applied.
  // Slave register write enable is asserted when valid address and data are available
  // and the slave is ready to accept the write address and write data.
  assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        slv_reg0 <= 0;
        slv_reg1 <= 0;
        // slv_reg2 <= 0;
        // slv_reg3 <= 0;
        // slv_reg4 <= 0;
        // slv_reg5 <= 0;
        // slv_reg6 <= 0;
        // slv_reg7 <= 0;
        // slv_reg8 <= 0;
        // slv_reg9 <= 0;
        // slv_reg10 <= 0;
        // slv_reg11 <= 0;
        // slv_reg12 <= 0;
        // slv_reg13 <= 0;
        // slv_reg14 <= 0;
        // slv_reg15 <= 0;
        // slv_reg16 <= 0;
        // slv_reg17 <= 0;
        // slv_reg18 <= 0;
        // slv_reg19 <= 0;
        // slv_reg20 <= 0;
        // slv_reg21 <= 0;
        // slv_reg22 <= 0;
        // slv_reg23 <= 0;
        // slv_reg24 <= 0;
        // slv_reg25 <= 0;
        // slv_reg26 <= 0;
        // slv_reg27 <= 0;
        // slv_reg28 <= 0;
        // slv_reg29 <= 0;
        // slv_reg30 <= 0;
        // slv_reg31 <= 0;
        // slv_reg32 <= 0;
        // slv_reg33 <= 0;
        // slv_reg34 <= 0;
        // slv_reg35 <= 0;
        // slv_reg36 <= 0;
        // slv_reg37 <= 0;
        // slv_reg38 <= 0;
        // slv_reg39 <= 0;
        // slv_reg40 <= 0;
        // slv_reg41 <= 0;
        // slv_reg42 <= 0;
        // slv_reg43 <= 0;
        // slv_reg44 <= 0;
        // slv_reg45 <= 0;
        // slv_reg46 <= 0;
        // slv_reg47 <= 0;
        // slv_reg48 <= 0;
        // slv_reg49 <= 0;
        // slv_reg50 <= 0;
        // slv_reg51 <= 0;
        // slv_reg52 <= 0;
        // slv_reg53 <= 0;
        // slv_reg54 <= 0;
        // slv_reg55 <= 0;
        // slv_reg56 <= 0;
        // slv_reg57 <= 0;
        // slv_reg58 <= 0;
        // slv_reg59 <= 0;
        // slv_reg60 <= 0;
        slv_reg61 <= 0;
        slv_reg62 <= 0;
        slv_reg63 <= 0;
      end
    else begin
      if (slv_reg_wren)
        begin
          case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            6'd0:
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
            6'd1:
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
            // 6'd2:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd3:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd4:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd5:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd6:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd7:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd8:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd9:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd10:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd11:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd12:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd13:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd14:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd15:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd16:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd17:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg17[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd18:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg18[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd19:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg19[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd20:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg20[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd21:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg21[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd22:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg22[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd23:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg23[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd24:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg24[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd25:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg25[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd26:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg26[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd27:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg27[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd28:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg28[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd29:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg29[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd30:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg30[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd31:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg31[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd32:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg32[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd33:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg33[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd34:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg34[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd35:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg35[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd36:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg36[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd37:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg37[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd38:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg38[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd39:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg39[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd40:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg40[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd41:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg41[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd42:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg42[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd43:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg43[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd44:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg44[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd45:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg45[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd46:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg46[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd47:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg47[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd48:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg48[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd49:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg49[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd50:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg50[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd51:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg51[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd52:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg52[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd53:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg53[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd54:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg54[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd55:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg55[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd56:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg56[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd57:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg57[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd58:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg58[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd59:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg59[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            // 6'd60:
            //   for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            //     if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            //       slv_reg60[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
            //     end
            6'd61:
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  slv_reg61[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
            6'd62:
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  slv_reg62[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
            6'd63:
              for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                  slv_reg63[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
            default : begin
              slv_reg0 <= slv_reg0;
              slv_reg1 <= slv_reg1;
              // slv_reg2 <= slv_reg2;
              // slv_reg3 <= slv_reg3;
              // slv_reg4 <= slv_reg4;
              // slv_reg5 <= slv_reg5;
              // slv_reg6 <= slv_reg6;
              // slv_reg7 <= slv_reg7;
              // slv_reg8 <= slv_reg8;
              // slv_reg9 <= slv_reg9;
              // slv_reg10 <= slv_reg10;
              // slv_reg11 <= slv_reg11;
              // slv_reg12 <= slv_reg12;
              // slv_reg13 <= slv_reg13;
              // slv_reg14 <= slv_reg14;
              // slv_reg15 <= slv_reg15;
              // slv_reg16 <= slv_reg16;
              // slv_reg17 <= slv_reg17;
              // slv_reg18 <= slv_reg18;
              // slv_reg19 <= slv_reg19;
              // slv_reg20 <= slv_reg20;
              // slv_reg21 <= slv_reg21;
              // slv_reg22 <= slv_reg22;
              // slv_reg23 <= slv_reg23;
              // slv_reg24 <= slv_reg24;
              // slv_reg25 <= slv_reg25;
              // slv_reg26 <= slv_reg26;
              // slv_reg27 <= slv_reg27;
              // slv_reg28 <= slv_reg28;
              // slv_reg29 <= slv_reg29;
              // slv_reg30 <= slv_reg30;
              // slv_reg31 <= slv_reg31;
              // slv_reg32 <= slv_reg32;
              // slv_reg33 <= slv_reg33;
              // slv_reg34 <= slv_reg34;
              // slv_reg35 <= slv_reg35;
              // slv_reg36 <= slv_reg36;
              // slv_reg37 <= slv_reg37;
              // slv_reg38 <= slv_reg38;
              // slv_reg39 <= slv_reg39;
              // slv_reg40 <= slv_reg40;
              // slv_reg41 <= slv_reg41;
              // slv_reg42 <= slv_reg42;
              // slv_reg43 <= slv_reg43;
              // slv_reg44 <= slv_reg44;
              // slv_reg45 <= slv_reg45;
              // slv_reg46 <= slv_reg46;
              // slv_reg47 <= slv_reg47;
              // slv_reg48 <= slv_reg48;
              // slv_reg49 <= slv_reg49;
              // slv_reg50 <= slv_reg50;
              // slv_reg51 <= slv_reg51;
              // slv_reg52 <= slv_reg52;
              // slv_reg53 <= slv_reg53;
              // slv_reg54 <= slv_reg54;
              // slv_reg55 <= slv_reg55;
              // slv_reg56 <= slv_reg56;
              // slv_reg57 <= slv_reg57;
              // slv_reg58 <= slv_reg58;
              // slv_reg59 <= slv_reg59;
              // slv_reg60 <= slv_reg60;
              slv_reg61 <= slv_reg61;
              slv_reg62 <= slv_reg62;
              slv_reg63 <= slv_reg63;
            end
          endcase
        end
    end
  end

  // Implement write response logic generation
  // The write response and response valid signals are asserted by the slave
  // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
  // This marks the acceptance of address and indicates the status of
  // write transaction.
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_bvalid  <= 0;
        axi_bresp   <= 2'b0;
      end
    else
      begin
        if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
          begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b0;
          end
        else
          begin
            if (S_AXI_BREADY && axi_bvalid)
              begin
                axi_bvalid <= 1'b0;
              end
          end
      end
  end

  // Implement axi_arready generation
  // axi_arready is asserted for one S_AXI_ACLK clock cycle when
  // S_AXI_ARVALID is asserted. axi_awready is
  // de-asserted when reset (active low) is asserted.
  // The read address is also latched when S_AXI_ARVALID is
  // asserted. axi_araddr is reset to zero on reset assertion.
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_arready <= 1'b0;
        axi_araddr  <= 32'b0;
      end
    else
      begin
        if (~axi_arready && S_AXI_ARVALID)
          begin
            axi_arready <= 1'b1;
            axi_araddr  <= S_AXI_ARADDR;
          end
        else
          begin
            axi_arready <= 1'b0;
          end
      end
  end

  // Implement axi_arvalid generation
  // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
  // S_AXI_ARVALID and axi_arready are asserted. The slave registers
  // data are available on the axi_rdata bus at this instance. The
  // assertion of axi_rvalid marks the validity of read data on the
  // bus and axi_rresp indicates the status of read transaction.axi_rvalid
  // is deasserted on reset (active low). axi_rresp and axi_rdata are
  // cleared to zero on reset (active low).
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_rvalid <= 0;
        axi_rresp  <= 0;
      end
    else
      begin
        if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
          begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b0;
          end
        else if (axi_rvalid && S_AXI_RREADY)
          begin
            axi_rvalid <= 1'b0;
          end
      end
  end

  // Implement memory mapped register select and read logic generation
  // Slave register read enable is asserted when valid address is available
  // and the slave is ready to accept the read address.
  assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
  always @(*)
  begin
    case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
      6'd0 : reg_data_out <= slv_reg0;
      6'd1 : reg_data_out <= slv_reg1;
      6'd2 : reg_data_out <= slv_reg2;
      6'd3 : reg_data_out <= slv_reg3;
      6'd4 : reg_data_out <= slv_reg4;
      6'd5 : reg_data_out <= slv_reg5;
      6'd6 : reg_data_out <= slv_reg6;
      6'd7 : reg_data_out <= slv_reg7;
      6'd8 : reg_data_out <= slv_reg8;
      6'd9 : reg_data_out <= slv_reg9;
      6'd10 : reg_data_out <= slv_reg10;
      6'd11 : reg_data_out <= slv_reg11;
      6'd12 : reg_data_out <= slv_reg12;
      6'd13 : reg_data_out <= slv_reg13;
      6'd14 : reg_data_out <= slv_reg14;
      6'd15 : reg_data_out <= slv_reg15;
      6'd16 : reg_data_out <= slv_reg16;
      6'd17 : reg_data_out <= slv_reg17;
      6'd18 : reg_data_out <= slv_reg18;
      6'd19 : reg_data_out <= slv_reg19;
      6'd20 : reg_data_out <= slv_reg20;
      6'd21 : reg_data_out <= slv_reg21;
      6'd22 : reg_data_out <= slv_reg22;
      6'd23 : reg_data_out <= slv_reg23;
      6'd24 : reg_data_out <= slv_reg24;
      6'd25 : reg_data_out <= slv_reg25;
      6'd26 : reg_data_out <= slv_reg26;
      6'd27 : reg_data_out <= slv_reg27;
      6'd28 : reg_data_out <= slv_reg28;
      6'd29 : reg_data_out <= slv_reg29;
      6'd30 : reg_data_out <= slv_reg30;
      6'd31 : reg_data_out <= slv_reg31;
      6'd32 : reg_data_out <= slv_reg32;
      6'd33 : reg_data_out <= slv_reg33;
      6'd34 : reg_data_out <= slv_reg34;
      6'd35 : reg_data_out <= slv_reg35;
      6'd36 : reg_data_out <= slv_reg36;
      6'd37 : reg_data_out <= slv_reg37;
      6'd38 : reg_data_out <= slv_reg38;
      6'd39 : reg_data_out <= slv_reg39;
      6'd40 : reg_data_out <= slv_reg40;
      6'd41 : reg_data_out <= slv_reg41;
      6'd42 : reg_data_out <= slv_reg42;
      6'd43 : reg_data_out <= slv_reg43;
      6'd44 : reg_data_out <= slv_reg44;
      6'd45 : reg_data_out <= slv_reg45;
      6'd46 : reg_data_out <= slv_reg46;
      6'd47 : reg_data_out <= slv_reg47;
      6'd48 : reg_data_out <= slv_reg48;
      6'd49 : reg_data_out <= slv_reg49;
      6'd50 : reg_data_out <= slv_reg50;
      6'd51 : reg_data_out <= slv_reg51;
      6'd52 : reg_data_out <= slv_reg52;
      6'd53 : reg_data_out <= slv_reg53;
      6'd54 : reg_data_out <= slv_reg54;
      6'd55 : reg_data_out <= slv_reg55;
      6'd56 : reg_data_out <= slv_reg56;
      6'd57 : reg_data_out <= slv_reg57;
      6'd58 : reg_data_out <= slv_reg58;
      6'd59 : reg_data_out <= slv_reg59;
      6'd60 : reg_data_out <= slv_reg60;
      6'd61 : reg_data_out <= slv_reg61;
      6'd62 : reg_data_out <= slv_reg62;
      6'd63 : reg_data_out <= slv_reg63;
      default : reg_data_out <= 0;
    endcase
  end

  // Output register or memory read data
  always @( posedge S_AXI_ACLK )
  begin
    if ( S_AXI_ARESETN == 1'b0 )
      begin
        axi_rdata <= 0;
      end
    else
      begin
        if (slv_reg_rden)
          begin
            axi_rdata <= reg_data_out;
          end
      end
  end

  endmodule
