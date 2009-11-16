Gem::Specification.new do |s|
  s.name = "webmoney"
  s.version = "0.0.4.8"
  s.homepage = "http://github.com/eagleas/webmoney"
  s.rubyforge_project = 'webmoney'
  s.author = "Alexander Oryol"
  s.email =  "eagle.alex@gmail.com"
  s.summary = "Webmoney interfaces and native wmsigner"
  s.description =
<<DESC
This library should help to make requests to WebMoney Transfer http://www.wmtransfer.com
XML-interfaces: http://www.wmtransfer.com/eng/developers/interfaces/index.shtml
Gem have built-in native wmsigner tool.
DESC

  s.has_rdoc = true
  s.files = [ "rakefile",
              "ChangeLog",
              "README",
              "lib/certs/02a6c417.0",
              "lib/certs/3c58f906.0",
              "lib/certs/AddTrust_External_Root.crt",
              "lib/certs/WebMoneyCA.crt",
              "lib/messenger.rb",
              "lib/request_result.rb",
              "lib/request_retval.rb",
              "lib/request_xml.rb",
              "lib/passport.rb",
              "lib/purse.rb",
              "lib/webmoney.rb",
              "lib/wmid.rb",
              "ext/wmsigner/extconf.rb",
              "ext/wmsigner/base64.cpp",
              "ext/wmsigner/base64.h",
              "ext/wmsigner/cmdbase.cpp",
              "ext/wmsigner/cmdbase.h",
              "ext/wmsigner/crypto.cpp",
              "ext/wmsigner/crypto.h",
              "ext/wmsigner/extconf.rb",
              "ext/wmsigner/md4.cpp",
              "ext/wmsigner/md4.h",
              "ext/wmsigner/rsalib1.cpp",
              "ext/wmsigner/rsalib1.h",
              "ext/wmsigner/signer.cpp",
              "ext/wmsigner/signer.h",
              "ext/wmsigner/stdafx.cpp",
              "ext/wmsigner/stdafx.h",
              "ext/wmsigner/wmsigner.cpp",
              "tools/rakehelp.rb"]
  s.test_files = [ "spec/spec_helper.rb",
              "spec/unit/messenger_spec.rb",
              "spec/unit/passport_spec.rb",
              "spec/unit/purse_spec.rb",
              "spec/unit/signer_spec.rb",
              "spec/unit/time_spec.rb",
              "spec/unit/webmoney_spec.rb",
              "spec/unit/wmid_spec.rb" ]
  s.extensions << 'ext/wmsigner/extconf.rb'
  s.extra_rdoc_files = ["ChangeLog", "README"]
  s.add_dependency('nokogiri')
end
