
require "/vagrant/borgrake.rb"

task :make_uboot do
  uboot_dir = '/home/vagrant/uboot-fslc'
  uboot_config = 'mx6sabresd_defconfig'
  arch = "arm"
  cross_compile = "arm-linux-gnueabihf-"
  Dir.chdir(uboot_dir) do
    sh "make ARCH=#{arch} CROSS_COMPILE=#{cross_compile} #{uboot_config}"
    sh "make ARCH=#{arch} CROSS_COMPILE=#{cross_compile} -j4"
  end
end
