#encoding: utf-8
#
# Please, see RUNNING_TESTS

require 'rubygems'
require 'rspec'
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
  TestWM.new :wmid => config.wmid,
    :key => config.key,
    :password => config.password,
    :cert => config.cert,
    :ca_cert => WmConfig.ca_cert,
    :rid => config.rid
end

def webmoney
  getwm(OpenStruct.new(WmConfig.first))
end

def contragent
  getwm(OpenStruct.new(WmConfig.second))
end
