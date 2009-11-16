require 'rubygems'
require 'test/unit'
require 'spec'
require 'ostruct'
require 'yaml'
require 'time'
require File.dirname(__FILE__) + '/../lib/webmoney'

# Variables may be access, for example WmConfig.wmid
config = OpenStruct.new(YAML.load_file("#{ENV['HOME']}/.wm/config.yml"))
if ENV['WM_ENV']
  env_config = config.send(ENV['WM_ENV'])
  config.common.update(env_config) unless env_config.nil?
end
::WmConfig = OpenStruct.new(config.common)

class TestWM
  include Webmoney
end

def webmoney
  TestWM.new :wmid => WmConfig.wmid,
    :password => WmConfig.password,
    :key => WmConfig.key,
    :ca_cert => WmConfig.ca_cert
end