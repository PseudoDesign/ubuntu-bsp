
require "/vagrant/borgrake.rb"


uboot_dir = '/home/vagrant/uboot-fslc'
kernel_dir = '/home/vagrant/linux-fslc'
ubuntu_rfs_dir = '/home/vagrant/ubuntu'
install_dir = '/home/vagrant/install'
uboot_file = 'u-boot-dtb.bin'


binary_dir = File.join(install_dir, "binary")
rfs_dir = File.join(install_dir, "media/rootfs")

TMP_SD_FILE_NAME = "/home/vagrant/.tmpsd.img"

PARTITION_INFO = [
  {
    partition_name: "boot",
    partition_start_sector: 2048,
    partition_length_sectors: (1024 * 1024 * 500 / 4)/512,
    fdisk_type: "6", # FAT16
    mkfs_command: "mkfs.vfat"
  },
  {
    partition_name: "rootfs1",
    partition_start_sector: 280000,
    partition_length_sectors: (1024 * 1024 * 500)/512,
    mkfs_command: "mkfs.ext3"
  }
]

def crossmake(target)
  arch = "arm"
  cross_compile = "arm-linux-gnueabihf-"
  cores = "4"

  sh "make ARCH=#{arch} CROSS_COMPILE=#{cross_compile} -j#{cores} #{target}"
end

task :uboot do
  uboot_config = 'imx6qdl_icore_mmc_defconfig'
  Dir.chdir(uboot_dir) do
    crossmake(uboot_config)
    crossmake("")
  end
end

task :kernel do
  kernel_config = 'imx_v7_defconfig'
  Dir.chdir(kernel_dir) do
    crossmake(kernel_config)
    crossmake("zImage modules dtbs")
  end
end

task :ubuntu do
  target = ubuntu_rfs_dir
  distro = 'trusty'
  # Install stage one of our rootfs
 `
  mkdir -p #{target}
  sudo debootstrap --arch=armhf --foreign --include=ubuntu-keyring,apt-transport-https,ca-certificates,openssl #{distro} "#{target}" http://ports.ubuntu.com
  sudo cp /usr/bin/qemu-arm-static #{target}/usr/bin
  sudo cp /etc/resolv.conf #{target}/etc
 `
 # chroot into the rootfs dir, then run second stage
bootstrap_script =
"
 set -v
 export LC_ALL=C LANGUAGE=C LANG=C
 /debootstrap/debootstrap --second-stage
 echo \"deb http://ports.ubuntu.com/ubuntu-ports/ #{distro} main restricted universe multiverse\" > /etc/apt/sources.list
 echo \"deb http://ports.ubuntu.com/ubuntu-ports/ #{distro}-updates main restricted universe multiverse\" >> /etc/apt/sources.list
 echo \"deb http://ports.ubuntu.com/ubuntu-ports/ #{distro}-security main restricted universe multiverse\" >> /etc/apt/sources.list
 apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 40976EAF437D05B5
 apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 3B4FE6ACC0B21F32
 apt-get update
 apt-get upgrade -y
 apt-get install -y vim
 passwd root
"
File.write(".bootstrap.sh", bootstrap_script)
 `
  sudo mv .bootstrap.sh #{target}
  sudo chroot #{target} ./.bootstrap.sh
 `
 # Clean up qemu and resolv.conf
 `
  sudo rm #{target}/etc/resolv.conf
  sudo rm #{target}/usr/bin/qemu-arm-static
 `
end

task :install => [:install_boot, :install_ubuntu, :install_kernel]

task :sd_card do
  if File.exist?(TMP_SD_FILE_NAME)
    `rm #{TMP_SD_FILE_NAME}`
  end
  BorgLib.create_image(TMP_SD_FILE_NAME, PARTITION_INFO)
  BorgLib.mount_partitions(TMP_SD_FILE_NAME, PARTITION_INFO) do
    `
      sudo cp -r #{binary_dir}/* /var/.tmpmnt/boot
      sudo cp -r #{rfs_dir}/* /var/.tmpmnt/rootfs1
    `
  end
  # Write uboot
  `
  dd conv=notrunc if=#{binary_dir}/#{uboot_file} of=#{TMP_SD_FILE_NAME} bs=512 seek=2
  `
  `
    mkdir -p /share/images
    cp /home/vagrant/.tmpsd.img /share/images/#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.img
  `
end

task :install_ubuntu => [:ubuntu] do
  FileUtils.mkdir_p rfs_dir
  # Install Ubuntu
  sh "sudo cp -r #{ubuntu_rfs_dir}/* #{rfs_dir}"
end

task :install_boot => [:uboot] do
  # Create install dirs
  FileUtils.mkdir_p binary_dir
  # TODO: Verify .bin is the correct file to load
  # Install uboot
  FileUtils.cp(
    File.join(uboot_dir, uboot_file),
    binary_dir
  )
end

task :install_kernel => [:kernel] do
  FileUtils.mkdir_p binary_dir
  FileUtils.mkdir_p rfs_dir
  # Install the kernel image
  FileUtils.cp(
    File.join(kernel_dir, "arch", "arm", "boot", "zImage"),
    binary_dir
  )
  # Install dts
  dts = File.join(kernel_dir, "arch", "arm", "boot", "dts")
  `cp #{dts}/imx6dqscm-1gb-qwks-rev2-wifi-fix-ldo.dts #{binary_dir}`
  # Install headers
  sh "sudo make -C #{kernel_dir} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- \
  headers_install INSTALL_HDR_PATH=#{rfs_dir}/usr  "
  # Install firmware
  sh "sudo make -C #{kernel_dir} modules_install firmware_install \
      INSTALL_MOD_PATH=#{rfs_dir} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- "
end

task :default => [:borg_install_sources, :install, :sd_card]
