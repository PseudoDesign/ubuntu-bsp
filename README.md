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

Execute

`dd if=YOUR_IMAGE_FILE of=/dev/sdX bs=1M`

Where "sdX" is the name of your SD card's device node.
