# X-HEEP-based FPGA EMUlation Platform (FEMU)

We ported our custom [eXtendable Heterogeneous Energy-Efficient Platform (X-HEEP)](https://github.com/esl-epfl/x-heep) microcontroller to the TUL Pynq-Z2 board, based on the Xilinx Zynq-7020 chip, in order to realize a valuable FPGA-based emulation platform for performing software explorations of ultra-low-power edge-computing applications.

## Requirements

The needed material for using our FPGA platform is the following:

 - a [TUL Pynq-Z2](https://www.tulembedded.com/fpga/ProductsPYNQ-Z2.html) with power supply.
 - A Micro USB cable.
 - A Ethernet cable.
 - A MicroSD card with at least 16GB of memory.
 - A PC (the Linux operating system is suggested) with a Web browser installed.

## Repository structure

The repository is organized as follows:

    .
    ├── .github
    ├── imp
    │   ├── rtl
    │   ├── scripts
    │   ├── pads
    │   ├── pinout
    │   └── vendor
    ├── doc
    └── README.md

## Setup

Follow these steps to get started with our FPGA platform:

 1. Download our pre-compiled PetaLinux-based image from this Drive [FEMU MicroSD Image](http://tiny.cc/femu_microsd_image) and load it to your MicroSD card. You can find more information about the writing process in this documentation: [Write SD card](https://pynq.readthedocs.io/en/latest/appendix/sdcard.html).
 2. Insert your MicroSD card in your Pynq-Z2 board and make sure the boot jumper is in the SD position. Then, power up the board. LED3 will switch on as soon as the Linux booting and the bitstream loading processes are completed.
 3. You can now connect to the board.

## Board connection

You can access Linux running on the board in the following 3 ways:

**USB (terminal)**
Connect your PC to the board using the Micro USB cable and run this command from your terminal:
```
sudo screen /dev/<your_usb_dev_name> 115200
```
NOTE: this method has several limitations and is suggested only for quick initial configurations.

**Ethernet (terminal)**
Connect the board to the same network of your PC using the Ethernet cable. The Linux ETH interface has the assigned static IP address `192.168.2.99` for direct connections, but can also be configured through DHCP, for router connections. Once you know the IP address of your board, run the following command from your terminal:
```
ssh -X xilinx@<board_ip>
```
**Ethernet (browser)**
Connect the board to the same network of your PC using the Ethernet cable (as explained in the previous paragraph). Then, open your browser and navigate to `<board_ip>:9090` to open the Jupyter environment.

NOTE: the Linux username and password are `xilinx` and `xilinx`, respectively.

## Software exploration

Read our `Read the Docs` documentation at the following link to learn in detail how to run your own applications on our FPGA platform and enjoy all its software exploration functionalities: [FEMU Documentation](http://tiny.cc/femu_documentation).

*---Enjoy our FPGA platform!*

## Hardware exploration (bonus)

Even if our platform is NOT thought to perform hardware exploration, this section quickly describes the content of the **imp/** folder, so that you may be able to modify the hardware if needed.

The folder is organized as follows:

 - **rtl/** contains the RTL code of our platform top-level and of all the modules that are instantiated outside X-HEEP.
 - **scripts/** contains the TCL script to automatically generate the Vivado block design of our platform.
 - **pads/** contains the HJSON configuration file to automatically generate the pad ring and pad controller of our platform.
 - **pinout/** contains the Vivado XDC constraints file to specify the pinout of our platform.
 - **vendor/** contains our cloned and patched X-HEEP repository.

Navigate to the **imp/** folder and run the following commands to generate our platform hardware.

NOTE: the following commands can ONLY be run inside our X-HEEP Conda environment. Please, refer to our [X-HEEP documentation](https://github.com/esl-epfl/x-heep) to learn how to configure it.

This command uses the [Vendor](https://docs.opentitan.org/doc/ug/vendor_hw/) tool to clone and patch our X-HEEP repository so that we can use its hardware and software in our FPGA platform.
```
make femu-gen-vendor
```
This command configures our architecture to generate the required RTL files.
```
make femu-gen-rtl
```
This command runs [FuseSoC](https://github.com/olofk/fusesoc) to generate the required scripts and then runs Vivado to synthesize and implement our design.
```
make femu-gen-vivado
```
