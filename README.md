# flipOS

flipOS was created to overcome a shortcoming of the Microsoft Windows installer.
When creating a USB flash drive installer for Microsoft Windows the installer
needs to be located on the first partition of the device. But Microsoft Windows
also only ever recognizes the first partition of a removable drive and denies
access to other partition, so one ends up with a USB drive with a single FAT32
formatted partition littered with Windows install files, not really usable for
anything else.

To overcome this flipOS was developed which allows the USB drive to be split in
3+ partitions. Partition 3 containing only the Windows install files and
partition 1 containing any file system and data. Partition 2's VBR will be home
to flipOS which will flip the MBR entries for partitions 1 and 3 allowing
to use the Windows installer and a clean data partition.

## Build
	make
