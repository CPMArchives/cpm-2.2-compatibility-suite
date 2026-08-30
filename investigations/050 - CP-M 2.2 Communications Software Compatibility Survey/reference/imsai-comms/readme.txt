The communication programs for IMSAI 8080 require CP/M 2.2 B01
or later, and CP/M 3 V1.5 or later, with support for the second
SIO-2 and the modem port. For the IMSAI 8080esp firmware
update v1.5 or later is required.


Kermit is the generic version for CP/M-80 2.2 systems,
to connect to the serial port use:

	SET PORT UC1
	CONNECT

Port UC1 is mapped in the BIOS to the modem port, for using the
second serial port execute 'submit porta' to patch the mapping.


Kermit3 is the generic version for CP/M-80 3.x systems. This
version has no SET PORT implemented, it will always talk to the
auxiliary port after a CONNECT. By default it is assigned to the
second serial port, to assign it to the modem before running
kermit3 use:

	DEVICE AUXIN:=MODEM
	DEVICE AUXOUT:=MODEM


The configuration file for xmodem has the IMSAI 8080
ports defined for the second serial port, so that is
used if the configuration file is found on the current
disk. The program also can be used without configuration
file and option /X1, it will use the CP/M PTR and PTP
devices supported in the BIOS then.


QTerm is patched for a DEC VT-100 terminal, so don't
use the program on the VIO screen. The escape character
is patched to CTL-^. With CTL-^ U you can select which
channel to use for the modem, A is the second serial
port, B is the modem. QTerm uses Z80 instructions and
won't work with a 8080 CPU.

Udo Munk - December 2019
