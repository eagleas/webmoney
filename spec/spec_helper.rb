#encoding: utf-8
#
# ~/.wm/config.yml example:
#
# ca_cert:
#
# first:
#   wmtype: classic
#   wmid: 
#   password: 
#   key: 
#   wmz:
#
# second:
#   wmtype: light
#   wmid: 
#   password: 
#   cert: webmoney.cert
#   key: webmoney.key
#   wmz:
#

require 'rubygems'
require 'test/unit'
require 'spec'
require 'ostruct'
require 'yaml'
require 'time'
require File.dirname(__FILE__) + '/../lib/webmoney'

# Variables may be access, for example WmConfig.wmid
config = YAML.load_file("#{ENV['HOME']}/.wm/config.yml")
if ENV['WM_ENV']
  env_config = config.send(ENV['WM_ENV'])
  config.common.update(env_config) unless env_config.nil?
end
::WmConfig = OpenStruct.new(config)
raise "First user wmtype must be classic!" if WmConfig.first['wmtype'] != 'classic'

class TestWM
  include Webmoney

  def initialize(opt = {})
    defaults = {:wmid => WmConfig.first['wmid'],
                :password => WmConfig.first['password'],
                :key => WmConfig.first['key'],
                :ca_cert => WmConfig.ca_cert}
    defaults.merge!(opt)
    super(defaults)
  end
end

def getwm(config)
  if config.wmtype == "light"
    # light
    cert = OpenSSL::X509::Certificate.new(File.read(config.cert))
    key = OpenSSL::PKey::RSA.new(File.read(config.key), config.password)
    TestWM.new :wmid => config.wmid,
      :key => key,
      :cert => cert,
      :ca_cert => WmConfig.ca_cert
  else
    # classic
    TestWM.new :wmid => config.wmid,
      :password => config.password,
      :key => config.key,
      :ca_cert => config.ca_cert
  end
end

def webmoney
  getwm(OpenStruct.new(WmConfig.first))
end

def contragent
  getwm(OpenStruct.new(WmConfig.second))
end
