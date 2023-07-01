RISC-V software
===============

This section quickly summarises our platform's RISC-V software. This software can be easily compiled thanks to our pre-installed RISC-V Toolchain which you can find in the MicroSD image. The generated binary will run on X-HEEP implemented on the PL side of the chip.

Hardware abstraction layer (HAL)
--------------------------------

We support the user with a dedicated hardware abstraction layer (HAL) that comes from our X-HEEP microcontroller. It provides a wide set of low-level C functions that allow you to easily access all the functionalities of the X-HEEP peripherals.

Our HAL covers the following modules:

- ``SoC controller``
- ``Fast interrupt controller``
- ``Platform-level interrupt controller``
- ``Timer``
- ``GPIOs``
- ``SPI``
- ``I2C``
- ``Direct memory access (DMA)``
- ``Power manager``
- ``Pad control``

Refer to the main `X-HEEP <https://github.com/esl-epfl/x-heep>`_ repository for a deeper HAL description.

Software development kit (SDK)
------------------------------

.. note::

   Our team is working to implement a set of higher-level functions that will help you explore all the X-HEEP peripherals' functionalities without the need of learning our lower-level HAL!

FreeRTOS
--------

.. note::

   Our team is working to port FreeRTOS (already supported by our X-HEEP microcontroller) to the FPGA platform!

Sample applications
-------------------

We provide the user with sample applications showing how he can use our HAL to explore the most important platform's functionalities.

The provided examples are the following:

- ``Hello World`` prints "Hello World" to the stdout.
- ``Virtual Flash read`` reads data from the virtual Flash.
- ``Virtual Flash write`` writes data to the virtual Flash.
- ``Virtual ADC read`` reads samples from the ADC memory.
- ``Virtual ADC write`` writes samples to the ADC memory (just for testing purposes).
- ``Performance estimation`` activates the performance counters and prints "Hello world" to the stdout (used for performance estimation).
- ``Energy estimation`` activates the performance counters and prints "Hello world" to the stdout (used for energy estimation).

These applications are thought to be used as a starting model for the development of more advanced and complex applications.

Real-world applications
-----------------------

.. note::

   Our team is working to port real-world edge-computing applications to our FPGA platform, in order to better show the benefit of all the implemented features!
