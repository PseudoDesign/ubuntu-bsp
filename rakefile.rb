
require "/vagrant/borgrake.rb"


uboot_dir = '/home/vagrant/uboot-fslc'
kernel_dir = '/home/vagrant/linux-fslc'
ubuntu_rfs_dir = '/home/vagrant/ubuntu-core'
install_dir = '/home/vagrant/install'


binary_dir = File.join(install_dir, "binary")
rfs_dir = File.join(install_dir, "media/rootfs")

def crossmake(target)
  arch = "arm"
  cross_compile = "arm-linux-gnueabihf-"
  cores = "4"

  sh "make ARCH=#{arch} CROSS_COMPILE=#{cross_compile} -j#{cores} #{target}"
end

task :uboot do
  uboot_config = 'mx6sabresd_defconfig'
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

task :ubuntu => [:borg_update_sources]

task :install => [:install_boot, :install_ubuntu, :install_kernel]

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
    File.join(uboot_dir, "u-boot.bin"),
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
  FileUtils.cp(
    File.join(
      kernel_dir, "arch", "arm", "boot", "dts",
      "imx6dqscm-1gb-qwks-rev3-btwifi-fix-ldo.dtb"
    ),
    binary_dir
  )
  # Install headers
  sh "sudo make -C #{kernel_dir} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- \
  headers_install INSTALL_HDR_PATH=#{rfs_dir}/usr  "
  # Install firmware
  sh "sudo make -C #{kernel_dir} modules_install firmware_install \
      INSTALL_MOD_PATH=#{rfs_dir} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- "
end
