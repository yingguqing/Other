#创建生成APP开发证书
require "spaceship"
require "pathname"
require "fileutils"

=begin
脚本功能：p12密码：123456
脚本运行前，确保有安装fastlane库。命令：sudo gem install fastlane
1。创建Push的dis和dev证书
=end
account_name      = "" #苹果账号
account_password  = "" #苹果密码
bundle_id         = "" #应用ID


$resultText       = "申请结果如下：\n"
$devPushName      = "push_deve.p12"
$disPushName      = "push_dist.p12"

# 修改ruby当前目录到执行文件目录下
rbPath = Pathname.new(File.dirname(__FILE__)).realpath
Dir.chdir(rbPath)

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

#登录开发者后台
begin
    Spaceship::Portal.login(account_name, account_password)
rescue Exception => e
    putsText "登录开发者后台失败"
    putsText e.message
    saveText
end

app = Spaceship::Portal.app.find(bundle_id)
if app == nil
    putsText "应用不存在。。。"
    putsText "创建新的应用失败"
    putsText e.message
    saveText
else
    begin
        app.update_service(Spaceship::Portal.app_service.push_notification.on)
        putsText "开启push成功"
    rescue Exception => e
        putsText "开启push失败"
        putsText e.message
        saveText
    end
end

#创建push证书
all_prod_certs = Spaceship::Portal.certificate.ProductionPush.all
if all_prod_certs.first == nil
    #创建一个发布push证书
    putsText "正在创建发布push证书。。。"
    csr, pkey = Spaceship::Portal.certificate.create_certificate_signing_request
    dist_cer = Spaceship::Portal.certificate.ProductionPush.create!(csr: csr, bundle_id: bundle_id)
    disPriPem = bundle_id + "_dist_private_push.pem"
    disCertPem = bundle_id + "_dist_cert_push.pem"
    File.write(disPriPem, pkey.to_pem)
    File.write(disCertPem, dist_cer.download)
    system("openssl pkcs12 -export -inkey " + disPriPem + " -in " + disCertPem + " -out #{$disPushName} -password pass:'123456' ")
    system("rm -rf " + disPriPem)
    system("rm -rf " + disCertPem)
    putsText "创建发布push证书完毕"
else
    putsText "存在发布push证书"
end

all_dev_certs = Spaceship::Portal.certificate.DevelopmentPush.all
if all_dev_certs.first == nil
    #创建调试push证书
    putsText "正在创建调试push证书。。。"
    dev_csr, dev_pkey = Spaceship::Portal.certificate.create_certificate_signing_request
    dev_cer = Spaceship::Portal.certificate.DevelopmentPush.create!(csr: dev_csr, bundle_id: bundle_id)
    devPriPem = bundle_id + "_dev_private_push.pem"
    devCertPem = bundle_id + "_dev_cert_push.pem"
    File.write(devPriPem, dev_pkey.to_pem)
    File.write(devCertPem, dev_cer.download)
    system("openssl pkcs12 -export -inkey  " + devPriPem + " -in " + devCertPem + " -out #{$devPushName} -password pass:'123456' ")
    system("rm -rf " + devPriPem)
    system("rm -rf " + devCertPem)
    putsText "创建调试push证书完毕"
else
    putsText "存在开发push证书"
end

File.write("z_结果.txt", $resultText)
#打开当前目录,方便查看生成的文件
system("open .")

