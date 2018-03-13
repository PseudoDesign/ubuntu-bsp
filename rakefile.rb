
require "/vagrant/borgrake.rb"


uboot_dir = '/home/vagrant/uboot-fslc'
kernel_dir = '/home/vagrant/linux-fslc'

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

task :install => [:kernel, :uboot] do
  install_dir = "/share/install"
  binary_dir = File.join(install_dir, "binary")
  FileUtils.mkdir_p binary_dir
  # TODO: Verify .bin is the correct file to load
  FileUtils.cp(
    File.join(uboot_dir, "u-boot.bin"),
    binary_dir
  )
  FileUtils.cp(
    File.join(kernel_dir, "arch", "arm", "boot", "zImage"),
    binary_dir
  )
  FileUtils.cp(
    File.join(kernel_dir, "arch", "arm", "boot", "dts", "imx6dqscm-1gb-qwks-rev3-btwifi-fix-ldo.dtb"),
    binary_dir
  )
end
