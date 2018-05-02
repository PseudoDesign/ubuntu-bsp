# Ubuntu iMX6

## Quick Start Guide

#### VM Setup

 This project utilizes the *[borg](https://github.com/Syncroness-Inc/borg)* project.  Follow the instructions in the "Required Software" section of that repository before continuing.

#### Clone the repository
 Clone this repository (and its submodules) by executing:

 `git clone --recursive https://github.com/Syncroness-Inc/ubuntu-imx6.git`

#### Initialize the VM
 Navigate to this project's `vagrant` directory, then execute `vagrant up`.  This will download and provision a virtual machine and will take several minutes the first time.

 Once that is completed, open a terminal into the VM by executing `vagrant ssh`.

 #### Building

 The download, build, and installation processes can be completed by executing `rake`.  During the process you will be prompted to enter a root password for your image.

Once complete, an SD-card image of the BSP can be found in the `images` directory.  The images are simply named with a timestamp.

#### Installing
##### On Windows

Install *[Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/)* and write the generated .img file to your SD card.  Refer to Win32 Disk Imager's documentation for details.

##### On Linux

Execute `dd if=YOUR_IMAGE_FILE of=/dev/sdX bs=1M`

Where "sdX" is the name of your SD card's device node.

## BSP Info

#### Sources
The source repository locations are set in `config/borg_config.yaml`.  Currently they utilize the Freescale Community u-boot and Linux repositories, but can easily be modified to use your own project by modifying the `sources` section.

#### Build Configuration

The u-boot and Linux config selections are shown in the *uboot* and *kernel* tasks of `rakefile.rb`.  Currently the bootloader and kernel are configured to use `mx6ull_14x14_evk_defconfig`and `imx_v7_defconfig`, respectively.  If you're building a BSP for a custom board, these fields will need to be updated.

#### Ubuntu RootFS

The Ubuntu install is currently configured for version 14.04.  This was done as a proof-of-concept and may not be suitable for a production release.
