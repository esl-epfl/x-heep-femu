/*
* Copyright 2023 EPFL
* Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
* SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
*
* Author: Simone Machetti - simone.machetti@epfl.ch
*/

module axi_address_fix_adder #
(
  parameter integer AXI_ADDR_WIDTH = 32
)(
  input wire [AXI_ADDR_WIDTH-1:0] axi_master_awaddr_in,
  input wire [AXI_ADDR_WIDTH-1:0] axi_master_araddr_in,

  output wire [AXI_ADDR_WIDTH-1:0] axi_master_araddr_out,
  output wire [AXI_ADDR_WIDTH-1:0] axi_master_awaddr_out
);

  assign axi_master_araddr_out = axi_master_araddr_in + 32'h40000000;
  assign axi_master_awaddr_out = axi_master_awaddr_in + 32'h40000000;

  endmodule
