ARM software
============

This section describes our platform's ARM software. This software runs on Linux on the PS side of the chip and is responsible for the interaction with X-HEEP implemented on the PL side of the chip. 

Software development kit (SDK)
------------------------------

We support the user with a dedicated Python class, called ``x_heep``, that allows you to easily use all the platform's functionalities.

Basic functions
^^^^^^^^^^^^^^^

.. code-block:: Python

    __init__()

It initialises the class and loads the bitstream.

.. code-block:: Python

    load_bitstream()

It loads the bitstream.

.. code-block:: Python

    compile_app(app_name)

* ``app_name`` is the name of the application to be compiled.

It compiles the application with the specified name.

.. code-block:: Python

    run_app()

It runs the last application that has been compiled.

.. code-block:: Python

    run_app_debug()

It runs the last application that has been compiled in debug mode so that you can debug it with GDB.

.. warning:: 

    This function is not supported by Jupyter notebooks!

These last two functions are realised through a combination of OpenOCD, GDB and Screen. OpenOCD is used to implement the JTAG protocol driving the required GPIO pins, while GDB is used to send the needed commands to OpenOCD in order to program the X-HEEP main memory and run or debug the application. Finally, Screen is exploited to extract the stdout of the application running on X-HEEP.

.. image:: ../images/arm_sw.svg
   :width: 600

Virtual Flash functions
^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: Python

    init_flash()

It allocates in the DDR memory a buffer of 32KB and stores its base address in the configuration register of the virtual Flash address adder. Then, initialises it to zero and returns the allocated virtual Flash buffer object.

.. code-block:: Python

    reset_flash(flash)

* ``flash`` is the name of the virtual Flash buffer object.

It initializes to zero the complete virtual Flash buffer.

.. code-block:: Python

    write_flash(flash)

* ``flash`` is the name of the virtual Flash buffer object.

It writes to the virtual Flash buffer the content of the file named ``flash_in.bin`` from the application folder.

.. warning::

    The input binary file must be named ``flash_in.bin`` and located in the application folder. The file cannot have a size higher than 32KB (the size of the virtual Flash)!

.. code-block:: Python

    read_flash(flash)

* ``flash`` is the name of the virtual Flash buffer object.

It reads the virtual Flash buffer and stores the content in a file named ``flash_out.bin`` that will be created in the ``build`` folder.

Virtual ADC functions
^^^^^^^^^^^^^^^^^^^^^

.. code-block:: Python

    init_adc_mem()

It maps the virtual ADC BRAM (8KB) and initialises it to zero. Then, returns the virtual ADC memory object.

.. code-block:: Python

    reset_adc_mem(adc_mem)

* ``adc_mem`` is the name of the virtual ADC memory object.

It initializes to zero the complete virtual ADC memory.

.. code-block:: Python

    write_adc_mem(adc_mem)

* ``adc_mem`` is the name of the virtual ADC memory object.

It writes to the virtual ADC memory the content of the file named ``adc_in.bin`` from the application folder.

.. warning::

    The input binary file must be named ``adc_in.bin`` and located in the application folder. The file cannot have a size higher than 8KB (the size of the ADC BRAM)!

.. code-block:: Python

    read_adc_mem(adc_mem)

* ``adc_mem`` is the name of the virtual ADC memory object.

It reads the virtual ADC memory and stores the content in a file named ``adc_out.bin`` that will be created in the ``build`` folder.

Performance estimation functions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: Python

    init_perf_cnt()

It maps the performance counters and resets them. Then, returns the performance counters object.

.. code-block:: Python

    reset_perf_cnt(perf_cnt)

* ``perf_cnt`` is the name of the performance counters object.

It resets the performance counters.

.. code-block:: Python

    start_perf_cnt_automatic(perf_cnt)

* ``perf_cnt`` is the name of the performance counters object.

It starts the performance counters in the automatic mode.

.. code-block:: Python

    start_perf_cnt_manual(perf_cnt)

* ``perf_cnt`` is the name of the performance counters object.

It starts the performance counters in the manual mode.

.. code-block:: Python

    stop_perf_cnt(perf_cnt)

* ``perf_cnt`` is the name of the performance counters object.

It stops the performance counters.

.. code-block:: Python

    read_perf_cnt(perf_cnt)

* ``perf_cnt`` is the name of the performance counters object.

It reads the performance counters and stores their values in a CSV file named ``perf_cnt.csv`` that will be created in the ``build`` folder.

.. code-block:: Python

    estimate_performance()

It combines the values of the performance counters file with the frequency of the platform's clock (20MHz) and calculates the performance of each IP in the architecture. Then, prints the performance to the stdout and stores the values in a CSV file named ``perf_estim.csv`` that will be created in the ``build`` folder.

.. warning::

    This function can only be called after the ``read_perf_cnt()`` function!

Energy estimation functions
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: Python

    estimate_energy(cells)

* ``cells`` is the type of cells, LVT or HVT, you would like to use for the energy estimation.

Our energy model combines the values of the performance file with the values of the power file and estimates the energy of each IP in the architecture. Then, prints the energies to the stdout and stores the values in a CSV file named ``energy_estim.csv`` that will be created in the ``build`` folder.

.. warning::

    This function can only be called after the ``estimate_performance()`` function!

.. note::

    Our team is working to allow the user to specify not only the type of cells but also the clock frequency (ranging from 10 MHz to 250 MHz, for LVT and from 10 MHz to 100 MHz, for HVT)!

Memory map
----------

+----------------+-----------------+------------------+------------------------------+
| Base address   | Length (Byte)   | Description                                     |
+================+=================+=================================================+
| 0x40000000     | 0x2000          | ADC memory                                      |
+----------------+-----------------+-------------------------------------------------+
| 0x43C00000     | 0x0004          | Flash AXI address adder                         |
+----------------+-----------------+-------------------------------------------------+
| 0x43C10000     | 0x0100          | Performance counters                            |
+----------------+-----------------+-------------------------------------------------+
