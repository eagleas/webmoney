Gem::Specification.new do |s|
  s.name = "webmoney"
  s.version = "0.0.4.4"
  s.homepage = "http://github.com/eagleas/webmoney"
  s.rubyforge_project = 'webmoney'
  s.author = "Alexander Oryol"
  s.email =  "eagle.alex@gmail.com"
  s.summary = "Webmoney interfaces and native wmsigner"
  s.has_rdoc = true
  s.files = [ "rakefile",
              "ChangeLog",
              "README",
              "lib/WebMoneyCA.crt",
              "lib/messenger.rb",
              "lib/request.rb",
              "lib/result.rb",
              "lib/passport.rb",
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
              "spec/unit/signer_spec.rb",
              "spec/unit/time_spec.rb",
              "spec/unit/webmoney_spec.rb",
              "spec/unit/wmid_spec.rb" ]
  s.extensions << 'ext/wmsigner/extconf.rb'
  s.extra_rdoc_files = ["ChangeLog", "README"]
  s.add_dependency('hpricot')
  s.add_dependency('builder')
end
