
require "spaceship"
require "pathname"

=begin
脚本功能：p12密码：123456
脚本运行前，确保有安装fastlane库。命令：sudo gem install fastlane
1。创建dev开发证书，受createDev变量控制
2。创建dis发布证书
3。创建Push的dis和dev证书，受createPushCert变量控件
4。到itunes创建相应App
5。创建沙箱，密码：Sandbox123，沙箱账号不为空时创建
6。添加设备
8。创建dev开发描述文件
9。创建dis发布描述文件
=end

account_name      = ""    # 苹果账号
account_password  = ""    # 苹果密码
bundle_id         = ""    # 应用ID
app_name          = ""    # 应用名称
sandbox_name      = ""    # 沙箱账号,必须是邮箱格式(为空不创建),沙箱密码:Sandbox123
createDev         = true  # 是否创建dev的描述文件和证书
createPushCert    = false # 是否同时创建Push证书
$resultText       = "申请结果如下：\n"
devP12Name        = "deve.p12"
disP12Name        = "dist.p12"
devMBName         = "dev_#{bundle_id}.mobileprovision"
disMBName         = "dis_#{bundle_id}.mobileprovision"
devPushName       = "push_deve.p12"
disPushName       = "push_dist.p12"
udids             = [] # 测试设备的udid，为空不添加，格式["0000-122-dd-11", "0000-222-333-555"]

# 修改ruby当前目录到执行文件目录下
rbPath = Pathname.new(File.dirname(__FILE__)).realpath
Dir.chdir(rbPath)

def putsText(text)
  puts text
  $resultText = $resultText + text + "\n"
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
    putsText "正在登录开发者后台"
    Spaceship::Portal.login(account_name, account_password)
rescue Exception => e
    putsText "登录开发者后台失败"
    putsText e.message
    saveText
end

#创建dev证书
if createDev
  all_dev_certs = Spaceship::Portal.certificate.development.all
  if all_dev_certs.first == nil
      #创建调试证书
      putsText "正在创建调试证书。。。"
      dev_csr, dev_pkey = Spaceship::Portal.certificate.create_certificate_signing_request
      dev_cer = Spaceship::Portal.certificate.development.create!(csr: dev_csr)
      devPriPem = bundle_id + "_dev_private.pem"
      devCertPem = bundle_id + "_dev_cert.pem"
      File.write(devPriPem, dev_pkey.to_pem)
      File.write(devCertPem, dev_cer.download)
      system("openssl pkcs12 -export -inkey  #{devPriPem} -in #{devCertPem} -out #{devP12Name} -password pass:'123456' ")
      system("rm -rf " + devPriPem)
      system("rm -rf " + devCertPem)
      putsText "创建调试书完成"
  end
end

# 创建dis的p12文件
all_prod_certs = Spaceship::Portal.certificate.production.all
if all_prod_certs.first == nil
  #创建一个发布者证书
  putsText "正在创建发布证书。。。"
  csr, pkey = Spaceship::Portal.certificate.create_certificate_signing_request
  dist_cer = Spaceship::Portal.certificate.production.create!(csr: csr)
  disPriPem = bundle_id + "_dist_private.pem"
  disCertPem = bundle_id + "_dist_cert.pem"
  File.write(disPriPem, pkey.to_pem)
  File.write(disCertPem, dist_cer.download)
  system("openssl pkcs12 -export -inkey #{disPriPem} -in #{disCertPem} -out #{disP12Name} -password pass:'123456' ")
  system("rm -rf " + disPriPem)
  system("rm -rf " + disCertPem)
  putsText "创建发布证书完成"
end

# 查询app是否存在
app = Spaceship::Portal.app.find(bundle_id)
if app == nil
  #创建一个app
  putsText "正在创建新应用。。。"
  begin
    name = bundle_id.delete(".")#名称不能为中文
    app = Spaceship::Portal.app.create!(bundle_id: bundle_id, name: name)
    app.update_service(Spaceship::Portal.app_service.in_app_purchase.on)
    if createPushCert
        app.update_service(Spaceship::Portal.app_service.push_notification.on)
    end
    #app.update_service(Spaceship::Portal.app_service.icloud.on)
    putsText "创建新应用成功"
  rescue Exception => e
    putsText "创建新的应用失败"
    putsText e.message
    saveText
  end
end

#创建push证书
if createPushCert
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
    system("openssl pkcs12 -export -inkey " + disPriPem + " -in " + disCertPem + " -out #{disPushName} -password pass:'123456' ")
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
    system("openssl pkcs12 -export -inkey  " + devPriPem + " -in " + devCertPem + " -out #{devPushName} -password pass:'123456' ")
    system("rm -rf " + devPriPem)
    system("rm -rf " + devCertPem)
    putsText "创建调试push证书完毕"
  else
    putsText "存在开发push证书"
  end
end

#登录itunes后台
begin
    putsText "正在登录iTunes后台"
    Spaceship::Tunes.login(account_name, account_password)
rescue Exception => e
    putsText "登录iTunes后台失败"
    putsText e.message
    saveText
end
 
itunes_app_info = Spaceship::Tunes::Application.find(bundle_id)
if itunes_app_info == nil
  putsText "正在从itunes创建应用。。。"
  begin
    generated_app = Spaceship::Tunes::Application.create!(
      # 加上一个随机数，防止重名
      name: app_name #+ rand(1..9).to_s,
      primary_language: "Chinese",
      sku: Time.now.to_i.to_s, # might be an int
      bundle_id: bundle_id,
      #bundle_id_suffix: Produce.config[:bundle_identifier_suffix],
      #  company_name: Produce.config[:company_name],
      platform: "ios")
    putsText "从itunes创建应用成功"
  rescue Exception => e
    putsText "从itunes创建应用失败"
    putsText e.message
    saveText
  end
else
  putsText "应用已存在"
end

#创建沙箱账号(沙箱账号不为空时)
unless sandbox_name.empty?
  begin
    putsText "正在创建沙箱账号: " + sandbox_name
    putsText "密码: Sandbox123"
    #testers = Spaceship::Tunes::SandboxTester.all
    testers = Spaceship::Tunes::SandboxTester.create!(
        email: sandbox_name, # required
        password: "Sandbox123", # required. Must contain >=8 characters, >=1 uppercase, >=1 lowercase, >=1 numeric.
        country: 'CN', # optional, defaults to 'US'
        first_name: "xs",
        last_name: "box")
    putsText "创建沙箱账号成功"
    putsText sandbox_name
  rescue Exception => e
    putsText "创建沙箱账号失败  "
    putsText e.message
  end
end

#添加测试设备
udids.each do |line|
  next if line.empty?
  temp_udid_dev = Spaceship::Portal.device.find_by_udid(line.lstrip.chomp)
  if !temp_udid_dev
    Spaceship::Portal.device.create!(name: Time.now.to_i.to_s + rand(999999).to_s, udid: line.lstrip.chomp)
  end
end

#修复现有所有有问题的证书
putsText "处理描述文件。。。"
begin
  if createDev
    isCreateProfiles = true
    dev_profiles = Spaceship::Portal.provisioning_profile.development.find_by_bundle_id(bundle_id: bundle_id)
    dev_first_profile = dev_profiles.first
    if dev_first_profile
      # 描述文件存在，且有效时，下载描述文件
      if dev_first_profile.valid?
        isCreateProfiles = false
        #下载列表
        File.write(devMBName, dev_first_profile.download)
        putsText "下载 开发描述文件 完成"
      else
        # 无效时，删除描述文件
        putsText "删除开发描述文件"
        dev_profiles.first.delete!
      end
    end 
    if isCreateProfiles
      #创建一个 development 的 描述文件
      dev_cert = Spaceship::Portal.certificate.development.all
      if dev_cert.first
        certificate_arr = []
        certificate_arr.push(dev_cert.first)
        profile = Spaceship::Portal.provisioning_profile.development.create!(bundle_id: bundle_id, certificate: certificate_arr)
        #下载列表
        File.write(devMBName, profile.download)
        putsText "创建 开发描述文件 完成"
      end
    end
  end

  isCreateProfiles = true
  ad_profiles = Spaceship::Portal.provisioning_profile.app_store.find_by_bundle_id(bundle_id: bundle_id)
  ad_first_profile = ad_profiles.first
  if ad_first_profile
    # 描述文件存在，且有效时，下载描述文件
    if ad_first_profile.valid?
      isCreateProfiles = false
      File.write(disMBName, ad_first_profile.download)
      putsText "下载 描述文件 完成"
    else
      # 无效时，删除描述文件
      putsText "删除描述文件"
      ad_profiles.first.delete!
    end
  end
  if isCreateProfiles
    #创建一个 dis 的 描述文件
    prod_certs = Spaceship::Portal.certificate.production.all
    if prod_certs
      certificate_arr = []
      certificate_arr.push(prod_certs.first)
  
      app_store_profile = Spaceship::Portal.provisioning_profile.app_store.create!(bundle_id: bundle_id, certificate: certificate_arr)
      File.write("dis_#{bundle_id}.mobileprovision", app_store_profile.download)
      putsText "创建 dis描述文件 完成"
    end
  end
rescue Exception => e
  putsText "生成描述文件失败"
  putsText e.message
end

#system("echo " + sandbox_name + " | pbcopy")
#putsText "沙箱账号已经复制到剪切板"

File.write("z_结果.txt", $resultText)
#打开当前目录,方便查看生成的文件
system("open .")

