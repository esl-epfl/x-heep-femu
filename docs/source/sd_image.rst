SD image
========

This section describes our pre-compiled `MicroSD image <http://tiny.cc/femu_microsd_image>`_.

Our image automatically performs the required initializations after booting the operating system. All the tools you need to interact with X-HEEP (implemented on the PL side of the chip) from Linux (running on the PS side of the chip) are already pre-installed on the image.

The most important tools are:

- ``RISC-V Toolchain`` to compile the code that runs on X-HEEP.
- ``OpenOCD`` to load the binary to the X-HEEP main memory and run it.
- ``GNU Debugger (GDB)`` to connect to OpenOCD and debug your application.
- ``Screen`` to display the stdout of the application running on X-HEEP.
