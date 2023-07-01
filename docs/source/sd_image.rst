SD image
========

This section describes the structure and content of our pre-compiled `MicroSD image <http://tiny.cc/femu_microsd_image>`_.

Our image automatically loads the X-HEEP bitstream and performs the required initializations after booting the operating system. All the tools you need to interact with X-HEEP (implemented on the PL side of the chip) from Linux (running on the PS side of the chip) are already pre-installed on the image.

The most important tools are:

- ``RISC-V Toolchain`` to compile the code that runs on X-HEEP.
- ``OpenOCD`` to load the binary to the X-HEEP main memory and run it.
- ``GNU Debugger (GDB)`` to connect to OpenOCD and debug your application.
- ``Screen`` to display the stdout of the application running on X-HEEP.
- ``X-HEEP Python class`` to use all the platform's features with a dedicated API.

The home directory of our image presents the following structure:

| ~
| ├── jupyter_notebooks
| ├── x_heep
| │    ├── init.sh
| │    ├── hw
| │    │   ├── x_heep.bit
| │    │   └── x_heep.hwh
| │    └── sw
| │        ├── riscv
| │        │    ├── apps
| │        │    ├── lib
| │        │    ├── link
| │        │    ├── pwr_val
| │        │    └── Makefile
| │        └── arm
| │             ├── apps
| │             ├── sdk
| │             └── tools
|

In the folder structure above:

- ``jupyter-notebooks`` contains notebooks that you can use to run our sample applications.
- ``x_heep`` stores the hardware and software of our platform.
- ``init.sh`` is used to initialize the environment.
- ``hw`` contains the hardware of our platform.
- ``x_heep.bit`` is the bitstream file.
- ``x_heep.hwh`` is the hardware configuration file.
- ``sw`` contains the software of our platform.
- ``riscv`` contains the software tools to compile the RISC-V application that runs on X-HEEP.
- ``apps`` stores our sample C applications.
- ``lib`` stores the needed hardware abstraction layer (HAL).
- ``link`` stores the linker script.
- ``pwr_val`` stores the power values for our energy model.
- ``Makefile`` is the Makefile used to compile our RISC-V applications.
- ``arm`` contains the software components needed to use our X-HEEP Python class.
- ``apps`` stores our sample Python applications.
- ``sdk`` stores our X-HEEP Python class.
- ``tools`` stores the needed tools to interact with X-HEEP.
