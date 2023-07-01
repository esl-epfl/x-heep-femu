Welcome to our X-HEEP-based FPGA EMUlation Platform (FEMU) documentation!
=========================================================================

This documentation describes in detail the hardware and software of our new X-HEEP-based FPGA EMUlation Platform (FEMU).

Goals
-----

We ported our custom `eXtendible Heterogeneous Energy-Efficient Platform (X-HEEP) <https://github.com/esl-epfl/x-heep>`_ microcontroller to the TUL Pynq-Z2 board, based on the Xilinx Zynq-7020 chip, in order to realize a valuable FPGA-based emulation platform for performing software explorations of ultra-low-power edge-computing applications. These applications are commonly based on acquisition periods, where the needed data are read from external analogue to digital converters (ADCs) and stored in memory, followed by processing periods, where the acquired data are elaborated. The development process may require exploring several acquisition schemes, memory management strategies and computational algorithms in order to optimize performance, power and energy consumption. Our FPGA platform is specifically thought to support software developers in performing this exploration. The design provides internal code debugging and peripherals virtualization, thanks to Linux running on the ARM-based processing system (PS) side of the chip, which allows performing Flash memory accesses and ADC acquisitions without requiring external board connectivity. Moreover, our design features a powerful performance extraction strategy that, combined with pre-calculated power values from our X-HEEP-based ASIC version (implemented with TSMC 65nm CMOS technology), allows software developers to estimate the energy consumption of their running applications. Finally, Jupyter notebook support in combination with a dedicated X-HEEP Python class provides a quick and easy way of interacting with the platform and exploring its functionalities.

Features
--------

The main features of our FPGA platform are the following:

- based on our X-HEEP microcontroller
- On-chip JTAG virtualization.
- On-chip UART virtualization.
- On-chip Flash virtualization.
- On-chip ADC virtualization.
- Off-board connectivity: GPIOs, QSPI and I2C.
- Performance estimation.
- Energy estimation (based on TSMC 65nm CMOS technology).
- Jupyter notebook support.
- Dedicated X-HEEP Python class.
- Very easy to set up thanks to our pre-compiled MicroSD image.

Contents
--------

.. toctree::
    :maxdepth: 0

    getting_started.rst
    sd_image.rst
    software.rst
    hardware.rst
