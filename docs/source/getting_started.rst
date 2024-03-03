Getting started
---------------

Adding the image into the SD card
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Firstly clean the SD card and then add the image.

Cleaning the SD card
""""""""""""""""""""

Before inserting the SD card into your PC run
.. code-block:: console
    df -h

to list the available drives. The output should be something like
.. code-block:: console
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           3.1G  4.4M  3.1G   1% /run
    /dev/nvme0n1p6  480G  434G   22G  96% /
    tmpfs            16G  115M   16G   1% /dev/shm
    tmpfs           5.0M  4.0K  5.0M   1% /run/lock
    /dev/nvme0n1p1  286M  108M  179M  38% /boot/efi

Insert the SD card and run the last command again:
.. code-block:: console
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           3.1G  4.4M  3.1G   1% /run
    /dev/nvme0n1p6  480G  434G   22G  96% /
    tmpfs            16G  115M   16G   1% /dev/shm
    tmpfs           5.0M  4.0K  5.0M   1% /run/lock
    /dev/nvme0n1p1  286M  108M  179M  38% /boot/efi
    /dev/sda1       100M  6.5M   94M   7% /media/user/D25F-20D1                             <------
    /dev/sda2        15G  6.3G  7.6G  46% /media/user/4573de46-64a6-4219-bcaf-1b50432057e6  <------

Format both partitions. For instance, open the disk manager and delete the two partitions so now its empty. Then add a new partition, name it ``/dev/sda`` and mark ``erase`` to make a new clean partition with the entirety of the space of the SD card.


Copying the image on the SD card
"""""""""""""""""""""""""""""""""

Note that no partition number should be added as ouptut file
.. code-block:: console
    # Do not copy paste this command!
    sudo dd bs=4M if=<path-to-file>.img of=/dev/sda status=progress

Once its done it will "freeze" for a few minutes. This is ok, its finishing the writing operation. Once the terminal is operational again run:
.. code-block:: console
    sync

And upon finish you can extract the SD card.

Connect to the pynq-z2 via SSH
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Setup
"""""

Insert the SD card into the pynq-z2. Put the boot jumper to ``SD`` (and not ``JTAG`` as it's used to communicate with the EPFL programmer). The reset LED  will turn on in around 30s once X-HEEP is up and running on the programmable logic. Connect the ETH cable to the pynq and to a switch or router.
Additionally, connect a USB to the pynq and your PC.
If you are going to power the pynq from the USB, make sure that the power jumper is set to ``USB``, otherwise use a power cord and select ``REG` with the jumper.

Obtaining the assigned IP address
"""""""""""""""""""""""""""""""""

Connect from your PC through the USB cable:
.. code-block:: console
    screen /dev/ttyUSB0 115200
Set the corresponding device according to what you find. If in doubt, type
.. code-block:: console
    screen /dev/
and press ``TAB``. A list of available devices will show up. If you  do this with and without the USB connected, the pynq will be one of the new devices that appear.

The password to access is ``xilinx``.

Once inside the device run
.. code-block:: console
    ifconfig
And scan the output to detected the assigned IP address:
e.g.
.. code-block:: console
    eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet 128.178.39.188  netmask 255.255.255.0  broadcast 128.178.39.255
            inet6 fe80:: . . .

In this case, the IP address assigned is ``128.178.39.188``
You can now `exit` and disconnect the USB (unless you are powering the pynq from the USB).

Connect using the assigned IP
"""""""""""""""""""""""""""""

Connect to the same network as the pynq is connected to and input:
.. code-block:: console
    ssh -X xilinx@<assigned-IP>
    # The first time you will be prompted if you want to authenticate yourself:
    yes
    # Input the password: xilinx

Additionally, you can open a browser and go to ``<assigned-IP>:9090``


Interacting with files in the pynq
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Mounting the file system
""""""""""""""""""""""""

It is possible to mount the file system of the pynq by running:
.. code-block:: console
    sshfs xilinx@<assigned-IP>:<path-to-source-directory> <path-to-destination-directory>
Note that the destination directory must be an existing folder.

Copy files
""""""""""
To copy files into the pynq run:
.. code-block:: console
    scp <path-to-source> xilinx@<assigned-IP>:<path-to-destination>


Running applications on X-HEEP
------------------------------

This section shows how to get started with our FPGA platform running your first ``Hello World`` application.

You can do this in three different ways:

- ``Jupyter notebook`` (suggested)
- ``Python script``
- ``Python shell``

Jupyter notebook
^^^^^^^^^^^^^^^^

Connect to Linux, running on the board, using your Web browser and follow these steps.

Navigate to ``arm`` and click on ``jupyter_notebooks``:

.. image:: ./images/jupyter_1.png
  :width: 400

Click on ``hello_world.ipynb``:

.. image:: ./images/jupyter_2.png
  :width: 400

Run the Python code:

.. image:: ./images/jupyter_3.png
  :width: 400

You will get this output:

.. image:: ./images/jupyter_4.png
  :width: 400

Python script
^^^^^^^^^^^^

Connect to Linux, running on the board, using SSH from your terminal and follow these steps.

Enter the X-HEEP FEMU SDK folder:

.. code-block:: console

    cd x-heep-femu-sdk/

Run sudo:

.. code-block:: console

    sudo su

Initialize the environment:

.. code-block:: console

    source ./init.sh

Navigate to the application folder:

.. code-block:: console

    cd sw/arm/apps/hello_world/

Run the ``Hello World`` application:

.. code-block:: Python

    python3 hello_world.py

You will get this output:

.. code-block:: console

    --- APPLICATION OUTPUT ---

    Hello World!

Python shell
^^^^^^^^^^^^

Connect to Linux, running on the board, using SSH from your terminal and follow these steps.

Enter the X-HEEP FEMU SDK folder:

.. code-block:: console

    cd x-heep-femu-sdk/

Run sudo:

.. code-block:: console

    sudo su

Initialize the environment:

.. code-block:: console

    source ./init.sh

Start the Python3 shell:

.. code-block:: console

    python3

Run the ``Hello World`` application with this Python code:

.. code-block:: Python

    # Import the X-HEEP Python class
    from pynq import x_heep

    # Load the X-HEEP bitstream
    x_heep = x_heep()

    # Compile the application
    x_heep.compile_app("hello_world")

    # Run the application
    x_heep.run_app()

You will get this output:

.. code-block:: console

    --- APPLICATION OUTPUT ---

    Hello World!

.. note::

  You can use the ``Python script`` and ``Python shell`` methods to debug the ``Hello World`` application (or your own application). You only need to substitute the ``run_app()`` function with the ``run_app_debug()`` function in the code. You can now debug the application with GDB!

.. warning::

  Debugging is NOT supported by the ``Jupyter notebook`` method!
