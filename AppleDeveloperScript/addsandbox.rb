# 新增沙箱账号
require "spaceship"

=begin
脚本功能：p12密码：123456
脚本运行前，确保有安装fastlane库。命令：sudo gem install fastlane
1。新增沙箱账号, 密码：Sandbox123
=end
account_name 	    =  ""#苹果账号
account_password  =  ""#苹果密码
sandbox_name 	    =  ""#沙箱账号
country           =  "CN" # 沙箱所在国家，默认为中国区沙箱，特殊情况修改成相应的国家代码，比如：美国(US)
$resultText       =  "沙箱申请结果：\n"

# 修改ruby当前目录到执行文件目录下
Dir.chdir(Pathname.new(File.dirname(__FILE__)).realpath)

def putsText(text)
    puts text
    $resultText = $resultText + text + "\n"
end

def saveText()
    File.write("z出错.txt", $resultText)
    system("open z出错.txt")
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

begin
    #登录开发者后台
    Spaceship::Tunes.login(account_name,account_password)
    testers = Spaceship::Tunes::SandboxTester.create!(
      email: sandbox_name, # required
      password: "Sandbox123", # required. Must contain >=8 characters, >=1 uppercase, >=1 lowercase, >=1 numeric.
      country: country, # optional, defaults to 'US'
      first_name: "fds", # optional, defaults to 'Test'
      last_name:"box", # optional, defaults to 'Test'
    )
rescue Exception => e
    putsText "创建沙箱账号失败"
    putsText e.message
    saveText
end

# 查询所有的沙箱账号
testers = Spaceship::Tunes::SandboxTester.all
testers.each do |line|
    putsText line.email
end

File.write("z_结果.txt", $resultText);
#打开当前目录,方便查看生成的文件
system("open .")
