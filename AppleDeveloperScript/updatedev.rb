#更新设备ID
require "spaceship"
require "pathname"

=begin
脚本功能：p12密码：123456
脚本运行前，确保有安装fastlane库。命令：sudo gem install fastlane
1。创建Push的dis和dev证书
=end

account_name      = "" #苹果账号
account_password  = ""
bundle_id         = ""
udids             = [] # 测试设备的udid，为空不添加，格式["0000-122-dd-11", "0000-222-333-555"]


$resultFileName   = "z结果.txt"
$resultText       = "所有设备UUID：\n"
$devMBName        = "dev_#{bundle_id}.mobileprovision"

# 修改ruby当前目录到执行文件目录下
rbPath = Pathname.new(File.dirname(__FILE__)).realpath
Dir.chdir(rbPath)

def putsText(text)
  puts text
  $resultText = $resultText + text + "\n"
end

def saveText()
    File.write($resultFileName, $resultText)
    system("open " + $resultFileName)
    exit
end

# 检查库是否有安装
def checkGemAvailable(gemName, versionLimit=nil)
  isAvailable = false
  begin
      if versionLimit == nil
          gem  gemName
      else
          gem  gemName, versionLimit
      end
      isAvailable = true
  rescue LoadError
    putsText LoadError.message
  end
  if isAvailable == false 
    putsText "不存在#{gemName}库，正在使用sudo gem install #{gemName}安装"
    putsText "如果安装失败，请在终端手动运行上面命令"
    system("sudo gem install #{gemName}")
  end
end

# 检查fastlane库
checkGemAvailable("fastlane")

#登录开发者后台
begin
    Spaceship::Portal.login(account_name, account_password)
rescue Exception => e
    putsText "登录开发者后台失败"
    putsText e.message
    saveText
end

udids.each do |line|
  temp_udid_dev = Spaceship::Portal.device.find_by_udid(line.lstrip.chomp)
  if !temp_udid_dev
    putsText "新增：" + line
    Spaceship::Portal.device.create!(name: Time.now.to_i.to_s + rand(999999).to_s, udid: line.lstrip.chomp)
  end
end

begin
  #更新 dev 证书
  profile = Spaceship::Portal.provisioning_profile.development.all.find {|p| p.app.bundle_id == bundle_id}
  profile.devices = Spaceship::Portal.device.all
  profile.update!

  dev_profile = Spaceship::Portal.provisioning_profile.development.all.find {|p| p.app.bundle_id == bundle_id}
  File.write($devMBName, dev_profile.download)
  putsText $devMBName + " 下载成功"
rescue Exception => e
  putsText "更新描述文件失败  "
  putsText e.message
  saveText
end

File.write($resultFileName, $resultText)
#打开当前目录,方便查看生成的文件
system("open .")

